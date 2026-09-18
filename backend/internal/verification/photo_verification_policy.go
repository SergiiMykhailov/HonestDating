package verification

import (
	"context"

	"honestdating/backend/internal/config"
)

type PhotoVerificationStatus string

const (
	PhotoVerificationPending     PhotoVerificationStatus = "pending"
	PhotoVerificationApproved    PhotoVerificationStatus = "approved"
	PhotoVerificationRejected    PhotoVerificationStatus = "rejected"
	PhotoVerificationUnavailable PhotoVerificationStatus = "unavailable"
)

// applyPhotoVerificationPolicy separates the product workflow from the
// provider decision. In approval_override, `approved` means only that the
// preview workflow may continue; it never asserts a real FaceTec photo match.
func applyPhotoVerificationPolicy(
	decisionMode string,
	providerStatus ProviderMatchStatus,
	providerErr error,
) PhotoVerificationStatus {
	if decisionMode == config.FaceTecDecisionApprovalOverride {
		return PhotoVerificationApproved
	}
	if providerErr != nil || providerStatus == ProviderMatchUnavailable {
		return PhotoVerificationUnavailable
	}
	switch providerStatus {
	case ProviderMatchApproved:
		return PhotoVerificationApproved
	case ProviderMatchRejected:
		return PhotoVerificationRejected
	default:
		return PhotoVerificationPending
	}
}

// resolvePhotoVerification always gives an installed provider adapter a chance
// to run. The decision policy deliberately decides what the mobile workflow
// sees afterward: approval_override discards the provider outcome, while
// enforce honors it.
func resolvePhotoVerification(
	ctx context.Context,
	provider FaceTecProvider,
	decisionMode string,
	providerReference string,
) (PhotoVerificationStatus, ProviderMatchStatus, error) {
	if providerReference == "" {
		providerStatus := ProviderMatchUnavailable
		providerErr := ErrFaceTecProviderUnconfigured
		return applyPhotoVerificationPolicy(decisionMode, providerStatus, providerErr), providerStatus, providerErr
	}
	providerStatus, providerErr := provider.GetMainPhotoMatch(ctx, providerReference)
	return applyPhotoVerificationPolicy(decisionMode, providerStatus, providerErr), providerStatus, providerErr
}
