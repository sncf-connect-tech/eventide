import 'package:flutter/services.dart';

import 'package:flutter_test/flutter_test.dart';

import 'package:eventide/src/eventide_exception.dart';

void main() {
  group('PlatformExceptionToETCalendarException tests', () {
    test('Converts PlatformException to ETPermissionException', () {
      final platformException = PlatformException(
        code: 'ACCESS_REFUSED',
        message: 'Permission denied',
      );
      final etException = platformException.toETException();
      expect(etException, isA<ETPermissionException>());
      expect(etException.code, 'ACCESS_REFUSED');
      expect(etException.message, 'Permission denied');
    });

    test('Converts PlatformException to ETNotFoundException', () {
      final platformException = PlatformException(
        code: 'NOT_FOUND',
        message: 'Not found',
      );
      final etException = platformException.toETException();
      expect(etException, isA<ETNotFoundException>());
      expect(etException.code, 'NOT_FOUND');
      expect(etException.message, 'Not found');
    });

    test('Converts PlatformException to ETNotEditableException', () {
      final platformException = PlatformException(
        code: 'NOT_EDITABLE',
        message: 'Not editable',
      );
      final etException = platformException.toETException();
      expect(etException, isA<ETNotEditableException>());
      expect(etException.code, 'NOT_EDITABLE');
      expect(etException.message, 'Not editable');
    });

    test('Converts PlatformException to ETGenericException', () {
      final platformException = PlatformException(
        code: 'UNKNOWN_ERROR',
        message: 'Unknown error',
      );
      final etException = platformException.toETException();
      expect(etException, isA<ETGenericException>());
      expect(etException.code, 'GENERIC_ERROR');
      expect(etException.message, 'Unknown error');
    });

    test('Converts PlatformException to ETNotSupportedByPlatform', () {
      final platformException = PlatformException(
        code: 'PLATFORM_DOES_NOT_SUPPORT',
        message: 'platform does not support this feature',
      );
      final etException = platformException.toETException();
      expect(etException, isA<ETNotSupportedByPlatform>());
      expect(etException.code, 'PLATFORM_DOES_NOT_SUPPORT');
      expect(etException.message, 'platform does not support this feature');
    });
  });
}
