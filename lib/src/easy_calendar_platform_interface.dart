import 'dart:ui';

import 'package:easy_calendar/src/easy_calendar.dart';
import 'package:easy_calendar/src/calendar_api.g.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

abstract class EasyCalendarPlatform extends PlatformInterface {
  EasyCalendarPlatform() : super(token: _token);

  static final Object _token = Object();

  static EasyCalendarPlatform _instance = EasyCalendar();

  static EasyCalendarPlatform get instance => _instance;

  static set instance(EasyCalendarPlatform instance) {
    PlatformInterface.verify(instance, _token);
    _instance = instance;
  }

  Future<bool> requestCalendarPermission();

  Future<Calendar> createCalendar({
    required String title,
    required Color color,
  });
  
  Future<List<Calendar>> retrieveCalendars({
    bool onlyWritableCalendars = true,
  });
  
  Future<void> deleteCalendar({
    required String calendarId,
  });
  
  Future<Event> createEvent({
    required String title,
    required DateTime startDate,
    required DateTime endDate,
    required String calendarId,
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

  Future<void> createReminder({
    required int minutes,
    required String eventId,
  });

  Future<List<int>> retrieveReminders({
    required String eventId,
  });

  Future<void> deleteReminder({
    required int minutes,
    required String eventId,
  });
}


extension EventCopy on Event {
  Event copyWith({
    String? id,
    String? title,
    int? startDate,
    int? endDate,
    String? calendarId,
    String? description,
    String? url,
    List<int>? reminders,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      calendarId: calendarId ?? this.calendarId,
      description: description ?? this.description,
      url: url ?? this.url,
      reminders: reminders ?? this.reminders,
    );
  }
}