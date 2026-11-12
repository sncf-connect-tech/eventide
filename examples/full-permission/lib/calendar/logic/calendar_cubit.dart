import 'package:eventide/eventide.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timezone/timezone.dart';
import 'package:value_state/value_state.dart';

typedef CalendarState = Value<CalendarData>;

class CalendarData {
  final Map<ETCalendar, Iterable<ETEvent>> calendars;
  final Set<String> visibleCalendarIds;
  final Iterable<ETAccount> availableAccounts;

  CalendarData({required this.calendars, required this.visibleCalendarIds, this.availableAccounts = const []});

  CalendarData copyWith({
    Map<ETCalendar, Iterable<ETEvent>>? calendars,
    Set<String>? visibleCalendarIds,
    Iterable<ETAccount>? availableAccounts,
  }) {
    return CalendarData(
      calendars: calendars ?? this.calendars,
      visibleCalendarIds: visibleCalendarIds ?? this.visibleCalendarIds,
      availableAccounts: availableAccounts ?? this.availableAccounts,
    );
  }

  Map<ETCalendar, Iterable<ETEvent>> get visibleCalendars {
    return Map.fromEntries(calendars.entries.where((entry) => visibleCalendarIds.contains(entry.key.id)));
  }
}

final class CalendarCubit extends Cubit<CalendarState> {
  final Eventide _eventide;

  CalendarCubit({required this._eventide}) : super(Value.initial());

  Iterable<ETAccount> _cachedAccounts = const [];

  Future<void> loadAvailableAccounts() async {
    final accounts = await _eventide.retrieveAccounts();
    _cachedAccounts = accounts;

    if (state case Value(:final data?)) {
      emit(Value.success(data.copyWith(availableAccounts: accounts)));
    }
  }

  DateTime _currentVisibleMonth = DateTime.now();

  Future<Map<ETCalendar, Iterable<ETEvent>>> _fetchCalendarsWithEvents() async {
    final startOfMonth = DateTime(_currentVisibleMonth.year, _currentVisibleMonth.month, 1);
    final startDate = startOfMonth.subtract(const Duration(days: 7));
    final endDate = DateTime(_currentVisibleMonth.year, _currentVisibleMonth.month + 1, 1).add(const Duration(days: 7));

    var calendars = <ETCalendar, Iterable<ETEvent>>{};
    for (final calendar in await _eventide.retrieveCalendars()) {
      final events = await _eventide.retrieveEvents(calendarId: calendar.id, startDate: startDate, endDate: endDate);
      calendars[calendar] = events;
    }
    return calendars;
  }

  Future<void> loadEventsForMonth(DateTime date) async {
    _currentVisibleMonth = date;
    await state
        .fetchFrom(() async {
          final calendars = await _fetchCalendarsWithEvents();
          final currentData = state.data;
          final allCalendarIds = calendars.keys.map((cal) => cal.id).toSet();
          final visibleCalendarIds = currentData?.visibleCalendarIds ?? allCalendarIds;

          return CalendarData(
            calendars: calendars,
            visibleCalendarIds: visibleCalendarIds,
            availableAccounts: currentData?.availableAccounts ?? _cachedAccounts,
          );
        })
        .forEach(emit);
  }

  Future<void> loadFullContent() => loadEventsForMonth(_currentVisibleMonth);

  Future<void> createCalendar({required String title, required Color color, ETAccount? account}) async {
    await state
        .fetchFrom(() async {
          await _eventide.createCalendar(title: title, color: color, account: account);

          final calendars = await _fetchCalendarsWithEvents();
          final currentData = state.data;
          final visibleCalendarIds = currentData?.visibleCalendarIds ?? <String>{};
          final allCalendarIds = calendars.keys.map((cal) => cal.id).toSet();

          visibleCalendarIds.addAll(allCalendarIds);

          return CalendarData(
            calendars: calendars,
            visibleCalendarIds: visibleCalendarIds,
            availableAccounts: currentData?.availableAccounts ?? [],
          );
        })
        .forEach(emit);

    if (state.error != null) {
      throw state.error!;
    }
  }

  Future<void> createEvent({
    required ETCalendar calendar,
    required String title,
    required String description,
    required bool isAllDay,
    required TZDateTime startDate,
    required TZDateTime endDate,
    String? recurrenceRule,
  }) async {
    if (state case Value(:final data?)) {
      await state
          .fetchFrom(() async {
            final event = await _eventide.createEvent(
              title: title,
              description: description,
              isAllDay: isAllDay,
              startDate: startDate,
              endDate: endDate,
              calendarId: calendar.id,
              recurrenceRule: recurrenceRule,
              reminders: [Duration(hours: 1), Duration(minutes: 10)],
            );

            if (recurrenceRule != null) {
              final calendars = await _fetchCalendarsWithEvents();
              return data.copyWith(calendars: calendars);
            }

            final updatedCalendars = Map<ETCalendar, List<ETEvent>>.from(data.calendars);
            updatedCalendars[calendar] = [...data.calendars[calendar] ?? [], event];

            return data.copyWith(calendars: updatedCalendars);
          })
          .forEach(emit);
    }
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

  Future<void> updateCalendar({required ETCalendar calendar, required String title, required Color color}) async {
    if (state case Value(:final data?)) {
      await state
          .fetchFrom(() async {
            final updatedCalendar = await _eventide.updateCalendar(calendar, title: title, color: color);

            final updatedCalendars = <ETCalendar, Iterable<ETEvent>>{};
            for (final entry in data.calendars.entries) {
              if (entry.key.id == calendar.id) {
                updatedCalendars[updatedCalendar] = entry.value;
              } else {
                updatedCalendars[entry.key] = entry.value;
              }
            }

            return data.copyWith(calendars: updatedCalendars);
          })
          .forEach(emit);
    }
  }

  Future<void> updateEvent({
    required ETCalendar calendar,
    required ETEvent event,
    required String title,
    required String description,
    required bool isAllDay,
    required TZDateTime startDate,
    required TZDateTime endDate,
    String? recurrenceRule,
    ETSpan span = ETSpan.thisEvent,
  }) async {
    if (state case Value(:final data?)) {
      await state
          .fetchFrom(() async {
            await _eventide.updateEvent(
              event,
              title: title,
              description: description,
              isAllDay: isAllDay,
              startDate: startDate,
              endDate: endDate,
              recurrenceRule: recurrenceRule,
              span: span,
              originalInstanceDate: event.originalInstanceDate,
            );

            final calendars = await _fetchCalendarsWithEvents();
            return data.copyWith(calendars: calendars);
          })
          .forEach(emit);
    }
  }

  Future<void> deleteEvent({required ETEvent event, ETSpan span = ETSpan.thisEvent}) async {
    if (state case Value(:final data?)) {
      await state
          .fetchFrom(() async {
            await _eventide.deleteEvent(
              eventId: event.id,
              span: span,
              originalInstanceDate: event.originalInstanceDate,
            );

            final calendars = await _fetchCalendarsWithEvents();
            return data.copyWith(calendars: calendars);
          })
          .forEach(emit);
    }
  }
}
