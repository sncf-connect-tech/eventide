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

  Future<Calendar> createCalendar({required String title, required Color color});
  
  Future<bool> createOrUpdateEvent({required Event event});
  
  Future<List<Calendar>> retrieveCalendars({required bool onlyWritableCalendars});
}