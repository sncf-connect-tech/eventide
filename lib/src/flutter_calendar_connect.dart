import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_calendar_connect/src/flutter_calendar_connect_exception.dart';
import 'package:flutter_calendar_connect/src/flutter_calendar_connect_platform_interface.dart';
import 'package:flutter_calendar_connect/src/calendar_api.g.dart';

class FlutterCalendarConnect extends FlutterCalendarConnectPlatform {
  final CalendarApi _calendarApi;

  FlutterCalendarConnect({
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
      throw e.toFlutterCalendarConnectException();
    }
  }

  /// Creates a new calendar with the given [title] and [color].
  /// 
  /// Returns the created [Calendar].
  /// 
  /// Throws a [FCCPermissionException] if the user refuses to grant calendar permissions.
  /// 
  /// Throws a [FCCNotFoundException] on iOS if not one callendar source has been found or if the created calendar id is not found.
  /// 
  /// Throws a [FCCGenericException] on iOS if the color hex cannot be converted to a UIColor.
  /// 
  /// Throws a [FCCGenericException] if any other error occurs during calendar creation.

  @override
  Future<Calendar> createCalendar({required String title, required Color color}) async {
    try {
      return await _calendarApi.createCalendar(title, color.value);
    } on PlatformException catch (e) {
      throw e.toFlutterCalendarConnectException();
    }
  }

  /// Retrieves a list of calendars.
  /// If [onlyWritableCalendars] is `true`, only writable calendars are returned.
  /// 
  /// Returns a list of [Calendar]s.
  /// 
  /// Throws a [FCCPermissionException] if the user refuses to grant calendar permissions.
  /// 
  /// Throws a [FCCGenericException] if any other error occurs during calendars retrieval.
  @override
  Future<List<Calendar>> retrieveCalendars({required bool onlyWritableCalendars}) async {
    try {
      return await _calendarApi.retrieveCalendars(onlyWritableCalendars);
    } on PlatformException catch (e) {
      throw e.toFlutterCalendarConnectException();
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
      throw e.toFlutterCalendarConnectException();
    }
  }

  /// Creates a new event with the given [title], [startDate], [endDate], and [calendarId].
  /// Optionally, you can provide a [description], [url], and a list of [reminders] in minutes.
  /// 
  /// Returns the created [Event].
  /// 
  /// Throws a [FCCPermissionException] if the user refuses to grant calendar permissions.
  /// 
  /// Throws a [FCCNotFoundException] if the calendar with the given [calendarId] is not found or if the created event id is not found.
  /// 
  /// Throws a [FCCGenericException] if any other error occurs during event creation.
  @override
  Future<Event> createEvent({
    required String title,
    required DateTime startDate,
    required DateTime endDate,
    required String calendarId,
    String? description,
    String? url,
    List<int>? reminders,
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

      for (final minutes in reminders ?? []) {
        await _calendarApi.createReminder(minutes, event.id);
      }

      return event.copyWith(reminders: reminders);
      
    } on PlatformException catch (e) {
      throw e.toFlutterCalendarConnectException();
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
  Future<List<Event>> retrieveEvents({required String calendarId, DateTime? startDate, DateTime? endDate}) async {
    try {
      final start = startDate ?? DateTime.now();
      final end = endDate ?? DateTime.now().add(const Duration(days: 7));
      
      final events = await _calendarApi.retrieveEvents(calendarId, start.millisecondsSinceEpoch, end.microsecondsSinceEpoch);

      final fcEvents = <Event>[];
      for (final event in events) {
        fcEvents.add(event.copyWith(
          reminders: await _calendarApi.retrieveReminders(event.id),
        ));
      }
      return fcEvents;
    } on PlatformException catch (e) {
      throw e.toFlutterCalendarConnectException();
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
      throw e.toFlutterCalendarConnectException();
    }
  }

  /// Creates a new reminder with the given [minutes] for the event with the given [eventId].
  /// 
  /// Throws a [FCCPermissionException] if the user refuses to grant calendar permissions.
  /// 
  /// Throws a [FCCNotFoundException] if the event with the given [eventId] is not found.
  /// 
  /// Throws a [FCCGenericException] if any other error occurs during reminder creation.
  @override
  Future<void> createReminder({required int minutes, required String eventId}) async {
    try {
      await _calendarApi.createReminder(minutes, eventId);
    } on PlatformException catch (e) {
      throw e.toFlutterCalendarConnectException();
    }
  }

  /// Retrieves a list of reminders for the event with the given [eventId].
  /// 
  /// Returns a list of [int]s representing the minutes of each reminder.
  /// 
  /// Throws a [FCCPermissionException] if the user refuses to grant calendar permissions.
  /// 
  /// Throws a [FCCNotFoundException] if the event with the given [eventId] is not found.
  /// 
  /// Throws a [FCCGenericException] if any other error occurs during reminders retrieval.
  @override
  Future<List<int>> retrieveReminders({required String eventId}) async {
    try {
      return await _calendarApi.retrieveReminders(eventId);
    } on PlatformException catch (e) {
      throw e.toFlutterCalendarConnectException();
    }
  }

  /// Deletes the reminder with the given [minutes] for the event with the given [eventId].
  /// 
  /// Throws a [FCCPermissionException] if the user refuses to grant calendar permissions.
  /// 
  /// Throws a [FCCNotFoundException] if the event with the given [eventId] is not found.
  /// 
  /// Throws a [FCCGenericException] if any other error occurs during reminder deletion.
  @override
  Future<void> deleteReminder({required int minutes, required String eventId}) async {
    try {
      await _calendarApi.deleteReminder(minutes, eventId);
    } on PlatformException catch (e) {
      throw e.toFlutterCalendarConnectException();
    }
  }
}