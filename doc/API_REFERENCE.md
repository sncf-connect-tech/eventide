# API Reference

Detailed documentation for all Eventide API methods.

## Table of Contents
- [Accounts](#accounts)
  - [retrieveAccounts](#retrieve-accounts)
- [Calendars](#calendars)
  - [createCalendar](#create-calendar)
  - [retrieveCalendars](#retrieve-calendars)
  - [updateCalendar](#update-calendar)
  - [deleteCalendar](#delete-calendar)
- [Events](#events)
  - [createEvent](#create-event)
  - [createEventInDefaultCalendar](#create-event-in-default-calendar)
  - [createEventThroughNativePlatform](#create-event-through-native-platform)
  - [retrieveEvents](#retrieve-events)
  - [updateEvent](#update-event)
  - [deleteEvent](#delete-event)
  - [Recurring events](#recurring-events)
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

> On iOS, the default source is used if no account is specified (for example, local or iCloud).

> On Android, a default local account will be used if no account is specified.

### Retrieve Calendars

```dart
Future<Iterable<ETCalendar>> retrieveCalendars({
  bool onlyWritableCalendars = true,
  ETAccount? account,
})
```

Retrieves a list of calendars, optionally filtered by account and calendar writability.

### Update Calendar

```dart
Future<ETCalendar> updateCalendar(
  ETCalendar calendar, {
  String? title,
  Color? color,
})
```

Updates an existing calendar. Only the provided optional parameters will be updated; the others remain unchanged.

Throws an ETPermissionException if the user refuses to grant calendar permissions.

Throws an ETNotFoundException if the calendar is not found.

Throws an ETNotEditableException if the calendar is not editable.

Throws an ETGenericException if any other error occurs.

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
  String? recurrenceRule,
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
  String? recurrenceRule,
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
  String? recurrenceRule,
})
```

Creates a new event using the native platform UI. This method does not require any permission on both iOS and Android.

> On iOS, this method will open a prefilled native modal to let the user create the event.

> On Android, both `createEventInDefaultCalendar()` and `createEventThroughNativePlatform()` share a prefilled `.ics` file so the user can choose a compatible calendar app.

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

### Update Event

```dart
Future<ETEvent> updateEvent(
  ETEvent event, {
  String? calendarId,
  String? title,
  DateTime? startDate,
  DateTime? endDate,
  bool? isAllDay,
  String? description,
  String? url,
  String? location,
  Iterable<Duration>? reminders,
  String? recurrenceRule,
  ETSpan span = ETSpan.thisEvent,
  DateTime? originalInstanceDate,
})
```

Updates an existing event. Only the provided optional parameters will be updated; the others remain unchanged.

> ⚠️ **Note:** A `Duration` in seconds will not be supported by Android due to API limitations.

Throws an ETPermissionException if the user refuses to grant calendar permissions.

Throws an ETNotFoundException if the event or the target calendar is not found.

Throws an ETNotEditableException if the calendar is not editable.

Throws an ETGenericException if any other error occurs.

### Delete Event

```dart
Future<void> deleteEvent({
  required String eventId,
  ETSpan span = ETSpan.thisEvent,
  DateTime? originalInstanceDate,
})
```

### Recurring events

Use `recurrenceRule` to supply an iCalendar RRULE, for example `FREQ=WEEKLY;BYDAY=MO`. When using the native event creation flow, the receiving calendar app controls how it handles the prefilled rule.

To target an occurrence of a recurring event, pass its `ETEvent.originalInstanceDate` along with the event ID. This is the occurrence's original start, which can differ from its current `startDate` if the occurrence was moved. `updateEvent` uses the event's `originalInstanceDate` when no override is supplied. For ID-based operations, pass the date explicitly when targeting an occurrence.

| Scope | Effect |
| --- | --- |
| `ETSpan.thisEvent` (default) | Changes only the selected occurrence when its original date is supplied. |
| `ETSpan.thisAndFuture` | Changes the selected occurrence and later occurrences in the series. |

For example, to delete a single occurrence loaded with `retrieveEvents`:

```dart
final originalDate = event.originalInstanceDate;
if (originalDate != null) {
  await eventide.deleteEvent(
    eventId: event.id,
    originalInstanceDate: originalDate,
  );
}
```

---

## Reminders

⚠️ **Platform Limitation:** Android reminders unit is in minutes. Therefore a [Duration] in seconds will only be supported on iOS.

### Create Reminder

```dart
Future<ETEvent> createReminder({
  required String eventId,
  required Duration durationBeforeEvent,
  ETSpan span = ETSpan.thisEvent,
  DateTime? originalInstanceDate,
})
```

### Delete Reminder

```dart
Future<ETEvent> deleteReminder({
  required String eventId,
  required Duration durationBeforeEvent,
  ETSpan span = ETSpan.thisEvent,
  DateTime? originalInstanceDate,
})
```

---

## Attendees

Attendees can be read on both iOS and Android. Adding or removing attendees is supported only on Android; those calls throw `ETNotSupportedByPlatform` on iOS.

### Create Attendee

```dart
Future<ETEvent> createAttendee({
  required String eventId,
  required String name,
  required String email,
  required ETAttendeeType type,
  ETSpan span = ETSpan.thisEvent,
  DateTime? originalInstanceDate,
})
```

### Delete Attendee

```dart
Future<ETEvent> deleteAttendee({
  required String eventId,
  required ETAttendee attendee,
  ETSpan span = ETSpan.thisEvent,
  DateTime? originalInstanceDate,
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

Eventide provides typed exceptions for permission, availability, and operation failures. See [the shared exception definitions](../packages/eventide_platform_interface/lib/src/exceptions.dart).

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
