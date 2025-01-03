import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/calendar_api.g.dart',
  dartOptions: DartOptions(),
  kotlinOut: 'android/src/main/kotlin/sncf/connect/tech/flutter_calendar_connect/CalendarApi.g.kt',
  kotlinOptions: KotlinOptions(package: 'sncf.connect.tech.flutter_calendar_connect'),
  swiftOut: 'ios/Classes/CalendarApi.g.swift',
  swiftOptions: SwiftOptions(),
  dartPackageName: 'flutter_calendar_connect',
))

@HostApi()
abstract class CalendarApi {
  @async
  bool requestCalendarPermission();

  @async
  Calendar createCalendar(String title, int color);

  @async
  List<Calendar> retrieveCalendars(bool onlyWritableCalendars);

  @async
  @SwiftFunction('deleteCalendar(_:)')
  void deleteCalendar(String calendarId);

  @async
  Event createEvent({
    required String title,
    required int startDate,
    required int endDate,
    required String calendarId,
    required String timeZone,
    required String? description,
    required String? url,
    required List<Alarm>? alarms,
  });

  @async
  List<Event> retrieveEvents(String calendarId, int startDate, int endDate);

  @async
  @SwiftFunction('deleteEvent(withId:_:)')
  void deleteEvent(String eventId, String calendarId);
}

class Calendar {
  final String id;
  final String title;
  final int color;
  final bool isWritable;

  const Calendar({
    required this.id,
    required this.title,
    required this.color,
    required this.isWritable,
  });
}

class Event {
  final String id;
  final String title;
  final int startDate;    // millisecondsSinceEpoch
  final int endDate;      // millisecondsSinceEpoch
  final String timeZone;  // String identifier
  final String calendarId;
  final String? description;
  final String? url;
  final List<Alarm>? alarms;

  const Event({
    required this.id,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.timeZone,
    required this.calendarId,
    required this.description,
    required this.url,
    required this.alarms,
  });
}

class Alarm {
  final int minutes;

  const Alarm({
    required this.minutes,
  });
}