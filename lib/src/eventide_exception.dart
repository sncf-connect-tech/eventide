import 'package:flutter/services.dart';

/// An exception thrown by the Flutter Calendar Connect plugin.
abstract class ETException extends PlatformException {
  ETException({
    required super.code,
    required super.message,
    super.details,
  });
}

/// An exception thrown when the user refuses to grant calendar permissions.
final class ETPermissionException extends ETException {
  ETPermissionException({
    required super.message,
    super.details,
  }) : super(code: 'ACCESS_REFUSED');
}

/// An exception thrown when a calendar/event/reminder is not found.
final class ETNotFoundException extends ETException {
  ETNotFoundException({
    required super.message,
    super.details,
  }) : super(code: 'NOT_FOUND');
}

/// An exception thrown when the calendar is not editable.
final class ETNotEditableException extends ETException {
  ETNotEditableException({
    required super.message,
    super.details,
  }) : super(code: 'NOT_EDITABLE');
}

/// An exception thrown when an unknown plugin error occurs.
final class ETGenericException extends ETException {
  ETGenericException({
    required super.message,
    super.details,
  }) : super(code: 'GENERIC_ERROR');
}

final class ETNotSupportedByPlatform extends ETException {
  ETNotSupportedByPlatform({
    required super.message,
    super.details,
  }) : super(code: 'PLATFORM_DOES_NOT_SUPPORT');
}

class D {}

extension PlatformExceptionToETCalendarException on PlatformException {
  /// Converts a [PlatformException] to a [ETException].
  ETException toETException() {
    return switch (code) {
      'ACCESS_REFUSED' => ETPermissionException(
          message: message,
          details: details,
        ),
      'NOT_FOUND' => ETNotFoundException(
          message: message,
          details: details,
        ),
      'NOT_EDITABLE' => ETNotEditableException(
          message: message,
          details: details,
        ),
      'PLATFORM_DOES_NOT_SUPPORT' => ETNotSupportedByPlatform(
          message: message,
          details: details,
        ),
      _ => ETGenericException(
          message: message,
          details: details,
        )
    };
  }
}
