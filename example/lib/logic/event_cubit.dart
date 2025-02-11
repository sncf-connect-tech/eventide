import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eventide_example/logic/event_state.dart';
import 'package:eventide/eventide.dart';
import 'package:timezone/timezone.dart';
import 'package:value_state/value_state.dart';

class EventCubit extends Cubit<EventState> {
  final Eventide _calendarPlugin;
  
  EventCubit({
    required Eventide calendarPlugin,
  }) :  _calendarPlugin = calendarPlugin,
        super(const EventState.initial());

  
  Future<void> createEvent({
    required String title,
    required String description,
    required bool isAllDay,
    required TZDateTime startDate,
    required TZDateTime endDate,
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

  Future<void> deleteEvent(String eventId) async {
    if (state case Value(:final data?)) {
      await state.fetchFrom(() async {
        await _calendarPlugin.deleteEvent(eventId: eventId);
        return EventValue(
          calendar: data.calendar,
          events: [...state.data?.events.where((event) => event.id != eventId) ?? []],
        );
      }).forEach(emit);
    }
  }

  Future<void> createReminder(Duration durationBeforeEvent, String eventId) async {
    if (state case Value(:final data?)) {
      await state.fetchFrom(() async {
        final event = await _calendarPlugin.createReminder(durationBeforeEvent: durationBeforeEvent, eventId: eventId);
        return EventValue(
          calendar: data.calendar,
          events: [
            ...data.events.where((e) => e.id != eventId),
            event,
          ],
        );
      }).forEach(emit);
    }
  }

  Future<void> deleteReminder(Duration durationBeforeEvent, String eventId) async {
    if (state case Value(:final data?)) {
      await state.fetchFrom(() async {
        final event = await _calendarPlugin.deleteReminder(durationBeforeEvent: durationBeforeEvent, eventId: eventId);
        return EventValue(
          calendar: data.calendar,
          events: [
            ...data.events.where((e) => e.id != eventId),
            event,
          ],
        );
      }).forEach(emit);
    }
  }
}