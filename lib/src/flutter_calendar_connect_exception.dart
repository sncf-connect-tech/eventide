import 'package:flutter/services.dart';

abstract class FlutterCalendarConnectException extends PlatformException {
  FlutterCalendarConnectException({
    required super.code,
    required super.message,
    super.details,
  });
}

class CalendarPermissionException extends FlutterCalendarConnectException {
  CalendarPermissionException({
    required super.message,
    super.details,
  }) : super(code: 'ACCESS_REFUSED');
}

class CalendarNotFoundException extends FlutterCalendarConnectException {
  CalendarNotFoundException({
    required super.message,
    super.details,
  }) : super(code: 'NOT_FOUND');
}

class CalendarNotEditableException extends FlutterCalendarConnectException {
  CalendarNotEditableException({
    required super.message,
    super.details,
  }) : super(code: 'NOT_EDITABLE');
}

class CalendarConnectGenericException extends FlutterCalendarConnectException {
  CalendarConnectGenericException({
    required super.message,
    super.details,
  }) : super(code: 'GENERIC_ERROR');
}

extension PlatformExceptionToFlutterCalendarConnectException on PlatformException {
  FlutterCalendarConnectException toFlutterCalendarConnectException() {
    return switch (code) {
      'ACCESS_REFUSED' => CalendarPermissionException(
        message: message,
        details: details,
      ),
      'NOT_FOUND' => CalendarNotFoundException(
        message: message,
        details: details,
      ),
      'NOT_EDITABLE' => CalendarNotEditableException(
        message: message,
        details: details,
      ),
      _ => CalendarConnectGenericException(
        message: message,
        details: details,
      )
    };
  }
}