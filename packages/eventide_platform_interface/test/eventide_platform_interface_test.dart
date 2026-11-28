import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:eventide_platform_interface/eventide_platform_interface.dart';

class _TestEventidePlatformInterface extends EventidePlatformInterface {}

class _ImplementsEventidePlatformInterface implements EventidePlatformInterface {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('EventidePlatformInterface', () {
    test('throws UnsupportedError when no instance is registered', () {
      expect(() => EventidePlatformInterface.instance, throwsUnsupportedError);
    });

    test('rejects implementations that use implements instead of extends', () {
      expect(() => EventidePlatformInterface.instance = _ImplementsEventidePlatformInterface(), throwsAssertionError);
    });

    test('accepts subclasses extending EventidePlatformInterface and throws UnimplementedError by default', () {
      final platform = _TestEventidePlatformInterface();
      EventidePlatformInterface.instance = platform;
      expect(EventidePlatformInterface.instance, same(platform));

      const account = ETAccount(id: '1', name: 'name', type: 'local');
      const calendar = ETCalendar(id: '1', title: 'cal', color: Color(0xFF000000), isWritable: true, account: account);
      final now = DateTime(2026, 1, 1);
      final event = ETEvent(
        id: '1',
        title: 'event',
        isAllDay: false,
        startDate: now,
        endDate: now.add(const Duration(hours: 1)),
        calendarId: '1',
      );
      const attendee = ETAttendee(
        name: 'John',
        email: 'john@example.com',
        type: ETAttendeeType.requiredPerson,
        status: ETAttendanceStatus.accepted,
      );

      expect(() => platform.createCalendar(title: 'cal', color: const Color(0xFF000000)), throwsUnimplementedError);
      expect(() => platform.retrieveCalendars(), throwsUnimplementedError);
      expect(() => platform.retrieveAccounts(), throwsUnimplementedError);
      expect(() => platform.updateCalendar(calendar), throwsUnimplementedError);
      expect(() => platform.deleteCalendar(calendarId: '1'), throwsUnimplementedError);
      expect(
        () => platform.createEvent(calendarId: '1', title: 'e', startDate: now, endDate: now),
        throwsUnimplementedError,
      );
      expect(
        () => platform.createEventInDefaultCalendar(title: 'e', startDate: now, endDate: now),
        throwsUnimplementedError,
      );
      expect(() => platform.createEventThroughNativePlatform(), throwsUnimplementedError);
      expect(() => platform.retrieveEvents(calendarId: '1'), throwsUnimplementedError);
      expect(() => platform.updateEvent(event), throwsUnimplementedError);
      expect(() => platform.deleteEvent(eventId: '1'), throwsUnimplementedError);
      expect(
        () => platform.createReminder(eventId: '1', durationBeforeEvent: const Duration(minutes: 10)),
        throwsUnimplementedError,
      );
      expect(
        () => platform.deleteReminder(eventId: '1', durationBeforeEvent: const Duration(minutes: 10)),
        throwsUnimplementedError,
      );
      expect(
        () => platform.createAttendee(
          eventId: '1',
          name: 'John',
          email: 'john@example.com',
          type: ETAttendeeType.requiredPerson,
        ),
        throwsUnimplementedError,
      );
      expect(() => platform.deleteAttendee(eventId: '1', attendee: attendee), throwsUnimplementedError);
    });
  });
}
