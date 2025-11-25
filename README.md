# test_example_flutter

Small Flutter app that explores different approaches to loading and selecting users from `jsonplaceholder.typicode.com`. The repo keeps multiple `main*.dart` entrypoints side by side to compare patterns.

## Entry points
- `lib/main.dart` — intentionally broken baseline (mutable models, heavy `setState`, no separation of concerns).
- `lib/main_fixed.dart` — bloc-driven fix with immutable models, repository + stream, and proper error handling.
- `lib/main_fixed_new.dart` — refined version of the fixed app with slimmer wiring and the same feature set.
- `lib/main_fixed_nostream.dart` — bloc-driven fix without the stream layer; straightforward HTTP fetch and toggle support.
- `lib/main_fixed_interview.dart` — minimal interview-style Cubit example (load-only, no selection) with inline wiring.

## Running a variant
Pick the entrypoint you want to run:
- `flutter run -t lib/main.dart`
- `flutter run -t lib/main_fixed.dart`
- `flutter run -t lib/main_fixed_new.dart`
- `flutter run -t lib/main_fixed_nostream.dart`
- `flutter run -t lib/main_fixed_interview.dart`

## Notes
- Uses `flutter_bloc` and `equatable` in the fixed variants for predictable state management.
- Models are immutable in the fixed examples; selection toggles flow through the cubit instead of direct mutation.
- `RefreshIndicator` hooks to `loadUsers()` so a pull-to-refresh triggers a fresh fetch.
