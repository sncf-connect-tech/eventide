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
    location: null,
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
          location: any(named: 'location'),
          reminders: any(named: 'reminders'),
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
          location: any(named: 'location'),
          reminders: any(named: 'reminders'),
        )).called(1);
  });

  test('createEvent with location returns event with location', () async {
    // Given
    final event = Event(
      id: '1',
      title: 'Test Event',
      isAllDay: false,
      startDate: startDate.millisecondsSinceEpoch,
      endDate: endDate.millisecondsSinceEpoch,
      calendarId: '1',
      location: '1 Place Bellecour, 69002 Lyon',
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
          location: any(named: 'location'),
          reminders: any(named: 'reminders'),
        )).thenAnswer((_) async => event);

    // When
    final result = await eventide.createEvent(
      title: 'Test Event',
      startDate: startDate,
      endDate: endDate,
      calendarId: '1',
      location: '1 Place Bellecour, 69002 Lyon',
    );

    // Then
    expect(result.location, '1 Place Bellecour, 69002 Lyon');
    verify(() => mockCalendarApi.createEvent(
          title: any(named: 'title'),
          isAllDay: any(named: 'isAllDay'),
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          calendarId: any(named: 'calendarId'),
          description: any(named: 'description'),
          url: any(named: 'url'),
          location: '1 Place Bellecour, 69002 Lyon',
          reminders: any(named: 'reminders'),
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
          location: any(named: 'location'),
          reminders: any(named: 'reminders'),
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
          location: any(named: 'location'),
          reminders: any(named: 'reminders'),
        )).called(1);
  });

  test('createEventInDefaultCalendar returns an ETEvent', () async {
    // Given
    final event = Event(
      id: '1',
      title: 'Test Event',
      isAllDay: false,
      startDate: startDate.millisecondsSinceEpoch,
      endDate: endDate.add(const Duration(hours: 1)).millisecondsSinceEpoch,
      calendarId: 'default',
      description: 'Test Description',
      url: 'http://test.com',
      reminders: [],
      attendees: [],
    );

    when(() => mockCalendarApi.createEventInDefaultCalendar(
          title: any(named: 'title'),
          isAllDay: any(named: 'isAllDay'),
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          description: any(named: 'description'),
          url: any(named: 'url'),
          location: any(named: 'location'),
          reminders: any(named: 'reminders'),
        )).thenAnswer((_) async => event);

    // When
    await eventide.createEventInDefaultCalendar(
      title: 'Test Event',
      startDate: startDate,
      endDate: endDate,
      description: 'Test Description',
      url: 'http://test.com',
    );

    // Then
    verify(() => mockCalendarApi.createEventInDefaultCalendar(
          title: 'Test Event',
          isAllDay: false,
          startDate: startDate.millisecondsSinceEpoch,
          endDate: endDate.millisecondsSinceEpoch,
          description: 'Test Description',
          url: 'http://test.com',
          location: null,
          reminders: null,
        )).called(1);
  });

  test('createEventInDefaultCalendar with all day event returns an ETEvent', () async {
    // Given
    final event = Event(
      id: '1',
      title: 'All Day Event',
      isAllDay: true,
      startDate: startDate.millisecondsSinceEpoch,
      endDate: endDate.add(const Duration(hours: 1)).millisecondsSinceEpoch,
      calendarId: 'default',
      reminders: [],
      attendees: [],
    );

    when(() => mockCalendarApi.createEventInDefaultCalendar(
          title: any(named: 'title'),
          isAllDay: any(named: 'isAllDay'),
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          description: any(named: 'description'),
          url: any(named: 'url'),
          location: any(named: 'location'),
          reminders: any(named: 'reminders'),
        )).thenAnswer((_) async => event);

    // When
    await eventide.createEventInDefaultCalendar(
      title: 'All Day Event',
      startDate: startDate,
      endDate: endDate,
      isAllDay: true,
    );

    // Then
    verify(() => mockCalendarApi.createEventInDefaultCalendar(
          title: 'All Day Event',
          isAllDay: true,
          startDate: startDate.millisecondsSinceEpoch,
          endDate: endDate.millisecondsSinceEpoch,
          description: null,
          url: null,
          location: null,
          reminders: null,
        )).called(1);
  });

  test('createEventInDefaultCalendar throws an exception when API fails', () async {
    // Given
    when(() => mockCalendarApi.createEventInDefaultCalendar(
          title: any(named: 'title'),
          isAllDay: any(named: 'isAllDay'),
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          description: any(named: 'description'),
          url: any(named: 'url'),
          location: any(named: 'location'),
          reminders: any(named: 'reminders'),
        )).thenThrow(ETGenericException(message: 'API Error'));

    // When
    Future<void> call() => eventide.createEventInDefaultCalendar(
          title: 'Test Event',
          startDate: startDate,
          endDate: endDate,
        );

    // Then
    expect(call, throwsException);
    verify(() => mockCalendarApi.createEventInDefaultCalendar(
          title: 'Test Event',
          isAllDay: false,
          startDate: startDate.millisecondsSinceEpoch,
          endDate: endDate.millisecondsSinceEpoch,
          description: null,
          url: null,
          location: null,
          reminders: null,
        )).called(1);
  });

  group('iOS tests', () {
    setUpAll(() {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    });

    tearDownAll(() {
      debugDefaultTargetPlatformOverride = null;
    });

    test('createEventInDefaultCalendar with reminders returns an ETEvent with reminders', () async {
      // Given
      const reminders = [Duration(minutes: 10), Duration(minutes: 20)];
      final event = Event(
        id: '1',
        title: 'Test Event',
        isAllDay: false,
        startDate: startDate.millisecondsSinceEpoch,
        endDate: endDate.add(const Duration(hours: 1)).millisecondsSinceEpoch,
        calendarId: 'default',
        reminders: [],
        attendees: [],
      );

      when(() => mockCalendarApi.createEventInDefaultCalendar(
            title: any(named: 'title'),
            isAllDay: any(named: 'isAllDay'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
            description: any(named: 'description'),
            url: any(named: 'url'),
            location: any(named: 'location'),
            reminders: any(named: 'reminders'),
          )).thenAnswer((_) async => event);
      when(() => mockCalendarApi.createReminder(reminder: any(named: 'reminder'), eventId: any(named: 'eventId')))
          .thenAnswer((_) async => event.copyWithReminders(reminders.toNativeList()));

      // When
      await eventide.createEventInDefaultCalendar(
        title: 'Test Event',
        startDate: startDate,
        endDate: endDate,
        reminders: reminders,
      );

      // Then
      verify(() => mockCalendarApi.createEventInDefaultCalendar(
            title: 'Test Event',
            isAllDay: false,
            startDate: startDate.millisecondsSinceEpoch,
            endDate: endDate.millisecondsSinceEpoch,
            description: null,
            url: null,
            location: null,
            reminders: [10 * 60, 20 * 60],
          )).called(1);
    });
  });

  group('Android tests', () {
    setUpAll(() {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
    });

    tearDownAll(() {
      debugDefaultTargetPlatformOverride = null;
    });

    test('createEvent with reminders returns an ETEvent with reminders', () async {
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
            location: any(named: 'location'),
            reminders: any(named: 'reminders'),
          )).thenAnswer((_) async => event);
      when(() => mockCalendarApi.createReminder(reminder: any(named: 'reminder'), eventId: any(named: 'eventId')))
          .thenAnswer((_) async => event.copyWithReminders(reminders.toNativeList()));

      // When
      final result = await eventide.createEvent(
        calendarId: '1',
        title: 'Test Event',
        startDate: startDate,
        endDate: endDate,
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
            location: any(named: 'location'),
            reminders: [10, 20],
          )).called(1);
    });

    test('createEventInDefaultCalendar with reminders returns an ETEvent with reminders', () async {
      // Given
      const reminders = [Duration(minutes: 10), Duration(minutes: 20)];
      final event = Event(
        id: '1',
        title: 'Test Event',
        isAllDay: false,
        startDate: startDate.millisecondsSinceEpoch,
        endDate: endDate.add(const Duration(hours: 1)).millisecondsSinceEpoch,
        calendarId: 'default',
        reminders: [],
        attendees: [],
        location: null,
      );

      when(() => mockCalendarApi.createEventInDefaultCalendar(
            title: any(named: 'title'),
            isAllDay: any(named: 'isAllDay'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
            description: any(named: 'description'),
            url: any(named: 'url'),
            location: any(named: 'location'),
            reminders: any(named: 'reminders'),
          )).thenAnswer((_) async => event);
      when(() => mockCalendarApi.createReminder(reminder: any(named: 'reminder'), eventId: any(named: 'eventId')))
          .thenAnswer((_) async => event.copyWithReminders(reminders.toNativeList()));

      // When
      await eventide.createEventInDefaultCalendar(
        title: 'Test Event',
        startDate: startDate,
        endDate: endDate,
        reminders: reminders,
      );

      // Then
      verify(() => mockCalendarApi.createEventInDefaultCalendar(
            title: 'Test Event',
            isAllDay: false,
            startDate: startDate.millisecondsSinceEpoch,
            endDate: endDate.millisecondsSinceEpoch,
            description: null,
            url: null,
            location: null,
            reminders: [10, 20],
          )).called(1);
    });
  });

  test('createEventThroughNativePlatform creates event with all parameters', () async {
    // Given
    when(() => mockCalendarApi.createEventThroughNativePlatform(
          title: any(named: 'title'),
          isAllDay: any(named: 'isAllDay'),
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          description: any(named: 'description'),
          url: any(named: 'url'),
          location: any(named: 'location'),
          reminders: any(named: 'reminders'),
        )).thenAnswer((_) async {});

    // When
    await eventide.createEventThroughNativePlatform(
      title: 'Test Event',
      startDate: startDate,
      endDate: endDate,
      isAllDay: false,
      description: 'Test Description',
      url: 'http://test.com',
      reminders: [Duration(minutes: 10)],
    );

    // Then
    verify(() => mockCalendarApi.createEventThroughNativePlatform(
          title: 'Test Event',
          isAllDay: false,
          startDate: startDate.millisecondsSinceEpoch,
          endDate: endDate.millisecondsSinceEpoch,
          description: 'Test Description',
          url: 'http://test.com',
          location: null,
          reminders: [10],
        )).called(1);
  });

  test('createEventThroughNativePlatform creates event with minimal parameters', () async {
    // Given
    when(() => mockCalendarApi.createEventThroughNativePlatform(
          title: any(named: 'title'),
          isAllDay: any(named: 'isAllDay'),
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          description: any(named: 'description'),
          url: any(named: 'url'),
          location: any(named: 'location'),
          reminders: any(named: 'reminders'),
        )).thenAnswer((_) async {});

    // When
    await eventide.createEventThroughNativePlatform();

    // Then
    verify(() => mockCalendarApi.createEventThroughNativePlatform(
          title: null,
          isAllDay: null,
          startDate: null,
          endDate: null,
          description: null,
          url: null,
          location: null,
          reminders: null,
        )).called(1);
  });

  test('createEventThroughNativePlatform throws ETPresentationException when API fails with presentation error',
      () async {
    // Given
    when(() => mockCalendarApi.createEventThroughNativePlatform(
          title: any(named: 'title'),
          isAllDay: any(named: 'isAllDay'),
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          description: any(named: 'description'),
          url: any(named: 'url'),
          location: any(named: 'location'),
          reminders: any(named: 'reminders'),
        )).thenThrow(ETPresentationException(message: 'Presentation Error'));

    // When
    Future<void> call() => eventide.createEventThroughNativePlatform(
          title: 'Test Event',
          startDate: startDate,
          endDate: endDate,
        );

    // Then
    expect(call, throwsException);
    verify(() => mockCalendarApi.createEventThroughNativePlatform(
          title: 'Test Event',
          isAllDay: null,
          startDate: startDate.millisecondsSinceEpoch,
          endDate: endDate.millisecondsSinceEpoch,
          description: null,
          url: null,
          location: null,
          reminders: null,
        )).called(1);
  });

  test('createEventThroughNativePlatform throws ETUserCanceledException when user cancels', () async {
    // Given
    when(() => mockCalendarApi.createEventThroughNativePlatform(
          title: any(named: 'title'),
          isAllDay: any(named: 'isAllDay'),
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          description: any(named: 'description'),
          url: any(named: 'url'),
          location: any(named: 'location'),
          reminders: any(named: 'reminders'),
        )).thenThrow(ETUserCanceledException(message: 'User Cancelled'));

    // When
    Future<void> call() => eventide.createEventThroughNativePlatform(
          title: 'Test Event',
          startDate: startDate,
          endDate: endDate,
        );

    // Then
    expect(call, throwsException);
    verify(() => mockCalendarApi.createEventThroughNativePlatform(
          title: 'Test Event',
          isAllDay: null,
          startDate: startDate.millisecondsSinceEpoch,
          endDate: endDate.millisecondsSinceEpoch,
          description: null,
          url: null,
          location: null,
          reminders: null,
        )).called(1);
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
      location: null,
    );

    when(() => mockCalendarApi.createEvent(
          calendarId: any(named: 'calendarId'),
          title: any(named: 'title'),
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          isAllDay: any(named: 'isAllDay'),
          description: any(named: 'description'),
          url: any(named: 'url'),
          location: any(named: 'location'),
          reminders: any(named: 'reminders'),
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
          location: null,
          reminders: null,
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

    test('Event toETEvent with location', () {
      final event = Event(
        id: '1',
        title: 'Test Event',
        isAllDay: false,
        startDate: DateTime(2023, 10, 1).millisecondsSinceEpoch,
        endDate: DateTime(2023, 10, 2).millisecondsSinceEpoch,
        calendarId: '1',
        description: 'Test Description',
        url: 'http://test.com',
        location: '1 Place Bellecour, 69002 Lyon',
        reminders: [10, 20],
        attendees: [],
      );
      final etEvent = event.toETEvent();
      expect(etEvent.location, '1 Place Bellecour, 69002 Lyon');
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
      location: location,
      reminders: reminders,
      attendees: [],
    );
  }
}
