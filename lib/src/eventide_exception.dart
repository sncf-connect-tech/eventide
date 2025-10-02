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

/// An exception thrown when the user cancels event creation in the native platform.
final class ETUserCanceledException extends ETException {
  ETUserCanceledException({
    required super.message,
    super.details,
  }) : super(code: 'USER_CANCELED');
}

/// An exception thrown when the event creation view cannot be presented.
final class ETPresentationException extends ETException {
  ETPresentationException({
    required super.message,
    super.details,
  }) : super(code: 'PRESENTATION_ERROR');
}

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
      'USER_CANCELED' => ETUserCanceledException(
          message: message,
          details: details,
        ),
      'PRESENTATION_ERROR' => ETPresentationException(
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
