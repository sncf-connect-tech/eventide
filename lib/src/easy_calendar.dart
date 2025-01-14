import 'package:easy_calendar/src/easy_calendar_extensions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:easy_calendar/src/easy_calendar_exception.dart';
import 'package:easy_calendar/src/easy_calendar_platform_interface.dart';
import 'package:easy_calendar/src/calendar_api.g.dart';

class EasyCalendar extends EasyCalendarPlatform {
  final CalendarApi _calendarApi;

  EasyCalendar({
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
      throw e.toEasyCalendarException();
    }
  }

  /// Creates a new calendar with the given [title] and [color].
  /// 
  /// Returns the created [ECCalendar].
  /// 
  /// Throws a [FCCPermissionException] if the user refuses to grant calendar permissions.
  /// 
  /// Throws a [FCCNotFoundException] on iOS if not one callendar source has been found or if the created calendar id is not found.
  /// 
  /// Throws a [FCCGenericException] on iOS if the color hex cannot be converted to a UIColor.
  /// 
  /// Throws a [FCCGenericException] if any other error occurs during calendar creation.

  @override
  Future<ECCalendar> createCalendar({required String title, required Color color}) async {
    try {
      final calendar = await _calendarApi.createCalendar(title, color.toValue());
      return calendar.toECCalendar();

    } on PlatformException catch (e) {
      throw e.toEasyCalendarException();
    }
  }

  /// Retrieves a list of calendars.
  /// If [onlyWritableCalendars] is `true`, only writable calendars are returned.
  /// 
  /// Returns a list of [ECCalendar]s.
  /// 
  /// Throws a [FCCPermissionException] if the user refuses to grant calendar permissions.
  /// 
  /// Throws a [FCCGenericException] if any other error occurs during calendars retrieval.
  @override
  Future<List<ECCalendar>> retrieveCalendars({bool onlyWritableCalendars = true}) async {
    try {
      final calendars = await _calendarApi.retrieveCalendars(onlyWritableCalendars);
      return calendars.toECCalendarList();

    } on PlatformException catch (e) {
      throw e.toEasyCalendarException();
    }
  }

  /// Deletes the calendar with the given [calendarId].
  /// 
  /// Throws a [FCCPermissionException] if the user refuses to grant calendar permissions.
  /// 
  /// Throws a [FCCNotFoundException] if the calendar with the given [calendarId] is not found.
  /// 
  /// Throws a [FCCNotEditableException] if the calendar is not editable.
  /// 
  /// Throws a [FCCGenericException] if any other error occurs during calendar deletion.
  @override
  Future<void> deleteCalendar({required String calendarId}) async {
    try {
      await _calendarApi.deleteCalendar(calendarId);

    } on PlatformException catch (e) {
      throw e.toEasyCalendarException();
    }
  }

  /// Creates a new event with the given [title], [startDate], [endDate], and [calendarId].
  /// Optionally, you can provide a [description], [url], and a list of [reminders] duration.
  /// 
  /// /!\ Note that a [Duration] in seconds will not be supported by Android for API limitations.
  /// 
  /// Returns the created [Event].
  /// 
  /// Throws a [FCCPermissionException] if the user refuses to grant calendar permissions.
  /// 
  /// Throws a [FCCNotFoundException] if the calendar with the given [calendarId] is not found or if the created event id is not found.
  /// 
  /// Throws a [FCCGenericException] if any other error occurs during event creation.
  @override
  Future<ECEvent> createEvent({
    required String title,
    required DateTime startDate,
    required DateTime endDate,
    required String calendarId,
    String? description,
    String? url,
    List<Duration>? reminders,
  }) async {
    try {
      final event = await _calendarApi.createEvent(
        title: title,
        startDate: startDate.millisecondsSinceEpoch,
        endDate: endDate.millisecondsSinceEpoch,
        calendarId: calendarId,
        description: description, 
        url: url,
      );

      for (final durationBeforeEvent in reminders ?? <Duration>[]) {
        await _calendarApi.createReminder(durationBeforeEvent.toNativeDuration(), event.id);
      }

      return event.toECEvent().copyWithReminders(reminders);
      
    } on PlatformException catch (e) {
      throw e.toEasyCalendarException();
    }
  }

  /// Retrieves a list of events from the calendar with the given [calendarId].
  /// Optionally, you can provide a [startDate] and [endDate] to filter the events.
  /// 
  /// Returns a list of [Event]s.
  /// 
  /// Throws a [FCCPermissionException] if the user refuses to grant calendar permissions.
  /// 
  /// Throws a [FCCNotFoundException] if the calendar with the given [calendarId] is not found.
  /// 
  /// Throws a [FCCGenericException] if any other error occurs during events retrieval.
  @override
  Future<List<ECEvent>> retrieveEvents({required String calendarId, DateTime? startDate, DateTime? endDate}) async {
    try {
      final start = startDate ?? DateTime.now();
      final end = endDate ?? DateTime.now().add(const Duration(days: 7));
      final events = await _calendarApi.retrieveEvents(calendarId, start.millisecondsSinceEpoch, end.microsecondsSinceEpoch);
      return events.toECEventList();

    } on PlatformException catch (e) {
      throw e.toEasyCalendarException();
    }
  }

  /// Deletes the event with the given [eventId] from the calendar with the given [calendarId].
  /// 
  /// Throws a [FCCPermissionException] if the user refuses to grant calendar permissions.
  /// 
  /// Throws a [FCCNotFoundException] if the event with the given [eventId] is not found.
  /// 
  /// Throws a [FCCNotEditableException] if the calendar is not editable.
  /// 
  /// Throws a [FCCGenericException] if any other error occurs during event deletion.
  @override
  Future<void> deleteEvent({required String eventId, required String calendarId}) async {
    try {
      await _calendarApi.deleteEvent(eventId, calendarId);
    } on PlatformException catch (e) {
      throw e.toEasyCalendarException();
    }
  }

  /// Creates a new reminder with the given [durationBeforeEvent] for the event with the given [eventId].
  /// 
  /// /!\ Note that a [Duration] in seconds will not be supported by Android for API limitations.
  /// 
  /// Throws a [FCCPermissionException] if the user refuses to grant calendar permissions.
  /// 
  /// Throws a [FCCNotFoundException] if the event with the given [eventId] is not found.
  /// 
  /// Throws a [FCCGenericException] if any other error occurs during reminder creation.
  @override
  Future<ECEvent> createReminder({
    required Duration durationBeforeEvent,
    required String eventId,
  }) async {
    try {
      final updatedEvent = await _calendarApi.createReminder(durationBeforeEvent.toNativeDuration(), eventId);
      return updatedEvent.toECEvent();

    } on PlatformException catch (e) {
      throw e.toEasyCalendarException();
    }
  }

  /// Deletes the reminder with the given [durationBeforeEvent] for the event with the given [eventId].
  /// 
  /// Throws a [FCCPermissionException] if the user refuses to grant calendar permissions.
  /// 
  /// Throws a [FCCNotFoundException] if the event with the given [eventId] is not found.
  /// 
  /// Throws a [FCCGenericException] if any other error occurs during reminder deletion.
  @override
  Future<ECEvent> deleteReminder({
    required Duration durationBeforeEvent,
    required String eventId,
  }) async {
    try {
      final updatedEvent = await _calendarApi.deleteReminder(durationBeforeEvent.toNativeDuration(), eventId);
      return updatedEvent.toECEvent();
      
    } on PlatformException catch (e) {
      throw e.toEasyCalendarException();
    }
  }
}