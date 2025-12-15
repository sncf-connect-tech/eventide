import 'package:flutter/foundation.dart';

import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:eventide/eventide.dart';
import 'package:eventide/src/calendar_api.g.dart';
import 'package:eventide/src/extensions/event_extensions.dart';

class _MockCalendarApi extends Mock implements CalendarApi {}

void main() {
  late _MockCalendarApi mockCalendarApi;
  late Eventide eventide;
  final startDate = Clock.fixed(DateTime(2025, 3, 1, 10, 0)).now();
  final endDate = startDate.add(const Duration(hours: 1));

  setUp(() {
    mockCalendarApi = _MockCalendarApi();
    eventide = Eventide(calendarApi: mockCalendarApi);
  });

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
        attendees: [],
      );

      when(
        () => mockCalendarApi.createReminder(reminder: any(named: 'reminder'), eventId: any(named: 'eventId')),
      ).thenAnswer((_) async => targetEvent);

      // When
      final result = await eventide.createReminder(durationBeforeEvent: const Duration(minutes: 10), eventId: '1');

      // Then
      expect(result, targetEvent.toETEvent());
      verify(() => mockCalendarApi.createReminder(reminder: 10 * 60, eventId: '1')).called(1);
    });

    test('createReminder throws an exception when API fails', () async {
      // Given
      when(
        () => mockCalendarApi.createReminder(reminder: any(named: 'reminder'), eventId: any(named: 'eventId')),
      ).thenThrow(ETGenericException(message: 'API Error'));

      // When
      Future<ETEvent> call() => eventide.createReminder(durationBeforeEvent: const Duration(minutes: 10), eventId: '1');

      // Then
      expect(call, throwsException);
      verify(() => mockCalendarApi.createReminder(reminder: 10 * 60, eventId: '1')).called(1);
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
        reminders: [],
        attendees: [],
      );

      when(
        () => mockCalendarApi.deleteReminder(reminder: any(named: 'reminder'), eventId: any(named: 'eventId')),
      ).thenAnswer((_) async => targetEvent);

      // When
      final result = await eventide.deleteReminder(durationBeforeEvent: const Duration(minutes: 10), eventId: '1');

      // Then
      expect(result, targetEvent.toETEvent());
      verify(() => mockCalendarApi.deleteReminder(reminder: 10 * 60, eventId: '1')).called(1);
    });

    test('deleteReminder throws an exception when API fails', () async {
      // Given
      when(
        () => mockCalendarApi.deleteReminder(reminder: any(named: 'reminder'), eventId: any(named: 'eventId')),
      ).thenThrow(ETGenericException(message: 'API Error'));

      // When
      Future<ETEvent> call() => eventide.deleteReminder(durationBeforeEvent: const Duration(minutes: 10), eventId: '1');

      // Then
      expect(call, throwsException);
      verify(() => mockCalendarApi.deleteReminder(reminder: 10 * 60, eventId: '1')).called(1);
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
        attendees: [],
      );

      when(
        () => mockCalendarApi.createReminder(reminder: any(named: 'reminder'), eventId: any(named: 'eventId')),
      ).thenAnswer((_) async => targetEvent);

      // When
      final result = await eventide.createReminder(durationBeforeEvent: const Duration(minutes: 10), eventId: '1');

      // Then
      expect(result, targetEvent.toETEvent());
      verify(() => mockCalendarApi.createReminder(reminder: 10, eventId: '1')).called(1);
    });

    test('createReminder throws an exception when API fails', () async {
      // Given
      when(
        () => mockCalendarApi.createReminder(reminder: any(named: 'reminder'), eventId: any(named: 'eventId')),
      ).thenThrow(ETGenericException(message: 'API Error'));

      // When
      Future<ETEvent> call() => eventide.createReminder(durationBeforeEvent: const Duration(minutes: 10), eventId: '1');

      // Then
      expect(call, throwsException);
      verify(() => mockCalendarApi.createReminder(reminder: 10, eventId: '1')).called(1);
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
        reminders: [],
        attendees: [],
      );

      when(
        () => mockCalendarApi.deleteReminder(reminder: any(named: 'reminder'), eventId: any(named: 'eventId')),
      ).thenAnswer((_) async => targetEvent);

      // When
      final result = await eventide.deleteReminder(durationBeforeEvent: const Duration(minutes: 10), eventId: '1');

      // Then
      expect(result, targetEvent.toETEvent());
      verify(() => mockCalendarApi.deleteReminder(reminder: 10, eventId: '1')).called(1);
    });

    test('deleteReminder throws an exception when API fails', () async {
      // Given
      when(
        () => mockCalendarApi.deleteReminder(reminder: any(named: 'reminder'), eventId: any(named: 'eventId')),
      ).thenThrow(ETGenericException(message: 'API Error'));

      // When
      Future<ETEvent> call() => eventide.deleteReminder(durationBeforeEvent: const Duration(minutes: 10), eventId: '1');

      // Then
      expect(call, throwsException);
      verify(() => mockCalendarApi.deleteReminder(reminder: 10, eventId: '1')).called(1);
    });
  });
}
