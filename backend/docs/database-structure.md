# Database structure

This document records persistent data formats introduced for Honest Dating.
All identity-verification and photo-verification data is private and
server-owned. Firebase Firestore and Storage rules deny client access to it.

## `users/{uid}`

Created by the authenticated mobile client immediately after Firebase social
sign-in. In debug builds only, the triple-tap preview path exchanges an
App-Check-attested anonymous bootstrap session for a server-minted custom token
for one canonical owner. The owner-only document uses the fixed dummy email
identifier. The user may read this exact document and refresh `updatedAt`; no
other client writes or collection-listing access are permitted. It contains no
profile, biometric, consent, payment, or provider-token data.

| Field | Type | Purpose |
| --- | --- | --- |
| `schemaVersion` | number | Current format version (`1`). |
| `createdAt` | timestamp | First authenticated app access, set by Firestore server time. |
| `updatedAt` | timestamp | Most recent authenticated app access, set by Firestore server time. |
| `email` | string, optional | Fixed `folia.dummy@gmail.com` identifier in the canonical debug-preview account only. It is not a Firebase email/password credential. |
| `accountKind` | string, optional | `debugPreview` for the canonical debug-preview account only. |
| `registrationCompletedAt` | timestamp, optional | Set once by the authenticated owner when mobile registration completes; used only to restore the signed-in app entry point. |

## `users/{uid}/profiles/discovery`

The discoverable, presentation-only projection of one registered user's
profile. The document is always nested under its owning `users/{uid}` account;
there is no root-level profile collection. It never holds viewer-specific
relationship state, private user media, verification data, or FaceTec data.
Viewer-specific relationship state is stored separately under the viewer.

Authenticated clients may read these documents and their media metadata. All
client writes remain denied.

| Field | Type | Purpose |
| --- | --- | --- |
| `schemaVersion` | number | Current format version (`1`). |
| `kind` | string | `person` for a discoverable member profile. |
| `displayOrder` | number | Deterministic ordering within the current Discover pool. |
| `firstName` / `age` / `distanceMiles` / `locationLabel` | string / number | Card and profile header data. |
| `headline` | string | Profile About text. |
| `primaryMediaId` | string | Document ID of the primary item in the `media` subcollection. |
| `mediaIds` | array of strings | Ordered profile-media document IDs. |
| `details` | array of maps | Display-only `{label, value}` profile attributes. |
| `interests` | array of strings | Display-only interests. |
| `questions` | array of maps | Display-only shared `{question, answer}` entries. |

## `users/{uid}/profiles/discovery/media/{mediaId}`

Metadata for one discoverable member image. The object itself lives in Cloud
Storage under the same UID; Firestore stores no encoded image bytes and no
public download URL.

| Field | Type | Purpose |
| --- | --- | --- |
| `schemaVersion` | number | Current format version (`1`). |
| `kind` | string | `primary` or a future gallery-media type. |
| `displayOrder` | number | Stable display order within the profile. |
| `storagePath` | string | Bucket-relative object path. |
| `contentType` | string | Media MIME type. |
| `byteSize` / `width` / `height` | number | Integrity and display metadata. |
| `sha256` | string | SHA-256 digest of the uploaded source object. |

Published image paths are under `users/{uid}/profile/{mediaId}.png` in the
approved Firebase Storage bucket. Authenticated clients may read this prefix
through Firebase Storage; all client writes remain denied.

Discover queries use the `profiles.displayOrder` ascending collection-group
index declared in `firestore.indexes.json`. It is required because profile
documents are nested below multiple user IDs.

## `users/{viewerUid}/relationships/{profileUid}`

The authenticated viewer's relationship projection for another profile. The
mobile app reads and updates only documents nested below its own UID. Profiles
with no relationship document use the neutral `none` states. This keeps
viewer-specific state out of public profile records and makes relationship UI
consistent across all of the viewer's devices.

| Field | Type | Purpose |
| --- | --- | --- |
| `schemaVersion` | number | Current format version (`1`). |
| `romanticState` | string | `none`, `likeSent`, `likeReceived`, `matched`, or `unavailable`. |
| `friendshipState` | string | `none`, `offerSent`, `offerReceived`, or `friends`. |
| `outgoingLikeReason` / `incomingLikeReason` | string, optional | Viewer-side reason text for a romantic interaction. |
| `outgoingFriendshipReason` / `incomingFriendshipReason` | string, optional | Viewer-side reason text for a friendship interaction. |
| `createdAt` | timestamp, optional | Server timestamp used by seeded or server-created projections. |
| `updatedAt` | timestamp | Most recent transition, set by Firestore server time. |

This projection is the current Firebase-backed mobile contract. A future
transactional relationship service should update both users' projections
atomically before production messaging or notification delivery is enabled.

## `systemDebugPreviewAccounts/folia`

Created and read only by the Go Cloud Run service when
`DEBUG_PREVIEW_AUTH_ENABLED=true`. Client Firestore rules default-deny this
path. It maps eligible debug bootstrap identities and the exact Google identity
`folia.dummy@gmail.com` to one canonical Firebase UID. The endpoint returns a
short-lived Firebase custom token for that UID only after verifying both the
caller's Firebase ID token and App Check token.

| Field | Type | Purpose |
| --- | --- | --- |
| `schemaVersion` | number | Current format version (`1`). |
| `canonicalUID` | string | Firebase Auth UID that owns the shared debug test account. |
| `createdAt` / `updatedAt` | timestamp | Server timestamps. |

No Firebase password, Google credential, raw ID token, App Check token, or
custom token is stored in this document.

## `users/{uid}/private/identityVerification`

Created only by the Go Cloud Run `POST /v1/identity-verifications` endpoint
(with the legacy `/v1/facetec/enrollments` alias) after valid Firebase
Authentication and App Check tokens are verified.

| Field | Type | Purpose |
| --- | --- | --- |
| `schemaVersion` | number | Current format version (`1`). |
| `provider` | string | Verification provider identifier (`faceTec`). |
| `providerMode` | string | Runtime FaceTec adapter mode: `unconfigured` or `adapter_contract_pending`. Neither asserts a working production adapter. |
| `biometricConsent.acceptedAt` | timestamp | Server-recorded time of consent. |
| `biometricConsent.version` | string | Accepted biometric-consent document version. |
| `currentEnrollment.attemptId` | string | Opaque enrollment-token identifier. It is not a FaceTec session ID. |
| `currentEnrollment.tokenDigest` | string | SHA-256 digest of the opaque mobile enrollment-token secret. The raw token is never stored. |
| `currentEnrollment.reference` | string | Server-only opaque FaceTec enrollment reference; never returned to the client. |
| `currentEnrollment.status` | string | Coarse lifecycle: `awaitingProductionFaceTecServer`, `sessionInProgress`, `pendingFaceTecProvider`, `verifiedByProductionFaceTecServer`, `rejectedByProductionFaceTecServer`, or `unavailable`. Only a production provider status can set either verified/rejected value. |
| `currentEnrollment.createdAt` / `updatedAt` | timestamp | Server timestamps. |

The mobile app keeps the raw opaque enrollment token only in registration-flow
memory. It can use it to relay an encrypted SDK request through
`POST /v1/identity-verifications/{token}/facetec-session-requests` and, after
the Device SDK exits, request the server-owned coarse result from
`POST /v1/identity-verifications/{token}/completion`. The endpoints return no
provider reference, provider credential, FaceTec session ID, or biometric data.

Never store FaceMaps, biometric templates, raw liveness captures, FaceTec
session request/response blobs, provider tokens, or audit images in Firestore.

## `users/{uid}/private/profilePhotos/{photoId}`

Created by the Go Cloud Run Eventarc handler when a storage object finalizes at
`users/{uid}/profile-photo-staging/{photoId}/original`.

| Field | Type | Purpose |
| --- | --- | --- |
| `schemaVersion` | number | Current format version (`1`). |
| `provider` / `providerMode` | string | FaceTec provider and current mock mode. |
| `sourceObjectPath` | string | Private staging-object path. |
| `verificationStatus` | string | `requiresVerifiedLivenessEnrollment`, `mockPendingCommercialServer`, or `requiresFaceTec3D2DMatch`. |
| `visibility` | string | Always `private` in this scaffold. |
| `uploadedAt` / `updatedAt` | timestamp | Server timestamps. |

No public-photo URL or approved-image record is created by this backend. A
future production-only FaceTec adapter may publish a derivative only after a
verified 3D:2D profile-photo match.

## `users/{uid}/private/profilePhotoVerifications/{sessionId}`

Created only by `POST /v1/profile-photo-verifications` after Firebase
Authentication and App Check verification. The document is found through the
authenticated user's private path and a digest of the opaque token; its raw
client token is never stored.

| Field | Type | Purpose |
| --- | --- | --- |
| `schemaVersion` | number | Current format version (`1`). |
| `tokenDigest` | string | SHA-256 digest of the opaque token secret. It is not reversible and the raw token is never persisted. |
| `mainPhotoId` | string | ID of the one private staged photo eligible for a later FaceTec 3D:2D match. |
| `galleryPhotoIds` | array of strings | IDs of private optional gallery photos. They are explicitly not FaceTec match candidates. |
| `livenessAttemptId` | string | Identifier of the owner-bound server enrollment authorized to start this photo workflow. It is not a FaceTec identifier. |
| `livenessEnrollmentStatus` | string | Coarse enrollment lifecycle at creation time. A 3D:2D match begins only after `verifiedByProductionFaceTecServer`. |
| `workflowStatus` | string | Client-facing opaque workflow status: `pending`, `approved`, `rejected`, or `unavailable`. |
| `decisionMode` | string | Runtime decision policy used when last checked: `approval_override` or `enforce`. |
| `provider` / `providerMode` | string | `faceTec` and either `unconfigured` or `adapter_contract_pending`. The latter does not assert that a production adapter exists. |
| `providerMatchStatus` | string | Coarse server-only provider state (`notStarted`, `pending`, `approved`, `rejected`, or `unavailable`); never a raw provider response. |
| `providerMatchReference` | string | Opaque server-only reference for a future provider adapter. Empty until a real adapter starts a match. |
| `createdAt` / `updatedAt` | timestamp | Server timestamps. |

With `approval_override`, `workflowStatus=approved` means only that the
preview registration flow may continue. It never means the main photo has
passed a genuine FaceTec match, and it must not unlock public-photo exposure.
When liveness has not been production-server verified, the record remains a
server-owned placeholder and no 3D:2D request is attempted.

Never store FaceMaps, biometric templates, 3D capture blobs, raw FaceTec
request/response payloads, provider tokens, or an image copy in this document.

## Cloud Storage staging object

`users/{uid}/profile-photo-staging/{photoId}/original`

The authenticated owner may create a JPEG, PNG, WebP, HEIC, or HEIF image up
to 10 MiB. The object cannot be read, updated, or deleted from a client. The
Go service uses its Cloud Run service account and is not constrained by client
Firebase rules.
