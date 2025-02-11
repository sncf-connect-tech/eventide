import 'dart:ui';

import 'package:eventide/src/eventide.dart';
import 'package:equatable/equatable.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

abstract class EventidePlatform extends PlatformInterface {
  EventidePlatform() : super(token: _token);

  static final Object _token = Object();

  static EventidePlatform _instance = Eventide();

  static EventidePlatform get instance => _instance;

  static set instance(EventidePlatform instance) {
    PlatformInterface.verify(instance, _token);
    _instance = instance;
  }

  Future<bool> requestCalendarPermission();

  Future<ETCalendar> createCalendar({
    required String title,
    required Color color,
  });
  
  Future<List<ETCalendar>> retrieveCalendars({
    bool onlyWritableCalendars = true,
  });
  
  Future<void> deleteCalendar({
    required String calendarId,
  });
  
  Future<ETEvent> createEvent({
    required String calendarId,
    required String title,
    required DateTime startDate,
    required DateTime endDate,
    String? description,
    String? url,
  });
  
  Future<List<ETEvent>> retrieveEvents({
    required String calendarId,
    DateTime? startDate,
    DateTime? endDate,
  });
  
  Future<void> deleteEvent({
    required String eventId,
  });

  Future<ETEvent> createReminder({
    required Duration durationBeforeEvent,
    required String eventId,
  });

  Future<ETEvent> deleteReminder({
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
final class ETCalendar extends Equatable {
  final String id;
  final String title;
  final Color color;
  final bool isWritable;
  final String sourceName;

  @override
  List<Object?> get props => [id, title, color, isWritable, sourceName];

  const ETCalendar({
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
final class ETEvent extends Equatable {
  final String id;
  final String title;
  final bool isAllDay;
  final DateTime startDate;
  final DateTime endDate;
  final String calendarId;
  final String? description;
  final String? url;
  final List<Duration>? reminders;

  @override
  List<Object?> get props => [id, title, isAllDay, startDate, endDate, calendarId, description, url, reminders];

  const ETEvent({
    required this.id,
    required this.title,
    required this.isAllDay,
    required this.startDate,
    required this.endDate,
    required this.calendarId,
    this.description,
    this.url,
    this.reminders,
  });
}