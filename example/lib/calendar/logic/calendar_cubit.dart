import 'package:eventide/eventide.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timezone/timezone.dart';
import 'package:value_state/value_state.dart';

typedef CalendarState = Value<CalendarData>;

class CalendarData {
  final Map<ETCalendar, List<ETEvent>> calendars;
  final Set<String> visibleCalendarIds;

  CalendarData({
    required this.calendars,
    required this.visibleCalendarIds,
  });

  CalendarData copyWith({
    Map<ETCalendar, List<ETEvent>>? calendars,
    Set<String>? visibleCalendarIds,
  }) {
    return CalendarData(
      calendars: calendars ?? this.calendars,
      visibleCalendarIds: visibleCalendarIds ?? this.visibleCalendarIds,
    );
  }

  Map<ETCalendar, List<ETEvent>> get visibleCalendars {
    return Map.fromEntries(calendars.entries.where((entry) => visibleCalendarIds.contains(entry.key.id)));
  }
}

final class CalendarCubit extends Cubit<CalendarState> {
  final Eventide _eventide;

  CalendarCubit({
    required Eventide eventide,
  })  : _eventide = eventide,
        super(Value.initial());

  Future<void> loadFullContent() async {
    await state.fetchFrom(() async {
      var calendars = <ETCalendar, List<ETEvent>>{};

      for (final calendar in await _eventide.retrieveCalendars()) {
        final events = await _eventide.retrieveEvents(calendarId: calendar.id);
        calendars[calendar] = events;
      }

      final visibleCalendarIds = calendars.keys.map((cal) => cal.id).toSet();

      return CalendarData(
        calendars: calendars,
        visibleCalendarIds: visibleCalendarIds,
      );
    }).forEach(emit);
  }

  Future<void> createCalendar({
    required String title,
    required Color color,
    required String localAccountName,
  }) async {
    await state.fetchFrom(() async {
      await _eventide.createCalendar(
        title: title,
        color: color,
        localAccountName: localAccountName,
      );

      var calendars = <ETCalendar, List<ETEvent>>{};
      for (final calendar in await _eventide.retrieveCalendars()) {
        final events = await _eventide.retrieveEvents(calendarId: calendar.id);
        calendars[calendar] = events;
      }

      final currentData = state.data;
      final visibleCalendarIds = currentData?.visibleCalendarIds ?? <String>{};
      final allCalendarIds = calendars.keys.map((cal) => cal.id).toSet();

      visibleCalendarIds.addAll(allCalendarIds);

      return CalendarData(
        calendars: calendars,
        visibleCalendarIds: visibleCalendarIds,
      );
    }).forEach(emit);
  }

  Future<void> createEvent({
    required ETCalendar calendar,
    required String title,
    required String description,
    required bool isAllDay,
    required TZDateTime startDate,
    required TZDateTime endDate,
  }) async {
    if (state case Value(:final data?)) {
      await state.fetchFrom(() async {
        final event = await _eventide.createEvent(
          title: title,
          description: description,
          isAllDay: isAllDay,
          startDate: startDate,
          endDate: endDate,
          calendarId: calendar.id,
          reminders: [
            Duration(hours: 1),
            Duration(minutes: 10),
          ],
        );

        final updatedCalendars = Map<ETCalendar, List<ETEvent>>.from(data.calendars);
        updatedCalendars[calendar] = [...data.calendars[calendar] ?? [], event];

        return data.copyWith(calendars: updatedCalendars);
      }).forEach(emit);
    }
  }

  Future<void> createEventInDefaultCalendar({
    required String title,
    required String description,
    required bool isAllDay,
    required TZDateTime startDate,
    required TZDateTime endDate,
  }) async {
    await state.fetchFrom(() async {
      await _eventide.createEventInDefaultCalendar(
        title: title,
        description: description,
        isAllDay: isAllDay,
        startDate: startDate,
        endDate: endDate,
        reminders: [
          Duration(hours: 1),
          Duration(minutes: 10),
        ],
      );

      var calendars = <ETCalendar, List<ETEvent>>{};
      for (final calendar in await _eventide.retrieveCalendars()) {
        final events = await _eventide.retrieveEvents(calendarId: calendar.id);
        calendars[calendar] = events;
      }

      final currentData = state.data;
      final visibleCalendarIds = currentData?.visibleCalendarIds ?? calendars.keys.map((cal) => cal.id).toSet();

      return CalendarData(
        calendars: calendars,
        visibleCalendarIds: visibleCalendarIds,
      );
    }).forEach(emit);
  }

  void toggleCalendarVisibility(String calendarId) {
    if (state case Value(:final data?)) {
      final newVisibleIds = Set<String>.from(data.visibleCalendarIds);
      if (newVisibleIds.contains(calendarId)) {
        newVisibleIds.remove(calendarId);
      } else {
        newVisibleIds.add(calendarId);
      }

      emit(Value.success(data.copyWith(visibleCalendarIds: newVisibleIds)));
    }
  }
}
