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

The iOS Firebase configuration is supplied locally at
`ios/Runner/Firebase/Staging/GoogleService-Info.plist` and is copied into the
Runner target at build time. Add `android/app/google-services.json` before
running the Android app; its Firebase app must use the `com.honestdating`
application ID.

## Run

```bash
flutter pub get
flutter run
```

The project targets iOS, Android, and web. Follow the required code-generation
policies in [skills.md](skills.md).

This project intentionally has no automated-test targets or test dependencies.
