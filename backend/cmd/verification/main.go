package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"time"

	"honestdating/backend/internal/config"
	"honestdating/backend/internal/verification"
)

func main() {
	ctx := context.Background()
	cfg, err := config.Load()
	if err != nil {
		log.Fatal("verification service configuration is invalid")
	}

	service, err := verification.NewService(ctx, cfg)
	if err != nil {
		log.Fatal("verification service could not initialize")
	}
	defer service.Close()

	mux := http.NewServeMux()
	mux.HandleFunc("GET /health", health)
	mux.HandleFunc("POST /v1/debug-preview-auth", service.StartDebugPreviewAuthentication)
	// The identity-verifications routes are the stable mobile contract. Keep
	// the original enrollment route temporarily so existing debug builds do
	// not break during this client migration.
	mux.HandleFunc("POST /v1/identity-verifications", service.StartFaceTecEnrollment)
	mux.HandleFunc("POST /v1/identity-verifications/{token}/facetec-session-requests", service.ProcessFaceTecSessionRequest)
	mux.HandleFunc("POST /v1/identity-verifications/{token}/completion", service.CompleteFaceTecEnrollment)
	mux.HandleFunc("POST /v1/facetec/enrollments", service.StartFaceTecEnrollment)
	mux.HandleFunc("POST /v1/profile-photo-verifications", service.StartProfilePhotoVerification)
	mux.HandleFunc("GET /v1/profile-photo-verifications/{token}", service.GetProfilePhotoVerification)
	mux.HandleFunc("POST /v1/relationships/{targetUid}/likes", service.SendLike)
	mux.HandleFunc("POST /v1/relationships/{targetUid}/friendship-offers", service.SendFriendshipOffer)
	mux.HandleFunc("POST /v1/relationships/{targetUid}/friendship-offers/acceptance", service.AcceptFriendshipOffer)
	mux.HandleFunc("POST /events/storage", service.HandleStorageFinalized)

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	server := &http.Server{
		Addr:              ":" + port,
		Handler:           mux,
		ReadHeaderTimeout: 5 * time.Second,
		ReadTimeout:       10 * time.Second,
		WriteTimeout:      10 * time.Second,
		IdleTimeout:       30 * time.Second,
	}

	log.Print("verification service is ready")
	if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
		log.Fatal("verification service stopped unexpectedly")
	}
}

// health is deliberately dependency-free: a successful response means the
// Cloud Run revision is accepting HTTP requests. It does not reveal project,
// credential, or verification state.
func health(w http.ResponseWriter, _ *http.Request) {
	w.Header().Set("Cache-Control", "no-store")
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(http.StatusOK)
	_, _ = w.Write([]byte(`{"status":"ok"}`))
}
