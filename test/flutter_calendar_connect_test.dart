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
    final calendar = Calendar(id: '1', title: 'Test Calendar', color: Colors.blue.value);
    when(() => mockCalendarApi.createCalendar(any(), any())).thenAnswer((_) async => calendar);

    // When
    final result = await flutterCalendarConnect.createCalendar(title: 'Test Calendar', color: Colors.blue);

    // Then
    expect(result, equals(calendar));
    verify(() => mockCalendarApi.createCalendar('Test Calendar', Colors.blue.value)).called(1);
  });

  test('createOrUpdateEvent returns true', () async {
    // Given
    when(() => mockCalendarApi.createOrUpdateEvent(any())).thenAnswer((_) async => true);

    // When
    final result = await flutterCalendarConnect.createOrUpdateEvent(event: event);

    // Then
    expect(result, isTrue);
    verify(() => mockCalendarApi.createOrUpdateEvent(event)).called(1);
  });

  test('retrieveCalendars returns a list of Calendars', () async {
    // Given
    final calendars = [
      Calendar(id: '1', title: 'Test Calendar 1', color: Colors.blue.value),
      Calendar(id: '2', title: 'Test Calendar 2', color: Colors.red.value),
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
    when(() => mockCalendarApi.createOrUpdateEvent(any())).thenThrow(Exception('API Error'));

    // When
    Future<bool> call() => flutterCalendarConnect.createOrUpdateEvent(event: event);

    // Then
    expect(call, throwsException);
    verify(() => mockCalendarApi.createOrUpdateEvent(event)).called(1);
  });
}