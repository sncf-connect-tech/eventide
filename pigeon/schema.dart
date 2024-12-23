import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/calendar_plugin.dart',
  dartOptions: DartOptions(),
  kotlinOut: 'android/src/main/kotlin/sncf/connect/tech/flutter_calendar_connect/CalendarActions.kt',
  kotlinOptions: KotlinOptions(),
  swiftOut: 'ios/Classes/CalendarActions.swift',
  swiftOptions: SwiftOptions(),
))

@HostApi()
abstract class CalendarActions {
  @async
  bool requestCalendarAccess();

  @async
  Calendar createCalendar(String title, String hexColor);

  @async
  List<Calendar> retrieveCalendars();

  @async
  bool createOrUpdateEvent(Event flutterEvent);
}

class Calendar {
  final String id;
  final String title;
  final String hexColor;
  final String? sourceName;

  const Calendar({
    required this.id,
    required this.title,
    required this.hexColor,
    required this.sourceName,
  });
}

class Event {
  final String? id;
  final String title;
  final int startDate; // millisecondsSinceEpoch
  final int endDate; // millisecondsSinceEpoch
  final String calendarId;
  final String? description;
  final String? url;
  final List<Alarm?> alarms;

  const Event({
    required this.id,
    required this.title,
    required this.startDate,
    required this.endDate,
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