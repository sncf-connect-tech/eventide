// ignore: depend_on_referenced_packages
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
  Event createReminder(int reminder, String eventId);

  @async
  @SwiftFunction('deleteReminder(_:withEventId:)')
  Event deleteReminder(int reminder, String eventId);
}

/// Native data struct to represent a calendar.
/// 
/// [id] is a unique identifier for the calendar.
/// 
/// [title] is the title of the calendar.
/// 
/// [color] is the color of the calendar.
/// 
/// [isWritable] is a boolean to indicate if the calendar is writable.
/// 
/// [sourceName] is the name of the source of the calendar.
final class Calendar {
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

/// Native data struct to represent an event.
/// 
/// [id] is a unique identifier for the event.
/// 
/// [title] is the title of the event.
/// 
/// [startDate] is the start date of the event in milliseconds since epoch.
/// 
/// [endDate] is the end date of the event in milliseconds since epoch.
/// 
/// [calendarId] is the id of the calendar that the event belongs to.
/// 
/// [description] is the description of the event.
/// 
/// [url] is the url of the event.  
/// 
/// [reminders] is a list of minutes before the event to remind the user.
final class Event {
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