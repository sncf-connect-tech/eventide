import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_calendar_connect/calendar_plugin.dart';
import 'package:flutter_calendar_connect_example/calendar_state.dart';

class CalendarCubit extends Cubit<CalendarState> {
  final CalendarActions _calendarActions;

  CalendarCubit({
    @visibleForTesting CalendarActions? calendarActions,
  }) : _calendarActions = calendarActions ?? CalendarActions(),
        super(const CalendarInitial());

  Future<void> fetchCalendars() async {
    try {
      if (await _calendarActions.requestCalendarAccess()) {
        final calendars = await _calendarActions.retrieveCalendars();
        emit(CalendarSuccess(calendars: calendars));
      }
    } catch (e) {
      emit(const CalendarError(message: "error while fetching calendars"));
    }
  }
}