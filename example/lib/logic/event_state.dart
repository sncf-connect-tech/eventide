import 'package:equatable/equatable.dart';
import 'package:flutter_calendar_connect/flutter_calendar_connect.dart';
import 'package:value_state/value_state.dart';

typedef EventState = Value<EventValue>;

class EventValue extends Equatable {
  final Calendar calendar;
  final List<Event> events;

  @override
  List<Object?> get props => [calendar, events];

  const EventValue({
    required this.calendar,
    required this.events,
  });
}