import 'package:eventide_platform_interface/eventide_platform_interface.dart';

import 'package:eventide_ios/src/calendar_api.g.dart';

extension AttendeeToET on Attendee {
  ETAttendee toETAttendee() {
    return ETAttendee(name: name, email: email, type: parseETAttendeeType(), status: parseETAttendanceStatus());
  }

  /*
    iOS EKParticipantType       iOS EKParticipantRole
    unknown = 0                 unknown = 0
    person = 1                  required = 1
    room = 2                    optional = 2
    resource = 3                chair = 3
    group = 4                   nonParticipant = 4
  */
  ETAttendeeType parseETAttendeeType() {
    return switch ((type, role)) {
      (1, 1) => ETAttendeeType.requiredPerson,
      (1, 2) || (1, 4) => ETAttendeeType.optionalPerson,
      (1, 3) => ETAttendeeType.organizer,
      (2, 1) || (3, 1) || (4, 1) => ETAttendeeType.resource,
      _ => ETAttendeeType.unknown,
    };
  }

  /*
    iOS EKParticipantStatus
    unknown = 0
    pending = 1
    accepted = 2
    declined = 3
    tentative = 4
    delegated = 5
    completed = 6
    inProcess = 7
  */
  ETAttendanceStatus parseETAttendanceStatus() {
    return switch (status) {
      1 => ETAttendanceStatus.pending,
      2 => ETAttendanceStatus.accepted,
      3 => ETAttendanceStatus.declined,
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
