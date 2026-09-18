package verification

import (
	"errors"
	"testing"
)

func TestLivenessStatusesExposeOnlyCoarseResult(t *testing.T) {
	tests := []struct {
		name           string
		providerStatus ProviderLivenessStatus
		err            error
		wantStored     string
		wantClient     string
	}{
		{"approved", ProviderLivenessApproved, nil, "verifiedByProductionFaceTecServer", "approved"},
		{"rejected", ProviderLivenessRejected, nil, "rejectedByProductionFaceTecServer", "rejected"},
		{"pending", ProviderLivenessPending, nil, "pendingFaceTecProvider", "pending"},
		{"unavailable", ProviderLivenessUnavailable, nil, "unavailable", "unavailable"},
		{"provider failure", ProviderLivenessPending, errors.New("provider unavailable"), "unavailable", "unavailable"},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			stored, client := livenessStatuses(test.providerStatus, test.err)
			if stored != test.wantStored || client != test.wantClient {
				t.Fatalf("got (%q, %q), want (%q, %q)", stored, client, test.wantStored, test.wantClient)
			}
		})
	}
}
