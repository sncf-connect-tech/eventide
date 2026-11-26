import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:eventide/eventide.dart';
import 'package:eventide/src/calendar_api.g.dart';

class _MockCalendarApi extends Mock implements CalendarApi {}

void main() {
  late _MockCalendarApi mockCalendarApi;
  late Eventide eventide;

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
    description: null,
    url: null,
    location: null,
    recurrenceRule: 'FREQ=WEEKLY;BYDAY=MO',
    originalInstanceDate: startDate.toUtc().millisecondsSinceEpoch,
  );

  setUp(() {
    mockCalendarApi = _MockCalendarApi();
    eventide = Eventide(calendarApi: mockCalendarApi);
    registerFallbackValue(baseEvent);
  });

  group('createEvent with recurrenceRule', () {
    test('forwards recurrenceRule to CalendarApi', () async {
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
  });

  group('deleteEvent with span', () {
    test('forwards thisEvent span and originalInstanceDate', () async {
      when(
        () => mockCalendarApi.deleteEvent(
          eventId: any(named: 'eventId'),
          span: any(named: 'span'),
          originalInstanceDate: any(named: 'originalInstanceDate'),
        ),
      ).thenAnswer((_) async {});

      await eventide.deleteEvent(eventId: 'master1', span: .thisEvent, originalInstanceDate: startDate);

      verify(
        () => mockCalendarApi.deleteEvent(
          eventId: 'master1',
          span: .thisEvent,
          originalInstanceDate: startDate.toUtc().millisecondsSinceEpoch,
        ),
      ).called(1);
    });

    test('forwards thisAndFuture span', () async {
      when(
        () => mockCalendarApi.deleteEvent(
          eventId: any(named: 'eventId'),
          span: any(named: 'span'),
          originalInstanceDate: any(named: 'originalInstanceDate'),
        ),
      ).thenAnswer((_) async {});

      await eventide.deleteEvent(eventId: 'master1', span: .thisAndFuture, originalInstanceDate: startDate);

      verify(
        () => mockCalendarApi.deleteEvent(
          eventId: 'master1',
          span: .thisAndFuture,
          originalInstanceDate: startDate.toUtc().millisecondsSinceEpoch,
        ),
      ).called(1);
    });
  });

  group('reminder and attendee recurrence forwarding', () {
    test('createReminder forwards span and originalInstanceDate', () async {
      when(
        () => mockCalendarApi.createReminder(
          reminder: any(named: 'reminder'),
          eventId: any(named: 'eventId'),
          span: any(named: 'span'),
          originalInstanceDate: any(named: 'originalInstanceDate'),
        ),
      ).thenAnswer((_) async => baseEvent);

      await eventide.createReminder(
        eventId: 'master1',
        durationBeforeEvent: const Duration(minutes: 15),
        span: ETSpan.thisEvent,
        originalInstanceDate: startDate,
      );

      verify(
        () => mockCalendarApi.createReminder(
          reminder: any(named: 'reminder'),
          eventId: 'master1',
          span: Span.thisEvent,
          originalInstanceDate: startDate.toUtc().millisecondsSinceEpoch,
        ),
      ).called(1);
    });

    test('deleteReminder forwards span and originalInstanceDate', () async {
      when(
        () => mockCalendarApi.deleteReminder(
          reminder: any(named: 'reminder'),
          eventId: any(named: 'eventId'),
          span: any(named: 'span'),
          originalInstanceDate: any(named: 'originalInstanceDate'),
        ),
      ).thenAnswer((_) async => baseEvent);

      await eventide.deleteReminder(
        eventId: 'master1',
        durationBeforeEvent: const Duration(minutes: 15),
        span: ETSpan.thisAndFuture,
        originalInstanceDate: startDate,
      );

      verify(
        () => mockCalendarApi.deleteReminder(
          reminder: any(named: 'reminder'),
          eventId: 'master1',
          span: Span.thisAndFuture,
          originalInstanceDate: startDate.toUtc().millisecondsSinceEpoch,
        ),
      ).called(1);
    });

    test('createAttendee forwards span and originalInstanceDate', () async {
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

      await eventide.createAttendee(
        eventId: 'master1',
        name: 'Jane',
        email: 'jane@example.com',
        type: ETAttendeeType.requiredPerson,
        span: ETSpan.thisEvent,
        originalInstanceDate: startDate,
      );

      verify(
        () => mockCalendarApi.createAttendee(
          eventId: 'master1',
          name: 'Jane',
          email: 'jane@example.com',
          role: any(named: 'role'),
          type: any(named: 'type'),
          span: Span.thisEvent,
          originalInstanceDate: startDate.toUtc().millisecondsSinceEpoch,
        ),
      ).called(1);
    });

    test('deleteAttendee forwards span and originalInstanceDate', () async {
      when(
        () => mockCalendarApi.deleteAttendee(
          eventId: any(named: 'eventId'),
          email: any(named: 'email'),
          span: any(named: 'span'),
          originalInstanceDate: any(named: 'originalInstanceDate'),
        ),
      ).thenAnswer((_) async => baseEvent);

      await eventide.deleteAttendee(
        eventId: 'master1',
        attendee: ETAttendee(
          name: 'Jane',
          email: 'jane@example.com',
          type: ETAttendeeType.requiredPerson,
          status: ETAttendanceStatus.accepted,
        ),
        span: ETSpan.thisAndFuture,
        originalInstanceDate: startDate,
      );

      verify(
        () => mockCalendarApi.deleteAttendee(
          eventId: 'master1',
          email: 'jane@example.com',
          span: Span.thisAndFuture,
          originalInstanceDate: startDate.toUtc().millisecondsSinceEpoch,
        ),
      ).called(1);
    });
  });
}
