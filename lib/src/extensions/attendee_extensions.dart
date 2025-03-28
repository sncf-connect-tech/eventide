import 'package:flutter/foundation.dart';

import 'package:eventide/src/calendar_api.g.dart';
import 'package:eventide/src/eventide_platform_interface.dart';

extension ETAttendeeTypeToNative on ETAttendeeType {
  int get nativeRole => switch (defaultTargetPlatform) {
        TargetPlatform.iOS => iosParticipantRole,
        TargetPlatform.android => androidAttendeeType,
        _ => throw UnimplementedError(),
      };

  int get nativeType => switch (defaultTargetPlatform) {
        TargetPlatform.iOS => iosParticipantType,
        TargetPlatform.android => androidAttendeeRelationship,
        _ => throw UnimplementedError(),
      };
}

extension ETAttendanceStatusToNative on ETAttendanceStatus {
  int get nativeStatus => switch (defaultTargetPlatform) {
        TargetPlatform.iOS => iosStatus,
        TargetPlatform.android => androidStatus,
        _ => throw UnimplementedError(),
      };
}

extension AttendeeToET on Attendee {
  ETAttendee toETAttendee() {
    return ETAttendee(
      name: name,
      email: email,
      type: parseETAttendeeType(),
      status: parseETAttendanceStatus(),
    );
  }

  /*
    iOS EKParticipantType       Android ATTENDEE_RELATIONSHIP     
    unknown = 0                 RELATIONSHIP_NONE = 0             
    person = 1                  RELATIONSHIP_ATTENDEE = 1         
    room = 2                    RELATIONSHIP_ORGANIZER = 2        
    resource = 3                RELATIONSHIP_PERFORMER = 3        
    group = 4                   RELATIONSHIP_SPEAKER = 4       

    iOS EKParticipantRole       Android ATTENDEE_TYPE             
    unknown = 0                 TYPE_NONE = 0                     
    required = 1                TYPE_REQUIRED = 1                 
    optional = 2                TYPE_OPTIONAL = 2                 
    chair = 3                   TYPE_RESOURCE = 3                 
    nonParticipant = 4                                          
  */
  ETAttendeeType parseETAttendeeType() {
    return switch ((defaultTargetPlatform, type, role)) {
      (TargetPlatform.iOS, 1, 1) => ETAttendeeType.requiredPerson,
      (TargetPlatform.iOS, 1, 2) => ETAttendeeType.optionalPerson,
      (TargetPlatform.iOS, 1, 3) => ETAttendeeType.organizer,
      (TargetPlatform.iOS, 3, 1) => ETAttendeeType.resource,
      (TargetPlatform.iOS, 2, 1) => ETAttendeeType.resource,
      (TargetPlatform.iOS, 4, 1) => ETAttendeeType.resource,
      (TargetPlatform.iOS, 1, 4) => ETAttendeeType.optionalPerson,
      (TargetPlatform.android, 1, 1) => ETAttendeeType.requiredPerson,
      (TargetPlatform.android, 2, 1) => ETAttendeeType.optionalPerson,
      (TargetPlatform.android, 1, 2) => ETAttendeeType.organizer,
      (TargetPlatform.android, 3, 1) => ETAttendeeType.resource,
      (TargetPlatform.android, 1, 4) => ETAttendeeType.requiredPerson,
      (TargetPlatform.android, 1, 3) => ETAttendeeType.requiredPerson,
      _ => ETAttendeeType.unknown,
    };
  }

  /*
    iOS EKParticipantStatus     Android ATTENDEE_STATUS
    unknown = 0                 ATTENDEE_STATUS_NONE = 0
    pending = 1                 ATTENDEE_STATUS_ACCEPTED = 1
    accepted = 2                ATTENDEE_STATUS_DECLINED = 2
    declined = 3                ATTENDEE_STATUS_INVITED = 3
    tentative = 4               ATTENDEE_STATUS_TENTATIVE = 4
    delegated = 5                 
    completed = 6                 
    inProcess = 7                 
  */
  ETAttendanceStatus parseETAttendanceStatus() {
    return switch ((defaultTargetPlatform, status)) {
      (TargetPlatform.iOS, 1) || (TargetPlatform.android, 3) => ETAttendanceStatus.pending,
      (TargetPlatform.iOS, 2) || (TargetPlatform.android, 1) => ETAttendanceStatus.accepted,
      (TargetPlatform.iOS, 3) || (TargetPlatform.android, 2) => ETAttendanceStatus.declined,
      (TargetPlatform.iOS, 4) || (TargetPlatform.android, 4) => ETAttendanceStatus.tentative,
      _ => ETAttendanceStatus.unknown,
    };
  }
}

extension AttendeeListToETAttendees on List<Attendee> {
  List<ETAttendee> toETAttendeeList() {
    return map((e) => e.toETAttendee()).toList();
  }
}
