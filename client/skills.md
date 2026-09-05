# Honest Dating Code-Generation Policies

## Architecture

- Keep code within the established layers: `ui` depends on repository interfaces and models; repository implementations depend on models; models and config do not depend on UI.
- Add each feature under `lib/ui/screens/<feature>/`; put its BLoC, events, and states in a `bloc/` subdirectory.
- Define repository contracts in `lib/repositories/base/` and implementations in `lib/repositories/app_repositories/`. Construct dependencies only through `BaseRepositoriesFactory` and `AppRepositoriesFactory`.
- Use `BaseRouter` route names and `MainRouter` for navigation. Do not navigate through ad-hoc route construction outside the router layer.

## Data and privacy

- Use local fake data unless an approved backend contract and configuration are supplied.
- Keep the documented database structure current whenever an entity, field, collection, or stored-data format is added, changed, or removed. Update the relevant database documentation in the same change.
- Do not add API keys, secrets, access tokens, personal data, or production endpoints to source control, fixtures, logs, or sample data.
- Do not request a device permission or add an analytics/advertising SDK without an explicit product requirement and a reviewed user-facing purpose string.

## Dart and Flutter conventions

- Use absolute `package:honest_dating/...` imports.
- Prefer immutable models, `const` widgets, explicit public API types, and narrowly scoped classes.
- Keep widgets declarative; put user actions and state transitions in BLoCs. Do not put data access in widgets.
- Add a dependency only when it is necessary for an approved feature; update `pubspec.yaml` and explain why in the change summary.
- Run `dart format` and `flutter analyze` after Dart changes.

## Tests

- Do not generate, add, modify, or run automated tests for this project unless the product owner explicitly changes this policy.
- Do not add a `test/` directory, `flutter_test`, integration-test targets, or platform test targets.
