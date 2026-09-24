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
    originalInstanceTime: startDate.toUtc().millisecondsSinceEpoch,
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
    test('forwards thisEvent span and originalInstanceTime', () async {
      when(
        () => mockCalendarApi.deleteEvent(
          eventId: any(named: 'eventId'),
          span: any(named: 'span'),
          originalInstanceTime: any(named: 'originalInstanceTime'),
        ),
      ).thenAnswer((_) async {});

      await eventide.deleteEvent(eventId: 'master1', span: ETSpan.thisEvent, originalInstanceTime: startDate);

      verify(
        () => mockCalendarApi.deleteEvent(
          eventId: 'master1',
          span: 'thisEvent',
          originalInstanceTime: startDate.toUtc().millisecondsSinceEpoch,
        ),
      ).called(1);
    });

    test('forwards allEvents span with null originalInstanceTime', () async {
      when(
        () => mockCalendarApi.deleteEvent(
          eventId: any(named: 'eventId'),
          span: any(named: 'span'),
          originalInstanceTime: any(named: 'originalInstanceTime'),
        ),
      ).thenAnswer((_) async {});

      await eventide.deleteEvent(eventId: 'master1', span: ETSpan.allEvents);

      verify(
        () => mockCalendarApi.deleteEvent(eventId: 'master1', span: 'allEvents', originalInstanceTime: null),
      ).called(1);
    });

    test('forwards thisAndFuture span', () async {
      when(
        () => mockCalendarApi.deleteEvent(
          eventId: any(named: 'eventId'),
          span: any(named: 'span'),
          originalInstanceTime: any(named: 'originalInstanceTime'),
        ),
      ).thenAnswer((_) async {});

      await eventide.deleteEvent(eventId: 'master1', span: ETSpan.thisAndFuture, originalInstanceTime: startDate);

      verify(
        () => mockCalendarApi.deleteEvent(
          eventId: 'master1',
          span: 'thisAndFuture',
          originalInstanceTime: startDate.toUtc().millisecondsSinceEpoch,
        ),
      ).called(1);
    });
  });
}
