# API Reference

Detailed documentation for all Eventide API methods.

## Table of Contents
- [Accounts](#accounts)
  - [retrieveAccounts](#retrieve-accounts)
- [Calendars](#calendars)
  - [createCalendar](#create-calendar)
  - [retrieveCalendars](#retrieve-calendars)
  - [deleteCalendar](#delete-calendar)
- [Events](#events)
  - [createEvent](#create-event)
  - [createEventInDefaultCalendar](#create-event-in-default-calendar)
  - [createEventThroughNativePlatform](#create-event-through-native-platform)
  - [retrieveEvents](#retrieve-events)
  - [deleteEvent](#delete-event)
- [Reminders](#reminders)
  - [createReminder](#create-reminder)
  - [deleteReminder](#delete-reminder)
- [Attendees](#attendees)
  - [createAttendee](#create-attendee)
  - [deleteAttendee](#delete-attendee)
- [Automatic permission handling](#automatic-permission-handling)
- [Exception Handling](#exception-handling)

---

## Accounts

### Retrieve Accounts

```dart
Future<Iterable<ETAccount>> retrieveAccounts()
```

Retrieves all available accounts from the device that have calendars. This includes Google accounts, iCloud accounts, Exchange accounts, etc.

---

## Calendars

### Create Calendar

```dart
Future<ETCalendar> createCalendar({
  required String title,
  required Color color,
  ETAccount? account,
})
```

Creates a new calendar with the specified title, color, and optional account.

> On iOS, default source will (local or iCloud)

> On Android, a default local account will be used if no account is specified.

### Retrieve Calendars

```dart
Future<Iterable<ETCalendar>> retrieveCalendars({
  bool onlyWritableCalendars = true,
  ETAccount? account,
})
```

Retrieves a list of calendars, optionally filtered by account and calendar writability.

### Delete Calendar

```dart
Future<void> deleteCalendar({
  required String calendarId,
})
```

---

## Events

### Create Event

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

### Create Event in Default Calendar

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

Creates a new event in the default calendar. This method does not require any permission on Android but requires at least write-only permission on iOS.

> On iOS, this method will prompt user for write-only permission and insert the event in the user's default calendar.

> On Android, the concept of "default calendar" does not exist yet. Both `createEventInDefaultCalendar()` and `createEventThroughNativePlatform()` work under the hood by "sharing" a virtual ics file. On Android, this method prompts user to choose the calendar app they want the event added into.

> See [PLATFORM_SETUP.md](./PLATFORM_SETUP.md) for permission related details.

### Create Event through Native Platform

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

Creates a new event using the native platform UI. This method does not require any permission on both iOS and Android.

> On iOS, this method will open a prefilled native modal to let the user create the event.

> On Android, such modal does not exist as user can have . Both `createEventInDefaultCalendar()` and `createEventThroughNativePlatform()` work under the hood by "sharing" a virtual ics file. On Android, this method prompts user to choose the calendar app they want the event added into.

> See [PLATFORM_SETUP.md](./PLATFORM_SETUP.md) for permission related details.

### Retrieve Events

```dart
final events = await eventide.retrieveEvents(
  calendarId: calendar.id,
  startDate: DateTime.now().subtract(Duration(days: 7)),
  endDate: DateTime.now().add(Duration(days: 7)),
);
```

Retrieves events from a calendar within the specified date range.

### Delete Event

```dart
Future<void> deleteEvent({
  required String eventId,
})
```

---

## Reminders

⚠️ **Platform Limitation:** Android reminders unit is in minutes. Therefore a [Duration] in seconds will only be supported on iOS.

### Create Reminder

```dart
Future<ETEvent> createReminder({
  required String eventId,
  required Duration durationBeforeEvent,
})
```

### Delete Reminder

```dart
Future<ETEvent> deleteReminder({
  required String eventId,
  required Duration durationBeforeEvent,
})
```

---

## Attendees

⚠️ **Platform Limitation:** Attendee creation and deletion are only supported on Android.

### Create Attendee

```dart
Future<ETEvent> createAttendee({
  required String eventId,
  required String name,
  required String email,
  required ETAttendeeType type,
})
```

#### Delete Attendee

```dart
Future<ETEvent> deleteAttendee({
  required String eventId,
  required ETAttendee attendee,
})
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
Platform specific values will be treated as follow when fetched:

| ETAttendeeType            | iOS (EKParticipantType)   | iOS (EKParticipantRole)   | Android (ATTENDEE_TYPE)   | Android (ATTENDEE_RELATIONSHIP)   |
| :------------------------ | :------------------------ | :------------------------ | :------------------------ | :-------------------------------- |
| optionalPerson            | person                    | nonParticipant            |                           |                                   |
| resource                  | group                     | required                  |                           |                                   |
| resource                  | room                      | required                  |                           |                                   |
| requiredPerson            |                           |                           | TYPE_REQUIRED             | RELATIONSHIP_PERFORMER            |
| requiredPerson            |                           |                           | TYPE_REQUIRED             | RELATIONSHIP_SPEAKER              |

---

## Automatic Permission Handling

Eventide automatically handles the permission flow for you - no need to manually request permissions. You still need to configure your `AndroidManifest.xml` and `Info.plist` files. See [PLATFORM_SETUP.md](./PLATFORM_SETUP.md)

### iOS
#### Without access
1. Call to `createEventThroughNativePlatform()` → Shows native event creation modal
2. No permissions required → User creates event in native calendar UI

#### Write-only access
1. First call to `createEventInDefaultCalendar()` → Shows write-only permission prompt
2. User grants write-only access → Creates event in default calendar
3. User denies access → Throws `ETPermissionException`

#### Full access
1. First call to `retrieveCalendars()` → Shows full access permission dialog
2. User grants full access → Returns list of calendars
3. User denies access → Throws `ETPermissionException`

### Android
#### Without access
1. Call to `createEventThroughNativePlatform()` → Prompts user to choose their preferred calendar app to create the event into
2. No permissions required → event is created through selected calendar app

#### Full access
1. First call to `retrieveCalendars()` → Shows full access permission dialog
2. User grants full access → Returns list of calendars
3. User denies permission → Throws `ETPermissionException`


## ⚠️ Exception Handling

Eventide provides several custom exception types for better error handling. See [eventide_exception.dart](../lib/src/eventide_exception.dart)

### Example Usage

```dart
try {
  final calendar = await eventide.retrieveCalendars();

} on ETPermissionException catch (e) {
  print('Permission denied: ${e.message}');

} on ETGenericException catch (e) {
  print('Other error on eventide side: ${e.message}');

} catch (e) {
  print('Unexpected error: $e');
}
```
