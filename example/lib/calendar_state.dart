import 'package:equatable/equatable.dart';
import 'package:flutter_calendar_connect/calendar_plugin.dart';

abstract class CalendarState extends Equatable {
  @override
  List<Object?> get props => [];

  const CalendarState();
}

class CalendarInitial extends CalendarState {
  @override
  List<Object?> get props => [];
  
  const CalendarInitial();
}

class CalendarSuccess extends CalendarState {
  final List<Calendar> calendars;
  
  @override
  List<Object?> get props => [calendars];

  const CalendarSuccess({
    required this.calendars,
  });

  CalendarSuccess copyWith({
    List<Calendar>? calendars,
  }) {
    return CalendarSuccess(
      calendars: calendars ?? this.calendars,
    );
  }
}

class CalendarNoValue extends CalendarState {
  @override
  List<Object?> get props => [];
  
  const CalendarNoValue();
}

class CalendarError extends CalendarState {
  final String message;

  @override
  List<Object?> get props => [message];

  const CalendarError({
    required this.message,
  });
}