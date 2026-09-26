# Honest Dating backend

This directory contains all server-side code. It is a Go Cloud Run service;
there is no JavaScript, TypeScript, Node runtime, or Firebase Functions source
in this repository.

## Responsibilities

- `GET /health` returns `200 {"status":"ok"}` when the Cloud Run revision is
  accepting requests. It does not contact Firebase or FaceTec and exposes no
  environment details.
- `POST /v1/identity-verifications` verifies Firebase Authentication and App
  Check tokens, then records a server-owned opaque liveness enrollment. The
  legacy `POST /v1/facetec/enrollments` route is retained during migration.
- `POST /v1/identity-verifications/{token}/facetec-session-requests` relays an
  encrypted Device SDK blob transiently to a future FaceTec adapter. It never
  stores or logs the request or response blob.
- `POST /v1/identity-verifications/{token}/completion` asks that adapter for a
  coarse server-owned liveness result. It never accepts a client claim that
  liveness succeeded.
- `POST /v1/profile-photo-verifications` accepts only previously uploaded
  private photo IDs, creates an opaque validation token, and returns `pending`.
- `GET /v1/profile-photo-verifications/{token}` returns only the authenticated
  owner's opaque workflow status.
- `POST /v1/debug-preview-auth` is disabled by default. When explicitly
  enabled for debug-only mobile testing, it verifies Firebase Authentication
  and App Check, then returns a short-lived custom token for the one canonical
  `folia.dummy@gmail.com` test account. It neither accepts nor stores a
  password, Google credential, or client-selected UID.
- `POST /events/storage` accepts authenticated Eventarc Cloud Storage
  finalization events for private profile-photo staging objects and records
  their private verification state.

The photo-validation preview defaults to `approval_override`: it returns an
approved *workflow* state after polling so registration can proceed. This does
not approve a liveness check, does not establish a FaceTec 3D:2D match, and
does not create a public-photo record. A real FaceTec provider result is never
claimed until the official production server adapter and its contract have been
configured and validated.

## Deployment shape

Deploy `cmd/verification` as a public Go Cloud Run service in Frankfurt
(`europe-west3`) in the Firebase project's Google Cloud project, with at least
one minimum instance. Configure these non-secret environment values:

| Variable | Purpose |
| --- | --- |
| `GOOGLE_CLOUD_PROJECT` | Firebase / Google Cloud project ID. Set this explicitly on the Cloud Run service. |
| `FIREBASE_STORAGE_BUCKET` | Firebase Storage bucket receiving private staged photos. |
| `DEBUG_PREVIEW_AUTH_ENABLED` | Defaults to `false`. Set to `true` only while the debug-only shared `folia.dummy@gmail.com` mobile preview is needed. |
| `FACETEC_PROVIDER_MODE` | `unconfigured` by default; `adapter_contract_pending` reserves the runtime configuration for a future official adapter but does not create one. |
| `FACETEC_DECISION_MODE` | `approval_override` by default. Change explicitly to `enforce` only after production FaceTec setup has been validated. |
| `FACETEC_SERVER_URL` | Optional runtime-only FaceTec Server URL for a future official adapter. |
| `FACETEC_SERVER_CREDENTIAL` | Optional runtime-only FaceTec Server credential. Supply through a secret environment variable, never source control. |
| `PORT` | HTTP listener port. Cloud Run supplies this automatically. |

The service uses Application Default Credentials. Give its dedicated service
account only the roles required to verify Firebase tokens and write the private
Firestore documents. When `DEBUG_PREVIEW_AUTH_ENABLED=true`, grant that same
service account permission to sign Firebase custom tokens for itself (the
minimum required IAM permission is `iam.serviceAccounts.signBlob`). Do not
commit a service-account key.

The service is deliberately publicly reachable so the mobile app can call it
directly. Firebase Authentication and App Check verification remain mandatory
inside each mobile verification handler; Cloud Run IAM does not replace either
check.
`GET /health` intentionally requires neither and returns only service readiness.
Keep one minimum instance warm to avoid scale-to-zero cold starts. This incurs
ongoing Cloud Run cost and improves availability, but does not guarantee that a
specific instance can never be restarted by the platform.

Create an Eventarc trigger for
`google.cloud.storage.object.v1.finalized` on the Firebase Storage bucket,
targeting `/events/storage`. The trigger and the bucket must be in compatible
locations.

Deploy Firebase rules from this directory using its `firebase.json`; it
contains rules configuration only and no Functions definition.

## Local development

The service requires Application Default Credentials plus
`GOOGLE_CLOUD_PROJECT` and `FIREBASE_STORAGE_BUCKET`. Local credentials and
FaceTec credentials remain outside the repository. The service has no mock
FaceTec endpoint: a local run may exercise request validation and persistence
only against a deliberately configured non-production Firebase project. The
approval override is a policy for the real private-photo endpoint, not a fake
FaceTec result and not a substitute for a production adapter.

## FaceTec adapter seam

`internal/verification/FaceTecProvider` is the server-owned port for liveness
enrollment, transient Device-SDK blob relay, liveness status, and main-photo
matching. The bundled implementation is intentionally unconfigured: FaceTec's
production liveness and 3D:2D request contracts are not guessed or committed.
The existing iOS FaceTec Test API bridge remains a device-only preview mode.

In the future production path, the app receives an Honest Dating opaque
enrollment token, never a FaceTec session ID or provider token. The backend
maps it to a UID-bound private enrollment reference. Once the server confirms
liveness, the app uploads the main photo privately, sends the photo ID and that
opaque enrollment token, and receives a separate opaque photo-verification
token to poll. Raw FaceTec artifacts remain transient at the provider boundary.

When FaceTec provides the production server package and documented request
contract, add an adapter behind that port. In `approval_override`, invoke that
adapter but return `approved` to mobile regardless of its result; retain only
the coarse private state. After an explicit operator switch to `enforce`, the
same adapter's pending/approved/rejected result will control the opaque mobile
workflow status.

### Production operator account

For every developer-operated command against the production project
`honestdating-22e7b`—including deployment, IAM or rules work, and live
Firestore smoke tests—use **`serg.mykhailov@gmail.com`** explicitly. This Mac
has several Google Cloud identities; never use whichever account `gcloud`
happens to select. Check the active identity before operating:

```bash
gcloud auth list --filter='status:ACTIVE' --format='value(account)'
```

For the Go live Firestore test, request its short-lived token from that exact
account with `gcloud auth print-access-token --account=serg.mykhailov@gmail.com`.
This is only the human operator identity. The deployed Cloud Run service keeps
using its dedicated runtime service account.

Persistent structures are documented in
[docs/database-structure.md](docs/database-structure.md). Update that document
in the same change as any persistent entity, field, or format.
