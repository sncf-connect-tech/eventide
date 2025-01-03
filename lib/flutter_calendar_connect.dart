import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_calendar_connect/flutter_calendar_connect_platform_interface.dart';
import 'package:flutter_calendar_connect/calendar_api.g.dart';

class FlutterCalendarConnect extends FlutterCalendarConnectPlatform {
  final CalendarApi _calendarApi;

  FlutterCalendarConnect({
    @visibleForTesting CalendarApi? calendarApi,
  }) : _calendarApi = calendarApi ?? CalendarApi();

  @override
  Future<bool> requestCalendarPermission() async {
    return await _calendarApi.requestCalendarPermission();
  }

  @override
  Future<Calendar> createCalendar({required String title, required Color color}) async {
    return await _calendarApi.createCalendar(title, color.value);
  }

  @override
  Future<List<Calendar>> retrieveCalendars({required bool onlyWritableCalendars}) async {
    return await _calendarApi.retrieveCalendars(onlyWritableCalendars);
  }

  @override
  Future<void> deleteCalendar({required String calendarId}) async {
    await _calendarApi.deleteCalendar(calendarId);
  }

  @override
  Future<Event> createEvent({
    required String title,
    required DateTime startDate,
    required DateTime endDate,
    required String calendarId,
    String timeZone = 'UTC',
    String? description,
    String? url,
    List<Alarm>? alarms,
  }) async {
    return await _calendarApi.createEvent(
      title: title,
      startDate: startDate.millisecondsSinceEpoch,
      endDate: endDate.millisecondsSinceEpoch,
      calendarId: calendarId,
      timeZone: timeZone, 
      description: description, 
      url: url, 
      alarms: alarms,
    );
  }

  @override
  Future<List<Event>> retrieveEvents({required String calendarId, DateTime? startDate, DateTime? endDate}) async {
    final start = startDate ?? DateTime.now();
    final end = endDate ?? DateTime.now().add(const Duration(days: 7));
    
    return await _calendarApi.retrieveEvents(calendarId, start.millisecondsSinceEpoch, end.microsecondsSinceEpoch);
  }

  @override
  Future<void> deleteEvent({required String eventId, required String calendarId}) async {
    await _calendarApi.deleteEvent(eventId, calendarId);
  }
}