/// Represents an account.
///
/// [id] is a unique identifier for the account. It corresponds to CalendarContract.Calendars.ACCOUNT_NAME on Android and EKSource.sourceIdentifier on iOS.
///
/// [name] is the name of the account. It corresponds to CalendarContract.Calendars.ACCOUNT_NAME on Android and EKSource.title on iOS.
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

  const ETAccount({required this.id, required this.name, required this.type});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other.runtimeType == runtimeType &&
          other is ETAccount &&
          other.name == name &&
          other.type == type &&
          other.id == id;
}
