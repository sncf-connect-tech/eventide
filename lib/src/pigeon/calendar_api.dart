import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/src/calendar_api.g.dart',
  dartOptions: DartOptions(),
  kotlinOut: 'android/src/main/kotlin/sncf/connect/tech/easy_calendar/CalendarApi.g.kt',
  kotlinOptions: KotlinOptions(package: 'sncf.connect.tech.easy_calendar'),
  swiftOut: 'ios/Classes/CalendarApi.g.swift',
  swiftOptions: SwiftOptions(),
  dartPackageName: 'easy_calendar',
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
    required String? description,
    required String? url,
  });

  @async
  List<Event> retrieveEvents(String calendarId, int startDate, int endDate);

  @async
  @SwiftFunction('deleteEvent(withId:_:)')
  void deleteEvent(String eventId, String calendarId);

  @async
  @SwiftFunction('createReminder(_:forEventId:)')
  void createReminder(int minutes, String eventId);

  @async
  @SwiftFunction('retrieveReminders(withEventId:)')
  List<int> retrieveReminders(String eventId);

  @async
  @SwiftFunction('deleteReminder(_:withEventId:)')
  void deleteReminder(int minutes, String eventId);
}

class Calendar {
  final String id;
  final String title;
  final int color;
  final bool isWritable;
  final String sourceName;

  const Calendar({
    required this.id,
    required this.title,
    required this.color,
    required this.isWritable,
    required this.sourceName,
  });
}

class Event{
  final String id;
  final String title;
  final int startDate;    // millisecondsSinceEpoch
  final int endDate;      // millisecondsSinceEpoch
  final String calendarId;
  final String? description;
  final String? url;
  final List<int>? reminders;

  const Event({
    required this.id,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.calendarId,
    required this.description,
    this.url,
    this.reminders,
  });
}