import 'dart:ui';

import 'package:eventide_platform_interface/eventide_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:eventide/eventide.dart';

class _MockEventidePlatformInterface extends Mock
    with MockPlatformInterfaceMixin
    implements EventidePlatformInterface {}

void main() {
  late _MockEventidePlatformInterface mockPlatform;
  const eventide = Eventide();

  const account = ETAccount(id: '1', name: 'Local', type: 'local');
  const calendar = ETCalendar(id: 'cal1', title: 'Work', color: Color(0xFF0000FF), isWritable: true, account: account);
  final startDate = DateTime(2026, 7, 7, 9, 0);
  final endDate = DateTime(2026, 7, 7, 10, 0);
  final event = ETEvent(
    id: 'ev1',
    title: 'Meeting',
    isAllDay: false,
    startDate: startDate,
    endDate: endDate,
    calendarId: 'cal1',
  );
  const attendee = ETAttendee(
    name: 'John Doe',
    email: 'john@example.com',
    type: ETAttendeeType.requiredPerson,
    status: ETAttendanceStatus.accepted,
  );

  setUp(() {
    mockPlatform = _MockEventidePlatformInterface();
    EventidePlatformInterface.instance = mockPlatform;
  });

  test('delegates createCalendar to EventidePlatformInterface.instance', () async {
    when(() => mockPlatform.createCalendar(title: 'Work', color: const Color(0xFF0000FF), account: account))
        .thenAnswer((_) async => calendar);

    final result = await eventide.createCalendar(title: 'Work', color: const Color(0xFF0000FF), account: account);

    expect(result, calendar);
    verify(() => mockPlatform.createCalendar(title: 'Work', color: const Color(0xFF0000FF), account: account))
        .called(1);
  });

  test('delegates retrieveCalendars to EventidePlatformInterface.instance', () async {
    when(() => mockPlatform.retrieveCalendars(onlyWritableCalendars: false, account: account))
        .thenAnswer((_) async => [calendar]);

    final result = await eventide.retrieveCalendars(onlyWritableCalendars: false, account: account);

    expect(result, [calendar]);
    verify(() => mockPlatform.retrieveCalendars(onlyWritableCalendars: false, account: account)).called(1);
  });

  test('delegates retrieveAccounts to EventidePlatformInterface.instance', () async {
    when(() => mockPlatform.retrieveAccounts()).thenAnswer((_) async => [account]);

    final result = await eventide.retrieveAccounts();

    expect(result, [account]);
    verify(() => mockPlatform.retrieveAccounts()).called(1);
  });

  test('delegates updateCalendar to EventidePlatformInterface.instance', () async {
    when(() => mockPlatform.updateCalendar(calendar, title: 'Updated', color: const Color(0xFF00FF00)))
        .thenAnswer((_) async => calendar);

    final result = await eventide.updateCalendar(calendar, title: 'Updated', color: const Color(0xFF00FF00));

    expect(result, calendar);
    verify(() => mockPlatform.updateCalendar(calendar, title: 'Updated', color: const Color(0xFF00FF00))).called(1);
  });

  test('delegates deleteCalendar to EventidePlatformInterface.instance', () async {
    when(() => mockPlatform.deleteCalendar(calendarId: 'cal1')).thenAnswer((_) async {});

    await eventide.deleteCalendar(calendarId: 'cal1');

    verify(() => mockPlatform.deleteCalendar(calendarId: 'cal1')).called(1);
  });

  test('delegates createEvent to EventidePlatformInterface.instance', () async {
    when(
      () => mockPlatform.createEvent(
        calendarId: 'cal1',
        title: 'Meeting',
        startDate: startDate,
        endDate: endDate,
        isAllDay: false,
        description: null,
        url: null,
        location: null,
        reminders: null,
        recurrenceRule: null,
      ),
    ).thenAnswer((_) async => event);

    final result = await eventide.createEvent(
      calendarId: 'cal1',
      title: 'Meeting',
      startDate: startDate,
      endDate: endDate,
    );

    expect(result, event);
  });

  test('delegates createEventInDefaultCalendar to EventidePlatformInterface.instance', () async {
    when(
      () => mockPlatform.createEventInDefaultCalendar(
        title: 'Meeting',
        startDate: startDate,
        endDate: endDate,
        isAllDay: false,
        description: null,
        url: null,
        location: null,
        reminders: null,
        recurrenceRule: null,
      ),
    ).thenAnswer((_) async {});

    await eventide.createEventInDefaultCalendar(title: 'Meeting', startDate: startDate, endDate: endDate);

    verify(
      () => mockPlatform.createEventInDefaultCalendar(
        title: 'Meeting',
        startDate: startDate,
        endDate: endDate,
        isAllDay: false,
        description: null,
        url: null,
        location: null,
        reminders: null,
        recurrenceRule: null,
      ),
    ).called(1);
  });

  test('delegates createEventThroughNativePlatform to EventidePlatformInterface.instance', () async {
    when(
      () => mockPlatform.createEventThroughNativePlatform(
        title: 'Meeting',
        startDate: null,
        endDate: null,
        isAllDay: null,
        description: null,
        url: null,
        location: null,
        reminders: null,
        recurrenceRule: null,
      ),
    ).thenAnswer((_) async {});

    await eventide.createEventThroughNativePlatform(title: 'Meeting');

    verify(
      () => mockPlatform.createEventThroughNativePlatform(
        title: 'Meeting',
        startDate: null,
        endDate: null,
        isAllDay: null,
        description: null,
        url: null,
        location: null,
        reminders: null,
        recurrenceRule: null,
      ),
    ).called(1);
  });

  test('delegates retrieveEvents to EventidePlatformInterface.instance', () async {
    when(() => mockPlatform.retrieveEvents(calendarId: 'cal1', startDate: startDate, endDate: endDate))
        .thenAnswer((_) async => [event]);

    final result = await eventide.retrieveEvents(calendarId: 'cal1', startDate: startDate, endDate: endDate);

    expect(result, [event]);
  });

  test('delegates updateEvent to EventidePlatformInterface.instance', () async {
    when(
      () => mockPlatform.updateEvent(
        event,
        calendarId: null,
        title: 'Updated',
        startDate: null,
        endDate: null,
        isAllDay: null,
        description: null,
        url: null,
        location: null,
        reminders: null,
        recurrenceRule: null,
        span: ETSpan.thisAndFuture,
        originalInstanceDate: startDate,
      ),
    ).thenAnswer((_) async => event);

    final result = await eventide.updateEvent(
      event,
      title: 'Updated',
      span: ETSpan.thisAndFuture,
      originalInstanceDate: startDate,
    );

    expect(result, event);
  });

  test('delegates deleteEvent to EventidePlatformInterface.instance', () async {
    when(() => mockPlatform.deleteEvent(eventId: 'ev1', span: ETSpan.thisEvent, originalInstanceDate: null))
        .thenAnswer((_) async {});

    await eventide.deleteEvent(eventId: 'ev1');

    verify(() => mockPlatform.deleteEvent(eventId: 'ev1', span: ETSpan.thisEvent, originalInstanceDate: null))
        .called(1);
  });

  test('delegates createReminder and deleteReminder to EventidePlatformInterface.instance', () async {
    when(
      () => mockPlatform.createReminder(
        eventId: 'ev1',
        durationBeforeEvent: const Duration(minutes: 10),
        span: ETSpan.thisEvent,
        originalInstanceDate: null,
      ),
    ).thenAnswer((_) async => event);

    when(
      () => mockPlatform.deleteReminder(
        eventId: 'ev1',
        durationBeforeEvent: const Duration(minutes: 10),
        span: ETSpan.thisEvent,
        originalInstanceDate: null,
      ),
    ).thenAnswer((_) async => event);

    expect(await eventide.createReminder(eventId: 'ev1', durationBeforeEvent: const Duration(minutes: 10)), event);
    expect(await eventide.deleteReminder(eventId: 'ev1', durationBeforeEvent: const Duration(minutes: 10)), event);
  });

  test('delegates createAttendee and deleteAttendee to EventidePlatformInterface.instance', () async {
    when(
      () => mockPlatform.createAttendee(
        eventId: 'ev1',
        name: 'John Doe',
        email: 'john@example.com',
        type: ETAttendeeType.requiredPerson,
        span: ETSpan.thisEvent,
        originalInstanceDate: null,
      ),
    ).thenAnswer((_) async => event);

    when(
      () => mockPlatform.deleteAttendee(
        eventId: 'ev1',
        attendee: attendee,
        span: ETSpan.thisEvent,
        originalInstanceDate: null,
      ),
    ).thenAnswer((_) async => event);

    expect(
      await eventide.createAttendee(
        eventId: 'ev1',
        name: 'John Doe',
        email: 'john@example.com',
        type: ETAttendeeType.requiredPerson,
      ),
      event,
    );
    expect(await eventide.deleteAttendee(eventId: 'ev1', attendee: attendee), event);
  });
}
