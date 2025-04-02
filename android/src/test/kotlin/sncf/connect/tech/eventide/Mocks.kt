package sncf.connect.tech.eventide

import android.content.ContentResolver
import android.database.Cursor
import android.net.Uri
import io.mockk.every
import io.mockk.mockk

fun mockRetrieveEvents(contentResolver: ContentResolver, eventContentUri: Uri) {
    val eventCursor = mockk<Cursor>(relaxed = true)
    every { contentResolver.query(eventContentUri, any(), any(), any(), any()) } returns eventCursor
    every { eventCursor.moveToNext() } returnsMany listOf(true, false)
    every { eventCursor.getString(any()) } returnsMany listOf("eventId", "eventTitle", "eventDescription", "calendarId")
    every { eventCursor.getInt(any()) } returns 0
    every { eventCursor.getLong(any()) } returnsMany listOf(1L, 1L)
}

fun mockRetrieveAttendees(contentResolver: ContentResolver, attendeesContentUri: Uri) {
    val attendeesCursor = mockk<Cursor>(relaxed = true)
    every { contentResolver.query(attendeesContentUri, any(), any(), any(), any()) } returns attendeesCursor
    every { attendeesCursor.moveToNext() } returnsMany listOf(true, false)
    every { attendeesCursor.getString(any()) } returnsMany listOf("John Doe", "john.doe@example.com")
    every { attendeesCursor.getInt(any()) } returnsMany listOf(1, 1, 1)
}

fun mockRetrieveReminders(contentResolver: ContentResolver, remindersContentUri: Uri) {
    val remindersCursor = mockk<Cursor>(relaxed = true)
    every { contentResolver.query(remindersContentUri, any(), any(), any(), any()) } returns remindersCursor
    every { remindersCursor.moveToNext() } returnsMany listOf(true, false)
    every { remindersCursor.getInt(any()) } returns 0
    every { remindersCursor.getLong(any()) } returnsMany listOf(10)
}

fun mockPermissionGranted(permissionHandler: PermissionHandler) {
    every { permissionHandler.requestWritePermission(any()) } answers {
        firstArg<(Boolean) -> Unit>().invoke(true)
    }

    every { permissionHandler.requestReadPermission(any()) } answers {
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
}
