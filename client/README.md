# Honest Dating

A Flutter foundation for Honest Dating. It provides a reference-aligned visual
system, a BLoC-driven Google/Apple authentication entry screen, named-route
navigation, a local placeholder repository, and one representative Discover
screen.

## Structure

- `lib/models` contains immutable domain models.
- `lib/repositories/base` declares data contracts; `app_repositories` provides
  the current local implementations.
- `lib/ui/routing` owns named routes and composition.
- `lib/ui/screens` contains feature screens and their BLoCs.
- `lib/ui/widgets` contains the shared controls used by Epic 1 flows.
- `lib/resources` holds configuration, localization, and future visual assets.

## Firebase

Firebase Core, Authentication, App Check, Firestore, and Storage are
initialized by the mobile app. Google sign-in establishes the Firebase user
required for private Storage uploads and Cloud Run requests. The Discover
carousel currently uses local fictional preview profiles. It supports only
vertical browsing and read-only profile opening; filters and relationship
actions arrive in later Epic 2 slices.

Server-side Firebase integration lives in [`../backend`](../backend),
implemented in Go for Cloud Run. Its private verification formats are
documented in
[`../backend/docs/database-structure.md`](../backend/docs/database-structure.md).
The Flutter layer neither receives nor stores FaceTec blobs, templates,
provider tokens, or backend credentials. The iOS Device SDK handles encrypted
session blobs transiently in native memory only.

In debug builds only, triple-tap the navy welcome area above the sign-in panel
to open Consent immediately. It is a local navigation shortcut and never
waits for Firebase, Firestore, App Check, or Cloud Run. It is not included in
release builds. Sign in with the same Google account on each device to use one
real Firebase account across devices.

The local phone-verification preview accepts only `012345` as its verification
code, then opens the following age-eligibility mock screen. It does not send
an SMS or retain a phone number.

The age-eligibility preview accepts a real calendar date in `DD.MM.YYYY`
format only when the user is at least 18, then opens the consent placeholder.

The consent preview enables Continue only after both document switches are on,
then opens the core-details stage. It stores no consent record.

After the profile-attribute flow, registration requires a main photo and its
private verification workflow. The app sends only generated main-photo IDs,
Firebase Authentication, and App Check tokens to Cloud Run, then polls an
opaque verification token. After all attributes are collected, the final local
registration gate requires at least five interests and two gallery photos.

The interests flow provides a local preview catalogue of the 33 required
categories. Selected interest names remain canonical within the local draft
even when shown under multiple categories. Gallery selections are still
device-local in this mobile preview; durable gallery media and interest
persistence require their own approved backend contracts.

The backend starts in `approval_override` mode. Its `approved` response allows
this preview flow to continue but is not a genuine FaceTec 3D:2D match and does
not make any photo public. Production enforcement stays unavailable until the
official FaceTec Server adapter is configured.

The public Frankfurt Cloud Run base URL is fixed in the app and is routing
metadata, not an access secret. The biometric-consent value intentionally has
no default: it must match an approved legal document.

```bash
flutter run \
  --dart-define=BIOMETRIC_CONSENT_VERSION=your-approved-version
```

With those values, the app receives an opaque Honest Dating liveness token
after the selfie step and supplies it with the private main-photo ID. It never
receives a FaceTec session ID or enrollment reference. The token remains in
memory only for the active registration flow.

The iOS Firebase configuration is supplied locally at
`ios/Runner/Firebase/Staging/GoogleService-Info.plist` and is copied into the
Runner target at build time. Add `android/app/google-services.json` before
running the Android app; its Firebase app must use the `com.honestdating`
application ID.

## FaceTec Test API (iOS Debug only)

The identity-check screen uses FaceTec's iOS Device SDK and Test API in Debug
builds only. This integration is for consenting development testing only; it
does not persist captures, FaceMaps, or verification results.

Keep the FaceTec SDK download and configuration in the ignored `.facetec/`
directory:

```text
.facetec/
  iOS/
    FaceTecSDK.xcframework
    FaceTecSDKForDevelopment.xcframework
  test-config.json
```

`test-config.json` must contain `deviceKeyIdentifier` and `testApiBaseUrl`.
The Debug build copies that local file into the signed app bundle at build time.
Do not commit the SDKs, this file, or any FaceTec credentials. Android remains
unavailable until its Device SDK is added in a separate change.

On an iOS Simulator, the app deliberately skips FaceTec. It still uploads the
chosen main photo to its private staging path, but photo validation is approved
only in memory and is never sent to Cloud Run as a claimed FaceTec result. This
keeps the registration UI previewable without creating a false server-side
verification. A physical iOS device still runs the FaceTec Test API check.

The current default transport is `direct_test`, which preserves that Test API
preview. After the backend has a validated production FaceTec adapter, switch
to server-owned encrypted-blob relay explicitly:

```bash
flutter run \
  --dart-define=BIOMETRIC_CONSENT_VERSION=your-approved-version \
  --dart-define=FACETEC_TRANSPORT_MODE=backend
```

`FACETEC_TRANSPORT_MODE=backend` is not usable with the current unconfigured
backend provider: it correctly fails closed until the official FaceTec server
contract and credentials are installed there.

## Run

```bash
flutter pub get
flutter run
```

The project targets iOS, Android, and web. Follow the required code-generation
policies in [skills.md](skills.md).

Run `flutter test` and `flutter analyze` before handoff. Live Firebase tests
remain explicitly opt-in and must use the guarded test configuration.
