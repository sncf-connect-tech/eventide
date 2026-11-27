# Eventide

Eventide is a Flutter plugin for reading and modifying device calendars on Android and iOS. It handles permission requests and can open the system's event creation flow without requesting calendar access.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](packages/eventide/LICENSE)
[![CI](https://github.com/sncf-connect-tech/eventide/actions/workflows/ci.yaml/badge.svg)](https://github.com/sncf-connect-tech/eventide/actions/workflows/ci.yaml)
[![Codecov](https://codecov.io/gh/sncf-connect-tech/eventide/graph/badge.svg?token=jxA8pZnWmR)](https://codecov.io/gh/sncf-connect-tech/eventide)

| [`eventide`](packages/eventide/) | [`eventide_android`](packages/eventide_android/) | [`eventide_ios`](packages/eventide_ios/) | [`eventide_platform_interface`](packages/eventide_platform_interface/) |
| --- | --- | --- | --- |
| [![Pub](https://img.shields.io/pub/v/eventide.svg)](https://pub.dev/packages/eventide) | First release pending | First release pending | First release pending |

## Platform support

| Android | iOS |
| --- | --- |
| Calendar access through `CalendarContract`; event creation via `.ics` sharing without calendar permissions. | Calendar access through EventKit; event creation through EventKitUI without calendar access, or directly in the default calendar with write-only access on iOS 17 and later. |

Both platforms support accounts, calendar and event management (including updates), reminders, recurring events, and reading attendees. Adding and removing attendees is available on Android.

## Getting started

Add the app-facing package to your Flutter app:

```sh
flutter pub add eventide
```

Follow the [platform setup guide](doc/PLATFORM_SETUP.md) for the features you use. Eventide requests permissions at runtime when needed; your app still declares the corresponding permissions or usage descriptions.

To open the platform's event creation flow:

```dart
import 'package:eventide/eventide.dart';

Future<void> addTeamStandup() async {
  await Eventide().createEventThroughNativePlatform(title: 'Team standup');
}
```

See the [integration guide](packages/eventide/README.md) for more examples and the [API reference](doc/API_REFERENCE.md) for supported operations and exceptions.

## Packages in this repository

Eventide follows Flutter's [federated plugin architecture](https://docs.flutter.dev/packages-and-plugins/developing-packages#federated-plugins).

| Package | Description | When to use |
| --- | --- | --- |
| [`eventide`](packages/eventide/) | Public API for Flutter apps | Add this to your app for Android and iOS support |
| [`eventide_android`](packages/eventide_android/) | Endorsed Android implementation | Work on `CalendarContract`, Android permissions, or `.ics` sharing |
| [`eventide_ios`](packages/eventide_ios/) | Endorsed iOS implementation | Work on EventKit, EventKitUI, or iOS permissions |
| [`eventide_platform_interface`](packages/eventide_platform_interface/) | Shared contract, models, and exceptions | Implement a platform or substitute an implementation in tests |

This documentation describes the federated version in this repository, ahead of the first pub.dev release of the platform packages.

## Examples

| Example | What it shows |
| --- | --- |
| [Plugin example](packages/eventide/example/) | Main development app for trying the public API |
| [Full permission](examples/full-permission/) | Browsing calendars and managing events with calendar access |
| [Write only](examples/write-only/) | Adding events with `createEventInDefaultCalendar` |
| [Native only](examples/native-only/) | Opening the system creation flow with `createEventThroughNativePlatform` |

See [CONTRIBUTING.md](CONTRIBUTING.md) to work on the plugin or [open an issue](https://github.com/sncf-connect-tech/eventide/issues) to report a problem. Eventide is maintained by SNCF Connect & Tech under the [MIT License](packages/eventide/LICENSE).
