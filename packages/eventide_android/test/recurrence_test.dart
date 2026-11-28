import 'package:eventide_platform_interface/eventide_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:eventide_android/eventide_android.dart';
import 'package:eventide_android/src/calendar_api.g.dart';

class _MockCalendarApi extends Mock implements CalendarApi {}

void main() {
  late _MockCalendarApi mockCalendarApi;
  late EventideAndroid eventide;

  final startDate = DateTime(2026, 7, 7, 9, 0);
  final endDate = DateTime(2026, 7, 7, 9, 30);

  final baseEvent = Event(
    id: 'master1',
    title: 'Standup',
    isAllDay: false,
    startDate: startDate.toUtc().millisecondsSinceEpoch,
    endDate: endDate.toUtc().millisecondsSinceEpoch,
    calendarId: 'cal1',
    reminders: [],
    attendees: [],
    recurrenceRule: 'FREQ=WEEKLY;BYDAY=MO',
    originalInstanceDate: startDate.toUtc().millisecondsSinceEpoch,
  );

  setUp(() {
    mockCalendarApi = _MockCalendarApi();
    eventide = EventideAndroid(calendarApi: mockCalendarApi);
    registerFallbackValue(baseEvent);
  });

  test('createEvent forwards recurrenceRule to CalendarApi', () async {
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
    ).thenAnswer((_) async => baseEvent);

    await eventide.createEvent(
      calendarId: 'cal1',
      title: 'Standup',
      startDate: startDate,
      endDate: endDate,
      recurrenceRule: 'FREQ=WEEKLY;BYDAY=MO',
    );

    verify(
      () => mockCalendarApi.createEvent(
        calendarId: 'cal1',
        title: 'Standup',
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
        isAllDay: false,
        description: null,
        url: null,
        location: null,
        reminders: null,
        recurrenceRule: 'FREQ=WEEKLY;BYDAY=MO',
      ),
    ).called(1);
  });

  test('deleteEvent forwards span and originalInstanceDate', () async {
    when(
      () => mockCalendarApi.deleteEvent(
        eventId: any(named: 'eventId'),
        span: any(named: 'span'),
        originalInstanceDate: any(named: 'originalInstanceDate'),
      ),
    ).thenAnswer((_) async {});

    await eventide.deleteEvent(eventId: 'master1', span: ETSpan.thisAndFuture, originalInstanceDate: startDate);

    verify(
      () => mockCalendarApi.deleteEvent(
        eventId: 'master1',
        span: Span.thisAndFuture,
        originalInstanceDate: startDate.toUtc().millisecondsSinceEpoch,
      ),
    ).called(1);
  });

  test('createAttendee and deleteAttendee forward span and originalInstanceDate', () async {
    when(
      () => mockCalendarApi.createAttendee(
        eventId: any(named: 'eventId'),
        name: any(named: 'name'),
        email: any(named: 'email'),
        role: any(named: 'role'),
        type: any(named: 'type'),
        span: any(named: 'span'),
        originalInstanceDate: any(named: 'originalInstanceDate'),
      ),
    ).thenAnswer((_) async => baseEvent);

    when(
      () => mockCalendarApi.deleteAttendee(
        eventId: any(named: 'eventId'),
        email: any(named: 'email'),
        span: any(named: 'span'),
        originalInstanceDate: any(named: 'originalInstanceDate'),
      ),
    ).thenAnswer((_) async => baseEvent);

    await eventide.createAttendee(
      eventId: 'master1',
      name: 'Jane',
      email: 'jane@example.com',
      type: ETAttendeeType.requiredPerson,
      span: ETSpan.thisEvent,
      originalInstanceDate: startDate,
    );

    await eventide.deleteAttendee(
      eventId: 'master1',
      attendee: const ETAttendee(
        name: 'Jane',
        email: 'jane@example.com',
        type: ETAttendeeType.requiredPerson,
        status: ETAttendanceStatus.accepted,
      ),
      span: ETSpan.thisAndFuture,
      originalInstanceDate: startDate,
    );

    verify(
      () => mockCalendarApi.createAttendee(
        eventId: 'master1',
        name: 'Jane',
        email: 'jane@example.com',
        role: 1,
        type: 1,
        span: Span.thisEvent,
        originalInstanceDate: startDate.toUtc().millisecondsSinceEpoch,
      ),
    ).called(1);

    verify(
      () => mockCalendarApi.deleteAttendee(
        eventId: 'master1',
        email: 'jane@example.com',
        span: Span.thisAndFuture,
        originalInstanceDate: startDate.toUtc().millisecondsSinceEpoch,
      ),
    ).called(1);
  });
}
