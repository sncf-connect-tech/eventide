import 'package:eventide/eventide.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timezone/timezone.dart';
import 'package:value_state/value_state.dart';

typedef CalendarState = Value<CalendarData>;

typedef CalendarData = Map<ETCalendar, List<ETEvent>>;

final class CalendarCubit extends Cubit<CalendarState> {
  final Eventide _eventide;

  CalendarCubit({
    required Eventide eventide,
  })  : _eventide = eventide,
        super(Value.initial());

  Future<void> loadFullContent() async {
    await state.fetchFrom(() async {
      var data = <ETCalendar, List<ETEvent>>{};

      for (final calendar in await _eventide.retrieveCalendars()) {
        final events = await _eventide.retrieveEvents(calendarId: calendar.id);
        data[calendar] = events;
      }

      return data;
    }).forEach(emit);
  }

  Future<void> addEventToDefaultCalendar({
    required String title,
    required String description,
    required bool isAllDay,
    required TZDateTime startDate,
    required TZDateTime endDate,
  }) async {
    await state.fetchFrom(() async {
      final calendar = await _eventide.retrieveDefaultCalendar();

      if (calendar == null) {
        throw Exception('No default calendar found');
      }

      final event = await _eventide.createEvent(
        title: title,
        description: description,
        isAllDay: isAllDay,
        startDate: startDate,
        endDate: endDate,
        calendarId: calendar.id,
      );

      // TODO: Update this part to correctly update the state after event creation
      // Since createEvent now returns void, we need to refetch the events for the calendar
      // or update the local state optimistically.
      // For now, let's just reload the full content as a simple approach.
      await loadFullContent();

      return state.dataOrThrow;
    }).forEach(emit);
  }

  Future<void> createEvent({
    required ETCalendar calendar,
    required String title,
    required String description,
    required bool isAllDay,
    required TZDateTime startDate,
    required TZDateTime endDate,
    List<Duration>? reminders,
  }) async {
    await state.fetchFrom(() async {
      await _eventide.createEvent(
        title: title,
        description: description,
        isAllDay: isAllDay,
        startDate: startDate,
        endDate: endDate,
        calendarId: calendar.id,
        reminders: reminders,
      );
      // TODO: Update this part to correctly update the state after event creation
      // Since createEvent now returns void, we need to refetch the events for the calendar
      // or update the local state optimistically.
      // For now, let's just reload the full content as a simple approach.
      await loadFullContent();
      return state.dataOrThrow;
    }).forEach(emit);
  }
}
