import 'package:flutter/foundation.dart';

import 'package:eventide_platform_interface/src/attendance.dart';

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
/// [location] is the location of the event.
///
/// [reminders] is a list of [Duration] before the event.
///
/// [recurrenceRule] is the RRULE string describing the recurrence pattern of the event, if any.
///
/// [originalInstanceDate] is the original start time of this instance within a recurring series, if any.
final class ETEvent {
  final String id;
  final String title;
  final bool isAllDay;
  final DateTime startDate;
  final DateTime endDate;
  final String calendarId;
  final Iterable<Duration> reminders;
  final Iterable<ETAttendee> attendees;
  final String? description;
  final String? url;
  final String? location;
  final String? recurrenceRule;
  final DateTime? originalInstanceDate;

  @override
  int get hashCode => Object.hashAll([
    id,
    title,
    isAllDay,
    startDate,
    endDate,
    calendarId,
    ...reminders,
    ...attendees,
    description,
    url,
    location,
    recurrenceRule,
    originalInstanceDate,
  ]);

  const ETEvent({
    required this.id,
    required this.title,
    required this.isAllDay,
    required this.startDate,
    required this.endDate,
    required this.calendarId,
    this.reminders = const [],
    this.attendees = const [],
    this.description,
    this.url,
    this.location,
    this.recurrenceRule,
    this.originalInstanceDate,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other.runtimeType == runtimeType &&
          other is ETEvent &&
          other.id == id &&
          other.title == title &&
          other.isAllDay == isAllDay &&
          other.startDate == startDate &&
          other.endDate == endDate &&
          other.calendarId == calendarId &&
          listEquals(List.from(other.attendees), List.from(attendees)) &&
          listEquals(List.from(other.reminders), List.from(reminders)) &&
          other.description == description &&
          other.url == url &&
          other.location == location &&
          other.recurrenceRule == recurrenceRule &&
          other.originalInstanceDate == originalInstanceDate;
}

/// The scope of a delete or update operation on a recurring event instance.
enum ETSpan {
  /// Affects only this specific occurrence.
  thisEvent,

  /// Affects this occurrence and all future occurrences in the series.
  thisAndFuture,
}
