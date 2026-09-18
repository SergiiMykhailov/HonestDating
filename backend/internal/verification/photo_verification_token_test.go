package verification

import "testing"

func TestPhotoVerificationTokenBindsToItsStoredDigest(t *testing.T) {
	sessionID, secret, err := newPhotoVerificationToken()
	if err != nil {
		t.Fatal(err)
	}
	parsedSessionID, parsedSecret, ok := parsePhotoVerificationToken(sessionID + "." + secret)
	if !ok || parsedSessionID != sessionID || parsedSecret != secret {
		t.Fatal("expected generated opaque token to parse")
	}

	storedDigest := photoVerificationTokenDigest(secret)
	if !validPhotoVerificationTokenDigest(storedDigest, secret) {
		t.Fatal("expected token to validate against its own digest")
	}
	if validPhotoVerificationTokenDigest(storedDigest, "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef") {
		t.Fatal("a token must not validate against another session secret")
	}
}

func TestPhotoVerificationTokenRejectsMalformedValues(t *testing.T) {
	for _, value := range []string{"", "only-one-part", "one.two.three", "abc.def"} {
		if _, _, ok := parsePhotoVerificationToken(value); ok {
			t.Fatalf("%q unexpectedly parsed", value)
		}
	}
}

func TestPhotoVerificationDocumentsAreOwnedByTheirPrivateUserPath(t *testing.T) {
	const sessionID = "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
	ownerPath := profilePhotoVerificationPath("owner", sessionID)
	otherUserPath := profilePhotoVerificationPath("other-user", sessionID)
	if ownerPath == otherUserPath {
		t.Fatal("a session ID must not resolve outside its authenticated owner's path")
	}
}
