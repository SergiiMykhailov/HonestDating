package verification

import (
	"context"
	"errors"
)

// FaceTecProvider is the server-only port for FaceTec. In production, the
// mobile Device SDK may transiently relay encrypted session blobs through the
// backend; the backend never persists or logs them. A production adapter uses
// the opaque enrollment reference and private Storage object path here.
//
// The current Test API liveness bridge remains native iOS preview code. It is
// deliberately not represented as a production server match result.
type FaceTecProvider interface {
	StartLivenessEnrollment(context.Context, LivenessEnrollmentRequest) (LivenessEnrollmentResult, error)
	ProcessLivenessSessionRequest(context.Context, LivenessSessionRequest) (LivenessSessionResponse, error)
	GetLivenessEnrollmentStatus(context.Context, string) (ProviderLivenessStatus, error)
	StartMainPhotoMatch(context.Context, MainPhotoMatchRequest) (MainPhotoMatchResult, error)
	GetMainPhotoMatch(context.Context, string) (ProviderMatchStatus, error)
}

type LivenessEnrollmentRequest struct {
	UserID string
}

type LivenessEnrollmentResult struct {
	EnrollmentReference string
}

// LivenessSessionRequest contains an encrypted FaceTec SDK blob only while it
// is in transit to FaceTec Server. It must never be logged or persisted.
type LivenessSessionRequest struct {
	UserID              string
	EnrollmentReference string
	SessionRequestBlob  string
}

// LivenessSessionResponse returns the opaque encrypted response blob directly
// to the Device SDK. It must never be stored in Firestore or Cloud Storage.
type LivenessSessionResponse struct {
	SessionResponseBlob string
}

type ProviderLivenessStatus string

const (
	ProviderLivenessPending     ProviderLivenessStatus = "pending"
	ProviderLivenessApproved    ProviderLivenessStatus = "approved"
	ProviderLivenessRejected    ProviderLivenessStatus = "rejected"
	ProviderLivenessUnavailable ProviderLivenessStatus = "unavailable"
)

type MainPhotoMatchRequest struct {
	UserID              string
	EnrollmentReference string
	MainPhotoObjectPath string
}

type MainPhotoMatchResult struct {
	MatchReference string
}

type ProviderMatchStatus string

const (
	ProviderMatchPending     ProviderMatchStatus = "pending"
	ProviderMatchApproved    ProviderMatchStatus = "approved"
	ProviderMatchRejected    ProviderMatchStatus = "rejected"
	ProviderMatchUnavailable ProviderMatchStatus = "unavailable"
)

var ErrFaceTecProviderUnconfigured = errors.New("FaceTec provider is not configured")

// unconfiguredFaceTecProvider is intentional. We cannot invent FaceTec's
// production 3D:2D endpoint, credential format, or request payload. Replacing
// this adapter later is the only required production-specific code change.
type unconfiguredFaceTecProvider struct{}

func (unconfiguredFaceTecProvider) StartLivenessEnrollment(context.Context, LivenessEnrollmentRequest) (LivenessEnrollmentResult, error) {
	return LivenessEnrollmentResult{}, ErrFaceTecProviderUnconfigured
}

func (unconfiguredFaceTecProvider) ProcessLivenessSessionRequest(context.Context, LivenessSessionRequest) (LivenessSessionResponse, error) {
	return LivenessSessionResponse{}, ErrFaceTecProviderUnconfigured
}

func (unconfiguredFaceTecProvider) GetLivenessEnrollmentStatus(context.Context, string) (ProviderLivenessStatus, error) {
	return ProviderLivenessUnavailable, ErrFaceTecProviderUnconfigured
}

func (unconfiguredFaceTecProvider) StartMainPhotoMatch(context.Context, MainPhotoMatchRequest) (MainPhotoMatchResult, error) {
	return MainPhotoMatchResult{}, ErrFaceTecProviderUnconfigured
}

func (unconfiguredFaceTecProvider) GetMainPhotoMatch(context.Context, string) (ProviderMatchStatus, error) {
	return ProviderMatchUnavailable, ErrFaceTecProviderUnconfigured
}
