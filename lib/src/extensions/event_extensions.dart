import 'package:eventide/src/calendar_api.g.dart';
import 'package:eventide/src/eventide_platform_interface.dart';
import 'package:eventide/src/extensions/attendee_extensions.dart';
import 'package:eventide/src/extensions/duration_extensions.dart';

extension EventToETEvent on Event {
  ETEvent toETEvent() {
    return ETEvent(
      id: id,
      title: title,
      isAllDay: isAllDay,
      startDate: DateTime.fromMillisecondsSinceEpoch(startDate),
      endDate: DateTime.fromMillisecondsSinceEpoch(endDate),
      calendarId: calendarId,
      description: description,
      url: url,
      reminders: reminders.toDurationList(),
      attendees: attendees.toETAttendeeList(),
    );
  }
}

extension ETEventCopy on ETEvent {
  ETEvent copyWithReminders(List<Duration>? reminders) {
    return ETEvent(
      id: id,
      title: title,
      isAllDay: isAllDay,
      startDate: startDate,
      endDate: endDate,
      calendarId: calendarId,
      description: description,
      url: url,
      reminders: reminders ?? this.reminders,
      attendees: attendees,
    );
  }
}

extension EventListToETEvent on List<Event> {
  List<ETEvent> toETEventList() {
    return map((e) => e.toETEvent()).toList();
  }
}
