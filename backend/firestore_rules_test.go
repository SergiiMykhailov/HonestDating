package backend

import (
	"os"
	"strings"
	"testing"
)

func TestFirestoreRulesKeepAccountOwnershipAndVerificationPrivacy(t *testing.T) {
	rules, err := os.ReadFile("firestore.rules")
	if err != nil {
		t.Fatalf("read Firestore rules: %v", err)
	}

	for _, requiredRule := range []string{
		"function isOwner(userId)",
		"match /users/{userId}",
		"allow get: if isOwner(userId);",
		"allow delete: if false;",
		"match /users/{userId}/private/{document=**}",
		"allow read, write: if false;",
	} {
		if !strings.Contains(string(rules), requiredRule) {
			t.Errorf("expected Firestore rules to contain %q", requiredRule)
		}
	}
}
