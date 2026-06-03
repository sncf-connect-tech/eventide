// ignore: depend_on_referenced_packages
import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/src/calendar_api.g.dart',
    dartOptions: DartOptions(),
    kotlinOut: 'android/src/main/kotlin/sncf/connect/tech/eventide/CalendarApi.g.kt',
    kotlinOptions: KotlinOptions(package: 'sncf.connect.tech.eventide'),
    swiftOut: 'ios/eventide/Sources/eventide/CalendarApi.g.swift',
    swiftOptions: SwiftOptions(),
    dartPackageName: 'eventide',
  ),
)
@HostApi()
abstract class CalendarApi {
  @async
  @TaskQueue(type: TaskQueueType.serialBackgroundThread)
  @SwiftFunction('createCalendar(title:color:in:)')
  Calendar createCalendar({required String title, required int color, required Account? account});

  @async
  @TaskQueue(type: TaskQueueType.serialBackgroundThread)
  @SwiftFunction('updateCalendar(withId:title:color:)')
  Calendar updateCalendar({required String calendarId, required String title, required int color});

  @async
  @TaskQueue(type: TaskQueueType.serialBackgroundThread)
  @SwiftFunction('retrieveCalendars(onlyWritable:from:)')
  List<Calendar> retrieveCalendars({required bool onlyWritableCalendars, required Account? account});

  @async
  @TaskQueue(type: TaskQueueType.serialBackgroundThread)
  List<Account> retrieveAccounts();

  @async
  @TaskQueue(type: TaskQueueType.serialBackgroundThread)
  @SwiftFunction('deleteCalendar(_:)')
  void deleteCalendar({required String calendarId});

  @async
  @TaskQueue(type: TaskQueueType.serialBackgroundThread)
  Event createEvent({
    required String calendarId,
    required String title,
    required int startDate,
    required int endDate,
    required bool isAllDay,
    required String? description,
    required String? url,
    required String? location,
    required List<int>? reminders,
  });

  @async
  @TaskQueue(type: TaskQueueType.serialBackgroundThread)
  @SwiftFunction('updateEvent(withId:calendarId:title:startDate:endDate:isAllDay:description:url:location:reminders:)')
  Event updateEvent({
    required String eventId,
    required String calendarId,
    required String title,
    required int startDate,
    required int endDate,
    required bool isAllDay,
    required String? description,
    required String? url,
    required String? location,
    required List<int>? reminders,
  });

  @async
  @TaskQueue(type: TaskQueueType.serialBackgroundThread)
  void createEventInDefaultCalendar({
    required String title,
    required int startDate,
    required int endDate,
    required bool isAllDay,
    required String? description,
    required String? url,
    required String? location,
    required List<int>? reminders,
  });

  @async
  @TaskQueue(type: TaskQueueType.serialBackgroundThread)
  void createEventThroughNativePlatform({
    String? title,
    int? startDate,
    int? endDate,
    bool? isAllDay,
    String? description,
    String? url,
    String? location,
    List<int>? reminders,
  });

  @async
  @TaskQueue(type: TaskQueueType.serialBackgroundThread)
  List<Event> retrieveEvents({required String calendarId, required int startDate, required int endDate});

  @async
  @TaskQueue(type: TaskQueueType.serialBackgroundThread)
  @SwiftFunction('deleteEvent(withId:)')
  void deleteEvent({required String eventId});

  @async
  @TaskQueue(type: TaskQueueType.serialBackgroundThread)
  @SwiftFunction('createReminder(_:forEventId:)')
  Event createReminder({required int reminder, required String eventId});

  @async
  @TaskQueue(type: TaskQueueType.serialBackgroundThread)
  @SwiftFunction('deleteReminder(_:withEventId:)')
  Event deleteReminder({required int reminder, required String eventId});

  @async
  @TaskQueue(type: TaskQueueType.serialBackgroundThread)
  Event createAttendee({
    required String eventId,
    required String name,
    required String email,
    required int role,
    required int type,
  });

  @async
  @TaskQueue(type: TaskQueueType.serialBackgroundThread)
  Event deleteAttendee({required String eventId, required String email});
}

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

final class Event {
  final String id;
  final String calendarId;
  final String title;
  final bool isAllDay;
  final int startDate;
  final int endDate;
  final List<int> reminders;
  final List<Attendee> attendees;
  final String? description;
  final String? url;
  final String? location;

  const Event({
    required this.id,
    required this.title,
    required this.isAllDay,
    required this.startDate,
    required this.endDate,
    required this.calendarId,
    required this.reminders,
    required this.attendees,
    required this.description,
    required this.url,
    required this.location,
  });
}

final class Account {
  final String id;
  final String name;
  final String type;

  const Account({required this.id, required this.name, required this.type});
}

final class Attendee {
  final String name;
  final String email;
  final int type;
  final int role;
  final int status;

  const Attendee({
    required this.name,
    required this.email,
    required this.role,
    required this.type,
    required this.status,
  });
}
