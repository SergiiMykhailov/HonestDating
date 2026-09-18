package backend

import (
	"context"
	"os"
	"testing"
	"time"

	"cloud.google.com/go/firestore"
	"golang.org/x/oauth2"
	"google.golang.org/api/option"
)

const runFirestoreLiveTestsEnvironment = "RUN_FIRESTORE_LIVE_TESTS"
const firestoreLiveTestAccessTokenEnvironment = "FIRESTORE_LIVE_TEST_ACCESS_TOKEN"

// TestFirestoreLiveConnectivity verifies the actual Firestore project used by
// the backend. It is opt-in because it creates temporary remote data.
//
// Enable it with RUN_FIRESTORE_LIVE_TESTS=true and GOOGLE_CLOUD_PROJECT set to
// the target project. For a local gcloud login that differs from Application
// Default Credentials, supply its short-lived token through
// FIRESTORE_LIVE_TEST_ACCESS_TOKEN. The test deletes its only document and
// verifies that the temporary root collection is empty before it completes.
func TestFirestoreLiveConnectivity(t *testing.T) {
	if os.Getenv(runFirestoreLiveTestsEnvironment) != "true" {
		t.Skip("set RUN_FIRESTORE_LIVE_TESTS=true to run the live Firestore smoke test")
	}

	projectID := os.Getenv("GOOGLE_CLOUD_PROJECT")
	if projectID == "" {
		t.Fatal("GOOGLE_CLOUD_PROJECT is required for the live Firestore smoke test")
	}

	contextWithTimeout, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	clientOptions := []option.ClientOption{}
	if accessToken := os.Getenv(firestoreLiveTestAccessTokenEnvironment); accessToken != "" {
		clientOptions = append(clientOptions, option.WithTokenSource(
			oauth2.StaticTokenSource(&oauth2.Token{AccessToken: accessToken}),
		))
	}

	client, err := firestore.NewClient(contextWithTimeout, projectID, clientOptions...)
	if err != nil {
		t.Fatalf("create Firestore client: %v", err)
	}
	defer client.Close()

	collectionID := "testData-" + time.Now().UTC().Format("20060102T150405.000000000Z")
	probe := client.Collection(collectionID).Doc("connectionProbe")

	if _, err := probe.Set(contextWithTimeout, map[string]interface{}{
		"key":       "value",
		"createdAt": firestore.ServerTimestamp,
	}); err != nil {
		t.Fatalf("write temporary Firestore probe document: %v", err)
	}

	defer func() {
		cleanupContext, cleanupCancel := context.WithTimeout(context.Background(), 15*time.Second)
		defer cleanupCancel()

		if _, err := probe.Delete(cleanupContext); err != nil {
			t.Errorf("delete temporary Firestore probe document: %v", err)
			return
		}

		documents, err := client.Collection(collectionID).Limit(1).Documents(cleanupContext).GetAll()
		if err != nil {
			t.Errorf("confirm temporary Firestore collection is empty: %v", err)
			return
		}
		if len(documents) != 0 {
			t.Errorf("temporary Firestore collection %q still contains documents", collectionID)
		}
	}()

	snapshot, err := probe.Get(contextWithTimeout)
	if err != nil {
		t.Fatalf("read temporary Firestore probe document: %v", err)
	}

	value, ok := snapshot.Data()["key"].(string)
	if !ok || value != "value" {
		t.Errorf("expected temporary Firestore probe key to equal %q, got %#v", "value", snapshot.Data()["key"])
	}
}
