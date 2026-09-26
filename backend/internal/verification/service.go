package verification

import (
	"context"
	"crypto/rand"
	"crypto/sha256"
	"crypto/subtle"
	"encoding/hex"
	"encoding/json"
	"errors"
	"io"
	"mime"
	"net/http"
	"strconv"
	"strings"
	"unicode/utf8"

	"cloud.google.com/go/firestore"
	"cloud.google.com/go/storage"
	firebase "firebase.google.com/go/v4"
	"firebase.google.com/go/v4/appcheck"
	"firebase.google.com/go/v4/auth"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	"honestdating/backend/internal/config"
)

const (
	appCheckHeader       = "X-Firebase-AppCheck"
	faceTecProvider      = "faceTec"
	mockProviderMode     = "mockPendingCommercialServer"
	storageFinalizedType = "google.cloud.storage.object.v1.finalized"
	maximumPhotoSize     = 10 * 1024 * 1024
	maximumFaceTecBlob   = 512 * 1024
	debugPreviewEmail    = "folia.dummy@gmail.com"
	debugPreviewClaim    = "debugPreview"
)

const debugPreviewAccountPath = "systemDebugPreviewAccounts/folia"

type debugPreviewAuthenticationResponse struct {
	CustomToken string `json:"customToken"`
}

type profilePhotoVerificationRequest struct {
	MainPhotoID               string   `json:"mainPhotoId"`
	GalleryPhotoIDs           []string `json:"galleryPhotoIds"`
	LivenessVerificationToken string   `json:"livenessVerificationToken"`
}

// Service owns all private verification writes. Its handlers use Application
// Default Credentials, so client Firestore and Storage rules never need to
// grant access to identity or verification data.
type Service struct {
	appCheck                *appcheck.Client
	auth                    *auth.Client
	firestore               *firestore.Client
	storage                 *storage.Client
	storageBucket           string
	debugPreviewAuthEnabled bool
	faceTec                 config.FaceTecConfig
	provider                FaceTecProvider
}

// NewService creates the Firebase Admin clients for a Cloud Run deployment.
func NewService(ctx context.Context, cfg config.Config) (*Service, error) {
	app, err := firebase.NewApp(ctx, &firebase.Config{ProjectID: cfg.ProjectID})
	if err != nil {
		return nil, err
	}

	appCheckClient, err := app.AppCheck(ctx)
	if err != nil {
		return nil, err
	}
	authClient, err := app.Auth(ctx)
	if err != nil {
		return nil, err
	}
	firestoreClient, err := app.Firestore(ctx)
	if err != nil {
		return nil, err
	}
	storageClient, err := storage.NewClient(ctx)
	if err != nil {
		_ = firestoreClient.Close()
		return nil, err
	}

	return &Service{
		appCheck:                appCheckClient,
		auth:                    authClient,
		firestore:               firestoreClient,
		storage:                 storageClient,
		storageBucket:           cfg.StorageBucket,
		debugPreviewAuthEnabled: cfg.DebugPreviewAuthEnabled,
		faceTec:                 cfg.FaceTec,
		provider:                unconfiguredFaceTecProvider{},
	}, nil
}

// StartDebugPreviewAuthentication exchanges a Firebase-authenticated debug
// bootstrap session for a custom token for the canonical test account. It is
// disabled unless an operator explicitly enables it at runtime. The endpoint
// requires both Firebase Authentication and App Check; it never accepts an
// email, password, or client-selected UID.
func (s *Service) StartDebugPreviewAuthentication(w http.ResponseWriter, r *http.Request) {
	if !s.debugPreviewAuthEnabled {
		writeError(w, http.StatusNotFound, "The debug preview authentication service is unavailable.")
		return
	}

	decodedToken, ok := s.requireAuthenticatedAppToken(w, r)
	if !ok {
		return
	}
	if !isDebugPreviewIdentity(decodedToken) {
		writeError(w, http.StatusForbidden, "This sign-in is not eligible for the debug preview account.")
		return
	}

	canonicalUID, err := s.debugPreviewCanonicalUID(r.Context(), decodedToken.UID)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "The debug preview account could not be prepared.")
		return
	}
	customToken, err := s.auth.CustomTokenWithClaims(r.Context(), canonicalUID, map[string]interface{}{
		debugPreviewClaim: true,
	})
	if err != nil {
		writeError(w, http.StatusInternalServerError, "The debug preview account could not be prepared.")
		return
	}

	w.Header().Set("Cache-Control", "no-store")
	writeJSON(w, http.StatusOK, debugPreviewAuthenticationResponse{CustomToken: customToken})
}

// Close releases the Firestore client during a graceful Cloud Run shutdown.
func (s *Service) Close() error {
	storageErr := s.storage.Close()
	firestoreErr := s.firestore.Close()
	if storageErr != nil {
		return storageErr
	}
	return firestoreErr
}

// StartProfilePhotoVerification accepts only identifiers for images already
// written to private Storage. The main photo is the sole candidate for a later
// 3D:2D match; gallery photos are stored privately but never match candidates.
func (s *Service) StartProfilePhotoVerification(w http.ResponseWriter, r *http.Request) {
	uid, ok := s.requireAuthenticatedApp(w, r)
	if !ok {
		return
	}

	var request profilePhotoVerificationRequest
	decoder := json.NewDecoder(io.LimitReader(r.Body, 16*1024))
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(&request); err != nil || !validPhotoRequest(request) {
		writeError(w, http.StatusBadRequest, "A valid main photo and gallery photo identifiers are required.")
		return
	}
	if err := decoder.Decode(&struct{}{}); !errors.Is(err, io.EOF) {
		writeError(w, http.StatusBadRequest, "The request body is invalid.")
		return
	}
	livenessAttemptID, enrollmentReference, enrollmentStatus, ok :=
		s.authorizedLivenessEnrollment(
			r.Context(),
			uid,
			request.LivenessVerificationToken,
		)
	if !ok {
		writeError(w, http.StatusConflict, "Complete the selfie verification before validating your profile photo.")
		return
	}
	if enrollmentStatus != "verifiedByProductionFaceTecServer" &&
		s.faceTec.DecisionMode == config.FaceTecDecisionEnforce {
		writeError(w, http.StatusConflict, "Complete the selfie verification before validating your profile photo.")
		return
	}

	photoIDs := append([]string{request.MainPhotoID}, request.GalleryPhotoIDs...)
	for _, photoID := range photoIDs {
		if err := s.requirePrivateStagedPhoto(r.Context(), uid, photoID); err != nil {
			writeError(w, http.StatusBadRequest, "One of the selected photos is not available. Please upload it again.")
			return
		}
	}

	sessionID, tokenSecret, err := newPhotoVerificationToken()
	if err != nil {
		writeError(w, http.StatusInternalServerError, "The photo verification could not be started.")
		return
	}

	providerReference, providerState := "", "awaitingVerifiedLivenessEnrollment"
	if enrollmentStatus == "verifiedByProductionFaceTecServer" {
		providerReference, providerState = s.startMainPhotoMatch(
			r.Context(),
			uid,
			enrollmentReference,
			request.MainPhotoID,
		)
	}
	_, err = s.firestore.Doc(profilePhotoVerificationPath(uid, sessionID)).Create(r.Context(), map[string]interface{}{
		"schemaVersion":            1,
		"tokenDigest":              photoVerificationTokenDigest(tokenSecret),
		"mainPhotoId":              request.MainPhotoID,
		"galleryPhotoIds":          request.GalleryPhotoIDs,
		"livenessAttemptId":        livenessAttemptID,
		"livenessEnrollmentStatus": enrollmentStatus,
		"workflowStatus":           string(PhotoVerificationPending),
		"decisionMode":             s.faceTec.DecisionMode,
		"provider":                 faceTecProvider,
		"providerMode":             faceTecProviderMode(s.faceTec),
		"providerMatchStatus":      providerState,
		"providerMatchReference":   providerReference,
		"createdAt":                firestore.ServerTimestamp,
		"updatedAt":                firestore.ServerTimestamp,
	})
	if err != nil {
		writeError(w, http.StatusInternalServerError, "The photo verification could not be started.")
		return
	}

	writeJSON(w, http.StatusAccepted, map[string]string{
		"verificationToken": sessionID + "." + tokenSecret,
		"status":            string(PhotoVerificationPending),
	})
}

// GetProfilePhotoVerification returns an opaque workflow status to the owner.
// It never returns provider tokens, FaceTec decisions, or photo storage paths.
func (s *Service) GetProfilePhotoVerification(w http.ResponseWriter, r *http.Request) {
	uid, ok := s.requireAuthenticatedApp(w, r)
	if !ok {
		return
	}
	sessionID, tokenSecret, ok := parsePhotoVerificationToken(r.PathValue("token"))
	if !ok {
		writeError(w, http.StatusNotFound, "The photo verification was not found.")
		return
	}

	document := s.firestore.Doc(profilePhotoVerificationPath(uid, sessionID))
	snapshot, err := document.Get(r.Context())
	if err != nil {
		if status.Code(err) == codes.NotFound {
			writeError(w, http.StatusNotFound, "The photo verification was not found.")
			return
		}
		writeError(w, http.StatusInternalServerError, "The photo verification could not be checked.")
		return
	}

	storedDigest, _ := snapshot.Data()["tokenDigest"].(string)
	if !validPhotoVerificationTokenDigest(storedDigest, tokenSecret) {
		writeError(w, http.StatusNotFound, "The photo verification was not found.")
		return
	}

	providerReference, _ := snapshot.Data()["providerMatchReference"].(string)
	workflowStatus, providerStatus, providerErr := resolvePhotoVerification(
		r.Context(),
		s.provider,
		s.faceTec.DecisionMode,
		providerReference,
	)
	providerState := string(providerStatus)
	if providerErr != nil {
		providerState = "unavailable"
	}
	_, err = document.Update(r.Context(), []firestore.Update{
		{Path: "workflowStatus", Value: string(workflowStatus)},
		{Path: "decisionMode", Value: s.faceTec.DecisionMode},
		{Path: "providerMatchStatus", Value: providerState},
		{Path: "updatedAt", Value: firestore.ServerTimestamp},
	})
	if err != nil {
		writeError(w, http.StatusInternalServerError, "The photo verification could not be checked.")
		return
	}

	writeJSON(w, http.StatusOK, map[string]string{"status": string(workflowStatus)})
}

// StartFaceTecEnrollment creates server-owned opaque enrollment state. The
// response token is only an Honest Dating capability bound to this UID. The
// FaceTec enrollment reference remains private to the backend.
func (s *Service) StartFaceTecEnrollment(w http.ResponseWriter, r *http.Request) {
	uid, ok := s.requireAuthenticatedApp(w, r)
	if !ok {
		return
	}

	var request struct {
		BiometricConsentVersion string `json:"biometricConsentVersion"`
	}
	decoder := json.NewDecoder(io.LimitReader(r.Body, 8*1024))
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(&request); err != nil || !validConsentVersion(request.BiometricConsentVersion) {
		writeError(w, http.StatusBadRequest, "A biometric consent version is required.")
		return
	}
	if err := decoder.Decode(&struct{}{}); !errors.Is(err, io.EOF) {
		writeError(w, http.StatusBadRequest, "The request body is invalid.")
		return
	}

	attemptID, tokenSecret, err := newPhotoVerificationToken()
	if err != nil {
		writeError(w, http.StatusInternalServerError, "The verification request could not be started.")
		return
	}
	enrollmentReference, enrollmentStatus, err := s.startLivenessEnrollment(
		r.Context(),
		uid,
	)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "The verification request could not be started.")
		return
	}

	_, err = s.firestore.Doc(identityVerificationPath(uid)).Set(r.Context(), map[string]interface{}{
		"schemaVersion": 1,
		"provider":      faceTecProvider,
		"providerMode":  faceTecProviderMode(s.faceTec),
		"biometricConsent": map[string]interface{}{
			"acceptedAt": firestore.ServerTimestamp,
			"version":    strings.TrimSpace(request.BiometricConsentVersion),
		},
		"currentEnrollment": map[string]interface{}{
			"attemptId":   attemptID,
			"tokenDigest": photoVerificationTokenDigest(tokenSecret),
			"reference":   enrollmentReference,
			"status":      enrollmentStatus,
			"createdAt":   firestore.ServerTimestamp,
			"updatedAt":   firestore.ServerTimestamp,
		},
		"updatedAt": firestore.ServerTimestamp,
	})
	if err != nil {
		writeError(w, http.StatusInternalServerError, "The verification request could not be started.")
		return
	}

	writeJSON(w, http.StatusAccepted, map[string]string{
		"verificationToken": attemptID + "." + tokenSecret,
		"status":            enrollmentStatus,
	})
}

// ProcessFaceTecSessionRequest relays an encrypted FaceTec SDK request blob
// only while it is in flight to a future production provider adapter. Neither
// the request nor response blob is logged or persisted by Honest Dating.
func (s *Service) ProcessFaceTecSessionRequest(w http.ResponseWriter, r *http.Request) {
	uid, ok := s.requireAuthenticatedApp(w, r)
	if !ok {
		return
	}

	attemptID, enrollmentReference, _, ok := s.authorizedLivenessEnrollment(
		r.Context(), uid, r.PathValue("token"),
	)
	if !ok {
		writeError(w, http.StatusNotFound, "The selfie verification was not found.")
		return
	}

	var request struct {
		SessionRequestBlob string `json:"requestBlob"`
	}
	decoder := json.NewDecoder(io.LimitReader(r.Body, maximumFaceTecBlob))
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(&request); err != nil || request.SessionRequestBlob == "" || len(request.SessionRequestBlob) > maximumFaceTecBlob {
		writeError(w, http.StatusBadRequest, "The selfie verification request is invalid.")
		return
	}
	if err := decoder.Decode(&struct{}{}); !errors.Is(err, io.EOF) {
		writeError(w, http.StatusBadRequest, "The request body is invalid.")
		return
	}

	response, err := s.provider.ProcessLivenessSessionRequest(r.Context(), LivenessSessionRequest{
		UserID:              uid,
		EnrollmentReference: enrollmentReference,
		SessionRequestBlob:  request.SessionRequestBlob,
	})
	if err != nil || response.SessionResponseBlob == "" {
		writeError(w, http.StatusServiceUnavailable, "Selfie verification is temporarily unavailable.")
		return
	}
	if !s.updateLivenessEnrollmentStatus(r.Context(), uid, attemptID, r.PathValue("token"), "sessionInProgress") {
		writeError(w, http.StatusNotFound, "The selfie verification was not found.")
		return
	}

	writeJSON(w, http.StatusOK, map[string]string{"responseBlob": response.SessionResponseBlob})
}

// CompleteFaceTecEnrollment asks the server-side provider for a coarse
// liveness result after the Device SDK exits. The client never submits or
// controls this decision.
func (s *Service) CompleteFaceTecEnrollment(w http.ResponseWriter, r *http.Request) {
	uid, ok := s.requireAuthenticatedApp(w, r)
	if !ok {
		return
	}
	token := r.PathValue("token")
	attemptID, enrollmentReference, _, ok := s.authorizedLivenessEnrollment(r.Context(), uid, token)
	if !ok {
		writeError(w, http.StatusNotFound, "The selfie verification was not found.")
		return
	}

	providerStatus, providerErr := s.provider.GetLivenessEnrollmentStatus(r.Context(), enrollmentReference)
	enrollmentStatus, clientStatus := livenessStatuses(providerStatus, providerErr)
	if !s.updateLivenessEnrollmentStatus(r.Context(), uid, attemptID, token, enrollmentStatus) {
		writeError(w, http.StatusNotFound, "The selfie verification was not found.")
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"status": clientStatus})
}

// HandleStorageFinalized receives only Eventarc-delivered Cloud Storage
// finalization events. Configure the Cloud Run service as authenticated and
// grant invoke permission exclusively to its Eventarc delivery account.
func (s *Service) HandleStorageFinalized(w http.ResponseWriter, r *http.Request) {
	if r.Header.Get("ce-type") != storageFinalizedType {
		writeError(w, http.StatusBadRequest, "Unsupported event type.")
		return
	}

	var event storageFinalizedEvent
	decoder := json.NewDecoder(io.LimitReader(r.Body, 32*1024))
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(&event); err != nil {
		writeError(w, http.StatusBadRequest, "The storage event is invalid.")
		return
	}

	if event.Data.Bucket != s.storageBucket {
		w.WriteHeader(http.StatusNoContent)
		return
	}
	uid, photoID, ok := parseStagingObjectPath(event.Data.Name)
	if !ok || !isSupportedContentType(event.Data.ContentType) || !isSupportedSize(event.Data.Size) {
		w.WriteHeader(http.StatusNoContent)
		return
	}

	verificationStatus, err := s.photoVerificationStatus(r.Context(), uid)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "The photo state could not be recorded.")
		return
	}

	_, err = s.firestore.Doc(profilePhotoPath(uid, photoID)).Set(r.Context(), map[string]interface{}{
		"schemaVersion":      1,
		"provider":           faceTecProvider,
		"providerMode":       mockProviderMode,
		"sourceObjectPath":   event.Data.Name,
		"verificationStatus": verificationStatus,
		"visibility":         "private",
		"uploadedAt":         firestore.ServerTimestamp,
		"updatedAt":          firestore.ServerTimestamp,
	})
	if err != nil {
		writeError(w, http.StatusInternalServerError, "The photo state could not be recorded.")
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func (s *Service) requireAuthenticatedApp(w http.ResponseWriter, r *http.Request) (string, bool) {
	decodedIDToken, ok := s.requireAuthenticatedAppToken(w, r)
	if !ok {
		return "", false
	}
	return decodedIDToken.UID, true
}

func (s *Service) requireAuthenticatedAppToken(w http.ResponseWriter, r *http.Request) (*auth.Token, bool) {
	idToken, ok := bearerToken(r.Header.Get("Authorization"))
	if !ok {
		writeError(w, http.StatusUnauthorized, "Authentication is required.")
		return nil, false
	}
	decodedIDToken, err := s.auth.VerifyIDToken(r.Context(), idToken)
	if err != nil {
		writeError(w, http.StatusUnauthorized, "Authentication is required.")
		return nil, false
	}
	if !s.requireAppCheck(w, r) {
		return nil, false
	}
	return decodedIDToken, true
}

func (s *Service) requireAppCheck(w http.ResponseWriter, r *http.Request) bool {
	appCheckToken := strings.TrimSpace(r.Header.Get(appCheckHeader))
	if appCheckToken == "" {
		writeError(w, http.StatusUnauthorized, "App verification is required.")
		return false
	}
	if _, err := s.appCheck.VerifyToken(appCheckToken); err != nil {
		writeError(w, http.StatusUnauthorized, "App verification is required.")
		return false
	}
	return true
}

func isDebugPreviewIdentity(token *auth.Token) bool {
	if token == nil {
		return false
	}
	if token.Firebase.SignInProvider == "anonymous" || token.Claims[debugPreviewClaim] == true {
		return true
	}
	email, _ := token.Claims["email"].(string)
	return token.Firebase.SignInProvider == "google.com" &&
		strings.EqualFold(strings.TrimSpace(email), debugPreviewEmail)
}

// debugPreviewCanonicalUID records the first eligible test identity as the
// shared account owner. Every later device receives a token for that same UID,
// so private Storage and verification records retain one owner.
func (s *Service) debugPreviewCanonicalUID(ctx context.Context, bootstrapUID string) (string, error) {
	document := s.firestore.Doc(debugPreviewAccountPath)
	canonicalUID := ""
	err := s.firestore.RunTransaction(ctx, func(ctx context.Context, transaction *firestore.Transaction) error {
		snapshot, err := transaction.Get(document)
		if status.Code(err) == codes.NotFound {
			canonicalUID = bootstrapUID
			return transaction.Set(document, map[string]interface{}{
				"schemaVersion": 1,
				"canonicalUID":  canonicalUID,
				"createdAt":     firestore.ServerTimestamp,
				"updatedAt":     firestore.ServerTimestamp,
			})
		}
		if err != nil {
			return err
		}
		storedUID, _ := snapshot.Data()["canonicalUID"].(string)
		if strings.TrimSpace(storedUID) == "" {
			return errors.New("debug preview account has no canonical owner")
		}
		canonicalUID = storedUID
		return transaction.Update(document, []firestore.Update{
			{Path: "updatedAt", Value: firestore.ServerTimestamp},
		})
	})
	return canonicalUID, err
}

func (s *Service) photoVerificationStatus(ctx context.Context, uid string) (string, error) {
	snapshot, err := s.firestore.Doc(identityVerificationPath(uid)).Get(ctx)
	if err != nil {
		if status.Code(err) == codes.NotFound {
			return "requiresVerifiedLivenessEnrollment", nil
		}
		return "", err
	}

	enrollment, ok := snapshot.Data()["currentEnrollment"].(map[string]interface{})
	if !ok || enrollment["status"] != "verifiedByProductionFaceTecServer" {
		return mockProviderMode, nil
	}
	return "requiresFaceTec3D2DMatch", nil
}

type storageFinalizedEvent struct {
	Data struct {
		Bucket      string `json:"bucket"`
		Name        string `json:"name"`
		ContentType string `json:"contentType"`
		Size        string `json:"size"`
	} `json:"data"`
}

func identityVerificationPath(uid string) string {
	return "users/" + uid + "/private/identityVerification"
}

func profilePhotoPath(uid string, photoID string) string {
	return "users/" + uid + "/private/profilePhotos/" + photoID
}

func profilePhotoVerificationPath(uid string, sessionID string) string {
	return "users/" + uid + "/private/profilePhotoVerifications/" + sessionID
}

func profilePhotoObjectPath(uid string, photoID string) string {
	return "users/" + uid + "/profile-photo-staging/" + photoID + "/original"
}

func validPhotoRequest(request profilePhotoVerificationRequest) bool {
	if !validPathSegment(request.MainPhotoID) || len(request.GalleryPhotoIDs) > 8 {
		return false
	}
	seen := map[string]bool{request.MainPhotoID: true}
	for _, photoID := range request.GalleryPhotoIDs {
		if !validPathSegment(photoID) || seen[photoID] {
			return false
		}
		seen[photoID] = true
	}
	return true
}

func (s *Service) requirePrivateStagedPhoto(ctx context.Context, uid string, photoID string) error {
	attributes, err := s.storage.Bucket(s.storageBucket).Object(profilePhotoObjectPath(uid, photoID)).Attrs(ctx)
	if err != nil {
		return err
	}
	if !isSupportedContentType(attributes.ContentType) || attributes.Size <= 0 || attributes.Size > maximumPhotoSize {
		return errors.New("unsupported staged photo")
	}
	return nil
}

func (s *Service) startMainPhotoMatch(ctx context.Context, uid, enrollmentReference, mainPhotoID string) (string, string) {
	result, err := s.provider.StartMainPhotoMatch(ctx, MainPhotoMatchRequest{
		UserID:              uid,
		EnrollmentReference: enrollmentReference,
		MainPhotoObjectPath: profilePhotoObjectPath(uid, mainPhotoID),
	})
	if err != nil || result.MatchReference == "" {
		return "", "unavailable"
	}
	return result.MatchReference, string(ProviderMatchPending)
}

// startLivenessEnrollment is the server-owned seam for the future production
// adapter. The current iOS Test API bridge is intentionally separate, so the
// unconfigured path records only an opaque local reference and no liveness
// result.
func (s *Service) startLivenessEnrollment(ctx context.Context, uid string) (string, string, error) {
	result, err := s.provider.StartLivenessEnrollment(ctx, LivenessEnrollmentRequest{
		UserID: uid,
	})
	if err == nil && result.EnrollmentReference != "" {
		return result.EnrollmentReference, "pendingFaceTecProvider", nil
	}
	reference, referenceErr := opaqueID()
	if referenceErr != nil {
		return "", "", referenceErr
	}
	return reference, "awaitingProductionFaceTecServer", nil
}

// authorizedLivenessEnrollment verifies that the opaque registration-flow
// token belongs to the authenticated user's current server-owned enrollment.
// It never returns the enrollment reference to a mobile caller.
func (s *Service) authorizedLivenessEnrollment(ctx context.Context, uid, token string) (string, string, string, bool) {
	attemptID, tokenSecret, ok := parsePhotoVerificationToken(token)
	if !ok {
		return "", "", "", false
	}
	snapshot, err := s.firestore.Doc(identityVerificationPath(uid)).Get(ctx)
	if err != nil {
		return "", "", "", false
	}
	enrollment, ok := snapshot.Data()["currentEnrollment"].(map[string]interface{})
	if !ok {
		return "", "", "", false
	}
	storedAttemptID, _ := enrollment["attemptId"].(string)
	storedDigest, _ := enrollment["tokenDigest"].(string)
	reference, _ := enrollment["reference"].(string)
	statusValue, _ := enrollment["status"].(string)
	if storedAttemptID != attemptID || reference == "" || statusValue == "" || !validPhotoVerificationTokenDigest(storedDigest, tokenSecret) {
		return "", "", "", false
	}
	return attemptID, reference, statusValue, true
}

// updateLivenessEnrollmentStatus compares the opaque capability again inside
// a transaction. An old registration-flow token cannot overwrite a newer
// enrollment for the same account.
func (s *Service) updateLivenessEnrollmentStatus(ctx context.Context, uid, attemptID, token, enrollmentStatus string) bool {
	_, tokenSecret, ok := parsePhotoVerificationToken(token)
	if !ok {
		return false
	}
	document := s.firestore.Doc(identityVerificationPath(uid))
	err := s.firestore.RunTransaction(ctx, func(ctx context.Context, transaction *firestore.Transaction) error {
		snapshot, err := transaction.Get(document)
		if err != nil {
			return err
		}
		enrollment, ok := snapshot.Data()["currentEnrollment"].(map[string]interface{})
		if !ok {
			return status.Error(codes.NotFound, "enrollment not found")
		}
		storedAttemptID, _ := enrollment["attemptId"].(string)
		storedDigest, _ := enrollment["tokenDigest"].(string)
		if storedAttemptID != attemptID || !validPhotoVerificationTokenDigest(storedDigest, tokenSecret) {
			return status.Error(codes.NotFound, "enrollment not found")
		}
		return transaction.Update(document, []firestore.Update{
			{Path: "currentEnrollment.status", Value: enrollmentStatus},
			{Path: "currentEnrollment.updatedAt", Value: firestore.ServerTimestamp},
			{Path: "updatedAt", Value: firestore.ServerTimestamp},
		})
	})
	return err == nil
}

func livenessStatuses(providerStatus ProviderLivenessStatus, providerErr error) (string, string) {
	if providerErr != nil || providerStatus == ProviderLivenessUnavailable {
		return "unavailable", "unavailable"
	}
	switch providerStatus {
	case ProviderLivenessApproved:
		return "verifiedByProductionFaceTecServer", "approved"
	case ProviderLivenessRejected:
		return "rejectedByProductionFaceTecServer", "rejected"
	default:
		return "pendingFaceTecProvider", "pending"
	}
}

func faceTecProviderMode(faceTec config.FaceTecConfig) string {
	return faceTec.ProviderMode
}

func newPhotoVerificationToken() (string, string, error) {
	sessionID, err := opaqueID()
	if err != nil {
		return "", "", err
	}
	secret, err := opaqueID()
	if err != nil {
		return "", "", err
	}
	return sessionID, secret, nil
}

func parsePhotoVerificationToken(token string) (string, string, bool) {
	parts := strings.Split(token, ".")
	if len(parts) != 2 || !validOpaqueID(parts[0]) || !validOpaqueID(parts[1]) {
		return "", "", false
	}
	return parts[0], parts[1], true
}

func validOpaqueID(value string) bool {
	if len(value) != 64 {
		return false
	}
	_, err := hex.DecodeString(value)
	return err == nil
}

func photoVerificationTokenDigest(secret string) string {
	digest := sha256.Sum256([]byte(secret))
	return hex.EncodeToString(digest[:])
}

func validPhotoVerificationTokenDigest(storedDigest string, secret string) bool {
	expectedDigest := photoVerificationTokenDigest(secret)
	return subtle.ConstantTimeCompare([]byte(storedDigest), []byte(expectedDigest)) == 1
}

func parseStagingObjectPath(path string) (string, string, bool) {
	parts := strings.Split(path, "/")
	if len(parts) != 6 || parts[0] != "users" || parts[2] != "profile-photo-staging" || parts[5] != "original" {
		return "", "", false
	}
	if !validPathSegment(parts[1]) || !validPathSegment(parts[3]) {
		return "", "", false
	}
	return parts[1], parts[3], true
}

func validPathSegment(value string) bool {
	return value != "" && len(value) <= 128 && !strings.ContainsAny(value, "/\\")
}

func isSupportedContentType(value string) bool {
	mediaType, _, err := mime.ParseMediaType(value)
	if err != nil {
		return false
	}
	switch strings.ToLower(mediaType) {
	case "image/jpeg", "image/png", "image/webp", "image/heic", "image/heif":
		return true
	default:
		return false
	}
}

func isSupportedSize(value string) bool {
	size, err := strconv.ParseInt(value, 10, 64)
	return err == nil && size > 0 && size <= maximumPhotoSize
}

func validConsentVersion(value string) bool {
	trimmed := strings.TrimSpace(value)
	return trimmed != "" && utf8.RuneCountInString(trimmed) <= 128
}

func opaqueID() (string, error) {
	bytes := make([]byte, 32)
	if _, err := rand.Read(bytes); err != nil {
		return "", err
	}
	return hex.EncodeToString(bytes), nil
}

func bearerToken(header string) (string, bool) {
	parts := strings.Fields(header)
	if len(parts) != 2 || !strings.EqualFold(parts[0], "Bearer") || parts[1] == "" {
		return "", false
	}
	return parts[1], true
}

func writeError(w http.ResponseWriter, status int, message string) {
	writeJSON(w, status, map[string]string{"error": message})
}

func writeJSON(w http.ResponseWriter, status int, body interface{}) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(body)
}
