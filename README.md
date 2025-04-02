## 📆 Eventide

[![pub package](https://img.shields.io/pub/v/eventide.svg)](https://pub.dev/packages/eventide) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT) [![Tests](https://github.com/sncf-connect-tech/eventide/actions/workflows/ci.yml/badge.svg)](https://github.com/sncf-connect-tech/eventide/actions/workflows/ci.yml) [![codecov](https://codecov.io/gh/sncf-connect-tech/eventide/graph/badge.svg?token=jxA8pZnWmR)](https://codecov.io/gh/sncf-connect-tech/eventide)

Eventide provides a easy-to-use flutter interface to access & modify native device calendars (iOS & Android).

---

### 🔥 Features
|    | Eventide |
---- | --------------------------------
:white_check_mark: | Automatic permission handling
:white_check_mark: | Create/retrieve/delete calendars
:white_check_mark: | Create/retrieve/delete events
:white_check_mark: | Create/delete reminders
:white_check_mark: | Custom exceptions
:construction: | Recurring events
:white_check_mark: | Attendees
:construction: | Streams

NOTE: Eventide handles timezones as UTC. Make sure the right data is feed to the plugin with a [timezone aware DateTime class](https://pub.dev/packages/timezone).

---

### 🔨 Getting Started

#### Android

Nothing to add on your side. All is already declared in eventide's AndroidManifest.xml

#### iOS

To read/write calendar data, your app must include the following permissions in its info.plist file.

```xml
<key>NSCalendarsUsageDescription</key>
<string>We need access to your calendar to add information about your trip.</string>
<key>NSCalendarsFullAccessUsageDescription</key>
<string>We need access to your calendar to add information about your trip.</string>
<key>NSCalendarsWriteOnlyAccessUsageDescription</key>
<string>We need access to your calendar to add information about your trip.</string>
```

---

### 🚀 Quick start

```dart
import 'package:eventide/eventide.dart';

final eventide = Eventide();

final calendar = await eventide.createCalendar('Work', Colors.red);

final event = await eventide.createEvent(
    calendarId: calendar.id,
    title: 'Meeting',
    startDate: DateTime.now(),
    endDate: DateTime.now().add(Duration(hours: 1)),
    reminders: [
        const Duration(hours: 1)
        const Duration(minutes: 15),
    ],
);

final updatedEvent = await eventide.deleteReminder(
    durationBeforeEvent: Duration(minutes: 15),
    eventId: event.id,
);
```

You can find more in the example app.

---

### 🧑🏻 Attendees

#### Creation & deletion

⚠️ Please note that attendees edition is only supported by Android, due to iOS EventKit API limitations. Attendees are still retrievable through events on both iOS & Android.

```dart
final eventWithAttendee = await eventide.createAttendee(
    eventId: event.id,
    name: 'John Doe',
    email: 'john.doe@gmail.com',
    type: ETAttendeeType.requiredPerson,
);

final eventWithoutAttendee = await eventide.deleteAttendee(
    eventId: event.id,
    attendee: eventWithAttendee.attendees.first,
);
```

#### Retrieval
##### Common attendees types mapping table
iOS and Android attendee APIs are quite different and thus required some conversion logic. Here's the mapping table that eventide currently supports:

|  ETAttendeeType            | iOS (EKParticipantType)   | iOS (EKParticipantRole)   | Android (ATTENDEE_TYPE)   | Android (ATTENDEE_RELATIONSHIP)   |
|  :------------------------ | :------------------------ | :------------------------ | :------------------------ | :-------------------------------- |
|  unknown                   | unknown                   | unknown                   | TYPE_NONE                 | RELATIONSHIP_NONE                 |
|  requiredPerson            | person                    | required                  | TYPE_REQUIRED             | RELATIONSHIP_ATTENDEE             |
|  optionalPerson            | person                    | optional                  | TYPE_OPTIONAL             | RELATIONSHIP_ATTENDEE             |
|  resource                  | resource                  | required                  | TYPE_RESOURCE             | RELATIONSHIP_ATTENDEE             |
|  organizer                 | person                    | chair                     | TYPE_REQUIRED             | RELATIONSHIP_ORGANIZER            |

##### Platform specific attendees types mapping table
Platform specific values will be treated as follow when fetched from existing system calendar:

| ETAttendeeType            | iOS (EKParticipantType)   | iOS (EKParticipantRole)   | Android (ATTENDEE_TYPE)   | Android (ATTENDEE_RELATIONSHIP)   |
| :------------------------ | :------------------------ | :------------------------ | :------------------------ | :-------------------------------- |
| optionalPerson            | person                    | nonParticipant            |                           |                                   |
| resource                  | group                     | required                  |                           |                                   |
| resource                  | room                      | required                  |                           |                                   |
| requiredPerson            |                           |                           | TYPE_REQUIRED             | RELATIONSHIP_PERFORMER            |
| requiredPerson            |                           |                           | TYPE_REQUIRED             | RELATIONSHIP_SPEAKER              |

---

### License

Copyright © 2025 SNCF Connect & Tech. This project is licensed under the MIT License - see the LICENSE file for details.

### Feedback

Please file any issues, bugs or feature requests as an issue on the [Github page](https://github.com/sncf-connect-tech/eventide/issues).