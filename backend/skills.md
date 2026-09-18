# Honest Dating Backend Policies

## Scope and architecture

- Keep all server-side work inside `backend/`. The mobile and web clients live
  in `client/`.
- Backend runtime code is Go only. Do not introduce Node.js, JavaScript,
  TypeScript, `package.json`, Firebase Functions source, or executable helper
  files.
- Deploy this service to Cloud Run, not Cloud Functions for Firebase. Use
  Application Default Credentials in Google Cloud; never commit service-account
  JSON, FaceTec credentials, tokens, or `.env` files.

## Deployment controls

- Deploy only with explicit user authorization. A request to inspect, diagnose,
  or describe backend state does not authorize a deployment, IAM change, API
  activation, rule publication, or Eventarc trigger creation.
- For developer-operated production deployments, IAM/rules operations, and
  live Firestore checks, authenticate explicitly as
  `serg.mykhailov@gmail.com`. This workstation has multiple Google Cloud
  accounts; never rely on whichever account happens to be active and never use
  a different account merely because it has project access. This applies to
  local `gcloud` commands only; Cloud Run itself continues to use its dedicated
  runtime service account.
- Verify the selected local principal before a production-cloud operation with
  `gcloud auth list --filter='status:ACTIVE' --format='value(account)'`. For a
  token passed to the opt-in Firestore smoke test, use
  `gcloud auth print-access-token --account=serg.mykhailov@gmail.com`.
- Derive the target Firebase project and Storage bucket from the approved mobile
  Firebase configuration. The current approved project is `honestdating-22e7b`.
- Use the public Cloud Run service `honest-dating-backend` in Frankfurt
  (`europe-west3`) unless the product owner approves a different name or
  region.
- Set both `GOOGLE_CLOUD_PROJECT` and `FIREBASE_STORAGE_BUCKET` explicitly as
  non-secret Cloud Run environment variables. Do not assume Cloud Run injects
  the project ID into this service's runtime environment.
- The product owner has explicitly approved public Cloud Run access for this
  service. Keep `allUsers` as an invoker and retain at least one minimum
  instance unless the product owner changes that decision.
- Public Cloud Run access never replaces application security: every endpoint
  that handles user data must verify Firebase Authentication and App Check in
  Go. Only `GET /health` may be unauthenticated and it must expose readiness
  only.
- Use a dedicated user-managed Cloud Run service account with only the minimum
  permissions required. Do not use a default service account or broad project
  roles such as Owner or Editor.
- Before deployment, run `gofmt`, `go build ./...`, `go vet ./...`, and
  `go mod verify`. Store any local build output only in ignored `backend/build/`.
- After deployment, fetch the service URL, call `GET /health` directly, and
  confirm both the public invoker binding and minimum-instance setting before
  reporting the deployed revision and result.

## Firebase and FaceTec data

- Keep client Firestore and Storage access fail-closed for private identity,
  biometric-consent, enrollment, and photo-verification data.
- Update `docs/database-structure.md` in the same change as every persistent
  entity, field, or stored-data format.
- Never store biometric templates, FaceMaps, raw liveness captures, provider
  tokens, or FaceTec session payloads in Firestore or Cloud Storage.
- Do not claim or persist a successful FaceTec photo match until production
  FaceTec Server access, credentials, and the server-side 3D:2D adapter have
  been explicitly configured and validated.
- Do not create the Storage/Eventarc photo-finalization trigger or publish
  Firebase Rules until the corresponding authenticated client upload path is
  approved for deployment.
