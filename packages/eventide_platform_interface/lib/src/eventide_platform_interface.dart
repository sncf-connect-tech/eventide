import 'dart:ui';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:eventide_platform_interface/src/account.dart';
import 'package:eventide_platform_interface/src/attendance.dart';
import 'package:eventide_platform_interface/src/calendar.dart';
import 'package:eventide_platform_interface/src/event.dart';

abstract class EventidePlatformInterface extends PlatformInterface {
  EventidePlatformInterface() : super(token: _token);

  static final Object _token = Object();

  static EventidePlatformInterface? _instance;

  static EventidePlatformInterface get instance {
    final instance = _instance;

    if (instance != null) {
      return instance;
    } else {
      throw UnsupportedError('eventide is unsupported on this platform');
    }
  }

  static set instance(EventidePlatformInterface instance) {
    PlatformInterface.verify(instance, _token);
    _instance = instance;
  }

  Future<ETCalendar> createCalendar({required String title, required Color color, ETAccount? account}) {
    throw UnimplementedError('createCalendar() has not been implemented.');
  }

  Future<Iterable<ETCalendar>> retrieveCalendars({bool onlyWritableCalendars = true, ETAccount? account}) {
    throw UnimplementedError('retrieveCalendars() has not been implemented.');
  }

  Future<Iterable<ETAccount>> retrieveAccounts() {
    throw UnimplementedError('retrieveAccounts() has not been implemented.');
  }

  Future<ETCalendar> updateCalendar(ETCalendar calendar, {String? title, Color? color}) {
    throw UnimplementedError('updateCalendar() has not been implemented.');
  }

  Future<void> deleteCalendar({required String calendarId}) {
    throw UnimplementedError('deleteCalendar() has not been implemented.');
  }

  Future<ETEvent> createEvent({
    required String calendarId,
    required String title,
    required DateTime startDate,
    required DateTime endDate,
    bool isAllDay = false,
    String? description,
    String? url,
    String? location,
    Iterable<Duration>? reminders,
    String? recurrenceRule,
  }) {
    throw UnimplementedError('createEvent() has not been implemented.');
  }

  Future<void> createEventInDefaultCalendar({
    required String title,
    required DateTime startDate,
    required DateTime endDate,
    bool isAllDay = false,
    String? description,
    String? url,
    String? location,
    Iterable<Duration>? reminders,
    String? recurrenceRule,
  }) {
    throw UnimplementedError('createEventInDefaultCalendar() has not been implemented.');
  }

  Future<void> createEventThroughNativePlatform({
    String? title,
    DateTime? startDate,
    DateTime? endDate,
    bool? isAllDay,
    String? description,
    String? url,
    String? location,
    Iterable<Duration>? reminders,
    String? recurrenceRule,
  }) {
    throw UnimplementedError('createEventThroughNativePlatform() has not been implemented.');
  }

  Future<Iterable<ETEvent>> retrieveEvents({required String calendarId, DateTime? startDate, DateTime? endDate}) {
    throw UnimplementedError('retrieveEvents() has not been implemented.');
  }

  Future<ETEvent> updateEvent(
    ETEvent event, {
    String? calendarId,
    String? title,
    DateTime? startDate,
    DateTime? endDate,
    bool? isAllDay,
    String? description,
    String? url,
    String? location,
    Iterable<Duration>? reminders,
    String? recurrenceRule,
    ETSpan span = ETSpan.thisEvent,
    DateTime? originalInstanceDate,
  }) {
    throw UnimplementedError('updateEvent() has not been implemented.');
  }

  Future<void> deleteEvent({required String eventId, ETSpan span = ETSpan.thisEvent, DateTime? originalInstanceDate}) {
    throw UnimplementedError('deleteEvent() has not been implemented.');
  }

  Future<ETEvent> createReminder({
    required String eventId,
    required Duration durationBeforeEvent,
    ETSpan span = ETSpan.thisEvent,
    DateTime? originalInstanceDate,
  }) {
    throw UnimplementedError('createReminder() has not been implemented.');
  }

  Future<ETEvent> deleteReminder({
    required String eventId,
    required Duration durationBeforeEvent,
    ETSpan span = ETSpan.thisEvent,
    DateTime? originalInstanceDate,
  }) {
    throw UnimplementedError('deleteReminder() has not been implemented.');
  }

  Future<ETEvent> createAttendee({
    required String eventId,
    required String name,
    required String email,
    required ETAttendeeType type,
    ETSpan span = ETSpan.thisEvent,
    DateTime? originalInstanceDate,
  }) {
    throw UnimplementedError('createAttendee() has not been implemented.');
  }

  Future<ETEvent> deleteAttendee({
    required String eventId,
    required ETAttendee attendee,
    ETSpan span = ETSpan.thisEvent,
    DateTime? originalInstanceDate,
  }) {
    throw UnimplementedError('deleteAttendee() has not been implemented.');
  }
}
