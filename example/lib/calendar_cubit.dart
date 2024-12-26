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

  Future<void> createCalendar({
    required String title,
    required int color,
  }) async {
    if (await _calendarActions.requestCalendarAccess()) {
      final calendar = await _calendarActions.createCalendar(title, color);
      
      if (state is CalendarSuccess) {
        final calendars = (state as CalendarSuccess).calendars;
        emit(CalendarSuccess(calendars: [...calendars, calendar]));
      } else {
        fetchCalendars(onlyWritable: false);
      }
    }
  }

  Future<void> fetchCalendars({required bool onlyWritable}) async {
    try {
      if (await _calendarActions.requestCalendarAccess()) {
        final calendars = await _calendarActions.retrieveCalendars(onlyWritableCalendars: onlyWritable);
        if (calendars.isEmpty) {
          emit(const CalendarNoValue());
        } else {
          emit(CalendarSuccess(calendars: calendars));
        }
      }
    } catch (e) {
      emit(CalendarError(message: e.toString()));
    }
  }
}