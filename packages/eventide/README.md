# Eventide

[![Pub](https://img.shields.io/pub/v/eventide.svg)](https://pub.dev/packages/eventide)

Access device calendars from Flutter on Android and iOS. Eventide provides a single API for calendar accounts, calendars, events, reminders, recurring events, and attendees.

## Installation

The federated version requires Flutter 3.47 and Dart 3.13 or later.

```sh
flutter pub add eventide
```

The federated package automatically selects its endorsed implementation for the current platform. Configure your app's `AndroidManifest.xml` or `Info.plist` as described in the [platform setup guide](https://github.com/sncf-connect-tech/eventide/blob/main/doc/PLATFORM_SETUP.md). Eventide handles the runtime permission prompts.

## Usage

### Open the platform's event creation flow

Use this when the user should finish creating the event in a calendar UI without granting your app calendar access. iOS presents the native editor; Android shares a prefilled `.ics` file with a compatible app.

```dart
import 'package:eventide/eventide.dart';

Future<void> openEventEditor() async {
  await Eventide().createEventThroughNativePlatform(title: 'Team standup');
}
```

### Write to the default calendar

`createEventInDefaultCalendar` writes to the default calendar on iOS, requesting write-only access on iOS 17+. On Android it uses the same sharing flow as `createEventThroughNativePlatform`.

### Create an event in a specific calendar

Use the direct calendar APIs to read and edit events and calendars. This example adds a weekly meeting with a reminder to the first writable calendar, if one is available:

```dart
import 'package:eventide/eventide.dart';

Future<ETEvent?> createWeeklyMeeting() async {
  final eventide = Eventide();
  final calendars = await eventide.retrieveCalendars();
  if (calendars.isEmpty) return null;

  final start = DateTime.now().add(const Duration(days: 1));
  return eventide.createEvent(
    calendarId: calendars.first.id,
    title: 'Weekly meeting',
    startDate: start,
    endDate: start.add(const Duration(hours: 1)),
    reminders: const [Duration(minutes: 15)],
    recurrenceRule: 'FREQ=WEEKLY',
  );
}
```

Android reminders use whole minutes; iOS supports seconds. Both implementations can read attendees, but only Android supports adding and removing them. See the [API reference](https://github.com/sncf-connect-tech/eventide/blob/main/doc/API_REFERENCE.md) for recurrence scopes, platform limitations, and exceptions.

## Testing apps that use Eventide

With the federated version, app tests can replace the platform implementation. For the example below, add `eventide_platform_interface`, `mocktail`, and `plugin_platform_interface` as direct dev dependencies of your app, alongside `flutter_test`.

```dart
import 'package:eventide/eventide.dart';
import 'package:eventide_platform_interface/eventide_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockEventidePlatform extends Mock
    with MockPlatformInterfaceMixin
    implements EventidePlatformInterface {}

void main() {
  test('reads the accounts returned by the registered platform', () async {
    final platform = MockEventidePlatform();
    when(platform.retrieveAccounts).thenAnswer((_) async => <ETAccount>[]);
    EventidePlatformInterface.instance = platform;

    expect(await Eventide().retrieveAccounts(), isEmpty);
  });
}
```

Set a fresh implementation for each test that uses Eventide. See the [example app](https://github.com/sncf-connect-tech/eventide/tree/main/packages/eventide/example) or the [repository overview](https://github.com/sncf-connect-tech/eventide) for more integration examples.
