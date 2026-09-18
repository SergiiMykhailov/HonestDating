package verification

import (
	"context"
	"errors"
	"testing"

	"honestdating/backend/internal/config"
)

type fakeFaceTecProvider struct {
	status ProviderMatchStatus
	err    error
	checks int
}

func (f *fakeFaceTecProvider) StartLivenessEnrollment(context.Context, LivenessEnrollmentRequest) (LivenessEnrollmentResult, error) {
	return LivenessEnrollmentResult{}, nil
}

func (f *fakeFaceTecProvider) ProcessLivenessSessionRequest(context.Context, LivenessSessionRequest) (LivenessSessionResponse, error) {
	return LivenessSessionResponse{}, nil
}

func (f *fakeFaceTecProvider) GetLivenessEnrollmentStatus(context.Context, string) (ProviderLivenessStatus, error) {
	return ProviderLivenessUnavailable, nil
}

func (f *fakeFaceTecProvider) StartMainPhotoMatch(context.Context, MainPhotoMatchRequest) (MainPhotoMatchResult, error) {
	return MainPhotoMatchResult{}, nil
}

func (f *fakeFaceTecProvider) GetMainPhotoMatch(context.Context, string) (ProviderMatchStatus, error) {
	f.checks++
	return f.status, f.err
}

func TestApprovalOverrideApprovesRegardlessOfProviderResult(t *testing.T) {
	for _, result := range []struct {
		name   string
		status ProviderMatchStatus
		err    error
	}{
		{name: "rejected", status: ProviderMatchRejected},
		{name: "unavailable", status: ProviderMatchUnavailable},
		{name: "failure", err: errors.New("provider unavailable")},
	} {
		t.Run(result.name, func(t *testing.T) {
			got := applyPhotoVerificationPolicy(config.FaceTecDecisionApprovalOverride, result.status, result.err)
			if got != PhotoVerificationApproved {
				t.Fatalf("got %q, want approved", got)
			}
		})
	}
}

func TestApprovalOverrideInvokesAnInstalledProviderButDiscardsItsResult(t *testing.T) {
	provider := &fakeFaceTecProvider{status: ProviderMatchRejected}
	workflowStatus, providerStatus, err := resolvePhotoVerification(
		context.Background(),
		provider,
		config.FaceTecDecisionApprovalOverride,
		"opaque-provider-reference",
	)
	if err != nil || provider.checks != 1 || providerStatus != ProviderMatchRejected {
		t.Fatal("expected the provider adapter to be checked exactly once")
	}
	if workflowStatus != PhotoVerificationApproved {
		t.Fatalf("got %q, want approved workflow", workflowStatus)
	}
}

func TestEnforcementHonorsProviderStatus(t *testing.T) {
	tests := []struct {
		name string
		in   ProviderMatchStatus
		want PhotoVerificationStatus
	}{
		{name: "pending", in: ProviderMatchPending, want: PhotoVerificationPending},
		{name: "approved", in: ProviderMatchApproved, want: PhotoVerificationApproved},
		{name: "rejected", in: ProviderMatchRejected, want: PhotoVerificationRejected},
		{name: "unavailable", in: ProviderMatchUnavailable, want: PhotoVerificationUnavailable},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			got := applyPhotoVerificationPolicy(config.FaceTecDecisionEnforce, test.in, nil)
			if got != test.want {
				t.Fatalf("got %q, want %q", got, test.want)
			}
		})
	}
}

func TestEnforcementMakesProviderFailuresUnavailable(t *testing.T) {
	got := applyPhotoVerificationPolicy(config.FaceTecDecisionEnforce, ProviderMatchPending, errors.New("network"))
	if got != PhotoVerificationUnavailable {
		t.Fatalf("got %q, want unavailable", got)
	}
}
