## 📆 Eventide

[![pub package](https://img.shields.io/pub/v/eventide.svg)](https://pub.dev/packages/eventide) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT) [![Tests](https://github.com/sncf-connect-tech/eventide/actions/workflows/ci.yaml/badge.svg)](https://github.com/sncf-connect-tech/eventide/actions/workflows/ci.yml) [![codecov](https://codecov.io/gh/sncf-connect-tech/eventide/graph/badge.svg?token=jxA8pZnWmR)](https://codecov.io/gh/sncf-connect-tech/eventide)

Eventide provides an easy-to-use flutter interface to access & modify native device calendars (iOS & Android).

---

## 🔥 Features

|    | Eventide |
---- | --------------------------------
:white_check_mark: | Automatic permission handling
:white_check_mark: | Create/retrieve/delete calendars
:white_check_mark: | Create/retrieve/delete events
:white_check_mark: | Create/delete reminders
:white_check_mark: | Custom exceptions
:white_check_mark: | Attendees
:building_construction: | Edit calendars/events
:bulb: | Recurring events

---

## 🚀 Quick Start

### Platform Setup

Detailed setup for Android and iOS can be found in [PLATFORM_SETUP.md](./doc/PLATFORM_SETUP.md).

### Automatic permission handling

Eventide automatically handles the permission flow for you - no need to manually request permissions. See [API_REFERENCE.md](./doc/API_REFERENCE.md#automatic-permission-handling).

### Usage

```dart
import 'package:eventide/eventide.dart';

final eventide = Eventide();

// Create an event in calendar
final calendars = await eventide.retrieveCalendars();

await eventide.createEvent(
  calendarId: calendars.first.id,
  title: 'Important Meeting',
  startDate: DateTime.now().add(Duration(days: 1)),
  endDate: DateTime.now().add(Duration(days: 1, hours: 1)),
  reminders: [const Duration(minutes: 15)],
);

// Create an event in the default calendar (Privacy-first)
await eventide.createEventInDefaultCalendar(
  title: 'Important Meeting',
  startDate: DateTime.now().add(Duration(days: 1)),
  endDate: DateTime.now().add(Duration(days: 1, hours: 1)),
);

// Create an event using native platform UI (No permissions required)
await eventide.createEventThroughNativePlatform(
  title: 'Team Standup',
);
```

---

## 📚 Documentation
- [Accounts](./doc/API_REFERENCE.md#accounts)
  - [retrieveAccounts](./doc/API_REFERENCE.md#retrieve-accounts)
- [Calendars](./doc/API_REFERENCE.md#calendars)
  - [createCalendar](./doc/API_REFERENCE.md#create-calendar)
  - [retrieveCalendars](./doc/API_REFERENCE.md#retrieve-calendars)
  - [deleteCalendar](./doc/API_REFERENCE.md#delete-calendar)
- [Events](./doc/API_REFERENCE.md#events)
  - [createEvent](./doc/API_REFERENCE.md#create-event)
  - [createEventInDefaultCalendar](./doc/API_REFERENCE.md#create-event-in-default-calendar)
  - [createEventThroughNativePlatform](./doc/API_REFERENCE.md#create-event-through-native-platform)
  - [retrieveEvents](./doc/API_REFERENCE.md#retrieve-events)
  - [deleteEvent](./doc/API_REFERENCE.md#delete-event)
- [Reminders](./doc/API_REFERENCE.md#reminders)
  - [createReminder](./doc/API_REFERENCE.md#create-reminder)
  - [deleteReminder](./doc/API_REFERENCE.md#delete-reminder)
- [Attendees](./doc/API_REFERENCE.md#attendees)
  - [createAttendee](./doc/API_REFERENCE.md#create-attendee)
  - [deleteAttendee](./doc/API_REFERENCE.md#delete-attendee)
- [Automatic permission handling](./doc/API_REFERENCE.md#automatic-permission-handling)
- [Exception Handling](./doc/API_REFERENCE.md#exception-handling)
- [Platform Setup](./doc/PLATFORM_SETUP.md)

---

## License

Copyright © 2026 SNCF Connect & Tech. This project is licensed under the [MIT License](./LICENSE).

## Feedback

Please file any issues, bugs or feature requests as an issue on the [Github page](https://github.com/sncf-connect-tech/eventide/issues).
