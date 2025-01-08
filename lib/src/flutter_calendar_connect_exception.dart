import 'package:flutter/services.dart';

/// An exception thrown by the Flutter Calendar Connect plugin.
abstract class FCCException extends PlatformException {
  FCCException({
    required super.code,
    required super.message,
    super.details,
  });
}

/// An exception thrown when the user refuses to grant calendar permissions.
class FCCPermissionException extends FCCException {
  FCCPermissionException({
    required super.message,
    super.details,
  }) : super(code: 'ACCESS_REFUSED');
}

/// An exception thrown when a calendar/event/reminder is not found.
class FCCNotFoundException extends FCCException {
  FCCNotFoundException({
    required super.message,
    super.details,
  }) : super(code: 'NOT_FOUND');
}

/// An exception thrown when the calendar is not editable.
class FCCNotEditableException extends FCCException {
  FCCNotEditableException({
    required super.message,
    super.details,
  }) : super(code: 'NOT_EDITABLE');
}

/// An exception thrown when an unknown plugin error occurs.
class FCCGenericException extends FCCException {
  FCCGenericException({
    required super.message,
    super.details,
  }) : super(code: 'GENERIC_ERROR');
}

extension PlatformExceptionToFlutterCalendarConnectException on PlatformException {
  /// Converts a [PlatformException] to a [FCCException].
  FCCException toFlutterCalendarConnectException() {
    return switch (code) {
      'ACCESS_REFUSED' => FCCPermissionException(
        message: message,
        details: details,
      ),
      'NOT_FOUND' => FCCNotFoundException(
        message: message,
        details: details,
      ),
      'NOT_EDITABLE' => FCCNotEditableException(
        message: message,
        details: details,
      ),
      _ => FCCGenericException(
        message: message,
        details: details,
      )
    };
  }
}