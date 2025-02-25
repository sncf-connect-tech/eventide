import 'package:eventide/src/eventide_extensions.dart';
import 'package:eventide/src/eventide_platform_interface.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eventide/src/eventide.dart';
import 'package:eventide/src/calendar_api.g.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart';
import 'package:timezone/data/latest.dart' as tz;

class _MockCalendarApi extends Mock implements CalendarApi {}

void main() {
  tz.initializeTimeZones();

  late _MockCalendarApi mockCalendarApi;
  late Eventide eventide;

  setUp(() {
    mockCalendarApi = _MockCalendarApi();
    eventide = Eventide(calendarApi: mockCalendarApi);
  });

  group('Calendar tests', () {
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
      when(() => mockCalendarApi.createCalendar(
          title: any(named: 'title'),
          color: any(named: 'color'),
          account: null)).thenThrow(Exception('API Error'));

      // When
      Future<ETCalendar> call() =>
          eventide.createCalendar(title: 'Test Calendar', color: Colors.blue);

      // Then
      expect(call, throwsException);
      verify(() => mockCalendarApi.createCalendar(
          title: 'Test Calendar',
          color: Colors.blue.toValue(),
          account: null)).called(1);
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
              onlyWritableCalendars: any(named: 'onlyWritableCalendars'),from: null,))
          .thenThrow(Exception('API Error'));

      // When
      Future<List<ETCalendar>> call() =>
          eventide.retrieveCalendars(onlyWritableCalendars: true);

      // Then
      expect(call, throwsException);
      verify(() =>
              mockCalendarApi.retrieveCalendars(onlyWritableCalendars: true,from: null,))
          .called(1);
    });

    test('deleteCalendar calls the API', () async {
      // Given
      when(() => mockCalendarApi.deleteCalendar(
          calendarId: any(named: 'calendarId'))).thenAnswer((_) async => {});

      // When
      await eventide.deleteCalendar(calendarId: '1');

      // Then
      verify(() => mockCalendarApi.deleteCalendar(calendarId: '1')).called(1);
    });

    test('deleteCalendar throws an exception when API fails', () async {
      // Given
      when(() => mockCalendarApi.deleteCalendar(
              calendarId: any(named: 'calendarId')))
          .thenThrow(Exception('API Error'));

      // When
      Future<void> call() => eventide.deleteCalendar(calendarId: '1');

      // Then
      expect(call, throwsException);
      verify(() => mockCalendarApi.deleteCalendar(calendarId: '1')).called(1);
    });
  });

  group('Event tests', () {
    final location = getLocation('UTC');
    final startDate = TZDateTime.now(location);
    final endDate = startDate.add(const Duration(hours: 1));
    final event = Event(
      id: '1',
      title: 'Test Event',
      isAllDay: false,
      startDate: startDate.millisecondsSinceEpoch,
      endDate: endDate.add(const Duration(hours: 1)).millisecondsSinceEpoch,
      calendarId: '1',
      description: null,
      url: null,
      reminders: [],
    );

    setUpAll(() {
      registerFallbackValue(event);
    });

    test('createEvent returns an ETEvent', () async {
      // Given
      final event = Event(
        id: '1',
        title: 'Test Event',
        isAllDay: true,
        startDate: startDate.millisecondsSinceEpoch,
        endDate: endDate.add(const Duration(hours: 1)).millisecondsSinceEpoch,
        calendarId: '1',
      );

      when(() => mockCalendarApi.createEvent(
            title: any(named: 'title'),
            isAllDay: any(named: 'isAllDay'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
            calendarId: any(named: 'calendarId'),
            description: any(named: 'description'),
            url: any(named: 'url'),
          )).thenAnswer((_) async => event);

      // When
      final result = await eventide.createEvent(
        title: 'Test Event',
        isAllDay: true,
        startDate: startDate,
        endDate: endDate,
        calendarId: '',
      );

      // Then
      expect(result, event.toETEvent());
      verify(() => mockCalendarApi.createEvent(
            title: any(named: 'title'),
            isAllDay: any(named: 'isAllDay'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
            calendarId: any(named: 'calendarId'),
            description: any(named: 'description'),
            url: any(named: 'url'),
          )).called(1);
    });

    test('createEvent throws an exception when API fails', () async {
      // Given
      when(() => mockCalendarApi.createEvent(
            title: any(named: 'title'),
            isAllDay: any(named: 'isAllDay'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
            calendarId: any(named: 'calendarId'),
            description: any(named: 'description'),
            url: any(named: 'url'),
          )).thenThrow(Exception('API Error'));

      // When
      Future<ETEvent> call() => eventide.createEvent(
            title: 'Test Event',
            startDate: startDate,
            endDate: endDate,
            calendarId: '',
          );

      // Then
      expect(call, throwsException);
      verify(() => mockCalendarApi.createEvent(
            title: any(named: 'title'),
            isAllDay: any(named: 'isAllDay'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
            calendarId: any(named: 'calendarId'),
            description: any(named: 'description'),
            url: any(named: 'url'),
          )).called(1);
    });

    test('retrieveEvents returns a list of ETEvents with reminders', () async {
      // Given
      const reminders = [Duration(minutes: 10), Duration(minutes: 20)];
      when(() => mockCalendarApi.retrieveEvents(
              calendarId: any(named: 'calendarId'),
              startDate: any(named: 'startDate'),
              endDate: any(named: 'endDate')))
          .thenAnswer(
              (_) async => [event.copyWithReminders(reminders.toNativeList())]);

      // When
      final result = await eventide.retrieveEvents(calendarId: '1');

      // Then
      expect(result.first.reminders, equals(reminders));
      verify(() => mockCalendarApi.retrieveEvents(
          calendarId: '1',
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'))).called(1);
    });

    test('create Event timezone management test: Paris - Montréal flight',
        () async {
      final parisDeparture =
          TZDateTime(getLocation('Europe/Paris'), 2025, 9, 8, 13, 30);
      final montrealArrival =
          TZDateTime(getLocation('America/Montreal'), 2025, 9, 8, 15, 00);
      final utcParisDeparture = parisDeparture.toUtc();
      final utcMontrealArrival = montrealArrival.toUtc();

      final mockEvent = Event(
        id: '1',
        title: 'Paris - Montréal',
        isAllDay: false,
        startDate: utcParisDeparture.millisecondsSinceEpoch,
        endDate: utcMontrealArrival.millisecondsSinceEpoch,
        calendarId: '1',
      );

      when(() => mockCalendarApi.createEvent(
            calendarId: any(named: 'calendarId'),
            title: any(named: 'title'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
            isAllDay: any(named: 'isAllDay'),
            description: any(named: 'description'),
            url: any(named: 'url'),
          )).thenAnswer((_) async => mockEvent);

      await eventide.createEvent(
        title: 'Paris - Montréal',
        startDate: parisDeparture,
        endDate: montrealArrival,
        calendarId: '1',
      );

      verify(() => mockCalendarApi.createEvent(
            calendarId: '1',
            title: 'Paris - Montréal',
            startDate: utcParisDeparture.millisecondsSinceEpoch,
            endDate: utcMontrealArrival.millisecondsSinceEpoch,
            isAllDay: false,
            description: null,
            url: null,
          )).called(1);
    });
  });

  group('Reminder tests', () {
    final location = getLocation('UTC');
    final startDate = TZDateTime.now(location);
    final endDate = startDate.add(const Duration(hours: 1));

    group('iOS', () {
      setUpAll(() {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      });

      tearDownAll(() {
        debugDefaultTargetPlatformOverride = null;
      });

      test('createReminder returns an ETEvent', () async {
        // Given
        final targetEvent = Event(
          id: '1',
          title: 'Test Event',
          isAllDay: false,
          startDate: startDate.millisecondsSinceEpoch,
          endDate: endDate.millisecondsSinceEpoch,
          calendarId: '1',
          reminders: [10 * 60],
        );

        when(() => mockCalendarApi.createReminder(
                reminder: any(named: 'reminder'),
                eventId: any(named: 'eventId')))
            .thenAnswer((_) async => targetEvent);

        // When
        final result = await eventide.createReminder(
          durationBeforeEvent: const Duration(minutes: 10),
          eventId: '1',
        );

        // Then
        expect(result, targetEvent.toETEvent());
        verify(() =>
                mockCalendarApi.createReminder(reminder: 10 * 60, eventId: '1'))
            .called(1);
      });

      test('createReminder throws an exception when API fails', () async {
        // Given
        when(() => mockCalendarApi.createReminder(
            reminder: any(named: 'reminder'),
            eventId: any(named: 'eventId'))).thenThrow(Exception('API Error'));

        // When
        Future<ETEvent> call() => eventide.createReminder(
              durationBeforeEvent: const Duration(minutes: 10),
              eventId: '1',
            );

        // Then
        expect(call, throwsException);
        verify(() =>
                mockCalendarApi.createReminder(reminder: 10 * 60, eventId: '1'))
            .called(1);
      });

      test('deleteReminder returns an ETEvent', () async {
        // Given
        final targetEvent = Event(
          id: '1',
          title: 'Test Event',
          isAllDay: false,
          startDate: startDate.millisecondsSinceEpoch,
          endDate: endDate.millisecondsSinceEpoch,
          calendarId: '1',
        );

        when(() => mockCalendarApi.deleteReminder(
                reminder: any(named: 'reminder'),
                eventId: any(named: 'eventId')))
            .thenAnswer((_) async => targetEvent);

        // When
        final result = await eventide.deleteReminder(
          durationBeforeEvent: const Duration(minutes: 10),
          eventId: '1',
        );

        // Then
        expect(result, targetEvent.toETEvent());
        verify(() =>
                mockCalendarApi.deleteReminder(reminder: 10 * 60, eventId: '1'))
            .called(1);
      });

      test('deleteReminder throws an exception when API fails', () async {
        // Given
        when(() => mockCalendarApi.deleteReminder(
            reminder: any(named: 'reminder'),
            eventId: any(named: 'eventId'))).thenThrow(Exception('API Error'));

        // When
        Future<ETEvent> call() => eventide.deleteReminder(
              durationBeforeEvent: const Duration(minutes: 10),
              eventId: '1',
            );

        // Then
        expect(call, throwsException);
        verify(() =>
                mockCalendarApi.deleteReminder(reminder: 10 * 60, eventId: '1'))
            .called(1);
      });
    });

    group('Android', () {
      setUpAll(() {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
      });

      tearDownAll(() {
        debugDefaultTargetPlatformOverride = null;
      });

      test('createReminder returns an ETEvent', () async {
        // Given
        final targetEvent = Event(
          id: '1',
          title: 'Test Event',
          isAllDay: false,
          startDate: startDate.millisecondsSinceEpoch,
          endDate: endDate.millisecondsSinceEpoch,
          calendarId: '1',
          reminders: [10 * 60],
        );

        when(() => mockCalendarApi.createReminder(
                reminder: any(named: 'reminder'),
                eventId: any(named: 'eventId')))
            .thenAnswer((_) async => targetEvent);

        // When
        final result = await eventide.createReminder(
          durationBeforeEvent: const Duration(minutes: 10),
          eventId: '1',
        );

        // Then
        expect(result, targetEvent.toETEvent());
        verify(() => mockCalendarApi.createReminder(reminder: 10, eventId: '1'))
            .called(1);
      });

      test('createReminder throws an exception when API fails', () async {
        // Given
        when(() => mockCalendarApi.createReminder(
            reminder: any(named: 'reminder'),
            eventId: any(named: 'eventId'))).thenThrow(Exception('API Error'));

        // When
        Future<ETEvent> call() => eventide.createReminder(
              durationBeforeEvent: const Duration(minutes: 10),
              eventId: '1',
            );

        // Then
        expect(call, throwsException);
        verify(() => mockCalendarApi.createReminder(reminder: 10, eventId: '1'))
            .called(1);
      });

      test('deleteReminder returns an ETEvent', () async {
        // Given
        final targetEvent = Event(
          id: '1',
          title: 'Test Event',
          isAllDay: false,
          startDate: startDate.millisecondsSinceEpoch,
          endDate: endDate.millisecondsSinceEpoch,
          calendarId: '1',
        );

        when(() => mockCalendarApi.deleteReminder(
                reminder: any(named: 'reminder'),
                eventId: any(named: 'eventId')))
            .thenAnswer((_) async => targetEvent);

        // When
        final result = await eventide.deleteReminder(
          durationBeforeEvent: const Duration(minutes: 10),
          eventId: '1',
        );

        // Then
        expect(result, targetEvent.toETEvent());
        verify(() => mockCalendarApi.deleteReminder(reminder: 10, eventId: '1'))
            .called(1);
      });

      test('deleteReminder throws an exception when API fails', () async {
        // Given
        when(() => mockCalendarApi.deleteReminder(
            reminder: any(named: 'reminder'),
            eventId: any(named: 'eventId'))).thenThrow(Exception('API Error'));

        // When
        Future<ETEvent> call() => eventide.deleteReminder(
              durationBeforeEvent: const Duration(minutes: 10),
              eventId: '1',
            );

        // Then
        expect(call, throwsException);
        verify(() => mockCalendarApi.deleteReminder(reminder: 10, eventId: '1'))
            .called(1);
      });
    });
  });
}

extension on Event {
  Event copyWithReminders(List<int> reminders) {
    return Event(
      id: id,
      title: title,
      isAllDay: isAllDay,
      startDate: startDate,
      endDate: endDate,
      calendarId: calendarId,
      description: description,
      url: url,
      reminders: reminders,
    );
  }
}
