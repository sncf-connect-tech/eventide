import 'package:eventide_platform_interface/eventide_platform_interface.dart';

import 'package:eventide_android/src/calendar_api.g.dart';

extension ETAttendeeTypeToNative on ETAttendeeType {
  /// Maps to Android `CalendarContract.Attendees.ATTENDEE_TYPE`.
  int get nativeRole => switch (this) {
    ETAttendeeType.unknown => 0,
    ETAttendeeType.requiredPerson => 1,
    ETAttendeeType.optionalPerson => 2,
    ETAttendeeType.organizer => 1,
    ETAttendeeType.resource => 3,
  };

  /// Maps to Android `CalendarContract.Attendees.ATTENDEE_RELATIONSHIP`.
  int get nativeType => switch (this) {
    ETAttendeeType.unknown => 0,
    ETAttendeeType.requiredPerson => 1,
    ETAttendeeType.optionalPerson => 1,
    ETAttendeeType.organizer => 2,
    ETAttendeeType.resource => 1,
  };
}

extension ETAttendanceStatusToNative on ETAttendanceStatus {
  /// Maps to Android `CalendarContract.Attendees.ATTENDEE_STATUS`.
  int get nativeStatus => switch (this) {
    ETAttendanceStatus.unknown => 0,
    ETAttendanceStatus.accepted => 1,
    ETAttendanceStatus.declined => 2,
    ETAttendanceStatus.pending => 3,
    ETAttendanceStatus.tentative => 4,
  };
}

extension AttendeeToET on Attendee {
  ETAttendee toETAttendee() {
    return ETAttendee(name: name, email: email, type: parseETAttendeeType(), status: parseETAttendanceStatus());
  }

  /*
    Android ATTENDEE_RELATIONSHIP (stored in Attendee.type)
    RELATIONSHIP_NONE = 0
    RELATIONSHIP_ATTENDEE = 1
    RELATIONSHIP_ORGANIZER = 2
    RELATIONSHIP_PERFORMER = 3
    RELATIONSHIP_SPEAKER = 4

    Android ATTENDEE_TYPE (stored in Attendee.role)
    TYPE_NONE = 0
    TYPE_REQUIRED = 1
    TYPE_OPTIONAL = 2
    TYPE_RESOURCE = 3
  */
  ETAttendeeType parseETAttendeeType() {
    return switch ((type, role)) {
      (1, 1) || (3, 1) || (4, 1) => ETAttendeeType.requiredPerson,
      (1, 2) => ETAttendeeType.optionalPerson,
      (2, 1) => ETAttendeeType.organizer,
      (1, 3) => ETAttendeeType.resource,
      _ => ETAttendeeType.unknown,
    };
  }

  /*
    Android ATTENDEE_STATUS
    ATTENDEE_STATUS_NONE = 0
    ATTENDEE_STATUS_ACCEPTED = 1
    ATTENDEE_STATUS_DECLINED = 2
    ATTENDEE_STATUS_INVITED = 3
    ATTENDEE_STATUS_TENTATIVE = 4
  */
  ETAttendanceStatus parseETAttendanceStatus() {
    return switch (status) {
      1 => ETAttendanceStatus.accepted,
      2 => ETAttendanceStatus.declined,
      3 => ETAttendanceStatus.pending,
      4 => ETAttendanceStatus.tentative,
      _ => ETAttendanceStatus.unknown,
    };
  }
}

extension AttendeeListToETAttendees on List<Attendee> {
  List<ETAttendee> toETAttendeeList() {
    return map((e) => e.toETAttendee()).toList();
  }
}
