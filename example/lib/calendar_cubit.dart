import 'package:flutter/foundation.dart';
import 'package:flutter_calendar_connect/calendar_plugin.dart';
import 'package:flutter_calendar_connect_example/calendar_state.dart';
import 'package:value_cubit/value_cubit.dart';

class CalendarCubit extends ValueCubit<CalendarValue> {
  final CalendarActions _calendarActions;

  CalendarCubit({
    @visibleForTesting CalendarActions? calendarActions,
  }) : _calendarActions = calendarActions ?? CalendarActions();

  void init() {
    emit(const CalendarValue(calendars: []).toState());
  }

  Future<void> fetchCalendars() async {
    await state.withValue((value) async {
      await perform(() async {
        if (await _requestCalendarAccess()) {
          final calendars = await _calendarActions.retrieveCalendars();

          emit(value.copyWith(
            calendars: calendars.whereType<Calendar>().toList(growable: false),
          ).toState());
        }
      });
    });
  }

  Future<bool> _requestCalendarAccess() async {
    var permissionGranted = false;

    try {
      permissionGranted = await _calendarActions.requestCalendarAccess();

    } catch (e) {
      print(e);
    }

    return permissionGranted;
  }
}