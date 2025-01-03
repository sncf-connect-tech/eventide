import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_calendar_connect/flutter_calendar_connect.dart';
import 'package:flutter_calendar_connect/calendar_api.g.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter/material.dart';

class _MockCalendarApi extends Mock implements CalendarApi {}

void main() {
  late _MockCalendarApi mockCalendarApi;
  late FlutterCalendarConnect flutterCalendarConnect;
  
  final event = Event(
    id: '1', 
    title: 'Test Event',
    startDate: DateTime.now().millisecondsSinceEpoch,
    endDate: DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch,
    timeZone: 'UTC',
    calendarId: '1',
    alarms: [],
  );

  setUpAll(() {
    registerFallbackValue(event);
  });

  setUp(() {
    mockCalendarApi = _MockCalendarApi();
    flutterCalendarConnect = FlutterCalendarConnect(calendarApi: mockCalendarApi);
  });

  test('createCalendar returns a Calendar', () async {
    // Given
    final calendar = Calendar(id: '1', title: 'Test Calendar', color: Colors.blue.value, isWritable: true);
    when(() => mockCalendarApi.createCalendar(any(), any())).thenAnswer((_) async => calendar);

    // When
    final result = await flutterCalendarConnect.createCalendar(title: 'Test Calendar', color: Colors.blue);

    // Then
    expect(result, equals(calendar));
    verify(() => mockCalendarApi.createCalendar('Test Calendar', Colors.blue.value)).called(1);
  });

  test('createOrUpdateEvent returns true', () async {
    // Given
    final event = Event(
      id: '1', 
      title: 'Test Event',
      startDate: DateTime.now().millisecondsSinceEpoch,
      endDate: DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch,
      timeZone: 'UTC',
      calendarId: '1',
      alarms: [],
    );

    when(() => mockCalendarApi.createEvent(
      title: any(named: 'title'),
      startDate: any(named: 'startDate'),
      endDate: any(named: 'endDate'),
      calendarId: any(named: 'calendarId'),
      timeZone: any(named: 'timeZone'),
      description: any(named: 'description'),
      url: any(named: 'url'),
      alarms: any(named: 'alarms'))
    ).thenAnswer((_) async => event);

    // When
    final result = await flutterCalendarConnect.createEvent(
      title: 'Test Event', 
      startDate: DateTime.now(),
      endDate: DateTime.now(),
      calendarId: '',
    );

    // Then
    expect(result, event);
    verify(() => mockCalendarApi.createEvent(
      title: any(named: 'title'),
      startDate: any(named: 'startDate'),
      endDate: any(named: 'endDate'),
      calendarId: any(named: 'calendarId'),
      timeZone: any(named: 'timeZone'),
      description: any(named: 'description'),
      url: any(named: 'url'),
      alarms: any(named: 'alarms'),
    )).called(1);
  });

  test('retrieveCalendars returns a list of Calendars', () async {
    // Given
    final calendars = [
      Calendar(id: '1', title: 'Test Calendar 1', color: Colors.blue.value, isWritable: true),
      Calendar(id: '2', title: 'Test Calendar 2', color: Colors.red.value, isWritable: true),
    ];
    when(() => mockCalendarApi.retrieveCalendars(any())).thenAnswer((_) async => calendars);

    // When
    final result = await flutterCalendarConnect.retrieveCalendars(onlyWritableCalendars: true);

    // Then
    expect(result, equals(calendars));
    verify(() => mockCalendarApi.retrieveCalendars(true)).called(1);
  });

  test('createCalendar throws an exception when API fails', () async {
    // Given
    when(() => mockCalendarApi.createCalendar(any(), any())).thenThrow(Exception('API Error'));

    // When
    Future<Calendar> call() => flutterCalendarConnect.createCalendar(title: 'Test Calendar', color: Colors.blue);

    // Then
    expect(call, throwsException);
    verify(() => mockCalendarApi.createCalendar('Test Calendar', Colors.blue.value)).called(1);
  });

  test('createOrUpdateEvent throws an exception when API fails', () async {
    // Given
    when(() => mockCalendarApi.createEvent(
      title: any(named: 'title'),
      startDate: any(named: 'startDate'),
      endDate: any(named: 'endDate'),
      calendarId: any(named: 'calendarId'),
      timeZone: any(named: 'timeZone'),
      description: any(named: 'description'),
      url: any(named: 'url'),
      alarms: any(named: 'alarms'))
    ).thenThrow(Exception('API Error'));

    // When
    Future<Event> call() => flutterCalendarConnect.createEvent(
      title: 'Test Event', 
      startDate: DateTime.now(),
      endDate: DateTime.now(),
      calendarId: '',
    );

    // Then
    expect(call, throwsException);
    verify(() => mockCalendarApi.createEvent(
      title: any(named: 'title'),
      startDate: any(named: 'startDate'),
      endDate: any(named: 'endDate'),
      calendarId: any(named: 'calendarId'),
      timeZone: any(named: 'timeZone'),
      description: any(named: 'description'),
      url: any(named: 'url'),
      alarms: any(named: 'alarms'),
    )).called(1);
  });
}