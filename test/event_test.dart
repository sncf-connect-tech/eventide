import 'package:flutter/foundation.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart';

import 'package:eventide/eventide.dart';
import 'package:eventide/src/calendar_api.g.dart';
import 'package:eventide/src/extensions/duration_extensions.dart';
import 'package:eventide/src/extensions/event_extensions.dart';

class _MockCalendarApi extends Mock implements CalendarApi {}

void main() {
  tz.initializeTimeZones();

  late _MockCalendarApi mockCalendarApi;
  late Eventide eventide;

  setUp(() {
    mockCalendarApi = _MockCalendarApi();
    eventide = Eventide(calendarApi: mockCalendarApi);
  });

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
    attendees: [],
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
      reminders: [],
      attendees: [],
    );

    when(() => mockCalendarApi.createEvent(
          title: any(named: 'title'),
          isAllDay: any(named: 'isAllDay'),
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          calendarId: any(named: 'calendarId'),
          description: any(named: 'description'),
          url: any(named: 'url'),
          rRule: any(named: 'rRule'),
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
          rRule: any(named: 'rRule'),
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
          rRule: any(named: 'rRule'),
        )).thenThrow(ETGenericException(message: 'API Error'));

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
          rRule: any(named: 'rRule'),
        )).called(1);
  });

  group('iOS tests', () {
    setUpAll(() {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    });

    tearDownAll(() {
      debugDefaultTargetPlatformOverride = null;
    });

    test('createEvent with reminders returns an ECEvent with reminders', () async {
      // Given
      const reminders = [Duration(minutes: 10), Duration(minutes: 20)];
      when(() => mockCalendarApi.createEvent(
            title: any(named: 'title'),
            isAllDay: any(named: 'isAllDay'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
            calendarId: any(named: 'calendarId'),
            description: any(named: 'description'),
            url: any(named: 'url'),
            rRule: any(named: 'rRule'),
          )).thenAnswer((_) async => event);
      when(() => mockCalendarApi.createReminder(reminder: any(named: 'reminder'), eventId: any(named: 'eventId')))
          .thenAnswer((_) async => event.copyWithReminders(reminders.toNativeList()));

      // When
      final result = await eventide.createEvent(
        title: 'Test Event',
        startDate: startDate,
        endDate: endDate,
        calendarId: '1',
        reminders: reminders,
      );

      // Then
      expect(result.reminders, equals(reminders));
      verify(() => mockCalendarApi.createEvent(
            title: any(named: 'title'),
            isAllDay: any(named: 'isAllDay'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
            calendarId: any(named: 'calendarId'),
            description: any(named: 'description'),
            url: any(named: 'url'),
            rRule: any(named: 'rRule'),
          )).called(1);
      verify(() => mockCalendarApi.createReminder(reminder: 10 * 60, eventId: event.id)).called(1);
      verify(() => mockCalendarApi.createReminder(reminder: 20 * 60, eventId: event.id)).called(1);
    });
  });

  group('Android tests', () {
    setUpAll(() {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
    });

    tearDownAll(() {
      debugDefaultTargetPlatformOverride = null;
    });

    test('createEvent with reminders returns an ECEvent with reminders', () async {
      // Given
      const reminders = [Duration(minutes: 10), Duration(minutes: 20)];
      when(() => mockCalendarApi.createEvent(
            title: any(named: 'title'),
            isAllDay: any(named: 'isAllDay'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
            calendarId: any(named: 'calendarId'),
            description: any(named: 'description'),
            url: any(named: 'url'),
            rRule: any(named: 'rRule'),
          )).thenAnswer((_) async => event);
      when(() => mockCalendarApi.createReminder(reminder: any(named: 'reminder'), eventId: any(named: 'eventId')))
          .thenAnswer((_) async => event.copyWithReminders(reminders.toNativeList()));

      // When
      final result = await eventide.createEvent(
        title: 'Test Event',
        startDate: startDate,
        endDate: endDate,
        calendarId: '1',
        reminders: reminders,
      );

      // Then
      expect(result.reminders, equals(reminders));
      verify(() => mockCalendarApi.createEvent(
            title: any(named: 'title'),
            isAllDay: any(named: 'isAllDay'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
            calendarId: any(named: 'calendarId'),
            description: any(named: 'description'),
            url: any(named: 'url'),
            rRule: any(named: 'rRule'),
          )).called(1);
      verify(() => mockCalendarApi.createReminder(reminder: 10, eventId: event.id)).called(1);
      verify(() => mockCalendarApi.createReminder(reminder: 20, eventId: event.id)).called(1);
    });
  });

  test('retrieveEvents returns a list of ETEvents with reminders', () async {
    // Given
    const reminders = [Duration(minutes: 10), Duration(minutes: 20)];
    when(() => mockCalendarApi.retrieveEvents(
        calendarId: any(named: 'calendarId'),
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'))).thenAnswer((_) async => [event.copyWithReminders(reminders.toNativeList())]);

    // When
    final result = await eventide.retrieveEvents(calendarId: '1');

    // Then
    expect(result.first.reminders, equals(reminders));
    verify(() => mockCalendarApi.retrieveEvents(
        calendarId: '1', startDate: any(named: 'startDate'), endDate: any(named: 'endDate'))).called(1);
  });

  test('create Event timezone management test: Paris - Montréal flight', () async {
    final parisDeparture = TZDateTime(getLocation('Europe/Paris'), 2025, 9, 8, 13, 30);
    final montrealArrival = TZDateTime(getLocation('America/Montreal'), 2025, 9, 8, 15, 00);
    final utcParisDeparture = parisDeparture.toUtc();
    final utcMontrealArrival = montrealArrival.toUtc();

    final mockEvent = Event(
      id: '1',
      title: 'Paris - Montréal',
      isAllDay: false,
      startDate: utcParisDeparture.millisecondsSinceEpoch,
      endDate: utcMontrealArrival.millisecondsSinceEpoch,
      calendarId: '1',
      reminders: [],
      attendees: [],
    );

    when(() => mockCalendarApi.createEvent(
          calendarId: any(named: 'calendarId'),
          title: any(named: 'title'),
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          isAllDay: any(named: 'isAllDay'),
          description: any(named: 'description'),
          url: any(named: 'url'),
          rRule: any(named: 'rRule'),
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
          rRule: null,
        )).called(1);
  });

  group('EventToETEvent tests', () {
    test('Event toETEvent', () {
      final event = Event(
        id: '1',
        title: 'Test Event',
        isAllDay: false,
        startDate: DateTime(2023, 10, 1).millisecondsSinceEpoch,
        endDate: DateTime(2023, 10, 2).millisecondsSinceEpoch,
        calendarId: '1',
        description: 'Test Description',
        url: 'http://test.com',
        reminders: [10, 20],
        attendees: [],
      );
      final etEvent = event.toETEvent();
      expect(etEvent.id, '1');
      expect(etEvent.title, 'Test Event');
      expect(etEvent.isAllDay, false);
      expect(etEvent.startDate, DateTime(2023, 10, 1));
      expect(etEvent.endDate, DateTime(2023, 10, 2));
      expect(etEvent.calendarId, '1');
      expect(etEvent.description, 'Test Description');
      expect(etEvent.url, 'http://test.com');
      expect(etEvent.reminders, [Duration(minutes: 10), Duration(minutes: 20)]);
    });

    test('List<Event> toETEventList', () {
      final events = [
        Event(
          id: '1',
          title: 'Test Event',
          isAllDay: false,
          startDate: DateTime(2023, 10, 1).millisecondsSinceEpoch,
          endDate: DateTime(2023, 10, 2).millisecondsSinceEpoch,
          calendarId: '1',
          description: 'Test Description',
          url: 'http://test.com',
          reminders: [10, 20],
          attendees: [],
        ),
      ];
      final etEvents = events.toETEventList();
      expect(etEvents.length, 1);
      expect(etEvents.first.id, '1');
    });
  });

  group('ETEventCopy tests', () {
    test('ETEvent copyWithReminders', () {
      final etEvent = ETEvent(
        id: '1',
        title: 'Test Event',
        isAllDay: false,
        startDate: DateTime(2023, 10, 1),
        endDate: DateTime(2023, 10, 2),
        calendarId: '1',
        description: 'Test Description',
        url: 'http://test.com',
        reminders: [Duration(minutes: 10)],
      );
      final copiedEvent = etEvent.copyWithReminders([Duration(minutes: 20)]);
      expect(copiedEvent.reminders, [Duration(minutes: 20)]);
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
      attendees: [],
    );
  }
}
