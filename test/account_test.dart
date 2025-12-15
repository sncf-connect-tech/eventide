import 'package:flutter/services.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:eventide/eventide.dart';
import 'package:eventide/src/calendar_api.g.dart';
import 'package:eventide/src/extensions/account_extensions.dart';

final class _MockCalendarApi extends Mock implements CalendarApi {}

void main() {
  late _MockCalendarApi mockCalendarApi;
  late Eventide eventide;

  setUp(() {
    mockCalendarApi = _MockCalendarApi();
    eventide = Eventide(calendarApi: mockCalendarApi);
  });

  group('retrieveAccounts', () {
    test('returns a list of ETAccounts when successful', () async {
      // Given
      final mockAccounts = [
        Account(
          id: '1',
          name: 'Google Account',
          type: 'com.google',
        ),
        Account(
          id: '2',
          name: 'iCloud',
          type: 'com.apple.calendar',
        ),
        Account(
          id: '3',
          name: 'Exchange',
          type: 'com.microsoft.exchange',
        ),
      ];

      when(() => mockCalendarApi.retrieveAccounts()).thenAnswer((_) async => mockAccounts);

      // When
      final result = await eventide.retrieveAccounts();

      // Then
      expect(result, hasLength(3));
      expect(result[0].id, '1');
      expect(result[0].name, 'Google Account');
      expect(result[0].type, 'com.google');
      expect(result[1].id, '2');
      expect(result[1].name, 'iCloud');
      expect(result[1].type, 'com.apple.calendar');
      expect(result[2].id, '3');
      expect(result[2].name, 'Exchange');
      expect(result[2].type, 'com.microsoft.exchange');

      verify(() => mockCalendarApi.retrieveAccounts()).called(1);
    });

    test('returns empty list when no accounts are available', () async {
      // Given
      when(() => mockCalendarApi.retrieveAccounts()).thenAnswer((_) async => <Account>[]);

      // When
      final result = await eventide.retrieveAccounts();

      // Then
      expect(result, isEmpty);
      verify(() => mockCalendarApi.retrieveAccounts()).called(1);
    });

    test('throws ETGenericException for other platform exceptions', () async {
      // Given
      when(() => mockCalendarApi.retrieveAccounts()).thenThrow(PlatformException(
        code: 'UNKNOWN_ERROR',
        message: 'Something went wrong',
      ));

      // When & Then
      expect(
        () => eventide.retrieveAccounts(),
        throwsA(isA<ETGenericException>()),
      );

      verify(() => mockCalendarApi.retrieveAccounts()).called(1);
    });

    test('properly maps Account to ETAccount', () async {
      // Given
      final mockAccount = Account(
        id: 'test-id',
        name: 'Test Account Name',
        type: 'test.account.type',
      );

      when(() => mockCalendarApi.retrieveAccounts()).thenAnswer((_) async => [mockAccount]);

      // When
      final result = await eventide.retrieveAccounts();

      // Then
      expect(result, hasLength(1));
      final etAccount = result.first;
      expect(etAccount.id, 'test-id');
      expect(etAccount.name, 'Test Account Name');
      expect(etAccount.type, 'test.account.type');

      // Verify the extension mapping works correctly
      final mappedAccount = mockAccount.toETAccount();
      expect(mappedAccount.id, etAccount.id);
      expect(mappedAccount.name, etAccount.name);
      expect(mappedAccount.type, etAccount.type);

      verify(() => mockCalendarApi.retrieveAccounts()).called(1);
    });

    test('handles accounts with special characters in names', () async {
      // Given
      final mockAccounts = [
        Account(
          id: '1',
          name: 'user+tag@gmail.com',
          type: 'com.google',
        ),
        Account(
          id: '2',
          name: 'Ñoño\'s Calendar',
          type: 'local',
        ),
      ];

      when(() => mockCalendarApi.retrieveAccounts()).thenAnswer((_) async => mockAccounts);

      // When
      final result = await eventide.retrieveAccounts();

      // Then
      expect(result, hasLength(2));
      expect(result[0].name, 'user+tag@gmail.com');
      expect(result[1].name, 'Ñoño\'s Calendar');

      verify(() => mockCalendarApi.retrieveAccounts()).called(1);
    });

    test('handles large number of accounts', () async {
      // Given
      final mockAccounts = List.generate(
          100,
          (index) => Account(
                id: 'account_$index',
                name: 'Account $index',
                type: 'test.type.$index',
              ));

      when(() => mockCalendarApi.retrieveAccounts()).thenAnswer((_) async => mockAccounts);

      // When
      final result = await eventide.retrieveAccounts();

      // Then
      expect(result, hasLength(100));
      expect(result.first.name, 'Account 0');
      expect(result.last.name, 'Account 99');

      verify(() => mockCalendarApi.retrieveAccounts()).called(1);
    });
  });
}
