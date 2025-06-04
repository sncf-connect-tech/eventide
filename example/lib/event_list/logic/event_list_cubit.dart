import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eventide_example/event_list/logic/event_list_state.dart';
import 'package:eventide/eventide.dart';
import 'package:rrule/rrule.dart';
import 'package:timezone/timezone.dart';
import 'package:value_state/value_state.dart';

class EventListCubit extends Cubit<EventListState> {
  final Eventide _calendarPlugin;

  EventListCubit({
    required Eventide calendarPlugin,
  })  : _calendarPlugin = calendarPlugin,
        super(const EventListState.initial());

  Future<void> createEvent({
    required String title,
    required String description,
    required bool isAllDay,
    required TZDateTime startDate,
    required TZDateTime endDate,
    required RecurrenceRule? rRule,
  }) async {
    if (state case Value(:final data?)) {
      await state.fetchFrom(() async {
        final event = await _calendarPlugin.createEvent(
          title: title,
          description: description,
          isAllDay: isAllDay,
          startDate: startDate,
          endDate: endDate,
          calendarId: data.calendar.id,
          rRule: rRule?.toString(),
        );
        return EventValue(
          calendar: data.calendar,
          events: [...state.data?.events ?? [], event],
        );
      }).forEach(emit);
    }
  }

  Future<void> selectCalendar(ETCalendar calendar) async {
    await state.fetchFrom(() async {
      return EventValue(
        calendar: calendar,
        events: await _calendarPlugin.retrieveEvents(calendarId: calendar.id),
      );
    }).forEach(emit);
  }

  Future<void> deleteEvent(String calendarId, String eventId, ETEventSpan span) async {
    if (state case Value(:final data?)) {
      await state.fetchFrom(() async {
        await _calendarPlugin.deleteEvent(calendarId: calendarId, eventId: eventId, span: span);
        return EventValue(
          calendar: data.calendar,
          events: [...state.data?.events.where((event) => event.id != eventId) ?? []],
        );
      }).forEach(emit);
    }
  }
}
