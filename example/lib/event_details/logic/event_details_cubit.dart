import 'package:eventide/eventide.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:value_state/value_state.dart';

final class EventDetailsCubit extends Cubit<Value<ETEvent>> {
  final Eventide _calendarPlugin;

  EventDetailsCubit({
    required ETEvent selectedEvent,
    required Eventide calendarPlugin,
  })  : _calendarPlugin = calendarPlugin,
        super(Value.success(selectedEvent));

  Future<void> deleteReminder(Duration durationBeforeEvent) async {
    if (state case Value(:final data?)) {
      await state.fetchFrom(() async {
        return await _calendarPlugin.deleteReminder(eventId: data.id, durationBeforeEvent: durationBeforeEvent);
      }).forEach(emit);
    }
  }

  Future<void> createAttendee({
    required String name,
    required String email,
    required ETAttendeeType type,
  }) async {
    if (state case Value(:final data?)) {
      await state.fetchFrom(() async {
        return await _calendarPlugin.createAttendee(eventId: data.id, name: name, email: email, type: type);
      }).forEach(emit);
    }
  }

  Future<void> removeAttendee(ETAttendee attendee) async {
    if (state case Value(:final data?)) {
      await state.fetchFrom(() async {
        return await _calendarPlugin.deleteAttendee(eventId: data.id, attendee: attendee);
      }).forEach(emit);
    }
  }
}
