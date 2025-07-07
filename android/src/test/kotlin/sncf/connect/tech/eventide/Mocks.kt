package sncf.connect.tech.eventide

import android.content.ContentResolver
import android.database.Cursor
import android.net.Uri
import android.provider.CalendarContract
import io.mockk.every
import io.mockk.mockk

fun mockRetrieveEvents(contentResolver: ContentResolver, eventContentUri: Uri) {
    val eventCursor = mockk<Cursor>(relaxed = true)
    every { contentResolver.query(eventContentUri, any(), any(), any(), any()) } returns eventCursor
    every { eventCursor.moveToNext() } returnsMany listOf(true, false)

    // Mock column indices
    every { eventCursor.getColumnIndexOrThrow(CalendarContract.Events._ID) } returns 0
    every { eventCursor.getColumnIndexOrThrow(CalendarContract.Events.TITLE) } returns 1
    every { eventCursor.getColumnIndexOrThrow(CalendarContract.Events.DESCRIPTION) } returns 2
    every { eventCursor.getColumnIndexOrThrow(CalendarContract.Events.CALENDAR_ID) } returns 3
    every { eventCursor.getColumnIndexOrThrow(CalendarContract.Events.DTSTART) } returns 4
    every { eventCursor.getColumnIndexOrThrow(CalendarContract.Events.DTEND) } returns 5
    every { eventCursor.getColumnIndexOrThrow(CalendarContract.Events.ALL_DAY) } returns 6

    // Mock values for each column
    every { eventCursor.getString(0) } returns "eventId"
    every { eventCursor.getString(1) } returns "eventTitle"
    every { eventCursor.getString(2) } returns "eventDescription"
    every { eventCursor.getString(3) } returns "calendarId"
    every { eventCursor.getLong(4) } returns 1L
    every { eventCursor.getLong(5) } returns 1L
    every { eventCursor.getInt(6) } returns 0
}

fun mockRetrieveAttendees(contentResolver: ContentResolver, attendeesContentUri: Uri) {
    val attendeesCursor = mockk<Cursor>(relaxed = true)
    every { contentResolver.query(attendeesContentUri, any(), any(), any(), any()) } returns attendeesCursor
    every { attendeesCursor.moveToNext() } returnsMany listOf(true, false)

    // Mock column indices
    every { attendeesCursor.getColumnIndexOrThrow(CalendarContract.Attendees.ATTENDEE_NAME) } returns 0
    every { attendeesCursor.getColumnIndexOrThrow(CalendarContract.Attendees.ATTENDEE_EMAIL) } returns 1
    every { attendeesCursor.getColumnIndexOrThrow(CalendarContract.Attendees.ATTENDEE_RELATIONSHIP) } returns 2
    every { attendeesCursor.getColumnIndexOrThrow(CalendarContract.Attendees.ATTENDEE_STATUS) } returns 3
    every { attendeesCursor.getColumnIndexOrThrow(CalendarContract.Attendees.ATTENDEE_TYPE) } returns 4

    // Mock values for each column
    every { attendeesCursor.getString(0) } returns "John Doe"
    every { attendeesCursor.getString(1) } returns "john.doe@example.com"
    every { attendeesCursor.getInt(2) } returns 1
    every { attendeesCursor.getInt(3) } returns 1
    every { attendeesCursor.getInt(4) } returns 1
}

fun mockRetrieveReminders(contentResolver: ContentResolver, remindersContentUri: Uri) {
    val remindersCursor = mockk<Cursor>(relaxed = true)
    every { contentResolver.query(remindersContentUri, any(), any(), any(), any()) } returns remindersCursor
    every { remindersCursor.moveToNext() } returnsMany listOf(true, false)

    // Mock column indices
    every { remindersCursor.getColumnIndexOrThrow(CalendarContract.Reminders._ID) } returns 0
    every { remindersCursor.getColumnIndexOrThrow(CalendarContract.Reminders.MINUTES) } returns 1
    every { remindersCursor.getColumnIndexOrThrow(CalendarContract.Reminders.METHOD) } returns 2

    // Mock values for each column
    every { remindersCursor.getInt(2) } returns 0
    every { remindersCursor.getLong(1) } returns 10L
}

fun mockPermissionGranted(permissionHandler: PermissionHandler) {
    every { permissionHandler.requestWritePermission(any()) } answers {
        firstArg<(Boolean) -> Unit>().invoke(true)
    }

    every { permissionHandler.requestReadPermission(any()) } answers {
        firstArg<(Boolean) -> Unit>().invoke(true)
    }

    every { permissionHandler.requestReadAndWritePermissions(any()) } answers {
        firstArg<(Boolean) -> Unit>().invoke(true)
    }
}

fun mockPermissionDenied(permissionHandler: PermissionHandler) {
    every { permissionHandler.requestWritePermission(any()) } answers {
        firstArg<(Boolean) -> Unit>().invoke(false)
    }

    every { permissionHandler.requestReadPermission(any()) } answers {
        firstArg<(Boolean) -> Unit>().invoke(false)
    }

    every { permissionHandler.requestReadAndWritePermissions(any()) } answers {
        firstArg<(Boolean) -> Unit>().invoke(false)
    }
}

fun mockPrimaryCalendarFound(contentResolver: ContentResolver, calendarContentUri: Uri, calendarId: String = "1") {
    val cursor = mockk<Cursor>(relaxed = true)
    every { contentResolver.query(calendarContentUri, any(), any(), any(), any()) } returns cursor
    every { cursor.moveToNext() } returns true
    every { cursor.getColumnIndexOrThrow(CalendarContract.Calendars._ID) } returns 0
    every { cursor.getColumnIndexOrThrow(CalendarContract.Calendars.CALENDAR_ACCESS_LEVEL) } returns 1
    every { cursor.getString(0) } returns calendarId
    every { cursor.getInt(1) } returns CalendarContract.Calendars.CAL_ACCESS_CONTRIBUTOR
}

fun mockPrimaryCalendarNotWritable(contentResolver: ContentResolver, calendarContentUri: Uri) {
    val cursor = mockk<Cursor>(relaxed = true)
    every { contentResolver.query(calendarContentUri, any(), any(), any(), any()) } returns cursor
    every { cursor.moveToNext() } returns true
    every { cursor.getColumnIndexOrThrow(CalendarContract.Calendars._ID) } returns 0
    every { cursor.getColumnIndexOrThrow(CalendarContract.Calendars.CALENDAR_ACCESS_LEVEL) } returns 1
    every { cursor.getString(0) } returns "1"
    every { cursor.getInt(1) } returns CalendarContract.Calendars.CAL_ACCESS_READ
}

fun mockPrimaryCalendarNotFound(contentResolver: ContentResolver, calendarContentUri: Uri) {
    val cursor = mockk<Cursor>(relaxed = true)
    every { contentResolver.query(calendarContentUri, any(), any(), any(), any()) } returns cursor
    every { cursor.moveToNext() } returns false
}
