import 'package:eventide_platform_interface/eventide_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:eventide_ios/eventide_ios.dart';
import 'package:eventide_ios/src/calendar_api.g.dart';
import 'package:eventide_ios/src/extensions/attendee_extensions.dart';
import 'package:eventide_ios/src/extensions/event_extensions.dart';

final class _MockCalendarApi extends Mock implements CalendarApi {}

void main() {
  late _MockCalendarApi mockCalendarApi;
  late EventideIOS eventide;

  setUp(() {
    mockCalendarApi = _MockCalendarApi();
    eventide = EventideIOS(calendarApi: mockCalendarApi);
  });

  group('EventideIOS attendee operations', () {
    test('createAttendee throws ETNotSupportedByPlatform', () async {
      expect(
        () => eventide.createAttendee(
          eventId: 'eventId',
          name: 'John Doe',
          email: 'john.doe@gmail.com',
          type: ETAttendeeType.requiredPerson,
        ),
        throwsA(isA<ETNotSupportedByPlatform>()),
      );
    });

    test('deleteAttendee throws ETNotSupportedByPlatform', () async {
      const attendee = ETAttendee(
        name: 'John Doe',
        email: 'john.doe@gmail.com',
        type: ETAttendeeType.requiredPerson,
        status: ETAttendanceStatus.accepted,
      );

      expect(
        () => eventide.deleteAttendee(eventId: 'eventId', attendee: attendee),
        throwsA(isA<ETNotSupportedByPlatform>()),
      );
    });
  });

  group('iOS attendee extensions tests', () {
    test('parseETAttendeeType maps EventKit (type, role) pairs', () {
      const tuples = [(0, 0), (1, 1), (1, 2), (1, 3), (3, 1), (2, 1), (4, 1), (1, 4)];

      final results = tuples.map(
        (e) => Attendee(
          name: 'John Doe',
          email: 'john.doe@example.com',
          type: e.$1,
          role: e.$2,
          status: 2,
        ).toETAttendee().type,
      );

      expect(results, [
        ETAttendeeType.unknown,
        ETAttendeeType.requiredPerson,
        ETAttendeeType.optionalPerson,
        ETAttendeeType.organizer,
        ETAttendeeType.resource,
        ETAttendeeType.resource,
        ETAttendeeType.resource,
        ETAttendeeType.optionalPerson,
      ]);
    });

    test('parseETAttendanceStatus maps EventKit status values', () {
      const statuses = [0, 1, 2, 3, 4, 5, 6, 7];

      final results = statuses.map(
        (status) => Attendee(
          name: 'John Doe',
          email: 'john.doe@example.com',
          type: 1,
          role: 1,
          status: status,
        ).parseETAttendanceStatus(),
      );

      expect(results, [
        ETAttendanceStatus.unknown,
        ETAttendanceStatus.pending,
        ETAttendanceStatus.accepted,
        ETAttendanceStatus.declined,
        ETAttendanceStatus.tentative,
        ETAttendanceStatus.unknown,
        ETAttendanceStatus.unknown,
        ETAttendanceStatus.unknown,
      ]);
    });

    test('toETAttendeeList converts list of Attendee to list of ETAttendee', () {
      final attendees = [
        Attendee(name: 'John Doe', email: 'john.doe@example.com', type: 1, role: 1, status: 2),
        Attendee(name: 'Jane Smith', email: 'jane.smith@example.com', type: 1, role: 2, status: 1),
      ];

      final etAttendees = attendees.toETAttendeeList();

      expect(etAttendees.length, 2);
      expect(etAttendees[0].name, 'John Doe');
      expect(etAttendees[0].email, 'john.doe@example.com');
      expect(etAttendees[0].type, ETAttendeeType.requiredPerson);
      expect(etAttendees[0].status, ETAttendanceStatus.accepted);
      expect(etAttendees[1].name, 'Jane Smith');
      expect(etAttendees[1].email, 'jane.smith@example.com');
      expect(etAttendees[1].type, ETAttendeeType.optionalPerson);
      expect(etAttendees[1].status, ETAttendanceStatus.pending);
    });

    test('Event.toETEvent preserves attendees from EventKit', () {
      final event = Event(
        id: '1',
        calendarId: 'cal1',
        title: 'Meeting',
        isAllDay: false,
        startDate: DateTime(2026, 1, 1, 10).millisecondsSinceEpoch,
        endDate: DateTime(2026, 1, 1, 11).millisecondsSinceEpoch,
        reminders: [],
        attendees: [Attendee(name: 'John Doe', email: '', type: 1, role: 1, status: 2)],
      );

      final etEvent = event.toETEvent();
      expect(etEvent.attendees, [
        const ETAttendee(
          name: 'John Doe',
          email: '',
          type: ETAttendeeType.requiredPerson,
          status: ETAttendanceStatus.accepted,
        ),
      ]);
    });
  });
}
