import 'package:flutter/services.dart';

import 'package:flutter_test/flutter_test.dart';

import 'package:eventide/src/eventide_exception.dart';

void main() {
  group('ETException tests', () {
    test('ETPermissionException is instantiated correctly', () {
      final exception = ETPermissionException(message: 'Permission denied');
      expect(exception.code, 'ACCESS_REFUSED');
      expect(exception.message, 'Permission denied');
      expect(exception.details, isNull);
    });

    test('ETNotFoundException is instantiated correctly', () {
      final exception = ETNotFoundException(message: 'Not found');
      expect(exception.code, 'NOT_FOUND');
      expect(exception.message, 'Not found');
      expect(exception.details, isNull);
    });

    test('ETNotEditableException is instantiated correctly', () {
      final exception = ETNotEditableException(message: 'Not editable');
      expect(exception.code, 'NOT_EDITABLE');
      expect(exception.message, 'Not editable');
      expect(exception.details, isNull);
    });

    test('ETGenericException is instantiated correctly', () {
      final exception = ETGenericException(message: 'Generic error');
      expect(exception.code, 'GENERIC_ERROR');
      expect(exception.message, 'Generic error');
      expect(exception.details, isNull);
    });
  });

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
  });
}
