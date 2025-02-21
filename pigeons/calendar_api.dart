// ignore: depend_on_referenced_packages
import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/src/calendar_api.g.dart',
  dartOptions: DartOptions(),
  kotlinOut:
      'android/src/main/kotlin/sncf/connect/tech/eventide/CalendarApi.g.kt',
  kotlinOptions: KotlinOptions(package: 'sncf.connect.tech.eventide'),
  swiftOut: 'ios/Classes/CalendarApi.g.swift',
  swiftOptions: SwiftOptions(),
  dartPackageName: 'eventide',
))
@HostApi()
abstract class CalendarApi {
  @async
  bool requestCalendarPermission();

  @async
  Calendar createCalendar({
    required String title,
    required int color,
    required Account? account,
  });

  @async
  List<Calendar> retrieveCalendars({
    required bool onlyWritableCalendars,
  });

  @async
  @SwiftFunction('deleteCalendar(_:)')
  void deleteCalendar({
    required String calendarId,
  });

  @async
  Event createEvent({
    required String calendarId,
    required String title,
    required int startDate,
    required int endDate,
    required bool isAllDay,
    required String? description,
    required String? url,
  });

  @async
  List<Event> retrieveEvents({
    required String calendarId,
    required int startDate,
    required int endDate,
  });

  @async
  @SwiftFunction('deleteEvent(withId:)')
  void deleteEvent({
    required String eventId,
  });

  @async
  @SwiftFunction('createReminder(_:forEventId:)')
  Event createReminder({
    required int reminder,
    required String eventId,
  });

  @async
  @SwiftFunction('deleteReminder(_:withEventId:)')
  Event deleteReminder({
    required int reminder,
    required String eventId,
  });
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
/// [account] is the account the calendar belongs to
/// TODO: explain android/ios differences
final class Calendar {
  final String id;
  final String title;
  final int color;
  final bool isWritable;
  final Account account;

  const Calendar({
    required this.id,
    required this.title,
    required this.color,
    required this.isWritable,
    required this.account,
  });
}

/// Native data struct to represent an event.
///
/// [id] is a unique identifier for the event.
///
/// [title] is the title of the event.
///
/// [isAllDay] is whether or not the event is an all day.
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
  final bool isAllDay;
  final int startDate;
  final int endDate;
  final String calendarId;
  final String? description;
  final String? url;
  final List<int>? reminders;

  const Event({
    required this.id,
    required this.title,
    required this.isAllDay,
    required this.startDate,
    required this.endDate,
    required this.calendarId,
    required this.description,
    required this.url,
    required this.reminders,
  });
}

final class Account {
  final String name;
  final String type;

  const Account({
    required this.name,
    required this.type,
  });
}
