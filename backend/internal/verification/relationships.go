package verification

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"sort"
	"strings"

	"cloud.google.com/go/firestore"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

const (
	relationshipNone         = "none"
	relationshipLikeSent     = "likeSent"
	relationshipLikeReceived = "likeReceived"
	relationshipMatched      = "matched"
	relationshipUnavailable  = "unavailable"
	friendshipOfferSent      = "offerSent"
	friendshipOfferReceived  = "offerReceived"
	friendshipFriends        = "friends"
	minimumConnectionReason  = 50
	maximumConnectionReason  = 500
)

type relationshipReasonRequest struct {
	Reason string `json:"reason"`
}

type relationshipPair struct {
	Likes              map[string]string `firestore:"likes"`
	FriendshipSenderID string            `firestore:"friendshipSenderId"`
	FriendshipReason   string            `firestore:"friendshipReason"`
	Friends            bool              `firestore:"friends"`
}

// SendLike records a meaningful one-sided Like or creates a Match when the
// target already has an active Like. Both owner projections are written in the
// same Firestore transaction.
func (s *Service) SendLike(w http.ResponseWriter, r *http.Request) {
	uid, ok := s.requireAuthenticatedApp(w, r)
	if !ok {
		return
	}
	targetUID := r.PathValue("targetUid")
	reason, ok := decodeRelationshipReason(w, r, uid, targetUID)
	if !ok {
		return
	}

	pair, err := s.updateRelationship(r.Context(), uid, targetUID, func(pair relationshipPair) (relationshipPair, error) {
		return sendLikeTransition(pair, uid, reason)
	})
	if err != nil {
		writeRelationshipError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, relationshipResponse(uid, targetUID, pair))
}

// SendFriendshipOffer replaces an incoming one-sided Like when applicable and
// makes romance unavailable for both people.
func (s *Service) SendFriendshipOffer(w http.ResponseWriter, r *http.Request) {
	uid, ok := s.requireAuthenticatedApp(w, r)
	if !ok {
		return
	}
	targetUID := r.PathValue("targetUid")
	reason, ok := decodeRelationshipReason(w, r, uid, targetUID)
	if !ok {
		return
	}

	pair, err := s.updateRelationship(r.Context(), uid, targetUID, func(pair relationshipPair) (relationshipPair, error) {
		return sendFriendshipOfferTransition(pair, uid, targetUID, reason)
	})
	if err != nil {
		writeRelationshipError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, relationshipResponse(uid, targetUID, pair))
}

// AcceptFriendshipOffer converts the target's pending offer into a persistent
// friendship and keeps its reason as connection context.
func (s *Service) AcceptFriendshipOffer(w http.ResponseWriter, r *http.Request) {
	uid, ok := s.requireAuthenticatedApp(w, r)
	if !ok {
		return
	}
	targetUID := r.PathValue("targetUid")
	if !validRelationshipTarget(uid, targetUID) {
		writeError(w, http.StatusBadRequest, "Choose a valid profile.")
		return
	}

	pair, err := s.updateRelationship(r.Context(), uid, targetUID, func(pair relationshipPair) (relationshipPair, error) {
		return acceptFriendshipOfferTransition(pair, targetUID)
	})
	if err != nil {
		writeRelationshipError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, relationshipResponse(uid, targetUID, pair))
}

func decodeRelationshipReason(w http.ResponseWriter, r *http.Request, uid, targetUID string) (string, bool) {
	if !validRelationshipTarget(uid, targetUID) {
		writeError(w, http.StatusBadRequest, "Choose a valid profile.")
		return "", false
	}
	var request relationshipReasonRequest
	decoder := json.NewDecoder(io.LimitReader(r.Body, 4*1024))
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(&request); err != nil {
		writeError(w, http.StatusBadRequest, "A personal reason between 50 and 500 characters is required.")
		return "", false
	}
	if err := decoder.Decode(&struct{}{}); !errors.Is(err, io.EOF) {
		writeError(w, http.StatusBadRequest, "The request body is invalid.")
		return "", false
	}
	reason := strings.TrimSpace(request.Reason)
	if len([]rune(reason)) < minimumConnectionReason || len([]rune(reason)) > maximumConnectionReason {
		writeError(w, http.StatusBadRequest, "A personal reason between 50 and 500 characters is required.")
		return "", false
	}
	return reason, true
}

func sendLikeTransition(pair relationshipPair, uid, reason string) (relationshipPair, error) {
	if pair.Friends || pair.FriendshipSenderID != "" {
		return pair, errors.New("romantic interaction is unavailable because a friendship connection exists or is pending")
	}
	if _, exists := pair.Likes[uid]; exists {
		return pair, errors.New("you have already sent a Like to this person")
	}
	pair.Likes[uid] = reason
	return pair, nil
}

func sendFriendshipOfferTransition(pair relationshipPair, uid, targetUID, reason string) (relationshipPair, error) {
	if pair.Friends || pair.FriendshipSenderID != "" {
		return pair, errors.New("a friendship connection already exists or is pending")
	}
	if _, sentLike := pair.Likes[uid]; sentLike {
		return pair, errors.New("you have already expressed romantic interest, so you cannot offer friendship at this time")
	}
	delete(pair.Likes, targetUID)
	pair.FriendshipSenderID = uid
	pair.FriendshipReason = reason
	return pair, nil
}

func acceptFriendshipOfferTransition(pair relationshipPair, senderUID string) (relationshipPair, error) {
	if pair.FriendshipSenderID != senderUID || pair.Friends {
		return pair, errors.New("there is no friendship offer to accept")
	}
	pair.Friends = true
	return pair, nil
}

func (s *Service) updateRelationship(ctx context.Context, uid, targetUID string, transition func(relationshipPair) (relationshipPair, error)) (relationshipPair, error) {
	if _, err := s.firestore.Doc("users/" + targetUID + "/profiles/discovery").Get(ctx); err != nil {
		if status.Code(err) == codes.NotFound {
			return relationshipPair{}, status.Error(codes.NotFound, "profile not found")
		}
		return relationshipPair{}, err
	}

	pairDocument := s.firestore.Doc("users/" + relationshipPairOwner(uid, targetUID) + "/privateRelationships/" + relationshipPairID(uid, targetUID))
	var result relationshipPair
	err := s.firestore.RunTransaction(ctx, func(ctx context.Context, transaction *firestore.Transaction) error {
		pair := relationshipPair{Likes: map[string]string{}}
		snapshot, err := transaction.Get(pairDocument)
		if err == nil {
			if err := snapshot.DataTo(&pair); err != nil {
				return err
			}
			if pair.Likes == nil {
				pair.Likes = map[string]string{}
			}
		} else if status.Code(err) != codes.NotFound {
			return err
		}

		pair, err = transition(pair)
		if err != nil {
			return status.Error(codes.FailedPrecondition, err.Error())
		}
		result = pair
		if err := transaction.Set(pairDocument, map[string]interface{}{
			"schemaVersion":      1,
			"userIds":            relationshipPairUIDs(uid, targetUID),
			"likes":              pair.Likes,
			"friendshipSenderId": pair.FriendshipSenderID,
			"friendshipReason":   pair.FriendshipReason,
			"friends":            pair.Friends,
			"updatedAt":          firestore.ServerTimestamp,
		}, firestore.MergeAll); err != nil {
			return err
		}
		if err := transaction.Set(s.firestore.Doc("users/"+uid+"/relationships/"+targetUID), relationshipProjection(uid, targetUID, pair), firestore.MergeAll); err != nil {
			return err
		}
		return transaction.Set(s.firestore.Doc("users/"+targetUID+"/relationships/"+uid), relationshipProjection(targetUID, uid, pair), firestore.MergeAll)
	})
	return result, err
}

func relationshipProjection(viewerUID, otherUID string, pair relationshipPair) map[string]interface{} {
	projection := map[string]interface{}{
		"schemaVersion":   1,
		"profileUid":      otherUID,
		"romanticState":   relationshipNone,
		"friendshipState": relationshipNone,
		"updatedAt":       firestore.ServerTimestamp,
	}
	viewerReason, viewerLiked := pair.Likes[viewerUID]
	otherReason, otherLiked := pair.Likes[otherUID]
	if viewerLiked && otherLiked {
		projection["romanticState"] = relationshipMatched
		projection["outgoingLikeReason"] = viewerReason
		projection["incomingLikeReason"] = otherReason
	} else if viewerLiked {
		projection["romanticState"] = relationshipLikeSent
		projection["outgoingLikeReason"] = viewerReason
	} else if otherLiked {
		projection["romanticState"] = relationshipLikeReceived
	}
	if pair.FriendshipSenderID != "" || pair.Friends {
		projection["romanticState"] = relationshipUnavailable
		if pair.Friends {
			projection["friendshipState"] = friendshipFriends
		} else if pair.FriendshipSenderID == viewerUID {
			projection["friendshipState"] = friendshipOfferSent
		} else {
			projection["friendshipState"] = friendshipOfferReceived
		}
		if pair.FriendshipSenderID == viewerUID {
			projection["outgoingFriendshipReason"] = pair.FriendshipReason
		} else {
			projection["incomingFriendshipReason"] = pair.FriendshipReason
		}
	}
	return projection
}

func relationshipResponse(viewerUID, targetUID string, pair relationshipPair) map[string]interface{} {
	projection := relationshipProjection(viewerUID, targetUID, pair)
	delete(projection, "updatedAt")
	return projection
}

func relationshipPairOwner(firstUID, secondUID string) string {
	ids := relationshipPairUIDs(firstUID, secondUID)
	return ids[0]
}

func relationshipPairID(firstUID, secondUID string) string {
	ids := relationshipPairUIDs(firstUID, secondUID)
	digest := sha256.Sum256([]byte(ids[0] + "\x00" + ids[1]))
	return hex.EncodeToString(digest[:])
}

func relationshipPairUIDs(firstUID, secondUID string) []string {
	ids := []string{firstUID, secondUID}
	sort.Strings(ids)
	return ids
}

func validRelationshipTarget(uid, targetUID string) bool {
	return uid != targetUID && validPathSegment(targetUID)
}

func writeRelationshipError(w http.ResponseWriter, err error) {
	switch status.Code(err) {
	case codes.NotFound:
		writeError(w, http.StatusNotFound, "This profile is no longer available.")
	case codes.FailedPrecondition:
		writeError(w, http.StatusConflict, status.Convert(err).Message())
	default:
		writeError(w, http.StatusInternalServerError, "The relationship could not be updated. Please try again.")
	}
}
