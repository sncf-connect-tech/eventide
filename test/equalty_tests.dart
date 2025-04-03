import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:eventide/src/eventide_platform_interface.dart';

void main() {
  group('ETCalendar equality tests', () {
    test('ETCalendar objects with identical properties are equal', () {
      const calendar1 = ETCalendar(
        id: '1',
        title: 'Work',
        color: Color(0xFF0000FF),
        isWritable: true,
        account: ETAccount(name: 'test@gmail.com', type: 'Google'),
      );
      const calendar2 = ETCalendar(
        id: '1',
        title: 'Work',
        color: Color(0xFF0000FF),
        isWritable: true,
        account: ETAccount(name: 'test@gmail.com', type: 'Google'),
      );

      expect(calendar1, equals(calendar2));
      expect(calendar1.hashCode, equals(calendar2.hashCode));
    });

    test('ETCalendar objects with different properties are not equal', () {
      const calendar1 = ETCalendar(
        id: '1',
        title: 'Work',
        color: Color(0xFF0000FF),
        isWritable: true,
        account: ETAccount(name: 'test@gmail.com', type: 'Google'),
      );
      const calendar2 = ETCalendar(
        id: '2',
        title: 'Personal',
        color: Color(0xFFFF0000),
        isWritable: false,
        account: ETAccount(name: 'other@gmail.com', type: 'Google'),
      );

      expect(calendar1, isNot(equals(calendar2)));
      expect(calendar1.hashCode, isNot(equals(calendar2.hashCode)));
    });
  });

  group('ETEvent equality tests', () {
    test('ETEvent objects with identical properties are equal', () {
      final event1 = ETEvent(
        id: '1',
        title: 'Meeting',
        isAllDay: false,
        startDate: DateTime(2023, 10, 1),
        endDate: DateTime(2023, 10, 2),
        calendarId: '1',
        reminders: [Duration(minutes: 10)],
        attendees: [],
        description: 'Team meeting',
        url: 'http://example.com',
      );
      final event2 = ETEvent(
        id: '1',
        title: 'Meeting',
        isAllDay: false,
        startDate: DateTime(2023, 10, 1),
        endDate: DateTime(2023, 10, 2),
        calendarId: '1',
        reminders: [Duration(minutes: 10)],
        attendees: [],
        description: 'Team meeting',
        url: 'http://example.com',
      );

      expect(event1, equals(event2));
      expect(event1.hashCode, equals(event2.hashCode));
    });

    test('ETEvent objects with different properties are not equal', () {
      final event1 = ETEvent(
        id: '1',
        title: 'Meeting',
        isAllDay: false,
        startDate: DateTime(2023, 10, 1),
        endDate: DateTime(2023, 10, 2),
        calendarId: '1',
        reminders: [Duration(minutes: 10)],
        attendees: [],
        description: 'Team meeting',
        url: 'http://example.com',
      );
      final event2 = ETEvent(
        id: '2',
        title: 'Workshop',
        isAllDay: true,
        startDate: DateTime(2023, 10, 3),
        endDate: DateTime(2023, 10, 4),
        calendarId: '2',
        reminders: [Duration(minutes: 20)],
        attendees: [],
        description: 'Training workshop',
        url: 'http://example.org',
      );

      expect(event1, isNot(equals(event2)));
      expect(event1.hashCode, isNot(equals(event2.hashCode)));
    });
  });

  group('ETAccount equality tests', () {
    test('ETAccount objects with identical properties are equal', () {
      const account1 = ETAccount(name: 'test@gmail.com', type: 'Google');
      const account2 = ETAccount(name: 'test@gmail.com', type: 'Google');

      expect(account1, equals(account2));
      expect(account1.hashCode, equals(account2.hashCode));
    });

    test('ETAccount objects with different properties are not equal', () {
      const account1 = ETAccount(name: 'test@gmail.com', type: 'Google');
      const account2 = ETAccount(name: 'other@gmail.com', type: 'Outlook');

      expect(account1, isNot(equals(account2)));
      expect(account1.hashCode, isNot(equals(account2.hashCode)));
    });
  });

  group('ETAttendee equality tests', () {
    test('ETAttendee objects with identical properties are equal', () {
      const attendee1 = ETAttendee(
        name: 'John Doe',
        email: 'john.doe@example.com',
        type: ETAttendeeType.requiredPerson,
        status: ETAttendanceStatus.accepted,
      );
      const attendee2 = ETAttendee(
        name: 'John Doe',
        email: 'john.doe@example.com',
        type: ETAttendeeType.requiredPerson,
        status: ETAttendanceStatus.accepted,
      );

      expect(attendee1, equals(attendee2));
      expect(attendee1.hashCode, equals(attendee2.hashCode));
    });

    test('ETAttendee objects with different properties are not equal', () {
      const attendee1 = ETAttendee(
        name: 'John Doe',
        email: 'john.doe@example.com',
        type: ETAttendeeType.requiredPerson,
        status: ETAttendanceStatus.accepted,
      );
      const attendee2 = ETAttendee(
        name: 'Jane Smith',
        email: 'jane.smith@example.com',
        type: ETAttendeeType.optionalPerson,
        status: ETAttendanceStatus.declined,
      );

      expect(attendee1, isNot(equals(attendee2)));
      expect(attendee1.hashCode, isNot(equals(attendee2.hashCode)));
    });
  });
}
