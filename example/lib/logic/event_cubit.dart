import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_calendar_connect/calendar_api.g.dart';
import 'package:flutter_calendar_connect/flutter_calendar_connect.dart';
import 'package:flutter_calendar_connect_example/logic/event_state.dart';
import 'package:value_state/value_state.dart';

class EventCubit extends Cubit<EventState> {
  final FlutterCalendarConnect _calendarPlugin;
  
  EventCubit({
    required FlutterCalendarConnect calendarPlugin,
  }) :  _calendarPlugin = calendarPlugin,
        super(const EventState.initial());

  
  Future<void> createEvent({
    required String title,
    required String description,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (state case Value(:final data?)) {
      await state.fetchFrom(() async {
        final event = await _calendarPlugin.createEvent(
          title: title,
          description: description,
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

  Future<void> selectCalendar(Calendar calendar) async {
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
        await _calendarPlugin.deleteEvent(eventId: eventId, calendarId: data.calendar.id);
        return EventValue(
          calendar: data.calendar,
          events: [...state.data?.events.where((event) => event.id != eventId) ?? []],
        );
      }).forEach(emit);
    }
  }

  Future<void> createReminder(int minutes, String eventId) async {
    await _calendarPlugin.createReminder(minutes: minutes, eventId: eventId);
  }

  Future<int> getNumberOfReminders(String eventId) async {
    final reminders = await _calendarPlugin.retrieveReminders(eventId: eventId);
    return reminders.length;
  }
}