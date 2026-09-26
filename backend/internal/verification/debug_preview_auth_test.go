package verification

import (
	"testing"

	"firebase.google.com/go/v4/auth"
)

func TestDebugPreviewIdentityEligibility(t *testing.T) {
	tests := []struct {
		name  string
		token *auth.Token
		want  bool
	}{
		{
			name:  "anonymous bootstrap session",
			token: &auth.Token{Firebase: auth.FirebaseInfo{SignInProvider: "anonymous"}},
			want:  true,
		},
		{
			name:  "custom debug account session",
			token: &auth.Token{Claims: map[string]interface{}{debugPreviewClaim: true}},
			want:  true,
		},
		{
			name: "exact Google test identity",
			token: &auth.Token{
				Firebase: auth.FirebaseInfo{SignInProvider: "google.com"},
				Claims:   map[string]interface{}{"email": "folia.dummy@gmail.com"},
			},
			want: true,
		},
		{
			name: "other Google identity",
			token: &auth.Token{
				Firebase: auth.FirebaseInfo{SignInProvider: "google.com"},
				Claims:   map[string]interface{}{"email": "someone@example.com"},
			},
			want: false,
		},
		{name: "no token", want: false},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			if got := isDebugPreviewIdentity(test.token); got != test.want {
				t.Fatalf("isDebugPreviewIdentity() = %t, want %t", got, test.want)
			}
		})
	}
}
