package verification

import "testing"

func TestSendLikeTransitionCreatesMatchProjection(t *testing.T) {
	pair := relationshipPair{Likes: map[string]string{"other": "their reason"}}
	pair, err := sendLikeTransition(pair, "viewer", "my reason")
	if err != nil {
		t.Fatal(err)
	}
	projection := relationshipProjection("viewer", "other", pair)
	if projection["romanticState"] != relationshipMatched {
		t.Fatalf("romanticState = %v, want %q", projection["romanticState"], relationshipMatched)
	}
	if projection["incomingLikeReason"] != "their reason" {
		t.Fatalf("incomingLikeReason = %v", projection["incomingLikeReason"])
	}
}

func TestFriendshipOfferReplacesIncomingLike(t *testing.T) {
	pair := relationshipPair{Likes: map[string]string{"other": "their reason"}}
	pair, err := sendFriendshipOfferTransition(pair, "viewer", "other", "friendship reason")
	if err != nil {
		t.Fatal(err)
	}
	if len(pair.Likes) != 0 {
		t.Fatalf("likes = %v, want empty", pair.Likes)
	}
	viewer := relationshipProjection("viewer", "other", pair)
	other := relationshipProjection("other", "viewer", pair)
	if viewer["friendshipState"] != friendshipOfferSent || other["friendshipState"] != friendshipOfferReceived {
		t.Fatalf("states = %v / %v", viewer["friendshipState"], other["friendshipState"])
	}
}

func TestOnlyOfferRecipientCanAcceptFriendship(t *testing.T) {
	pair := relationshipPair{
		Likes:              map[string]string{},
		FriendshipSenderID: "sender",
		FriendshipReason:   "friendship reason",
	}
	if _, err := acceptFriendshipOfferTransition(pair, "someone-else"); err == nil {
		t.Fatal("expected non-recipient acceptance to fail")
	}
	pair, err := acceptFriendshipOfferTransition(pair, "sender")
	if err != nil {
		t.Fatal(err)
	}
	if !pair.Friends {
		t.Fatal("friends = false, want true")
	}
}

func TestRelationshipPairIDIsOrderIndependent(t *testing.T) {
	if relationshipPairID("a", "b") != relationshipPairID("b", "a") {
		t.Fatal("pair ID depends on argument order")
	}
}

func TestRelationshipPairUIDsAreSorted(t *testing.T) {
	ids := relationshipPairUIDs("z", "a")
	if ids[0] != "a" || ids[1] != "z" {
		t.Fatalf("relationshipPairUIDs() = %v", ids)
	}
}
