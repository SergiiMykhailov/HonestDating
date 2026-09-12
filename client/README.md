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

Firebase Core is initialized at launch, but the app currently has no Firestore
data access or documented Firestore collections. The Discover screen uses a
local placeholder profile.

Google and Apple buttons on the welcome screen are intentionally local entry
points until the approved Firebase Authentication configuration is supplied in
US-1.1.1. They do not authenticate a user or collect any data in this slice.

In debug builds only, triple-tap the navy welcome area above the sign-in panel
to preview the next phone-verification screen. This flow-preview shortcut is
not included in release builds.

The local phone-verification preview accepts only `012345` as its verification
code, then opens the following age-eligibility mock screen. It does not send
an SMS or retain a phone number.

The age-eligibility preview accepts a real calendar date in `DD.MM.YYYY`
format only when the user is at least 18, then opens the consent placeholder.

The consent preview enables Continue only after both document switches are on,
then opens the identity-verification placeholder. It stores no consent record.

After the profile-detail flow, registration continues through an on-device
photo-library picker, required About Me text, semicolon-separated interests,
and a final review screen. Completing this path opens the local Discover
preview only. Photos, profile data, interest interpretation, and verification
results are not uploaded or persisted until the backend slice is implemented.

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

On an iOS Simulator, the native bridge deliberately skips FaceTec and returns a
successful verification outcome so the registration flow can be previewed. A
physical iOS device still runs the FaceTec Test API check.

## Run

```bash
flutter pub get
flutter run
```

The project targets iOS, Android, and web. Follow the required code-generation
policies in [skills.md](skills.md).

This project intentionally has no automated-test targets or test dependencies.
