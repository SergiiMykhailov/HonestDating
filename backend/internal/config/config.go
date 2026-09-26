package config

import (
	"fmt"
	"os"
	"strconv"
	"strings"
)

// Config contains non-secret Cloud Run deployment configuration.
type Config struct {
	ProjectID               string
	StorageBucket           string
	DebugPreviewAuthEnabled bool
	FaceTec                 FaceTecConfig
}

// FaceTecConfig is runtime-only provider configuration. Server credentials
// belong in Cloud Run's secret environment, never in source control. A server
// URL and credential alone do not enable matching: the official 3D:2D request
// contract must still be installed as an adapter.
type FaceTecConfig struct {
	ProviderMode string
	DecisionMode string
	ServerURL    string
	Credential   string
}

const (
	FaceTecDecisionApprovalOverride = "approval_override"
	FaceTecDecisionEnforce          = "enforce"
	FaceTecProviderUnconfigured     = "unconfigured"
	FaceTecProviderAdapterPending   = "adapter_contract_pending"
)

// Load reads configuration supplied by the Cloud Run environment. Credentials
// are always resolved through Application Default Credentials, never from a
// credential file committed to this repository.
func Load() (Config, error) {
	projectID := firstNonEmpty(
		os.Getenv("GOOGLE_CLOUD_PROJECT"),
		os.Getenv("GCLOUD_PROJECT"),
	)
	storageBucket := strings.TrimSpace(os.Getenv("FIREBASE_STORAGE_BUCKET"))
	decisionMode := strings.TrimSpace(os.Getenv("FACETEC_DECISION_MODE"))
	if decisionMode == "" {
		decisionMode = FaceTecDecisionApprovalOverride
	}
	providerMode := strings.TrimSpace(os.Getenv("FACETEC_PROVIDER_MODE"))
	if providerMode == "" {
		providerMode = FaceTecProviderUnconfigured
	}
	debugPreviewAuthEnabled, err := optionalBooleanEnvironment(
		"DEBUG_PREVIEW_AUTH_ENABLED",
	)
	if err != nil {
		return Config{}, err
	}

	if projectID == "" {
		return Config{}, fmt.Errorf("missing Google Cloud project ID")
	}
	if storageBucket == "" {
		return Config{}, fmt.Errorf("missing Firebase Storage bucket")
	}
	if decisionMode != FaceTecDecisionApprovalOverride && decisionMode != FaceTecDecisionEnforce {
		return Config{}, fmt.Errorf("invalid FaceTec decision mode")
	}
	if providerMode != FaceTecProviderUnconfigured && providerMode != FaceTecProviderAdapterPending {
		return Config{}, fmt.Errorf("invalid FaceTec provider mode")
	}

	return Config{
		ProjectID:               projectID,
		StorageBucket:           storageBucket,
		DebugPreviewAuthEnabled: debugPreviewAuthEnabled,
		FaceTec: FaceTecConfig{
			ProviderMode: providerMode,
			DecisionMode: decisionMode,
			ServerURL:    strings.TrimSpace(os.Getenv("FACETEC_SERVER_URL")),
			Credential:   strings.TrimSpace(os.Getenv("FACETEC_SERVER_CREDENTIAL")),
		},
	}, nil
}

func optionalBooleanEnvironment(name string) (bool, error) {
	value := strings.TrimSpace(os.Getenv(name))
	if value == "" {
		return false, nil
	}
	parsed, err := strconv.ParseBool(value)
	if err != nil {
		return false, fmt.Errorf("invalid %s", name)
	}
	return parsed, nil
}

func firstNonEmpty(values ...string) string {
	for _, value := range values {
		if trimmed := strings.TrimSpace(value); trimmed != "" {
			return trimmed
		}
	}
	return ""
}
