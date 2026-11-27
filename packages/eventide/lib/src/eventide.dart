import 'dart:ui';

import 'package:eventide_platform_interface/eventide_platform_interface.dart';

class Eventide {
  const Eventide();

  /// Creates a new calendar with the given [title], [color] and optional [account].
  ///
  /// If [account] is provided, the calendar will be created under that account.
  /// If [account] is null, the calendar will be created in the default account/source:
  /// - On iOS: Uses default source (local or iCloud)
  /// - On Android: Uses "local" as the account name
  ///
  /// Returns the created [ETCalendar].
  ///
  /// Throws a [ETPermissionException] if the user refuses to grant calendar permissions.
  ///
  /// Throws a [ETNotFoundException] on iOS if no suitable calendar source is found or if the created calendar id is not found.
  ///
  /// Throws a [ETGenericException] on iOS if the color hex cannot be converted to a UIColor.
  ///
  /// Throws a [ETGenericException] if any other error occurs during calendar creation.
  Future<ETCalendar> createCalendar({required String title, required Color color, ETAccount? account}) {
    return EventidePlatformInterface.instance.createCalendar(title: title, color: color, account: account);
  }

  /// Retrieves a list of calendars.
  /// If [onlyWritableCalendars] is `true`, only writable calendars are returned.
  ///
  /// If [account] is provided, only calendars from that account are returned.
  ///
  /// Returns a list of [ETCalendar]s.
  ///
  /// Throws a [ETPermissionException] if the user refuses to grant calendar permissions.
  ///
  /// Throws a [ETGenericException] if any other error occurs during calendars retrieval.
  Future<Iterable<ETCalendar>> retrieveCalendars({bool onlyWritableCalendars = true, ETAccount? account}) {
    return EventidePlatformInterface.instance.retrieveCalendars(
      onlyWritableCalendars: onlyWritableCalendars,
      account: account,
    );
  }

  /// Retrieves all available accounts from the device.
  ///
  /// Returns a list of [ETAccount] representing all accounts that have calendars.
  /// This includes Google accounts, local accounts, Exchange accounts, etc.
  ///
  /// Throws a [ETPermissionException] if the user refuses to grant calendar permissions.
  ///
  /// Throws a [ETGenericException] if any other error occurs during accounts retrieval.
  Future<Iterable<ETAccount>> retrieveAccounts() {
    return EventidePlatformInterface.instance.retrieveAccounts();
  }

  /// Updates the given [calendar] with optional new values for [title] and [color].
  /// Only the provided parameters will be updated, the others will remain unchanged.
  ///
  /// Returns the updated [ETCalendar].
  ///
  /// Throws a [ETPermissionException] if the user refuses to grant calendar permissions.
  ///
  /// Throws a [ETNotFoundException] if the calendar with the given [calendar.id] is not found.
  ///
  /// Throws a [ETNotEditableException] if the calendar is not editable.
  ///
  /// Throws a [ETGenericException] if any other error occurs during calendar update.
  Future<ETCalendar> updateCalendar(ETCalendar calendar, {String? title, Color? color}) {
    return EventidePlatformInterface.instance.updateCalendar(calendar, title: title, color: color);
  }

  /// Deletes the calendar with the given [calendarId].
  ///
  /// Throws a [ETPermissionException] if the user refuses to grant calendar permissions.
  ///
  /// Throws a [ETNotFoundException] if the calendar with the given [calendarId] is not found.
  ///
  /// Throws a [ETNotEditableException] if the calendar is not editable.
  ///
  /// Throws a [ETGenericException] if any other error occurs during calendar deletion.
  Future<void> deleteCalendar({required String calendarId}) {
    return EventidePlatformInterface.instance.deleteCalendar(calendarId: calendarId);
  }

  /// Creates a new event with the given [title], [startDate], [endDate], and [calendarId].
  /// Optionally, you can provide a [description], [url], [location], and a list of [reminders] duration.
  ///
  /// /!\ Note that a [Duration] in seconds will not be supported by Android for API limitations.
  ///
  /// Returns the created [ETEvent].
  ///
  /// Throws a [ETPermissionException] if the user refuses to grant calendar permissions.
  ///
  /// Throws a [ETNotFoundException] if the calendar with the given [calendarId] is not found or if the created event id is not found.
  ///
  /// Throws a [ETGenericException] if any other error occurs during event creation.
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
    return EventidePlatformInterface.instance.createEvent(
      calendarId: calendarId,
      title: title,
      startDate: startDate,
      endDate: endDate,
      isAllDay: isAllDay,
      description: description,
      url: url,
      location: location,
      reminders: reminders,
      recurrenceRule: recurrenceRule,
    );
  }

  /// Creates a new event in the default calendar with the given [title], [startDate], [endDate].
  /// Optionally, you can provide a [description], [url], [location], and a list of [reminders] duration.
  ///
  /// On iOS, this method will prompt user for write only permission and will insert your event in user's default calendar.
  ///
  /// On Android, this method will prompt user to choose the calendar app whom they want the event added into.
  /// It is the same Android native implementation as [createEventThroughNativePlatform].
  ///
  /// /!\ Note that a [Duration] in seconds will not be supported by Android for API limitations.
  ///
  /// Throws a [ETPermissionException] if the user refuses to grant calendar permissions.
  ///
  /// Throws a [ETNotFoundException] if the default calendar is not found or if the created event id is not found.
  ///
  /// Throws a [ETGenericException] if any other error occurs during event creation.
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
    return EventidePlatformInterface.instance.createEventInDefaultCalendar(
      title: title,
      startDate: startDate,
      endDate: endDate,
      isAllDay: isAllDay,
      description: description,
      url: url,
      location: location,
      reminders: reminders,
      recurrenceRule: recurrenceRule,
    );
  }

  /// Creates a new event with optional [title], [startDate], [endDate], [isAllDay], [description], [url], [location], and a list of [reminders] duration.
  ///
  /// On iOS, this method will present the native event creation UI with the provided parameters pre-filled. The user can then choose to create the event or cancel the operation.
  ///
  /// On Android, this method will prompt user to choose the calendar app whom they want the event added into.
  /// It is the same Android native implementation as [createEventInDefaultCalendar].
  ///
  /// /!\ Note that a [Duration] in seconds will not be supported by Android for API limitations.
  ///
  /// Throws a [ETPresentationException] if there is an error presenting the native event creation UI.
  ///
  /// Throws a [ETUserCanceledException] if the user cancels the event creation.
  ///
  /// Throws a [ETGenericException] if any other error occurs during event creation.
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
    return EventidePlatformInterface.instance.createEventThroughNativePlatform(
      title: title,
      startDate: startDate,
      endDate: endDate,
      isAllDay: isAllDay,
      description: description,
      url: url,
      location: location,
      reminders: reminders,
      recurrenceRule: recurrenceRule,
    );
  }

  /// Retrieves a list of events from the calendar with the given [calendarId].
  /// Optionally, you can provide a [startDate] and [endDate] to filter the events.
  ///
  /// Returns a list of [ETEvent]s.
  ///
  /// Throws a [ETPermissionException] if the user refuses to grant calendar permissions.
  ///
  /// Throws a [ETNotFoundException] if the calendar with the given [calendarId] is not found.
  ///
  /// Throws a [ETGenericException] if any other error occurs during events retrieval.
  Future<Iterable<ETEvent>> retrieveEvents({required String calendarId, DateTime? startDate, DateTime? endDate}) {
    return EventidePlatformInterface.instance.retrieveEvents(
      calendarId: calendarId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Updates the given [event] with optional new values for [calendarId], [title], [startDate], [endDate], [isAllDay], [description], [url], [location], and a list of [reminders] duration.
  /// Only the provided parameters will be updated, the others will remain unchanged.
  ///
  /// Returns the updated [ETEvent].
  ///
  /// Throws a [ETPermissionException] if the user refuses to grant calendar permissions.
  ///
  /// Throws a [ETNotFoundException] if the event with the given [event.id] is not found or if the new calendar with the given [calendarId] is not found.
  ///
  /// Throws a [ETNotEditableException] if the calendar is not editable.
  ///
  /// Throws a [ETGenericException] if any other error occurs during event update.
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
    return EventidePlatformInterface.instance.updateEvent(
      event,
      calendarId: calendarId,
      title: title,
      startDate: startDate,
      endDate: endDate,
      isAllDay: isAllDay,
      description: description,
      url: url,
      location: location,
      reminders: reminders,
      recurrenceRule: recurrenceRule,
      span: span,
      originalInstanceDate: originalInstanceDate,
    );
  }

  /// Deletes the event with the given [eventId].
  ///
  /// Throws a [ETPermissionException] if the user refuses to grant calendar permissions.
  ///
  /// Throws a [ETNotFoundException] if the event with the given [eventId] is not found.
  ///
  /// Throws a [ETNotEditableException] if the calendar is not editable.
  ///
  /// Throws a [ETGenericException] if any other error occurs during event deletion.
  Future<void> deleteEvent({required String eventId, ETSpan span = ETSpan.thisEvent, DateTime? originalInstanceDate}) {
    return EventidePlatformInterface.instance.deleteEvent(
      eventId: eventId,
      span: span,
      originalInstanceDate: originalInstanceDate,
    );
  }

  /// Creates a new reminder with the given [durationBeforeEvent] for the event with the given [eventId].
  ///
  /// /!\ Note that a [Duration] in seconds will not be supported by Android for API limitations.
  ///
  /// Throws a [ETPermissionException] if the user refuses to grant calendar permissions.
  ///
  /// Throws a [ETNotFoundException] if the event with the given [eventId] is not found.
  ///
  /// Throws a [ETGenericException] if any other error occurs during reminder creation.
  Future<ETEvent> createReminder({
    required String eventId,
    required Duration durationBeforeEvent,
    ETSpan span = ETSpan.thisEvent,
    DateTime? originalInstanceDate,
  }) {
    return EventidePlatformInterface.instance.createReminder(
      eventId: eventId,
      durationBeforeEvent: durationBeforeEvent,
      span: span,
      originalInstanceDate: originalInstanceDate,
    );
  }

  /// Deletes the reminder with the given [durationBeforeEvent] for the event with the given [eventId].
  ///
  /// Throws a [ETPermissionException] if the user refuses to grant calendar permissions.
  ///
  /// Throws a [ETNotFoundException] if the event with the given [eventId] is not found.
  ///
  /// Throws a [ETGenericException] if any other error occurs during reminder deletion.
  Future<ETEvent> deleteReminder({
    required String eventId,
    required Duration durationBeforeEvent,
    ETSpan span = ETSpan.thisEvent,
    DateTime? originalInstanceDate,
  }) {
    return EventidePlatformInterface.instance.deleteReminder(
      eventId: eventId,
      durationBeforeEvent: durationBeforeEvent,
      span: span,
      originalInstanceDate: originalInstanceDate,
    );
  }

  /// Creates a new attendee with the given [name], [email], and [type] for the event with the given [eventId].
  ///
  /// Throws a [ETNotSupportedByPlatform] if the method is called on iOS. Make sure you handle it.
  ///
  /// Throws a [ETPermissionException] if the user refuses to grant calendar permissions.
  ///
  /// Throws a [ETNotFoundException] if the event with the given [eventId] is not found.
  ///
  /// Throws a [ETGenericException] if any other error occurs during attendee creation.
  Future<ETEvent> createAttendee({
    required String eventId,
    required String name,
    required String email,
    required ETAttendeeType type,
    ETSpan span = ETSpan.thisEvent,
    DateTime? originalInstanceDate,
  }) {
    return EventidePlatformInterface.instance.createAttendee(
      eventId: eventId,
      name: name,
      email: email,
      type: type,
      span: span,
      originalInstanceDate: originalInstanceDate,
    );
  }

  /// Deletes the attendee with the given [attendee] for the event with the given [eventId].
  ///
  /// Throws a [ETNotSupportedByPlatform] if the method is called on iOS. Make sure you handle it.
  ///
  /// Throws a [ETPermissionException] if the user refuses to grant calendar permissions.
  ///
  /// Throws a [ETNotFoundException] if the event with the given [eventId] is not found.
  ///
  /// Throws a [ETGenericException] if any other error occurs during attendee deletion.
  Future<ETEvent> deleteAttendee({
    required String eventId,
    required ETAttendee attendee,
    ETSpan span = ETSpan.thisEvent,
    DateTime? originalInstanceDate,
  }) {
    return EventidePlatformInterface.instance.deleteAttendee(
      eventId: eventId,
      attendee: attendee,
      span: span,
      originalInstanceDate: originalInstanceDate,
    );
  }
}
