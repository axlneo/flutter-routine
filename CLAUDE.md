# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Development Commands

```bash
# Run the app
flutter run

# Run tests
flutter test

# Run a single test file
flutter test test/widget_test.dart

# Analyze code (linting)
flutter analyze

# Format code
dart format lib/

# Regenerate Hive adapters after modifying @HiveType models
dart run build_runner build
```

## Architecture

This is a French-language fitness app ("Routine") for daily morning/evening workout routines with Polar H10 heart rate monitoring and medication tracking. All UI strings are in French.

### Layers

- **`lib/data/`** — Static routine definitions (morning 20min, evening 40min with day-variant exercises)
- **`lib/models/`** — Data models (`Exercise`, `Section`, `SessionRecord`, `HrPoint`, `MedRecord`, `UserSettings`) with Hive type adapters generated in `models.g.dart`
- **`lib/screens/`** — Stateful widget screens using push/pop navigation
- **`lib/services/`** — Three singleton services:
  - `StorageService` — Hive-based persistence with three boxes (sessions, meds, settings)
  - `NotificationsService` — Scheduled daily reminders (7:00/19:00, Europe/Paris timezone)
  - `PolarService` — BLE heart rate streaming via `polar` package with broadcast StreamControllers

### Key Patterns

- **State management:** StatefulWidgets + StreamControllers (no Provider/BLoC/Riverpod)
- **Persistence:** Hive with code generation — after changing `@HiveType` classes in `models.dart`, run `build_runner build` to regenerate `models.g.dart`
- **Reactivity:** HR data and connection state flow through broadcast streams, consumed by StreamBuilder widgets
- **Initialization:** `main.dart` runs a strict sequence — Intl locale → StorageService → NotificationsService → orientation lock → app launch
- **Theme:** Dark mode only, Material 3, deepPurple seed color
- **Portrait-only** orientation lock

### Hive Adapter Registration

Adapters are manually registered in `StorageService.init()`. When adding a new `@HiveType`, you must:
1. Add the annotation with a unique `typeId`
2. Run `dart run build_runner build`
3. Register the new adapter in `StorageService.init()`
