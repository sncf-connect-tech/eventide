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
          type: any(named: 'type'),
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
          attendees: [Attendee(name: 'John Doe', email: 'john.doe@gmail.com', role: 1, type: 1, status: 2)],
        ),
      );

      await eventide.createAttendee(
        eventId: 'eventId',
        name: 'John Doe',
        email: 'john.doe@gmail.com',
        type: ETAttendeeType.requiredPerson,
      );

      verify(
        () => mockCalendarApi.createAttendee(
          eventId: 'eventId',
          name: 'John Doe',
          email: 'john.doe@gmail.com',
          role: any(named: 'role'),
          type: any(named: 'type'),
        ),
      ).called(1);
    });

    test('remove attendee', () async {
      final attendee = ETAttendee(
        name: 'name',
        email: 'email',
        type: ETAttendeeType.requiredPerson,
        status: ETAttendanceStatus.unknown,
      );

      when(() => mockCalendarApi.deleteAttendee(eventId: any(named: 'eventId'), email: any(named: 'email'))).thenAnswer(
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

      await eventide.deleteAttendee(eventId: "eventId", attendee: attendee);

      verify(() => mockCalendarApi.deleteAttendee(eventId: 'eventId', email: 'email')).called(1);
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
      const tuples = [(0, 0), (1, 1), (1, 2), (1, 3), (3, 1), (2, 1), (4, 1), (1, 4)];

      final results = tuples.map(
        (e) =>
            Attendee(
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

    test('parseETAttendanceStatus', () {
      const statuses = [0, 1, 2, 3, 4];

      final results = statuses.map(
        (status) =>
            Attendee(
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
      ]);
    });
  });

  group('ETAttendeeTypeToNative extension tests iOS', () {
    setUp(() {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    });

    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
    });

    test('nativeRole returns correct iOS values', () {
      expect(ETAttendeeType.requiredPerson.nativeRole, 1);
      expect(ETAttendeeType.optionalPerson.nativeRole, 2);
      expect(ETAttendeeType.organizer.nativeRole, 3);
      expect(ETAttendeeType.resource.nativeRole, 1);
    });

    test('nativeType returns correct iOS values', () {
      expect(ETAttendeeType.requiredPerson.nativeType, 1);
      expect(ETAttendeeType.optionalPerson.nativeType, 1);
      expect(ETAttendeeType.organizer.nativeType, 1);
      expect(ETAttendeeType.resource.nativeType, 3);
    });

    test('nativeRole throws UnimplementedError for unsupported platforms', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      expect(() => ETAttendeeType.requiredPerson.nativeRole, throwsUnimplementedError);
    });

    test('nativeType throws UnimplementedError for unsupported platforms', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      expect(() => ETAttendeeType.requiredPerson.nativeType, throwsUnimplementedError);
    });
  });

  group('ETAttendeeTypeToNative extension tests Android', () {
    setUp(() {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
    });

    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
    });

    test('nativeRole returns correct Android values', () {
      expect(ETAttendeeType.requiredPerson.nativeRole, 1);
      expect(ETAttendeeType.optionalPerson.nativeRole, 2);
      expect(ETAttendeeType.organizer.nativeRole, 1);
      expect(ETAttendeeType.resource.nativeRole, 3);
    });

    test('nativeType returns correct Android values', () {
      expect(ETAttendeeType.requiredPerson.nativeType, 1);
      expect(ETAttendeeType.optionalPerson.nativeType, 1);
      expect(ETAttendeeType.organizer.nativeType, 2);
      expect(ETAttendeeType.resource.nativeType, 1);
    });
  });

  group('ETAttendanceStatusToNative extension tests iOS', () {
    setUp(() {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    });

    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
    });

    test('nativeStatus returns correct iOS values', () {
      expect(ETAttendanceStatus.pending.nativeStatus, 1);
      expect(ETAttendanceStatus.accepted.nativeStatus, 2);
      expect(ETAttendanceStatus.declined.nativeStatus, 3);
      expect(ETAttendanceStatus.tentative.nativeStatus, 4);
    });

    test('nativeStatus throws UnimplementedError for unsupported platforms', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      expect(() => ETAttendanceStatus.pending.nativeStatus, throwsUnimplementedError);
    });
  });

  group('ETAttendanceStatusToNative extension tests Android', () {
    setUp(() {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
    });

    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
    });

    test('nativeStatus returns correct Android values', () {
      expect(ETAttendanceStatus.pending.nativeStatus, 3);
      expect(ETAttendanceStatus.accepted.nativeStatus, 1);
      expect(ETAttendanceStatus.declined.nativeStatus, 2);
      expect(ETAttendanceStatus.tentative.nativeStatus, 4);
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
      const tuples = [(0, 0), (1, 1), (2, 1), (1, 2), (3, 1), (1, 4), (1, 3)];

      final results = tuples.map(
        (e) =>
            Attendee(
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
        ETAttendeeType.requiredPerson,
        ETAttendeeType.requiredPerson,
      ]);
    });

    test('parseETAttendanceStatus', () {
      const statuses = [0, 1, 2, 3, 4];

      final results = statuses.map(
        (status) =>
            Attendee(
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
  });

  group('AttendeeListToETAttendees extension tests', () {
    setUp(() {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    });

    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
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

    test('toETAttendeeList returns empty list for empty input', () {
      final attendees = <Attendee>[];
      final etAttendees = attendees.toETAttendeeList();
      expect(etAttendees, isEmpty);
    });
  });
}
