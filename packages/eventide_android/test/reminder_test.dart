import 'package:clock/clock.dart';
import 'package:eventide_platform_interface/eventide_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:eventide_android/eventide_android.dart';
import 'package:eventide_android/src/calendar_api.g.dart';
import 'package:eventide_android/src/extensions/event_extensions.dart';

class _MockCalendarApi extends Mock implements CalendarApi {}

void main() {
  late _MockCalendarApi mockCalendarApi;
  late EventideAndroid eventide;
  final startDate = Clock.fixed(DateTime(2025, 3, 1, 10, 0)).now();
  final endDate = startDate.add(const Duration(hours: 1));

  setUp(() {
    mockCalendarApi = _MockCalendarApi();
    eventide = EventideAndroid(calendarApi: mockCalendarApi);
  });

  test('createReminder sends minutes and returns an ETEvent', () async {
    final targetEvent = Event(
      id: '1',
      title: 'Test Event',
      isAllDay: false,
      startDate: startDate.millisecondsSinceEpoch,
      endDate: endDate.millisecondsSinceEpoch,
      calendarId: '1',
      reminders: [10],
      attendees: [],
    );

    when(
      () => mockCalendarApi.createReminder(
        reminder: any(named: 'reminder'),
        eventId: any(named: 'eventId'),
        span: any(named: 'span'),
        originalInstanceDate: any(named: 'originalInstanceDate'),
      ),
    ).thenAnswer((_) async => targetEvent);

    final result = await eventide.createReminder(durationBeforeEvent: const Duration(minutes: 10), eventId: '1');

    expect(result, targetEvent.toETEvent());
    verify(
      () =>
          mockCalendarApi.createReminder(reminder: 10, eventId: '1', span: Span.thisEvent, originalInstanceDate: null),
    ).called(1);
  });

  test('deleteReminder sends minutes and returns an ETEvent', () async {
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
      () => mockCalendarApi.deleteReminder(
        reminder: any(named: 'reminder'),
        eventId: any(named: 'eventId'),
        span: any(named: 'span'),
        originalInstanceDate: any(named: 'originalInstanceDate'),
      ),
    ).thenAnswer((_) async => targetEvent);

    final result = await eventide.deleteReminder(durationBeforeEvent: const Duration(minutes: 10), eventId: '1');

    expect(result, targetEvent.toETEvent());
    verify(
      () =>
          mockCalendarApi.deleteReminder(reminder: 10, eventId: '1', span: Span.thisEvent, originalInstanceDate: null),
    ).called(1);
  });

  test('createReminder throws when API fails', () async {
    when(
      () => mockCalendarApi.createReminder(
        reminder: any(named: 'reminder'),
        eventId: any(named: 'eventId'),
        span: any(named: 'span'),
        originalInstanceDate: any(named: 'originalInstanceDate'),
      ),
    ).thenThrow(const ETGenericException(message: 'API Error'));

    expect(
      () => eventide.createReminder(durationBeforeEvent: const Duration(minutes: 10), eventId: '1'),
      throwsException,
    );
  });
}
