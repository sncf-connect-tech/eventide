import 'dart:ui';

import 'package:easy_calendar/src/easy_calendar.dart';
import 'package:equatable/equatable.dart';
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

  Future<ECCalendar> createCalendar({
    required String title,
    required Color color,
  });
  
  Future<List<ECCalendar>> retrieveCalendars({
    bool onlyWritableCalendars = true,
  });
  
  Future<void> deleteCalendar({
    required String calendarId,
  });
  
  Future<ECEvent> createEvent({
    required String title,
    required DateTime startDate,
    required DateTime endDate,
    required String calendarId,
    String? description,
    String? url,
    List<Duration>? reminders,
  });
  
  Future<List<ECEvent>> retrieveEvents({
    required String calendarId,
    DateTime? startDate,
    DateTime? endDate,
  });
  
  Future<void> deleteEvent({
    required String eventId,
    required String calendarId,
  });

  Future<ECEvent> createReminder({
    required Duration durationBeforeEvent,
    required String eventId,
  });

  Future<ECEvent> deleteReminder({
    required Duration durationBeforeEvent,
    required String eventId,
  });
}

/// Represents a calendar.
/// 
/// [id] is a unique identifier for the calendar.
/// 
/// [title] is the title of the calendar.
/// 
/// [color] is the color of the calendar.
/// 
/// [isWritable] is a boolean to indicate if the calendar is writable.
/// 
/// [sourceName] is the name of the source of the calendar.
final class ECCalendar extends Equatable {
  final String id;
  final String title;
  final int color;
  final bool isWritable;
  final String sourceName;

  @override
  List<Object?> get props => [id, title, color, isWritable, sourceName];

  const ECCalendar({
    required this.id,
    required this.title,
    required this.color,
    required this.isWritable,
    required this.sourceName,
  });
}

/// Represents an event.
/// 
/// [id] is a unique identifier for the event.
/// 
/// [title] is the title of the event.
/// 
/// [startDate] is the start date of the event in milliseconds since epoch.
/// 
/// [endDate] is the end date of the event in milliseconds since epoch.
/// 
/// [calendarId] is the id of the calendar that the event belongs to.
/// 
/// [description] is the description of the event.
/// 
/// [url] is the url of the event.  
/// 
/// [reminders] is a list of [Duration] before the event.
final class ECEvent extends Equatable {
  final String id;
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final String calendarId;
  final String? description;
  final String? url;
  final List<Duration>? reminders;

  @override
  List<Object?> get props => [id, title, startDate, endDate, calendarId, description, url, reminders];

  const ECEvent({
    required this.id,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.calendarId,
    this.description,
    this.url,
    this.reminders,
  });
}