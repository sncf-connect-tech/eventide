import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart';

import 'package:eventide_ios/eventide_ios.dart';
import 'package:eventide_ios/src/calendar_api.g.dart';
import 'package:eventide_ios/src/extensions/duration_extensions.dart';
import 'package:eventide_ios/src/extensions/event_extensions.dart';

class _MockCalendarApi extends Mock implements CalendarApi {}

void main() {
  tz.initializeTimeZones();

  late _MockCalendarApi mockCalendarApi;
  late EventideIOS eventide;

  setUp(() {
    mockCalendarApi = _MockCalendarApi();
    eventide = EventideIOS(calendarApi: mockCalendarApi);
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
    reminders: [],
    attendees: [],
  );

  setUpAll(() {
    registerFallbackValue(event);
  });

  test('createEvent returns an ETEvent', () async {
    when(
      () => mockCalendarApi.createEvent(
        title: any(named: 'title'),
        isAllDay: any(named: 'isAllDay'),
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
        calendarId: any(named: 'calendarId'),
        description: any(named: 'description'),
        url: any(named: 'url'),
        location: any(named: 'location'),
        reminders: any(named: 'reminders'),
        recurrenceRule: any(named: 'recurrenceRule'),
      ),
    ).thenAnswer((_) async => event);

    final result = await eventide.createEvent(
      title: 'Test Event',
      startDate: startDate,
      endDate: endDate,
      calendarId: '1',
    );

    expect(result, event.toETEvent());
  });

  test('createEventInDefaultCalendar sends reminders in seconds', () async {
    const reminders = [Duration(minutes: 10), Duration(minutes: 20)];
    when(
      () => mockCalendarApi.createEventInDefaultCalendar(
        title: any(named: 'title'),
        isAllDay: any(named: 'isAllDay'),
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
        description: any(named: 'description'),
        url: any(named: 'url'),
        location: any(named: 'location'),
        reminders: any(named: 'reminders'),
        recurrenceRule: any(named: 'recurrenceRule'),
      ),
    ).thenAnswer((_) async {});

    await eventide.createEventInDefaultCalendar(
      title: 'Test Event',
      startDate: startDate,
      endDate: endDate,
      reminders: reminders,
    );

    verify(
      () => mockCalendarApi.createEventInDefaultCalendar(
        title: 'Test Event',
        isAllDay: false,
        startDate: startDate.millisecondsSinceEpoch,
        endDate: endDate.millisecondsSinceEpoch,
        description: null,
        url: null,
        location: null,
        reminders: [10 * 60, 20 * 60],
        recurrenceRule: null,
      ),
    ).called(1);
  });

  test('createEventThroughNativePlatform sends reminders in seconds', () async {
    when(
      () => mockCalendarApi.createEventThroughNativePlatform(
        title: any(named: 'title'),
        isAllDay: any(named: 'isAllDay'),
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
        description: any(named: 'description'),
        url: any(named: 'url'),
        location: any(named: 'location'),
        reminders: any(named: 'reminders'),
        recurrenceRule: any(named: 'recurrenceRule'),
      ),
    ).thenAnswer((_) async {});

    await eventide.createEventThroughNativePlatform(
      title: 'Test Event',
      startDate: startDate,
      endDate: endDate,
      isAllDay: false,
      description: 'Test Description',
      url: 'http://test.com',
      reminders: const [Duration(minutes: 10)],
    );

    verify(
      () => mockCalendarApi.createEventThroughNativePlatform(
        title: 'Test Event',
        isAllDay: false,
        startDate: startDate.millisecondsSinceEpoch,
        endDate: endDate.millisecondsSinceEpoch,
        description: 'Test Description',
        url: 'http://test.com',
        location: null,
        reminders: [600],
      ),
    ).called(1);
  });

  test('retrieveEvents returns a list of ETEvents with reminders', () async {
    const reminders = [Duration(minutes: 10), Duration(minutes: 20)];
    final eventWithReminders = Event(
      id: '1',
      title: 'Test Event',
      isAllDay: false,
      startDate: startDate.millisecondsSinceEpoch,
      endDate: endDate.millisecondsSinceEpoch,
      calendarId: '1',
      reminders: reminders.toNativeList(),
      attendees: [],
    );

    when(
      () => mockCalendarApi.retrieveEvents(
        calendarId: any(named: 'calendarId'),
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
      ),
    ).thenAnswer((_) async => [eventWithReminders]);

    final result = await eventide.retrieveEvents(calendarId: '1');

    expect(result.first.reminders, equals(reminders));
  });

  test('createEvent timezone management: Paris - Montreal flight', () async {
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

    when(
      () => mockCalendarApi.createEvent(
        calendarId: any(named: 'calendarId'),
        title: any(named: 'title'),
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
        isAllDay: any(named: 'isAllDay'),
        description: any(named: 'description'),
        url: any(named: 'url'),
        location: any(named: 'location'),
        reminders: any(named: 'reminders'),
        recurrenceRule: any(named: 'recurrenceRule'),
      ),
    ).thenAnswer((_) async => mockEvent);

    await eventide.createEvent(
      title: 'Paris - Montréal',
      startDate: parisDeparture,
      endDate: montrealArrival,
      calendarId: '1',
    );

    verify(
      () => mockCalendarApi.createEvent(
        calendarId: '1',
        title: 'Paris - Montréal',
        startDate: utcParisDeparture.millisecondsSinceEpoch,
        endDate: utcMontrealArrival.millisecondsSinceEpoch,
        isAllDay: false,
        description: null,
        url: null,
        location: null,
        reminders: null,
        recurrenceRule: any(named: 'recurrenceRule'),
      ),
    ).called(1);
  });

  test('updateEvent calls the API with updated values', () async {
    final originalEvent = Event(
      id: '1',
      title: 'Test Event',
      isAllDay: false,
      startDate: DateTime(2023, 10, 1).millisecondsSinceEpoch,
      endDate: DateTime(2023, 10, 2).millisecondsSinceEpoch,
      calendarId: '19',
      description: 'Test Description',
      url: 'http://test.com',
      reminders: [600, 1200],
      attendees: [],
    );

    when(
      () => mockCalendarApi.updateEvent(
        eventId: any(named: 'eventId'),
        title: any(named: 'title'),
        isAllDay: any(named: 'isAllDay'),
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
        calendarId: any(named: 'calendarId'),
        description: any(named: 'description'),
        url: any(named: 'url'),
        location: any(named: 'location'),
        reminders: any(named: 'reminders'),
        recurrenceRule: any(named: 'recurrenceRule'),
        span: any(named: 'span'),
        originalInstanceDate: any(named: 'originalInstanceDate'),
      ),
    ).thenAnswer((_) async => originalEvent);

    await eventide.updateEvent(originalEvent.toETEvent(), title: 'Updated Test Event');

    verify(
      () => mockCalendarApi.updateEvent(
        eventId: '1',
        title: 'Updated Test Event',
        isAllDay: originalEvent.isAllDay,
        startDate: originalEvent.startDate,
        endDate: originalEvent.endDate,
        calendarId: '19',
        description: originalEvent.description,
        url: originalEvent.url,
        location: originalEvent.location,
        reminders: originalEvent.reminders,
        recurrenceRule: originalEvent.recurrenceRule,
        span: Span.thisEvent,
        originalInstanceDate: null,
      ),
    ).called(1);
  });

  test('Event.toETEvent maps recurrenceRule and originalInstanceDate', () {
    final raw = Event(
      id: '1',
      title: 'T',
      isAllDay: false,
      startDate: 0,
      endDate: 3600000,
      calendarId: 'cal1',
      reminders: [600],
      attendees: [],
      recurrenceRule: 'FREQ=WEEKLY;BYDAY=MO',
      originalInstanceDate: 1751788800000,
    );
    final etEvent = raw.toETEvent();
    expect(etEvent.recurrenceRule, equals('FREQ=WEEKLY;BYDAY=MO'));
    expect(etEvent.originalInstanceDate, equals(DateTime.fromMillisecondsSinceEpoch(1751788800000, isUtc: true)));
    expect(etEvent.reminders, [const Duration(minutes: 10)]);
  });
}
