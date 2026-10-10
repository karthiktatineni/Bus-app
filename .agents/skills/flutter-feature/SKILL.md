---
name: flutter-feature
description: How to add a feature using our folder layout, shared widgets, design tokens, Riverpod controller, repository interface, tests.
---
# flutter-feature

## When to use
When adding a new feature or screen to the Flutter app.

## Procedure
1. Create the model in `lib/src/features/<name>/domain/`.
2. Create the repository interface and Supabase implementation in `lib/src/features/<name>/data/`.
3. Create the Riverpod controller in `lib/src/features/<name>/application/`.
4. Build the UI in `lib/src/features/<name>/presentation/` using shared widgets and design tokens.
5. Write unit tests for the controller and widget tests for the UI.

## Definition of Done
- Code follows `ARCHITECTURE.md` layers.
- Tests are written and passing.
- No direct Supabase calls in UI.
