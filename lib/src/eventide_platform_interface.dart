import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:eventide/src/eventide.dart';

abstract class EventidePlatform extends PlatformInterface {
  EventidePlatform() : super(token: _token);

  static final Object _token = Object();

  static EventidePlatform _instance = Eventide();

  static EventidePlatform get instance => _instance;

  static set instance(EventidePlatform instance) {
    PlatformInterface.verify(instance, _token);
    _instance = instance;
  }

  Future<ETCalendar> createCalendar({
    required String title,
    required Color color,
    ETAccount? account,
  });

  Future<List<ETCalendar>> retrieveCalendars({
    bool onlyWritableCalendars = true,
    ETAccount? account,
  });

  Future<List<ETAccount>> retrieveAccounts();

  Future<void> deleteCalendar({
    required String calendarId,
  });

  Future<ETEvent> createEvent({
    required String calendarId,
    required String title,
    required DateTime startDate,
    required DateTime endDate,
    bool isAllDay = false,
    String? description,
    String? url,
    List<Duration>? reminders,
  });

  Future<void> createEventInDefaultCalendar({
    required String title,
    required DateTime startDate,
    required DateTime endDate,
    bool isAllDay = false,
    String? description,
    String? url,
    List<Duration>? reminders,
  });

  Future<void> createEventThroughNativePlatform({
    String? title,
    DateTime? startDate,
    DateTime? endDate,
    bool? isAllDay,
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
    required String eventId,
    required Duration durationBeforeEvent,
  });

  Future<ETEvent> deleteReminder({
    required String eventId,
    required Duration durationBeforeEvent,
  });

  Future<ETEvent> createAttendee({
    required String eventId,
    required String name,
    required String email,
    required ETAttendeeType type,
  });

  Future<ETEvent> deleteAttendee({
    required String eventId,
    required ETAttendee attendee,
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
final class ETCalendar {
  final String id;
  final String title;
  final Color color;
  final bool isWritable;
  final ETAccount account;

  @override
  int get hashCode => Object.hash(id, title, color, isWritable, account);

  const ETCalendar({
    required this.id,
    required this.title,
    required this.color,
    required this.isWritable,
    required this.account,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other.runtimeType == runtimeType &&
          other is ETCalendar &&
          other.id == id &&
          other.title == title &&
          other.color == color &&
          other.isWritable == isWritable &&
          other.account == account;
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
final class ETEvent {
  final String id;
  final String title;
  final bool isAllDay;
  final DateTime startDate;
  final DateTime endDate;
  final String calendarId;
  final List<Duration> reminders;
  final List<ETAttendee> attendees;
  final String? description;
  final String? url;

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
          listEquals(other.reminders, reminders) &&
          listEquals(other.attendees, attendees) &&
          other.description == description &&
          other.url == url;
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
final class ETAccount {
  final String id;
  final String name;
  final String type;

  @override
  int get hashCode => Object.hash(id, name, type);

  const ETAccount({
    required this.id,
    required this.name,
    required this.type,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other.runtimeType == runtimeType &&
          other is ETAccount &&
          other.name == name &&
          other.type == type &&
          other.id == id;
}

/// Represents an attendee.
///
/// [name] is the name of the attendee.
///
/// [email] is the email of the attendee.
///
/// [type] is the type of the attendee. See README for more information.
///
/// [status] is the status of the attendee.
final class ETAttendee {
  final String name;
  final String email;
  final ETAttendeeType type;
  final ETAttendanceStatus status;

  @override
  int get hashCode => Object.hash(name, email, type, status);

  const ETAttendee({
    required this.name,
    required this.email,
    required this.type,
    required this.status,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other.runtimeType == runtimeType &&
          other is ETAttendee &&
          other.name == name &&
          other.email == email &&
          other.type == type &&
          other.status == status;
}

enum ETAttendeeType {
  unknown(
    iosParticipantType: 0,
    iosParticipantRole: 0,
    androidAttendeeType: 0,
    androidAttendeeRelationship: 0,
  ),
  requiredPerson(
    iosParticipantType: 1,
    iosParticipantRole: 1,
    androidAttendeeType: 1,
    androidAttendeeRelationship: 1,
  ),
  optionalPerson(
    iosParticipantType: 1,
    iosParticipantRole: 2,
    androidAttendeeType: 2,
    androidAttendeeRelationship: 1,
  ),
  organizer(
    iosParticipantType: 1,
    iosParticipantRole: 3,
    androidAttendeeType: 1,
    androidAttendeeRelationship: 2,
  ),
  resource(
    iosParticipantType: 3,
    iosParticipantRole: 1,
    androidAttendeeType: 3,
    androidAttendeeRelationship: 1,
  );

  final int iosParticipantType;
  final int iosParticipantRole;
  final int androidAttendeeType;
  final int androidAttendeeRelationship;

  const ETAttendeeType({
    required this.iosParticipantType,
    required this.iosParticipantRole,
    required this.androidAttendeeType,
    required this.androidAttendeeRelationship,
  });
}

/// ETAttendanceStatus
/// IOS     EKParticipantStatus : unknown, pending, accepted, declined, tentative, delegated, completed, inProcess
/// ANDROID ATTENDEE_STATUS     : STATUS_NONE, STATUS_ACCEPTED, STATUS_DECLINED, STATUS_INVITED, STATUS_TENTATIVE

/// Represents the status of the attendee.
///
/// [unknown] is the status of the attendee when the status is unknown.
///
/// [pending] is the status of the attendee when the attendee has not accepted the invitation.
///
/// [accepted] is the status of the attendee when the attendee has accepted the invitation.
///
/// [declined] is the status of the attendee when the attendee has declined the invitation.
///
/// [tentative] is the status of the attendee when the attendee has tentatively accepted the invitation.
///
/// Notes :
///
/// [EKParticipantStatus.inProcess] and [EKParticipantStatus.completed] are relative to the event status and not the participant attendance status and will be treated as [unknown].
///
/// [EKParticipantStatus.delegated] is not supported because it has no equivalent on Android.
enum ETAttendanceStatus {
  unknown(
    iosStatus: 0,
    androidStatus: 0,
  ),
  pending(
    iosStatus: 1,
    androidStatus: 3,
  ),
  accepted(
    iosStatus: 2,
    androidStatus: 1,
  ),
  declined(
    iosStatus: 3,
    androidStatus: 2,
  ),
  tentative(
    iosStatus: 4,
    androidStatus: 4,
  );

  final int iosStatus;
  final int androidStatus;

  const ETAttendanceStatus({
    required this.iosStatus,
    required this.androidStatus,
  });
}
