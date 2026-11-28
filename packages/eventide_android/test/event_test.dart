import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart';

import 'package:eventide_android/eventide_android.dart';
import 'package:eventide_android/src/calendar_api.g.dart';
import 'package:eventide_android/src/extensions/duration_extensions.dart';
import 'package:eventide_android/src/extensions/event_extensions.dart';

class _MockCalendarApi extends Mock implements CalendarApi {}

void main() {
  tz.initializeTimeZones();

  late _MockCalendarApi mockCalendarApi;
  late EventideAndroid eventide;

  setUp(() {
    mockCalendarApi = _MockCalendarApi();
    eventide = EventideAndroid(calendarApi: mockCalendarApi);
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

  test('createEvent with reminders sends minutes', () async {
    const reminders = [Duration(minutes: 10), Duration(minutes: 20)];
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
      calendarId: '1',
      title: 'Test Event',
      startDate: startDate,
      endDate: endDate,
      reminders: reminders,
    );

    expect(result.reminders, equals(reminders));
    verify(
      () => mockCalendarApi.createEvent(
        title: 'Test Event',
        isAllDay: false,
        startDate: startDate.millisecondsSinceEpoch,
        endDate: endDate.millisecondsSinceEpoch,
        calendarId: '1',
        description: null,
        url: null,
        location: null,
        reminders: [10, 20],
        recurrenceRule: null,
      ),
    ).called(1);
  });

  test('createEventInDefaultCalendar sends reminders in minutes', () async {
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
        reminders: [10, 20],
        recurrenceRule: null,
      ),
    ).called(1);
  });

  test('createEventThroughNativePlatform sends reminders in minutes', () async {
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
        reminders: [10],
      ),
    ).called(1);
  });

  test('retrieveEvents returns a list of ETEvents with reminders in minutes', () async {
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

  test('Event.toETEvent maps recurrenceRule, originalInstanceDate and reminders', () {
    final raw = Event(
      id: '1',
      title: 'T',
      isAllDay: false,
      startDate: 0,
      endDate: 3600000,
      calendarId: 'cal1',
      reminders: [10, 20],
      attendees: [],
      recurrenceRule: 'FREQ=WEEKLY;BYDAY=MO',
      originalInstanceDate: 1751788800000,
    );
    final etEvent = raw.toETEvent();
    expect(etEvent.recurrenceRule, equals('FREQ=WEEKLY;BYDAY=MO'));
    expect(etEvent.originalInstanceDate, equals(DateTime.fromMillisecondsSinceEpoch(1751788800000, isUtc: true)));
    expect(etEvent.reminders, [const Duration(minutes: 10), const Duration(minutes: 20)]);
  });
}
