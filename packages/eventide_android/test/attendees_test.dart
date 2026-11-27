import 'package:eventide_platform_interface/eventide_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:eventide_android/eventide_android.dart';
import 'package:eventide_android/src/calendar_api.g.dart';
import 'package:eventide_android/src/extensions/attendee_extensions.dart';
import 'package:eventide_android/src/extensions/event_extensions.dart';

class _MockCalendarApi extends Mock implements CalendarApi {}

void main() {
  late _MockCalendarApi mockCalendarApi;
  late EventideAndroid eventide;

  group('EventideAndroid attendee operations', () {
    setUp(() {
      mockCalendarApi = _MockCalendarApi();
      eventide = EventideAndroid(calendarApi: mockCalendarApi);
    });

    test('createAttendee forwards native role and type', () async {
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
      ).thenAnswer(
        (_) async => Event(
          id: 'eventId',
          calendarId: 'calendarId',
          title: 'title',
          startDate: DateTime.now().millisecondsSinceEpoch,
          endDate: DateTime.now().add(const Duration(minutes: 30)).millisecondsSinceEpoch,
          isAllDay: false,
          description: 'description',
          url: 'url',
          reminders: [],
          attendees: [Attendee(name: 'John Doe', email: 'john.doe@gmail.com', role: 1, type: 1, status: 1)],
        ),
      );

      final result = await eventide.createAttendee(
        eventId: 'eventId',
        name: 'John Doe',
        email: 'john.doe@gmail.com',
        type: ETAttendeeType.requiredPerson,
      );

      expect(result.attendees, [
        const ETAttendee(
          name: 'John Doe',
          email: 'john.doe@gmail.com',
          type: ETAttendeeType.requiredPerson,
          status: ETAttendanceStatus.accepted,
        ),
      ]);

      verify(
        () => mockCalendarApi.createAttendee(
          eventId: 'eventId',
          name: 'John Doe',
          email: 'john.doe@gmail.com',
          role: 1,
          type: 1,
          span: Span.thisEvent,
          originalInstanceDate: null,
        ),
      ).called(1);
    });

    test('deleteAttendee forwards email and span', () async {
      const attendee = ETAttendee(
        name: 'name',
        email: 'email',
        type: ETAttendeeType.requiredPerson,
        status: ETAttendanceStatus.unknown,
      );

      when(
        () => mockCalendarApi.deleteAttendee(
          eventId: any(named: 'eventId'),
          email: any(named: 'email'),
          span: any(named: 'span'),
          originalInstanceDate: any(named: 'originalInstanceDate'),
        ),
      ).thenAnswer(
        (_) async => Event(
          id: 'id',
          title: 'title',
          startDate: DateTime.now().millisecondsSinceEpoch,
          endDate: DateTime.now().add(const Duration(minutes: 30)).millisecondsSinceEpoch,
          isAllDay: false,
          calendarId: 'calendarId',
          reminders: [],
          attendees: [],
        ),
      );

      await eventide.deleteAttendee(eventId: 'eventId', attendee: attendee);

      verify(
        () => mockCalendarApi.deleteAttendee(
          eventId: 'eventId',
          email: 'email',
          span: Span.thisEvent,
          originalInstanceDate: null,
        ),
      ).called(1);
    });
  });

  group('Android attendee extensions tests', () {
    test('ETAttendeeType nativeRole (ATTENDEE_TYPE) and nativeType (ATTENDEE_RELATIONSHIP)', () {
      expect(ETAttendeeType.unknown.nativeRole, 0);
      expect(ETAttendeeType.requiredPerson.nativeRole, 1);
      expect(ETAttendeeType.optionalPerson.nativeRole, 2);
      expect(ETAttendeeType.organizer.nativeRole, 1);
      expect(ETAttendeeType.resource.nativeRole, 3);

      expect(ETAttendeeType.unknown.nativeType, 0);
      expect(ETAttendeeType.requiredPerson.nativeType, 1);
      expect(ETAttendeeType.optionalPerson.nativeType, 1);
      expect(ETAttendeeType.organizer.nativeType, 2);
      expect(ETAttendeeType.resource.nativeType, 1);
    });

    test('ETAttendanceStatus nativeStatus', () {
      expect(ETAttendanceStatus.unknown.nativeStatus, 0);
      expect(ETAttendanceStatus.accepted.nativeStatus, 1);
      expect(ETAttendanceStatus.declined.nativeStatus, 2);
      expect(ETAttendanceStatus.pending.nativeStatus, 3);
      expect(ETAttendanceStatus.tentative.nativeStatus, 4);
    });

    test('parseETAttendeeType is symmetric with nativeType/nativeRole', () {
      for (final etType in ETAttendeeType.values) {
        final native = Attendee(
          name: 'John Doe',
          email: 'john.doe@example.com',
          type: etType.nativeType,
          role: etType.nativeRole,
          status: 1,
        );
        expect(native.parseETAttendeeType(), etType);
      }

      // PERFORMER (3) and SPEAKER (4) with TYPE_REQUIRED (1) map to requiredPerson
      expect(
        Attendee(name: 'A', email: 'a@b.c', type: 3, role: 1, status: 1).parseETAttendeeType(),
        ETAttendeeType.requiredPerson,
      );
      expect(
        Attendee(name: 'A', email: 'a@b.c', type: 4, role: 1, status: 1).parseETAttendeeType(),
        ETAttendeeType.requiredPerson,
      );
    });

    test('parseETAttendanceStatus maps Android ATTENDEE_STATUS values', () {
      const statuses = [0, 1, 2, 3, 4];

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
        ETAttendanceStatus.accepted,
        ETAttendanceStatus.declined,
        ETAttendanceStatus.pending,
        ETAttendanceStatus.tentative,
      ]);
    });

    test('Event.toETEvent preserves attendees', () {
      final event = Event(
        id: '1',
        calendarId: 'cal1',
        title: 'Meeting',
        isAllDay: false,
        startDate: DateTime(2026, 1, 1, 10).millisecondsSinceEpoch,
        endDate: DateTime(2026, 1, 1, 11).millisecondsSinceEpoch,
        reminders: [],
        attendees: [Attendee(name: 'Jane', email: 'jane@example.com', type: 2, role: 1, status: 3)],
      );

      expect(event.toETEvent().attendees, [
        const ETAttendee(
          name: 'Jane',
          email: 'jane@example.com',
          type: ETAttendeeType.organizer,
          status: ETAttendanceStatus.pending,
        ),
      ]);
    });
  });
}
