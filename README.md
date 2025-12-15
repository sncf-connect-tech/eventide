## 📆 Eventide

[![pub package](https://img.shields.io/pub/v/eventide.svg)](https://pub.dev/packages/eventide) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT) [![Tests](https://github.com/sncf-connect-tech/eventide/actions/workflows/ci.yaml/badge.svg)](https://github.com/sncf-connect-tech/eventide/actions/workflows/ci.yml) [![codecov](https://codecov.io/gh/sncf-connect-tech/eventide/graph/badge.svg?token=jxA8pZnWmR)](https://codecov.io/gh/sncf-connect-tech/eventide)

Eventide provides an easy-to-use flutter interface to access & modify native device calendars (iOS & Android).

---

## 📋 Table of Contents

- [Features](#-features)
- [Getting Started](#-getting-started)
- [Quick Start](#-quick-start)
- [API Reference](#-api-reference)
  - [Calendars](#calendars)
  - [Events](#events)
  - [Reminders](#reminders)
  - [Attendees](#attendees)
  - [Accounts](#accounts)
- [Platform-Specific Features](#-platform-specific-features)
- [Exception Handling](#-exception-handling)
- [License](#license)
- [Feedback](#feedback)

---

## 🔥 Features

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

> **Note:** Eventide handles timezones as UTC. Make sure the right data is fed to the plugin with a [timezone aware DateTime class](https://pub.dev/packages/timezone).

---

## 🔨 Getting Started

### Platform Setup

#### Android

Add the following permissions to your `android/app/src/main/AndroidManifest.xml` based on the features you need:

```xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"...>
    <!-- For reading calendars and events -->
    <uses-permission android:name="android.permission.READ_CALENDAR" />
    
    <!-- For creating, modifying, or deleting calendars and events -->
    <uses-permission android:name="android.permission.WRITE_CALENDAR" />
    ...
</manifest>
```

**Note:** `createEventInDefaultCalendar()` and `createEventThroughNativePlatform()` do not require declaring these permissions in your AndroidManifest.xml as they use the system calendar app. This privacy-first approach ensures your app doesn't need to access user's calendar data directly. Both methods have identical behavior on Android.

#### iOS

The following are the lines you need to add to your `info.plist` file:

##### Versions below iOS 17
```xml
<key>NSCalendarsUsageDescription</key>
<string>We need access to your calendar to add information about your trip.</string>
```
Starting iOS 17+, it depends whether you want full or write-only access from your user.

##### Write-only
```xml
<key>NSCalendarsWriteOnlyAccessUsageDescription</key>
<string>We need access to your calendar to add information about your trip.</string>
```

##### Full access
```xml
<key>NSCalendarsFullAccessUsageDescription</key>
<string>We need access to your calendar to add information about your trip.</string>
```

Note that write-only AND full access will result on your app asking for both.

**Note:** `createEventThroughNativePlatform()` does not require any calendar usage description in your Info.plist as it uses the native event creation UI, which handles permissions internally.

---

## 🚀 Quick Start

```dart
import 'package:eventide/eventide.dart';

final eventide = Eventide();

// Get available accounts
final accounts = await eventide.retrieveAccounts();
print('Available accounts: ${accounts.map((a) => a.name).join(', ')}');

// Create a calendar in default account
final calendar = await eventide.createCalendar(
  title: 'Work',
  color: Colors.red,
);

// Create a calendar in specific account
if (accounts.isNotEmpty) {
  final specificCalendar = await eventide.createCalendar(
    title: 'Personal',
    color: Colors.blue,
    account: accounts.first,
  );
}

// Create an event in a specific calendar with reminders
final event = await eventide.createEvent(
  calendarId: calendar.id,
  title: 'Meeting',
  startDate: DateTime.now(),
  endDate: DateTime.now().add(Duration(hours: 1)),
  location: '1 Place Bellecour, 69002 Lyon',
  reminders: [
    const Duration(hours: 1),
    const Duration(minutes: 15),
  ],
);

// Create an event in the default calendar (iOS write-only access)
await eventide.createEventInDefaultCalendar(
  title: 'Important Meeting',
  startDate: DateTime.now().add(Duration(days: 1)),
  endDate: DateTime.now().add(Duration(days: 1, hours: 1)),
  reminders: [
    const Duration(minutes: 15),
  ],
);

// Create an event using native platform UI (no permissions required)
await eventide.createEventThroughNativePlatform(
  title: 'Team Standup',
  startDate: DateTime.now().add(Duration(hours: 2)),
  endDate: DateTime.now().add(Duration(hours: 2, minutes: 30)),
);

// Delete a reminder
final updatedEvent = await eventide.deleteReminder(
  durationBeforeEvent: Duration(minutes: 15),
  eventId: event.id,
);
```

You can find more examples in the [examples app](./example/apps).

---

## 📚 API Reference

### Calendars

#### Create Calendar

```dart
Future<ETCalendar> createCalendar({
  required String title,
  required Color color,
  ETAccount? account,
})
```

Creates a new calendar with the specified title, color, and optional account.

```dart
// Create calendar in default account
final calendar = await eventide.createCalendar(
  title: 'Personal',
  color: Colors.blue,
);

// Create calendar in specific account
final accounts = await eventide.retrieveAccounts();
final googleAccount = accounts.firstWhere((acc) => acc.name.contains('gmail'));

final workCalendar = await eventide.createCalendar(
  title: 'Work',
  color: Colors.red,
  account: googleAccount,
);
```

#### Retrieve Calendars

```dart
Future<Iterable<ETCalendar>> retrieveCalendars({
  bool onlyWritableCalendars = true,
  ETAccount? account,
})
```

Retrieves a list of calendars, optionally filtered by account and writability.

```dart
// Get all writable calendars
final calendars = await eventide.retrieveCalendars();

// Get calendars from specific account
final accounts = await eventide.retrieveAccounts();
final googleAccount = accounts.firstWhere((acc) => acc.name.contains('gmail'));
final googleCalendars = await eventide.retrieveCalendars(
  account: googleAccount,
);

// Get all calendars (including read-only)
final allCalendars = await eventide.retrieveCalendars(
  onlyWritableCalendars: false,
);
```

#### Delete Calendar

```dart
Future<void> deleteCalendar({
  required String calendarId,
})
```

Deletes a calendar by its ID.

```dart
await eventide.deleteCalendar(calendarId: calendar.id);
```

#### Retrieve Accounts

```dart
Future<Iterable<ETAccount>> retrieveAccounts()
```

Retrieves all available accounts from the device that have calendars. This includes Google accounts, iCloud accounts, Exchange accounts, etc.

```dart
// Get all available accounts
final accounts = await eventide.retrieveAccounts();

// Use account for calendar operations
final calendar = await eventide.createCalendar(
  title: 'Work Schedule',
  color: Colors.blue,
  account: accounts.first, // Note that a default local account will be used if no account is specified.
);
```

### Events

#### Create Event

```dart
Future<ETEvent> createEvent({
  required String calendarId,
  required String title,
  required DateTime startDate,
  required DateTime endDate,
  bool isAllDay = false,
  String? description,
  String? url,
  String? location,
  Iterable<Duration>? reminders,
})
```

Creates a new event in the specified calendar.

```dart
final event = await eventide.createEvent(
  calendarId: calendar.id,
  title: 'Team Meeting',
  startDate: DateTime.now(),
  endDate: DateTime.now().add(Duration(hours: 1)),
  description: 'Weekly team sync',
  location: '1 Place Bellecour, 69002 Lyon',
  isAllDay: false,
  reminders: [Duration(minutes: 15)],
);
```

#### Create Event in Default Calendar

```dart
Future<void> createEventInDefaultCalendar({
  required String title,
  required DateTime startDate,
  required DateTime endDate,
  bool isAllDay = false,
  String? description,
  String? url,
  String? location,
  Iterable<Duration>? reminders,
})
```

Creates a new event in the default calendar
- On iOS, this method will prompt the user for write-only permission and insert the event in the user's default calendar.
- On Android, this method opens the system calendar app for the user to create the event (no permissions required).

> **Note:** On Android, `createEventThroughNativePlatform()` has identical behavior to this method. This behavior may change in the future if Android introduces a native default calendar API.

```dart
await eventide.createEventInDefaultCalendar(
  title: 'Important Meeting',
  startDate: DateTime.now().add(Duration(days: 1)),
  endDate: DateTime.now().add(Duration(days: 1, hours: 1)),
  description: 'Weekly team sync',
  location: 'Conference Room A',
  isAllDay: false,
  reminders: [Duration(minutes: 15)],
);
```

#### Create Event through Native Platform

```dart
Future<void> createEventThroughNativePlatform({
  String? title,
  DateTime? startDate,
  DateTime? endDate,
  bool? isAllDay,
  String? description,
  String? url,
  String? location,
  Iterable<Duration>? reminders,
})
```

Creates a new event using the native platform UI. This method provides a consistent cross-platform experience for event creation without requiring calendar permissions.

**Platform Behavior:**
- **iOS**: Opens the native event creation modal where users can create events with write-only permission
- **Android**: Opens the system calendar app for event creation (identical behavior to `createEventInDefaultCalendar()`)

> **Note:** All parameters are optional, allowing flexible event creation. The method is fire-and-forget on Android - it doesn't wait for event creation completion.

```dart
// Create event with full details
await eventide.createEventThroughNativePlatform(
  title: 'Team Standup',
  startDate: DateTime.now().add(Duration(hours: 2)),
  endDate: DateTime.now().add(Duration(hours: 2, minutes: 30)),
  description: 'Daily team synchronization',
  location: 'Meeting Room B',
  isAllDay: false,
  reminders: [Duration(minutes: 10)],
);

// Create event with minimal parameters
await eventide.createEventThroughNativePlatform(
  title: 'Quick Meeting',
);

// No parameters - opens empty native form
await eventide.createEventThroughNativePlatform();
```

#### Retrieve Events

```dart
Future<Iterable<ETEvent>> retrieveEvents({
  required String calendarId,
  DateTime? startDate,
  DateTime? endDate,
})
```

Retrieves events from a calendar within the specified date range.

```dart
final events = await eventide.retrieveEvents(
  calendarId: calendar.id,
  startDate: DateTime.now().subtract(Duration(days: 7)),
  endDate: DateTime.now().add(Duration(days: 7)),
);
```

#### Delete Event

```dart
Future<void> deleteEvent({
  required String eventId,
})
```

Deletes an event by its ID.

```dart
await eventide.deleteEvent(eventId: event.id);
```

### Reminders

#### Create Reminder

```dart
Future<ETEvent> createReminder({
  required String eventId,
  required Duration durationBeforeEvent,
})
```

Adds a reminder to an existing event.

```dart
final updatedEvent = await eventide.createReminder(
  eventId: event.id,
  durationBeforeEvent: Duration(minutes: 30),
);
```

#### Delete Reminder

```dart
Future<ETEvent> deleteReminder({
  required String eventId,
  required Duration durationBeforeEvent,
})
```

Removes a specific reminder from an event.

```dart
final updatedEvent = await eventide.deleteReminder(
  eventId: event.id,
  durationBeforeEvent: Duration(minutes: 30),
);
```

> **Note:** Reminders with durations in seconds are not supported on Android due to API limitations.

### Attendees

⚠️ **Platform Limitation:** Attendee creation and deletion are only supported on Android due to iOS EventKit API restrictions. However, attendees can be retrieved on both platforms.

#### Create Attendee (Android Only)

```dart
Future<ETEvent> createAttendee({
  required String eventId,
  required String name,
  required String email,
  required ETAttendeeType type,
})
```

Adds an attendee to an event.

```dart
final eventWithAttendee = await eventide.createAttendee(
  eventId: event.id,
  name: 'John Doe',
  email: 'john.doe@gmail.com',
  type: ETAttendeeType.requiredPerson,
);
```

#### Delete Attendee (Android Only)

```dart
Future<ETEvent> deleteAttendee({
  required String eventId,
  required ETAttendee attendee,
})
```

Removes an attendee from an event.

```dart
final eventWithoutAttendee = await eventide.deleteAttendee(
  eventId: event.id,
  attendee: eventWithAttendee.attendees.first,
);
```

#### Attendee Types

Available `ETAttendeeType` values:

- `ETAttendeeType.unknown`
- `ETAttendeeType.requiredPerson`
- `ETAttendeeType.optionalPerson`
- `ETAttendeeType.resource`
- `ETAttendeeType.organizer`

##### Platform Mapping Tables

###### Common attendees types mapping
iOS and Android attendee APIs are quite different and thus required some conversion logic. Here's the mapping table that eventide currently supports:

|  ETAttendeeType            | iOS (EKParticipantType)   | iOS (EKParticipantRole)   | Android (ATTENDEE_TYPE)   | Android (ATTENDEE_RELATIONSHIP)   |
|  :------------------------ | :------------------------ | :------------------------ | :------------------------ | :-------------------------------- |
|  unknown                   | unknown                   | unknown                   | TYPE_NONE                 | RELATIONSHIP_NONE                 |
|  requiredPerson            | person                    | required                  | TYPE_REQUIRED             | RELATIONSHIP_ATTENDEE             |
|  optionalPerson            | person                    | optional                  | TYPE_OPTIONAL             | RELATIONSHIP_ATTENDEE             |
|  resource                  | resource                  | required                  | TYPE_RESOURCE             | RELATIONSHIP_ATTENDEE             |
|  organizer                 | person                    | chair                     | TYPE_REQUIRED             | RELATIONSHIP_ORGANIZER            |

###### Platform specific attendees types mapping
Platform specific values will be treated as follow when fetched from existing system calendar:

| ETAttendeeType            | iOS (EKParticipantType)   | iOS (EKParticipantRole)   | Android (ATTENDEE_TYPE)   | Android (ATTENDEE_RELATIONSHIP)   |
| :------------------------ | :------------------------ | :------------------------ | :------------------------ | :-------------------------------- |
| optionalPerson            | person                    | nonParticipant            |                           |                                   |
| resource                  | group                     | required                  |                           |                                   |
| resource                  | room                      | required                  |                           |                                   |
| requiredPerson            |                           |                           | TYPE_REQUIRED             | RELATIONSHIP_PERFORMER            |
| requiredPerson            |                           |                           | TYPE_REQUIRED             | RELATIONSHIP_SPEAKER              |

### Accounts

A calendar belongs to an account, such as a Google account, Exchange account, or a local on-device account. You can optionally specify an `ETAccount` when creating a calendar with Eventide.

#### Working with Accounts

```dart
// Get all available accounts
final accounts = await eventide.retrieveAccounts();

// Display available accounts
for (final account in accounts) {
  print('📧 ${account.name} (${account.type})');
}

// Find Google account
final googleAccount = accounts.firstWhere(
  (account) => account.name.toLowerCase().contains('gmail'),
  orElse: () => throw Exception('Google account not found'),
);

// Create calendar in specific account
final workCalendar = await eventide.createCalendar(
  title: 'Work',
  color: Colors.red,
  account: googleAccount,
);

// Create calendar in default account (when account is null)
final personalCalendar = await eventide.createCalendar(
  title: 'Personal',
  color: Colors.blue,
  // account: null, // Will use default account
);
```

#### Filtering Calendars by Account

```dart
// Get calendars from specific account
final googleCalendars = await eventide.retrieveCalendars(
  account: googleAccount,
  onlyWritableCalendars: true,
);

// Get all calendars from all accounts
final allCalendars = await eventide.retrieveCalendars();
```

---

## 🔧 Platform-Specific Features

### Privacy-First Approach

Eventide is designed with user privacy as a core principle. We believe users should have granular control over their calendar data and only grant the minimum permissions necessary for your app to function.

**Our privacy-focused design:**

- **Minimal permissions**: Only request the permissions your app actually needs
- **User choice**: Support both write-only and full access modes on iOS 17+
- **System delegation**: On Android, `createEventInDefaultCalendar()` and `createEventThroughNativePlatform()` delegate to the system calendar app, ensuring no direct data access
- **Transparency**: Clear documentation about what each method requires and accesses

This approach ensures users maintain control over their personal calendar data while still enabling powerful calendar integration for your app.

### iOS Write-Only Access

As of iOS 17, Apple introduced a new write-only access permission for calendar data, providing users with more granular control over app permissions. This feature allows apps to add events to calendars without being able to read existing calendar data.

#### How it works

When you call `createEventInDefaultCalendar()` on iOS 17+, the system will prompt the user for write-only access if full access hasn't been granted. This method directly creates an event in the user's default calendar without requiring you to retrieve the calendar first.

```dart
// Will prompt user for write only access on iOS 17+
await eventide.createEventInDefaultCalendar(
  title: 'New Meeting',
  startDate: DateTime.now(),
  endDate: DateTime.now().add(Duration(hours: 1)),
  description: 'Weekly team sync',
  reminders: [Duration(minutes: 15)],
);

print('Event created successfully');
```

#### Important limitations

⚠️ **Key restrictions when using write-only access:**

- **No reading capabilities**: You cannot retrieve events from calendars when using write-only access
- **Create only**: You can only create new events, not modify or read existing ones
- **No calendar enumeration**: You cannot list or retrieve calendar information

```dart
// ❌ This will fail with write-only access
try {
  final calendars = await eventide.retrieveCalendars();
  final events = await eventide.retrieveEvents(
    calendarId: calendars.first.id,
  );
} catch (e) {
  // Will throw ETPermissionException on iOS with write-only access
  print('Cannot read calendars/events with write-only access: $e');
}

// ✅ This works with write-only access
await eventide.createEventInDefaultCalendar(
  title: 'Team Meeting',
  startDate: DateTime.now().add(Duration(days: 1)),
  endDate: DateTime.now().add(Duration(days: 1, hours: 1)),
  description: 'Weekly team sync',
  reminders: [Duration(minutes: 15)],
);
```

#### Permission handling

Eventide automatically handles the permission flow for you - no need to manually request permissions. 

**Example for iOS:**

1. First call to `createEventInDefaultCalendar()` → Shows write-only permission prompt
2. User grants write-only access → Creates event in default calendar
3. User denies access → Throws `ETPermissionException`

**Another iOS example:**

1. First call to `retrieveCalendars()` → Shows full calendar access prompt
2. User grants full access → Returns list of calendars
3. User denies access → Throws `ETPermissionException`

**Examples for Android:**

1. Call to `createEventThroughNativePlatform()` → Opens system calendar app directly
2. No permissions required → User creates event in native calendar UI
3. Returns immediately after opening system app

**Another Android example:**

1. First call to `createEvent()` → Shows calendar permission dialog
2. User grants permission → Creates event in specified calendar
3. User denies permission → Throws `ETPermissionException`

#### Best practices

**Privacy-first approach - from least to most intrusive:**

1. **No permissions required**: `createEventThroughNativePlatform()` for simple event creation using native UI
2. **Write-only access**: `createEventInDefaultCalendar()` for apps that only need to add events (booking confirmations, reminders, etc.)
3. **Full calendar access**: For apps that need to read existing events and manage calendars

**Error handling:**
- Handle `ETPermissionException` when attempting operations that require read access
- Consider graceful fallbacks when permissions are denied

**Development approach:**
- Start with minimal permissions and only escalate when features require it
- Offer clear value proposition when requesting additional access

---

## ⚠️ Exception Handling

Eventide provides several custom exception types for better error handling.

### Example Usage

```dart
try {
  final calendar = await eventide.createCalendar(
    title: 'My Calendar',
    color: Colors.blue,
    localAccountName: 'My App',
  );
} on ETPermissionException catch (e) {
  print('Permission denied: ${e.message}');
} on ETGenericException catch (e) {
  print('Error creating calendar: ${e.message}');
} catch (e) {
  print('Unexpected error: $e');
}
```

---

## License

Copyright © 2025 SNCF Connect & Tech. This project is licensed under the MIT License - see the LICENSE file for details.

## Feedback

Please file any issues, bugs or feature requests as an issue on the [Github page](https://github.com/sncf-connect-tech/eventide/issues).
