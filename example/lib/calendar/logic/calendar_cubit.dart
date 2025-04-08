import 'dart:ui';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eventide/eventide.dart';
import 'package:value_state/value_state.dart';

class CalendarCubit extends Cubit<Value<List<ETCalendar>>> {
  final Eventide _calendarPlugin;

  CalendarCubit({
    required Eventide calendarPlugin,
  })  : _calendarPlugin = calendarPlugin,
        super(const Value.initial());

  Future<void> createCalendar({
    required String title,
    required Color color,
  }) async {
    await state.fetchFrom(() async {
      final calendar = await _calendarPlugin.createCalendar(
        title: title,
        color: color,
        localAccountName: "My Company",
      );

      return [...state.data ?? [], calendar];
    }).forEach(emit);
  }

  Future<void> fetchCalendars({required bool onlyWritable}) async {
    await state.fetchFrom(() async {
      return await _calendarPlugin.retrieveCalendars(onlyWritableCalendars: onlyWritable);
    }).forEach(emit);
  }

  Future<void> deleteCalendar(String calendarId) async {
    await state.fetchFrom(() async {
      await _calendarPlugin.deleteCalendar(calendarId: calendarId);
      return [...state.data?.where((calendar) => calendar.id != calendarId) ?? []];
    }).forEach(emit);
  }
}
