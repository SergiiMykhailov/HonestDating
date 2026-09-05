# Honest Dating

An offline Flutter architecture skeleton for a future dating app. It provides
an iOS-style app shell, named-route navigation, repository interfaces with
local placeholder data, and one representative BLoC-driven Discover screen.

## Structure

- `lib/models` contains immutable domain models.
- `lib/repositories/base` declares data contracts; `app_repositories` provides
  the current local implementations.
- `lib/ui/routing` owns named routes and composition.
- `lib/ui/screens` contains feature screens and their BLoCs.
- `lib/resources` holds configuration, localization, and future visual assets.

## Run

```bash
flutter pub get
flutter run
```

The project targets iOS, Android, and web. Follow the required code-generation
policies in [skills.md](skills.md).

This project intentionally has no automated-test targets or test dependencies.
