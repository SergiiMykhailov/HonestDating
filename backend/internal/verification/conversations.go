package verification

import (
	"context"
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"strings"
	"unicode/utf8"

	"cloud.google.com/go/firestore"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

const maximumMessageLength = 1000

type messageRequest struct {
	Text string `json:"text"`
}

// SendMessage writes two private message copies only if the canonical
// relationship is a mutual Like or accepted friendship.
func (s *Service) SendMessage(w http.ResponseWriter, r *http.Request) {
	uid, ok := s.requireAuthenticatedApp(w, r)
	if !ok {
		return
	}
	targetUID := r.PathValue("targetUid")
	if !validRelationshipTarget(uid, targetUID) {
		writeError(w, http.StatusBadRequest, "Choose a valid conversation participant.")
		return
	}
	text, ok := decodeMessage(w, r)
	if !ok {
		return
	}
	if err := s.appendMessage(r, uid, targetUID, text); err != nil {
		writeConversationError(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// MarkConversationRead clears only the current owner's unread count.
func (s *Service) MarkConversationRead(w http.ResponseWriter, r *http.Request) {
	uid, ok := s.requireAuthenticatedApp(w, r)
	if !ok {
		return
	}
	targetUID := r.PathValue("targetUid")
	if !validRelationshipTarget(uid, targetUID) {
		writeError(w, http.StatusBadRequest, "Choose a valid conversation participant.")
		return
	}
	document := s.firestore.Doc("users/" + uid + "/conversations/" + relationshipPairID(uid, targetUID))
	err := s.firestore.RunTransaction(r.Context(), func(ctx context.Context, transaction *firestore.Transaction) error {
		snapshot, err := transaction.Get(document)
		if status.Code(err) == codes.NotFound {
			return status.Error(codes.NotFound, "conversation not found")
		}
		if err != nil {
			return err
		}
		if participantUID, _ := snapshot.DataAt("participantUid"); participantUID != targetUID {
			return status.Error(codes.PermissionDenied, "conversation is unavailable")
		}
		return transaction.Set(document, map[string]interface{}{
			"unreadCount": 0,
			"updatedAt":   firestore.ServerTimestamp,
		}, firestore.MergeAll)
	})
	if err != nil {
		writeConversationError(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func decodeMessage(w http.ResponseWriter, r *http.Request) (string, bool) {
	var request messageRequest
	decoder := json.NewDecoder(io.LimitReader(r.Body, 8*1024))
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(&request); err != nil {
		writeError(w, http.StatusBadRequest, "Write a message of up to 1,000 characters.")
		return "", false
	}
	if err := decoder.Decode(&struct{}{}); !errors.Is(err, io.EOF) {
		writeError(w, http.StatusBadRequest, "The request body is invalid.")
		return "", false
	}
	text := strings.TrimSpace(request.Text)
	if text == "" || utf8.RuneCountInString(text) > maximumMessageLength {
		writeError(w, http.StatusBadRequest, "Write a message of up to 1,000 characters.")
		return "", false
	}
	return text, true
}

func (s *Service) appendMessage(r *http.Request, uid, targetUID, text string) error {
	conversationID := relationshipPairID(uid, targetUID)
	pairDocument := s.firestore.Doc("users/" + relationshipPairOwner(uid, targetUID) + "/privateRelationships/" + conversationID)
	viewerConversation := s.firestore.Doc("users/" + uid + "/conversations/" + conversationID)
	targetConversation := s.firestore.Doc("users/" + targetUID + "/conversations/" + conversationID)
	messageID := viewerConversation.Collection("messages").NewDoc().ID
	viewerMessage := viewerConversation.Collection("messages").Doc(messageID)
	targetMessage := targetConversation.Collection("messages").Doc(messageID)

	return s.firestore.RunTransaction(r.Context(), func(ctx context.Context, transaction *firestore.Transaction) error {
		snapshot, err := transaction.Get(pairDocument)
		if status.Code(err) == codes.NotFound {
			return status.Error(codes.FailedPrecondition, "Messaging is available after you match or become friends.")
		}
		if err != nil {
			return err
		}
		pair := relationshipPair{Likes: map[string]string{}}
		if err := snapshot.DataTo(&pair); err != nil {
			return err
		}
		kind, err := messageConnectionKind(pair)
		if err != nil {
			return status.Error(codes.FailedPrecondition, err.Error())
		}

		targetUnreadCount := 0
		if targetSnapshot, err := transaction.Get(targetConversation); err == nil {
			if unread, err := targetSnapshot.DataAt("unreadCount"); err == nil {
				switch count := unread.(type) {
				case int64:
					targetUnreadCount = int(count)
				case int:
					targetUnreadCount = count
				}
			}
		} else if status.Code(err) != codes.NotFound {
			return err
		}

		message := map[string]interface{}{
			"schemaVersion": 1,
			"senderUid":     uid,
			"text":          text,
			"sentAt":        firestore.ServerTimestamp,
		}
		if err := transaction.Set(viewerMessage, message); err != nil {
			return err
		}
		if err := transaction.Set(targetMessage, message); err != nil {
			return err
		}
		for _, projection := range []struct {
			document       *firestore.DocumentRef
			participantUID string
			unreadCount    int
		}{
			{viewerConversation, targetUID, 0},
			{targetConversation, uid, targetUnreadCount + 1},
		} {
			if err := transaction.Set(projection.document, map[string]interface{}{
				"schemaVersion":  1,
				"conversationId": conversationID,
				"participantUid": projection.participantUID,
				"connectionKind": kind,
				"lastMessage":    text,
				"lastMessageAt":  firestore.ServerTimestamp,
				"lastSenderUid":  uid,
				"unreadCount":    projection.unreadCount,
				"updatedAt":      firestore.ServerTimestamp,
			}, firestore.MergeAll); err != nil {
				return err
			}
		}
		return nil
	})
}

func messageConnectionKind(pair relationshipPair) (string, error) {
	if pair.Friends {
		return "friendship", nil
	}
	if len(pair.Likes) == 2 {
		return "match", nil
	}
	return "", errors.New("Messaging is available after you match or become friends.")
}

func writeConversationError(w http.ResponseWriter, err error) {
	switch status.Code(err) {
	case codes.NotFound:
		writeError(w, http.StatusNotFound, "This conversation is no longer available.")
	case codes.PermissionDenied:
		writeError(w, http.StatusForbidden, "You cannot access this conversation.")
	case codes.FailedPrecondition:
		writeError(w, http.StatusConflict, err.Error())
	default:
		writeError(w, http.StatusInternalServerError, "The message could not be sent. Please try again.")
	}
}
