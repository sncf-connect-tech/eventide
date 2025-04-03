import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:eventide/eventide.dart';
import 'package:eventide/src/calendar_api.g.dart';
import 'package:eventide/src/extensions/account_extensions.dart';
import 'package:eventide/src/extensions/calendar_extensions.dart';
import 'package:eventide/src/extensions/color_extensions.dart';

class _MockCalendarApi extends Mock implements CalendarApi {}

void main() {
  late _MockCalendarApi mockCalendarApi;
  late Eventide eventide;

  setUp(() {
    mockCalendarApi = _MockCalendarApi();
    eventide = Eventide(calendarApi: mockCalendarApi);
  });

  test('createCalendar returns an ETCalendar', () async {
    // Given
    const etAccount = ETAccount(name: 'Test Account', type: 'Test Type');
    final calendar = Calendar(
      id: '1',
      title: 'Test Calendar',
      color: Colors.blue.toValue(),
      isWritable: true,
      account: etAccount.toAccount(),
    );

    when(() => mockCalendarApi.createCalendar(
          title: any(named: 'title'),
          color: any(named: 'color'),
          account: any(named: 'account'),
        )).thenAnswer((_) async => calendar);

    // When
    final result = await eventide.createCalendar(
      title: 'Test Calendar',
      color: Colors.blue,
      account: etAccount,
    );

    // Then
    expect(result, equals(calendar.toETCalendar()));
    verify(() => mockCalendarApi.createCalendar(
          title: 'Test Calendar',
          color: Colors.blue.toValue(),
          account: any(named: 'account'),
        )).called(1);
  });

  test('createCalendar throws an exception when API fails', () async {
    // Given
    when(() => mockCalendarApi.createCalendar(title: any(named: 'title'), color: any(named: 'color'), account: null))
        .thenThrow(ETGenericException(message: 'API Error'));

    // When
    Future<ETCalendar> call() => eventide.createCalendar(title: 'Test Calendar', color: Colors.blue);

    // Then
    expect(call, throwsException);
    verify(() => mockCalendarApi.createCalendar(title: 'Test Calendar', color: Colors.blue.toValue(), account: null))
        .called(1);
  });

  test('retrieveCalendars returns a list of ETCalendars', () async {
    // Given
    final account1 = Account(name: 'Test Account 1', type: 'Test Type 1');
    final account2 = Account(name: 'Test Account 2', type: 'Test Type 2');
    final calendars = [
      Calendar(
        id: '1',
        title: 'Test Calendar 1',
        color: Colors.blue.toValue(),
        isWritable: true,
        account: account1,
      ),
      Calendar(
        id: '2',
        title: 'Test Calendar 2',
        color: Colors.red.toValue(),
        isWritable: true,
        account: account2,
      ),
    ];
    when(() => mockCalendarApi.retrieveCalendars(
          onlyWritableCalendars: any(named: 'onlyWritableCalendars'),
          from: any(named: 'from'),
        )).thenAnswer((_) async => [calendars.last]);

    // When
    final result = await eventide.retrieveCalendars(onlyWritableCalendars: true);

    // Then
    expect(result, [calendars.last].toETCalendarList());
    verify(() => mockCalendarApi.retrieveCalendars(
          onlyWritableCalendars: true,
          from: any(named: 'from'),
        )).called(1);
  });

  test('retrieveCalendars throws an exception when API fails', () async {
    // Given
    when(() => mockCalendarApi.retrieveCalendars(
          onlyWritableCalendars: any(named: 'onlyWritableCalendars'),
          from: null,
        )).thenThrow(ETGenericException(message: 'API Error'));

    // When
    Future<List<ETCalendar>> call() => eventide.retrieveCalendars(onlyWritableCalendars: true);

    // Then
    expect(call, throwsException);
    verify(() => mockCalendarApi.retrieveCalendars(
          onlyWritableCalendars: true,
          from: null,
        )).called(1);
  });

  test('deleteCalendar calls the API', () async {
    // Given
    when(() => mockCalendarApi.deleteCalendar(calendarId: any(named: 'calendarId'))).thenAnswer((_) async => {});

    // When
    await eventide.deleteCalendar(calendarId: '1');

    // Then
    verify(() => mockCalendarApi.deleteCalendar(calendarId: '1')).called(1);
  });

  test('deleteCalendar throws an exception when API fails', () async {
    // Given
    when(() => mockCalendarApi.deleteCalendar(calendarId: any(named: 'calendarId')))
        .thenThrow(ETGenericException(message: 'API Error'));

    // When
    Future<void> call() => eventide.deleteCalendar(calendarId: '1');

    // Then
    expect(call, throwsException);
    verify(() => mockCalendarApi.deleteCalendar(calendarId: '1')).called(1);
  });

  group('CalendarToETCalendar tests', () {
    test('Calendar toETCalendar', () {
      final calendar = Calendar(
        id: '1',
        title: 'Test Calendar',
        color: 0xFF123456,
        isWritable: true,
        account: Account(name: 'Test Account', type: 'Test Type'),
      );
      final etCalendar = calendar.toETCalendar();
      expect(etCalendar.id, '1');
      expect(etCalendar.title, 'Test Calendar');
      expect(etCalendar.color, const Color(0xFF123456));
      expect(etCalendar.isWritable, true);
      expect(etCalendar.account.name, 'Test Account');
    });

    test('List<Calendar> toETCalendarList', () {
      final calendars = [
        Calendar(
          id: '1',
          title: 'Test Calendar',
          color: 0xFF123456,
          isWritable: true,
          account: Account(name: 'Test Account', type: 'Test Type'),
        ),
      ];
      final etCalendars = calendars.toETCalendarList();
      expect(etCalendars.length, 1);
      expect(etCalendars.first.id, '1');
    });
  });

  group('Account tests', () {
    test('Account toETAccount', () {
      final account = Account(name: 'Test Account', type: 'Test Type');
      final etAccount = account.toETAccount();
      expect(etAccount.name, 'Test Account');
      expect(etAccount.type, 'Test Type');
    });

    test('ETAccount toAccount', () {
      const etAccount = ETAccount(name: 'Test Account', type: 'Test Type');
      final account = etAccount.toAccount();
      expect(account.name, 'Test Account');
      expect(account.type, 'Test Type');
    });
  });
}
