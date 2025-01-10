
import 'package:easy_calendar/src/calendar_api.g.dart';
import 'package:easy_calendar/src/easy_calendar_platform_interface.dart';

extension CalendarToECCalendar on Calendar {
  ECCalendar toECCalendar() {
    return ECCalendar(
      id: id,
      title: title,
      color: color,
      isWritable: isWritable,
      sourceName: sourceName,
    );
  }
}

extension EventToECEvent on Event {
  ECEvent toECEvent() {
    return ECEvent(
      id: id,
      title: title,
      startDate: DateTime.fromMillisecondsSinceEpoch(startDate),
      endDate: DateTime.fromMillisecondsSinceEpoch(endDate),
      calendarId: calendarId,
      description: description,
      url: url,
      reminders: reminders ?? [],
    );
  }
}

extension ECEventCopy on ECEvent {
  ECEvent copyWith({
    String? title,
    DateTime? startDate,
    DateTime? endDate,
    String? calendarId,
    String? description,
    String? url,
    List<int>? reminders,
  }) {
    return ECEvent(
      id: id,
      title: title ?? this.title,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      calendarId: calendarId ?? this.calendarId,
      description: description ?? this.description,
      url: url ?? this.url,
      reminders: reminders ?? this.reminders,
    );
  }
}