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

  const ETAttendee({required this.name, required this.email, required this.type, required this.status});

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

/// Represents the type/role of an attendee.
enum ETAttendeeType { unknown, requiredPerson, optionalPerson, organizer, resource }

/// Represents the attendance status of an attendee.
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
enum ETAttendanceStatus { unknown, pending, accepted, declined, tentative }
