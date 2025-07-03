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

      return {
        calendar: [event]
      };
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
        );

        return {
          calendar: [...data[calendar] ?? [], event]
        };
      }).forEach(emit);
    }
  }
}
