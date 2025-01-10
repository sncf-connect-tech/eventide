import 'package:equatable/equatable.dart';
import 'package:easy_calendar/easy_calendar.dart';
import 'package:value_state/value_state.dart';

typedef EventState = Value<EventValue>;

class EventValue extends Equatable {
  final ECCalendar calendar;
  final List<ECEvent> events;

  @override
  List<Object?> get props => [calendar, events];

  const EventValue({
    required this.calendar,
    required this.events,
  });
}