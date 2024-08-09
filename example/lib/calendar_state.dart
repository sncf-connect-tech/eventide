import 'package:flutter_calendar_connect/calendar_plugin.dart';
import 'package:flutter_value_state/flutter_value_state.dart';

typedef CalendarState = BaseState<CalendarValue>;

class CalendarValue {
  final List<Calendar> calendars;

  const CalendarValue({
    required this.calendars,
  });

  CalendarValue copyWith({
    List<Calendar>? calendars,
  }) {
    return CalendarValue(
      calendars: calendars ?? this.calendars,
    );
  }
}