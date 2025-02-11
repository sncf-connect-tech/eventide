import 'package:equatable/equatable.dart';
import 'package:eventide/eventide.dart';
import 'package:value_state/value_state.dart';

typedef EventState = Value<EventValue>;

class EventValue extends Equatable {
  final ETCalendar calendar;
  final List<ETEvent> events;

  @override
  List<Object?> get props => [calendar, events];

  const EventValue({
    required this.calendar,
    required this.events,
  });
}
