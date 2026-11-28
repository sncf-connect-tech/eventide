import 'dart:ui';

import 'package:eventide_platform_interface/eventide_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:eventide_ios/eventide_ios.dart';
import 'package:eventide_ios/src/calendar_api.g.dart';
import 'package:eventide_ios/src/extensions/account_extensions.dart';
import 'package:eventide_ios/src/extensions/calendar_extensions.dart';
import 'package:eventide_ios/src/extensions/color_extensions.dart';

final class _MockCalendarApi extends Mock implements CalendarApi {}

void main() {
  const blue = Color(0xFF2196F3);
  const red = Color(0xFFF44336);
  const green = Color(0xFF4CAF50);

  late _MockCalendarApi mockCalendarApi;
  late EventideIOS eventide;

  setUp(() {
    mockCalendarApi = _MockCalendarApi();
    eventide = EventideIOS(calendarApi: mockCalendarApi);
  });

  test('createCalendar returns an ETCalendar', () async {
    const etAccount = ETAccount(id: '1', name: 'Test Account', type: 'Test Type');
    final calendar = Calendar(
      id: '1',
      title: 'Test Calendar',
      color: blue.toValue(),
      isWritable: true,
      account: etAccount.toAccount(),
    );

    when(
      () => mockCalendarApi.createCalendar(
        title: any(named: 'title'),
        color: any(named: 'color'),
        account: any(named: 'account'),
      ),
    ).thenAnswer((_) async => calendar);

    final result = await eventide.createCalendar(
      title: 'Test Calendar',
      color: blue,
      account: const ETAccount(id: 'Test account', name: 'Test account', type: 'local'),
    );

    expect(result, equals(calendar.toETCalendar()));
    verify(
      () => mockCalendarApi.createCalendar(
        title: 'Test Calendar',
        color: blue.toValue(),
        account: any(named: 'account'),
      ),
    ).called(1);
  });

  test('createCalendar throws an exception when API fails', () async {
    final account = Account(id: 'Test account', name: 'Test account', type: 'local');
    when(
      () => mockCalendarApi.createCalendar(
        title: any(named: 'title'),
        color: any(named: 'color'),
        account: account,
      ),
    ).thenThrow(const ETGenericException(message: 'API Error'));

    Future<ETCalendar> call() =>
        eventide.createCalendar(title: 'Test Calendar', color: blue, account: account.toETAccount());

    expect(call, throwsException);
    verify(() => mockCalendarApi.createCalendar(title: 'Test Calendar', color: blue.toValue(), account: account))
        .called(1);
  });

  test('retrieveCalendars returns a list of ETCalendars', () async {
    final account1 = Account(id: '1', name: 'Test Account 1', type: 'Test Type 1');
    final account2 = Account(id: '2', name: 'Test Account 2', type: 'Test Type 2');
    final calendars = [
      Calendar(id: '1', title: 'Test Calendar 1', color: blue.toValue(), isWritable: true, account: account1),
      Calendar(id: '2', title: 'Test Calendar 2', color: red.toValue(), isWritable: true, account: account2),
    ];
    when(
      () => mockCalendarApi.retrieveCalendars(
        onlyWritableCalendars: any(named: 'onlyWritableCalendars'),
        account: any(named: 'account'),
      ),
    ).thenAnswer((_) async => [calendars.last]);

    final result = await eventide.retrieveCalendars(onlyWritableCalendars: true);

    expect(result, [calendars.last].toETCalendarList());
    verify(() => mockCalendarApi.retrieveCalendars(onlyWritableCalendars: true, account: any(named: 'account')))
        .called(1);
  });

  test('updateCalendar calls the API and returns an ETCalendar with updated values', () async {
    final calendar = Calendar(
      id: '987654321',
      title: 'Calendar',
      color: red.toValue(),
      isWritable: true,
      account: Account(id: '1', name: 'Test Account', type: 'Test Type'),
    );
    when(
      () => mockCalendarApi.updateCalendar(
        calendarId: any(named: 'calendarId'),
        title: any(named: 'title'),
        color: any(named: 'color'),
      ),
    ).thenAnswer((_) async => calendar);

    await eventide.updateCalendar(calendar.toETCalendar(), title: 'Updated Calendar', color: green);

    verify(
      () => mockCalendarApi.updateCalendar(calendarId: calendar.id, title: 'Updated Calendar', color: green.toValue()),
    ).called(1);
  });

  test('deleteCalendar calls the API', () async {
    when(() => mockCalendarApi.deleteCalendar(calendarId: any(named: 'calendarId'))).thenAnswer((_) async {});

    await eventide.deleteCalendar(calendarId: '1');

    verify(() => mockCalendarApi.deleteCalendar(calendarId: '1')).called(1);
  });
}
