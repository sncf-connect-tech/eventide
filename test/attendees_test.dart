import 'package:flutter/foundation.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:eventide/eventide.dart';
import 'package:eventide/src/calendar_api.g.dart';
import 'package:eventide/src/extensions/attendee_extensions.dart';

class _MockCalendarApi extends Mock implements CalendarApi {}

void main() {
  late _MockCalendarApi mockCalendarApi;
  late Eventide eventide;

  group('attendee tests', () {
    setUp(() {
      mockCalendarApi = _MockCalendarApi();
      eventide = Eventide(calendarApi: mockCalendarApi);
    });

    test('add attendee', () async {
      when(
        () => mockCalendarApi.createAttendee(
            eventId: any(named: 'eventId'),
            name: any(named: 'name'),
            email: any(named: 'email'),
            role: any(named: 'role'),
            type: any(named: 'type')),
      ).thenAnswer((_) async => Event(
            id: 'eventId',
            calendarId: 'calendarId',
            title: 'title',
            startDate: DateTime.now().millisecondsSinceEpoch,
            endDate: DateTime.now().add(const Duration(minutes: 30)).millisecondsSinceEpoch,
            isAllDay: false,
            description: 'description',
            url: 'url',
            reminders: [],
            attendees: [
              Attendee(
                name: 'John Doe',
                email: 'john.doe@gmail.com',
                role: 1,
                type: 1,
                status: 2,
              ),
            ],
          ));

      await eventide.createAttendee(
        eventId: 'eventId',
        name: 'John Doe',
        email: 'john.doe@gmail.com',
        type: ETAttendeeType.requiredPerson,
      );

      verify(() => mockCalendarApi.createAttendee(
            eventId: 'eventId',
            name: 'John Doe',
            email: 'john.doe@gmail.com',
            role: any(named: 'role'),
            type: any(named: 'type'),
          )).called(1);
    });

    test('remove attendee', () async {
      final attendee = ETAttendee(
        name: 'name',
        email: 'email',
        type: ETAttendeeType.requiredPerson,
        status: ETAttendanceStatus.unknown,
      );

      when(() => mockCalendarApi.deleteAttendee(
            eventId: any(named: 'eventId'),
            email: any(named: 'email'),
          )).thenAnswer((_) async => Event(
            id: 'id',
            title: 'title',
            startDate: DateTime.now().millisecondsSinceEpoch,
            endDate: DateTime.now().add(const Duration(minutes: 30)).millisecondsSinceEpoch,
            isAllDay: false,
            calendarId: 'calendarId',
            reminders: [],
            attendees: [],
          ));

      await eventide.deleteAttendee(eventId: "eventId", attendee: attendee);

      verify(() => mockCalendarApi.deleteAttendee(
            eventId: 'eventId',
            email: 'email',
          )).called(1);
    });
  });

  group('attendees extensions tests iOS', () {
    setUp(() {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    });

    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
    });

    test('parseETAttendeeType', () {
      const tuples = [
        (0, 0),
        (1, 1),
        (1, 2),
        (1, 3),
        (3, 1),
      ];

      final results = tuples.map((e) => Attendee(
            name: 'John Doe',
            email: 'john.doe@example.com',
            type: e.$1,
            role: e.$2,
            status: 2,
          ).toETAttendee().type);

      expect(results, [
        ETAttendeeType.unknown,
        ETAttendeeType.requiredPerson,
        ETAttendeeType.optionalPerson,
        ETAttendeeType.organizer,
        ETAttendeeType.resource,
      ]);
    });

    test('parseETAttendanceStatus', () {
      const statuses = [0, 1, 2, 3, 4];

      final results = statuses.map((status) => Attendee(
            name: 'John Doe',
            email: 'john.doe@example.com',
            type: 1,
            role: 1,
            status: status,
          ).parseETAttendanceStatus());

      expect(results, [
        ETAttendanceStatus.unknown,
        ETAttendanceStatus.pending,
        ETAttendanceStatus.accepted,
        ETAttendanceStatus.declined,
        ETAttendanceStatus.tentative,
      ]);
    });
  });

  group('attendees extensions tests Android', () {
    setUp(() {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
    });

    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
    });

    test('parseETAttendeeType', () {
      const tuples = [
        (0, 0),
        (1, 1),
        (2, 1),
        (1, 2),
        (3, 1),
      ];

      final results = tuples.map((e) => Attendee(
            name: 'John Doe',
            email: 'john.doe@example.com',
            type: e.$1,
            role: e.$2,
            status: 2,
          ).toETAttendee().type);

      expect(results, [
        ETAttendeeType.unknown,
        ETAttendeeType.requiredPerson,
        ETAttendeeType.optionalPerson,
        ETAttendeeType.organizer,
        ETAttendeeType.resource,
      ]);
    });

    test('parseETAttendanceStatus', () {
      const statuses = [0, 1, 2, 3, 4];

      final results = statuses.map((status) => Attendee(
            name: 'John Doe',
            email: 'john.doe@example.com',
            type: 1,
            role: 1,
            status: status,
          ).parseETAttendanceStatus());

      expect(results, [
        ETAttendanceStatus.unknown,
        ETAttendanceStatus.accepted,
        ETAttendanceStatus.declined,
        ETAttendanceStatus.pending,
        ETAttendanceStatus.tentative,
      ]);
    });
  });
}
