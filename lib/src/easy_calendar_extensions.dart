import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:easy_calendar/src/calendar_api.g.dart';
import 'package:easy_calendar/src/easy_calendar_platform_interface.dart';

extension CalendarToECCalendar on Calendar {
  ECCalendar toECCalendar() {
    return ECCalendar(
      id: id,
      title: title,
      color: Color(color),
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
      reminders: [
        if (reminders != null)
          ...reminders!.toDurationList(),
      ],
    );
  }
}

extension CalendarListToECCalendar on List<Calendar> {
  List<ECCalendar> toECCalendarList() {
    return map((c) => c.toECCalendar()).toList();
  }
}

extension EventListToECEvent on List<Event> {
  List<ECEvent> toECEventList() {
    return map((e) => e.toECEvent()).toList();
  }
}

extension ECEventCopy on ECEvent {
  ECEvent copyWithReminders(List<Duration>? reminders) {
    return ECEvent(
      id: id,
      title: title,
      startDate: startDate,
      endDate: endDate,
      calendarId: calendarId,
      description: description,
      url: url,
      reminders: reminders ?? this.reminders,
    );
  }
}

extension NativeToDuration on int {
  Duration toDuration() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return Duration(seconds: abs());
      case TargetPlatform.android:
        return Duration(minutes: abs());
      default:
        throw UnsupportedError('Unsupported platform');
    }
  }
}

extension DurationToNative on Duration {
  int toNativeDuration() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return inSeconds.abs();
      case TargetPlatform.android:
        return inMinutes.abs();
      default:
        throw UnsupportedError('Unsupported platform');
    }
  }
}

extension DurationListToNative on List<Duration> {
  List<int> toNativeList() {
    return map((d) => d.toNativeDuration()).toList();
  }
}

extension NativeListToDuration on List<int> {
  List<Duration> toDurationList() {
    return map((i) => i.toDuration()).toList();
  }
}