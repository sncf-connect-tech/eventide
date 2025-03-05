import 'package:eventide/src/eventide_extensions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:eventide/src/eventide_exception.dart';
import 'package:eventide/src/eventide_platform_interface.dart';
import 'package:eventide/src/calendar_api.g.dart';

class Eventide extends EventidePlatform {
  final CalendarApi _calendarApi;

  Eventide({
    @visibleForTesting CalendarApi? calendarApi,
  }) : _calendarApi = calendarApi ?? CalendarApi();

  /// Requests permission to access the calendar.
  ///
  /// This method call is only necessary if you want to ask for permission early at runtime,
  /// as the plugin will automatically request permission when needed.
  ///
  /// Returns `true` if permission is granted, `false` otherwise.
  @override
  Future<bool> requestCalendarPermission() async {
    try {
      return await _calendarApi.requestCalendarPermission();
    } on PlatformException catch (e) {
      throw e.toETException();
    }
  }

  /// Creates a new calendar with the given [title], [color] and [accountName].
  ///
  /// Note that [accountName] is an Android feature. It will be ignored on iOS.
  ///
  /// Returns the created [ETCalendar].
  ///
  /// Throws a [ETPermissionException] if the user refuses to grant calendar permissions.
  ///
  /// Throws a [ETNotFoundException] on iOS if not one callendar source has been found or if the created calendar id is not found.
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
  /// Returns a list of [ETCalendar]s.
  ///
  /// Throws a [ETPermissionException] if the user refuses to grant calendar permissions.
  ///
  /// Throws a [ETGenericException] if any other error occurs during calendars retrieval.
  @override
  Future<List<ETCalendar>> retrieveCalendars({
    bool onlyWritableCalendars = true,
    ETAccount? fromAccount,
  }) async {
    try {
      final calendars = await _calendarApi.retrieveCalendars(
        onlyWritableCalendars: onlyWritableCalendars,
        from: fromAccount?.toAccount(),
      );
      return calendars.toETCalendarList();
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
  /// Optionally, you can provide a [description], [url], and a list of [reminders] duration.
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
    List<Duration>? reminders,
  }) async {
    try {
      final event = await _calendarApi.createEvent(
        title: title,
        startDate: startDate.millisecondsSinceEpoch,
        endDate: endDate.millisecondsSinceEpoch,
        isAllDay: isAllDay,
        calendarId: calendarId,
        description: description,
        url: url,
      );

      if (reminders != null) {
        for (final reminder in reminders) {
          await _calendarApi.createReminder(
            reminder: reminder.toNativeDuration(),
            eventId: event.id,
          );
        }
      }

      return event.toETEvent().copyWithReminders(reminders);
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
      final start = startDate ?? DateTime.now();
      final end = endDate ?? DateTime.now().add(const Duration(days: 7));
      final events = await _calendarApi.retrieveEvents(
        calendarId: calendarId,
        startDate: start.millisecondsSinceEpoch,
        endDate: end.microsecondsSinceEpoch,
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
    required Duration durationBeforeEvent,
    required String eventId,
  }) async {
    try {
      final updatedEvent = await _calendarApi.createReminder(
          reminder: durationBeforeEvent.toNativeDuration(), eventId: eventId);
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
    required Duration durationBeforeEvent,
    required String eventId,
  }) async {
    try {
      final updatedEvent = await _calendarApi.deleteReminder(
          reminder: durationBeforeEvent.toNativeDuration(), eventId: eventId);
      return updatedEvent.toETEvent();
    } on PlatformException catch (e) {
      throw e.toETException();
    }
  }
}
