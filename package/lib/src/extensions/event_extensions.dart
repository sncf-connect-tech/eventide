import '../calendar_api.g.dart';
import '../eventide_platform_interface.dart';
import 'attendee_extensions.dart';
import 'duration_extensions.dart';

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
      location: location,
      reminders: reminders.toDurationList(),
      attendees: attendees.toETAttendeeList(),
      recurrenceRule: recurrenceRule,
      originalInstanceDate: originalInstanceDate != null
          ? DateTime.fromMillisecondsSinceEpoch(originalInstanceDate!, isUtc: true)
          : null,
    );
  }
}

extension ETEventCopy on ETEvent {
  ETEvent copyWithReminders(Iterable<Duration>? reminders) {
    return ETEvent(
      id: id,
      title: title,
      isAllDay: isAllDay,
      startDate: startDate,
      endDate: endDate,
      calendarId: calendarId,
      description: description,
      url: url,
      location: location,
      reminders: reminders ?? this.reminders,
      attendees: attendees,
      recurrenceRule: recurrenceRule,
      originalInstanceDate: originalInstanceDate,
    );
  }
}

extension EventListToETEvent on List<Event> {
  List<ETEvent> toETEventList() {
    return map((e) => e.toETEvent()).toList();
  }
}

extension SpanToETSpan on ETSpan {
  Span toSpan() {
    return switch (this) {
      .thisEvent => Span.thisEvent,
      .thisAndFuture => Span.thisAndFuture,
    };
  }
}
