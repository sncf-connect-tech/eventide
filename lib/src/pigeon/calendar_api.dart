import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/src/calendar_api.g.dart',
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
  Calendar createCalendar(String title, int color, bool saveOnCloud);

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

/// Represents a calendar.
/// 
/// [id] is the unique identifier of the calendar.
/// 
/// [title] is the title of the calendar.
/// 
/// [color] is the color of the calendar.
/// 
/// [isWritable] is `true` if the calendar is writable, `false` otherwise.
/// 
/// [isRemote] is `true` if the calendar is remote, `false` otherwise.
class Calendar {
  final String id;
  final String title;
  final int color;
  final bool isWritable;
  final bool isRemote;

  const Calendar({
    required this.id,
    required this.title,
    required this.color,
    required this.isWritable,
    required this.isRemote,
  });
}

/// Represents an event.
/// 
/// [id] is the unique identifier of the event.
/// 
/// [title] is the title of the event.
/// 
/// [startDate] is the start date of the event in milliseconds since epoch.
/// 
/// [endDate] is the end date of the event in milliseconds since epoch.
/// 
/// [calendarId] is the unique identifier of the calendar the event belongs to.
/// 
/// [description] is the description of the event.
/// 
/// [url] is the URL of the event.
/// 
/// [reminders] is a list of minutes before the event to trigger a reminder.
class Event{
  final String id;
  final String title;
  final int startDate;
  final int endDate;
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