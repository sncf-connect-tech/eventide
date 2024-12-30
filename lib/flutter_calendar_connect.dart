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
  Future<Calendar> createCalendar({required String title, required Color color}) async {
    return await _calendarApi.createCalendar(title, color.value);
  }

  @override
  Future<bool> createOrUpdateEvent({required Event event}) async {
    return await _calendarApi.createOrUpdateEvent(event);
  }

  @override
  Future<List<Calendar>> retrieveCalendars({required bool onlyWritableCalendars}) async {
    return await _calendarApi.retrieveCalendars(onlyWritableCalendars);
  }
}