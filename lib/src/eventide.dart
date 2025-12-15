import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:eventide/src/calendar_api.g.dart';
import 'package:eventide/src/eventide_exception.dart';
import 'package:eventide/src/eventide_platform_interface.dart';
import 'package:eventide/src/extensions/account_extensions.dart';
import 'package:eventide/src/extensions/attendee_extensions.dart';
import 'package:eventide/src/extensions/calendar_extensions.dart';
import 'package:eventide/src/extensions/color_extensions.dart';
import 'package:eventide/src/extensions/duration_extensions.dart';
import 'package:eventide/src/extensions/event_extensions.dart';

class Eventide extends EventidePlatform {
  final CalendarApi _calendarApi;

  Eventide({
    @visibleForTesting CalendarApi? calendarApi,
  }) : _calendarApi = calendarApi ?? CalendarApi();

  /// Creates a new calendar with the given [title], [color] and optional [accountName].
  ///
  /// If [account] is provided, the calendar will be created under that account.
  /// If [account] is null, the calendar will be created in the default account/source:
  /// - On iOS: Uses default source (local or iCloud)
  /// - On Android: Uses "LocalCalendar" as the account name
  ///
  /// Returns the created [ETCalendar].
  ///
  /// Throws a [ETPermissionException] if the user refuses to grant calendar permissions.
  ///
  /// Throws a [ETNotFoundException] on iOS if no suitable calendar source is found or if the created calendar id is not found.
  ///
  /// Throws a [ETGenericException] on iOS if the color hex cannot be converted to a UIColor.
  ///
  /// Throws a [ETGenericException] if any other error occurs during calendar creation.

  @override
  Future<ETCalendar> createCalendar({
    required String title,
    required Color color,
    ETAccount? account,
  }) async {
    try {
      final calendar = await _calendarApi.createCalendar(
        title: title,
        color: color.toValue(),
        account: account?.toAccount(),
      );
      return calendar.toETCalendar();
    } on PlatformException catch (e) {
      throw e.toETException();
    }
  }

  /// Retrieves a list of calendars.
  /// If [onlyWritableCalendars] is `true`, only writable calendars are returned.
  ///
  /// If [account] is provided, only calendars from that account are returned.
  ///
  /// Returns a list of [ETCalendar]s.
  ///
  /// Throws a [ETPermissionException] if the user refuses to grant calendar permissions.
  ///
  /// Throws a [ETGenericException] if any other error occurs during calendars retrieval.
  @override
  Future<List<ETCalendar>> retrieveCalendars({
    bool onlyWritableCalendars = true,
    ETAccount? account,
  }) async {
    try {
      final calendars = await _calendarApi.retrieveCalendars(
        onlyWritableCalendars: onlyWritableCalendars,
        account: account?.toAccount(),
      );
      return calendars.toETCalendarList();
    } on PlatformException catch (e) {
      throw e.toETException();
    }
  }

  /// Retrieves all available accounts from the device.
  ///
  /// Returns a list of [ETAccount] representing all accounts that have calendars.
  /// This includes Google accounts, local accounts, Exchange accounts, etc.
  ///
  /// Throws a [ETPermissionException] if the user refuses to grant calendar permissions.
  ///
  /// Throws a [ETGenericException] if any other error occurs during accounts retrieval.
  @override
  Future<List<ETAccount>> retrieveAccounts() async {
    try {
      final accounts = await _calendarApi.retrieveAccounts();
      return accounts.toETAccountList();
    } on PlatformException catch (e) {
      throw e.toETException();
    }
  }

  /// Deletes the calendar with the given [calendarId].
  ///
  /// Throws a [ETPermissionException] if the user refuses to grant calendar permissions.
  ///
  /// Throws a [ETNotFoundException] if the calendar with the given [calendarId] is not found.
  ///
  /// Throws a [ETNotEditableException] if the calendar is not editable.
  ///
  /// Throws a [ETGenericException] if any other error occurs during calendar deletion.
  @override
  Future<void> deleteCalendar({
    required String calendarId,
  }) async {
    try {
      await _calendarApi.deleteCalendar(calendarId: calendarId);
    } on PlatformException catch (e) {
      throw e.toETException();
    }
  }

  /// Creates a new event with the given [title], [startDate], [endDate], and [calendarId].
  /// Optionally, you can provide a [description], [url], [location], and a list of [reminders] duration.
  ///
  /// /!\ Note that a [Duration] in seconds will not be supported by Android for API limitations.
  ///
  /// Returns the created [Event].
  ///
  /// Throws a [ETPermissionException] if the user refuses to grant calendar permissions.
  ///
  /// Throws a [ETNotFoundException] if the calendar with the given [calendarId] is not found or if the created event id is not found.
  ///
  /// Throws a [ETGenericException] if any other error occurs during event creation.
  @override
  Future<ETEvent> createEvent({
    required String calendarId,
    required String title,
    required DateTime startDate,
    required DateTime endDate,
    bool isAllDay = false,
    String? description,
    String? url,
    String? location,
    List<Duration>? reminders,
  }) async {
    try {
      final event = await _calendarApi.createEvent(
        calendarId: calendarId,
        title: title,
        startDate: startDate.toUtc().millisecondsSinceEpoch,
        endDate: endDate.toUtc().millisecondsSinceEpoch,
        isAllDay: isAllDay,
        description: description,
        url: url,
        location: location,
        reminders: reminders?.map((e) => e.toNativeDuration()).toList(),
      );

      return event.toETEvent().copyWithReminders(reminders);
    } on PlatformException catch (e) {
      throw e.toETException();
    }
  }

  /// Creates a new event in the default calendar with the given [title], [startDate], [endDate].
  /// Optionally, you can provide a [description], [url], [location], and a list of [reminders] duration.
  ///
  /// On iOS, this method will prompt user for write only permission and will insert your event in user's default calendar.
  ///
  /// / /!\ Note that a [Duration] in seconds will not be supported by Android for API limitations.
  ///
  /// Returns the created [ETEvent].
  ///
  /// Throws a [ETPermissionException] if the user refuses to grant calendar permissions.
  ///
  /// Throws a [ETNotFoundException] if the default calendar is not found or if the created event id is not found.
  ///
  /// Throws a [ETGenericException] if any other error occurs during event creation.
  ///
  /// Not that this is a fire and forget method on Android. It will not wait the event creation to be done to return, so nothing will happen after this method call.
  /// It is the same Android native implementation as [createEventThroughNativePlatform].
  @override
  Future<void> createEventInDefaultCalendar({
    required String title,
    required DateTime startDate,
    required DateTime endDate,
    bool isAllDay = false,
    String? description,
    String? url,
    String? location,
    List<Duration>? reminders,
  }) async {
    try {
      await _calendarApi.createEventInDefaultCalendar(
        title: title,
        startDate: startDate.toUtc().millisecondsSinceEpoch,
        endDate: endDate.toUtc().millisecondsSinceEpoch,
        isAllDay: isAllDay,
        description: description,
        url: url,
        location: location,
        reminders: reminders?.map((e) => e.toNativeDuration()).toList(),
      );
    } on PlatformException catch (e) {
      throw e.toETException();
    }
  }

  /// Creates a new event through the native platform's event creation UI with optional [title], [startDate], [endDate], [description], [url], [location], and a list of [reminders] duration.
  ///
  /// /!\ Note that a [Duration] in seconds will not be supported by Android for API limitations.
  ///
  /// This method does not guarantee that an event will be created, as the user may cancel the operation.
  /// If the user creates an event, it will be added to the selected calendar.
  /// If the user cancels the operation, no event will be created.
  ///
  /// Throws a [ETPresentationException] if there is an error presenting the native event creation UI.
  ///
  /// Throws a [ETUserCanceledException] if the user cancels the event creation.
  ///
  /// Throws a [ETEventDeletedException] if the event is deleted during the creation
  ///
  /// Throws a [ETGenericException] if any other error occurs during event creation.
  ///
  /// Not that this is a fire and forget method on Android. It will not wait the event creation to be done to return, so nothing will happen after this method call.
  /// It is the same Android native implementation as [createEventInDefaultCalendar].
  @override
  Future<void> createEventThroughNativePlatform({
    String? title,
    DateTime? startDate,
    DateTime? endDate,
    bool? isAllDay,
    String? description,
    String? url,
    String? location,
    List<Duration>? reminders,
  }) async {
    try {
      await _calendarApi.createEventThroughNativePlatform(
        title: title,
        startDate: startDate?.toUtc().millisecondsSinceEpoch,
        endDate: endDate?.toUtc().millisecondsSinceEpoch,
        isAllDay: isAllDay,
        description: description,
        url: url,
        location: location,
        reminders: reminders?.map((e) => e.toNativeDuration()).toList(),
      );
    } on PlatformException catch (e) {
      throw e.toETException();
    }
  }

  /// Retrieves a list of events from the calendar with the given [calendarId].
  /// Optionally, you can provide a [startDate] and [endDate] to filter the events.
  ///
  /// Returns a list of [Event]s.
  ///
  /// Throws a [ETPermissionException] if the user refuses to grant calendar permissions.
  ///
  /// Throws a [ETNotFoundException] if the calendar with the given [calendarId] is not found.
  ///
  /// Throws a [ETGenericException] if any other error occurs during events retrieval.
  @override
  Future<List<ETEvent>> retrieveEvents({
    required String calendarId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final start = (startDate ?? DateTime.now()).toUtc();
      final end = (endDate ?? DateTime.now()).toUtc();
      final events = await _calendarApi.retrieveEvents(
        calendarId: calendarId,
        startDate: start.millisecondsSinceEpoch,
        endDate: end.millisecondsSinceEpoch,
      );
      return events.toETEventList();
    } on PlatformException catch (e) {
      throw e.toETException();
    }
  }

  /// Deletes the event with the given [eventId] from the calendar with the given [calendarId].
  ///
  /// Throws a [ETPermissionException] if the user refuses to grant calendar permissions.
  ///
  /// Throws a [ETNotFoundException] if the event with the given [eventId] is not found.
  ///
  /// Throws a [ETNotEditableException] if the calendar is not editable.
  ///
  /// Throws a [ETGenericException] if any other error occurs during event deletion.
  @override
  Future<void> deleteEvent({
    required String eventId,
  }) async {
    try {
      await _calendarApi.deleteEvent(eventId: eventId);
    } on PlatformException catch (e) {
      throw e.toETException();
    }
  }

  /// Creates a new reminder with the given [durationBeforeEvent] for the event with the given [eventId].
  ///
  /// /!\ Note that a [Duration] in seconds will not be supported by Android for API limitations.
  ///
  /// Throws a [ETPermissionException] if the user refuses to grant calendar permissions.
  ///
  /// Throws a [ETNotFoundException] if the event with the given [eventId] is not found.
  ///
  /// Throws a [ETGenericException] if any other error occurs during reminder creation.
  @override
  Future<ETEvent> createReminder({
    required String eventId,
    required Duration durationBeforeEvent,
  }) async {
    try {
      final updatedEvent = await _calendarApi.createReminder(
        reminder: durationBeforeEvent.toNativeDuration(),
        eventId: eventId,
      );
      return updatedEvent.toETEvent();
    } on PlatformException catch (e) {
      throw e.toETException();
    }
  }

  /// Deletes the reminder with the given [durationBeforeEvent] for the event with the given [eventId].
  ///
  /// Throws a [ETPermissionException] if the user refuses to grant calendar permissions.
  ///
  /// Throws a [ETNotFoundException] if the event with the given [eventId] is not found.
  ///
  /// Throws a [ETGenericException] if any other error occurs during reminder deletion.
  @override
  Future<ETEvent> deleteReminder({
    required String eventId,
    required Duration durationBeforeEvent,
  }) async {
    try {
      final updatedEvent = await _calendarApi.deleteReminder(
        reminder: durationBeforeEvent.toNativeDuration(),
        eventId: eventId,
      );
      return updatedEvent.toETEvent();
    } on PlatformException catch (e) {
      throw e.toETException();
    }
  }

  /// Creates a new attendee with the given [name], [email], and [type] for the event with the given [eventId].
  ///
  /// Throws a [ETNotSupportedByPlatform] if the method is called on iOS. Make sure you handle it.
  ///
  /// Throws a [ETPermissionException] if the user refuses to grant calendar permissions.
  ///
  /// Throws a [ETNotFoundException] if the event with the given [eventId] is not found.
  ///
  /// Throws a [ETGenericException] if any other error occurs during attendee creation.
  @override
  Future<ETEvent> createAttendee({
    required String eventId,
    required String name,
    required String email,
    required ETAttendeeType type,
  }) async {
    try {
      final event = await _calendarApi.createAttendee(
        eventId: eventId,
        name: name,
        email: email,
        role: type.nativeRole,
        type: type.nativeType,
      );
      return event.toETEvent();
    } on PlatformException catch (e) {
      throw e.toETException();
    }
  }

  /// Deletes the attendee with the given [attendee] for the event with the given [eventId].
  ///
  /// Throws a [ETNotSupportedByPlatform] if the method is called on iOS. Make sure you handle it.
  ///
  /// Throws a [ETPermissionException] if the user refuses to grant calendar permissions.
  ///
  /// Throws a [ETNotFoundException] if the event with the given [eventId] is not found.
  ///
  /// Throws a [ETGenericException] if any other error occurs during attendee deletion.
  @override
  Future<ETEvent> deleteAttendee({
    required String eventId,
    required ETAttendee attendee,
  }) async {
    try {
      final event = await _calendarApi.deleteAttendee(eventId: eventId, email: attendee.email);
      return event.toETEvent();
    } on PlatformException catch (e) {
      throw e.toETException();
    }
  }
}
