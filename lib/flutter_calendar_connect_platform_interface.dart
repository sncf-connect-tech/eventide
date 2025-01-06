import 'dart:ui';

import 'package:flutter_calendar_connect/flutter_calendar_connect.dart';
import 'package:flutter_calendar_connect/calendar_api.g.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

abstract class FlutterCalendarConnectPlatform extends PlatformInterface {
  FlutterCalendarConnectPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterCalendarConnectPlatform _instance = FlutterCalendarConnect();

  static FlutterCalendarConnectPlatform get instance => _instance;

  static set instance(FlutterCalendarConnectPlatform instance) {
    PlatformInterface.verify(instance, _token);
    _instance = instance;
  }

  Future<bool> requestCalendarPermission();

  Future<Calendar> createCalendar({
    required String title,
    required Color color,
  });
  
  Future<List<Calendar>> retrieveCalendars({
    required bool onlyWritableCalendars,
  });
  
  Future<void> deleteCalendar({
    required String calendarId,
  });
  
  Future<Event> createEvent({
    required String title,
    required DateTime startDate,
    required DateTime endDate,
    required String calendarId,
    String timeZone = 'UTC',
    String? description,
    String? url,
  });
  
  Future<List<Event>> retrieveEvents({
    required String calendarId,
    DateTime? startDate,
    DateTime? endDate,
  });
  
  Future<void> deleteEvent({
    required String eventId,
    required String calendarId,
  });
}