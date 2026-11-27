# Eventide project context

Eventide is a federated Flutter plugin for native calendar access on iOS and Android, maintained by SNCF Connect & Tech.

## Package layout

| Package | Responsibility |
| --- | --- |
| [`eventide`](packages/eventide/) | App-facing API. Delegates to the registered platform implementation and re-exports shared models and exceptions. |
| [`eventide_platform_interface`](packages/eventide_platform_interface/) | Shared `EventidePlatformInterface`, `ET*` models, and exceptions. |
| [`eventide_ios`](packages/eventide_ios/) | Dart adapter and Swift implementation using EventKit and EventKitUI. |
| [`eventide_android`](packages/eventide_android/) | Dart adapter and Kotlin implementation using `CalendarContract` and `.ics` sharing. |

## Native communication

Each platform package owns its Pigeon schema at `pigeon/calendar_api.dart` and the matching generated Dart client at `lib/src/calendar_api.g.dart`. The iOS schema generates `ios/eventide_ios/Sources/eventide_ios/CalendarApi.g.swift`; the Android schema generates `android/src/main/kotlin/sncf/connect/tech/eventide/CalendarApi.g.kt`. These paths are relative to their platform packages.

Regenerate both sides of any changed schema using the [contributor guide](CONTRIBUTING.md#regenerate-pigeon-bindings). Avoid editing generated bindings directly. Conversions between the Pigeon types and shared `ET*` models live in the platform packages' `lib/src/extensions/` directories.

## Tests and examples

- Dart tests live in each package's `test/` directory.
- Swift XCTest: [`packages/eventide_ios/ios/eventide_ios/Tests/EventideTests/`](packages/eventide_ios/ios/eventide_ios/Tests/EventideTests/).
- Kotlin tests: [`packages/eventide_android/android/src/test/kotlin/`](packages/eventide_android/android/src/test/kotlin/).
- The [main example](packages/eventide/example/) exercises the public package; [`examples/`](examples/) shows the different permission flows.

## Public contracts

Eventide requests calendar access when an operation needs it; the app declares the necessary permissions and usage descriptions. Prefer the system creation flow or write-only access where appropriate. Update the [API reference](doc/API_REFERENCE.md) and [platform setup guide](doc/PLATFORM_SETUP.md) when changing public behavior.
