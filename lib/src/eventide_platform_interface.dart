import 'dart:ui';

import 'package:eventide/src/eventide.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
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
    ETAccount? account,
  });

  Future<List<ETCalendar>> retrieveCalendars({
    bool onlyWritableCalendars = true,
    ETAccount? fromAccount,
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
    List<Duration>? reminders,
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
  final ETAccount account;

  @override
  List<Object?> get props => [id, title, color, isWritable, account];

  const ETCalendar({
    required this.id,
    required this.title,
    required this.color,
    required this.isWritable,
    required this.account,
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
  List<Object?> get props => [
        id,
        title,
        isAllDay,
        startDate,
        endDate,
        calendarId,
        description,
        url,
        reminders
      ];

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

/// Represents an account.
///
/// [name] is the name of the account. It corresponds to CalendarContract.Calendars.ACCOUNT_NAME on Android and EKSource.sourceIdentifier on iOS.
///
/// [type] is the type of the account. It corresponds to CalendarContract.Calendars.ACCOUNT_TYPE on Android and EKSource.sourceType on iOS.
///
/// This class is used to represent the account that the calendar belongs to.
///
/// For example, if the calendar belongs to a Google account, the account name will be the email address of the Google account.
final class ETAccount extends Equatable {
  final String name;
  final String type;

  @override
  List<Object?> get props => [name, type];

  const ETAccount({
    required this.name,
    required this.type,
  });
}
