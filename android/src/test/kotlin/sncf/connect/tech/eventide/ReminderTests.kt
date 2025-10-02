package sncf.connect.tech.eventide

import android.content.ContentResolver
import android.content.Context
import android.database.Cursor
import android.net.Uri
import android.provider.CalendarContract
import io.mockk.*
import kotlinx.coroutines.test.runTest
import org.junit.jupiter.api.Assertions.*
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import java.util.concurrent.CountDownLatch

class ReminderTests {
    private lateinit var context: Context
    private lateinit var contentResolver: ContentResolver
    private lateinit var permissionHandler: PermissionHandler
    private lateinit var activityManager: CalendarActivityManager
    private lateinit var calendarImplem: CalendarImplem
    private lateinit var calendarContentUri: Uri
    private lateinit var eventContentUri: Uri
    private lateinit var remindersContentUri: Uri
    private lateinit var attendeesContentUri: Uri

    @BeforeEach
    fun setup() {
        context = mockk(relaxed = true)
        contentResolver = mockk(relaxed = true)
        permissionHandler = mockk(relaxed = true)
        activityManager = mockk(relaxed = true)
        calendarContentUri = mockk(relaxed = true)
        eventContentUri = mockk(relaxed = true)
        remindersContentUri = mockk(relaxed = true)
        attendeesContentUri = mockk(relaxed = true)

        calendarImplem = CalendarImplem(
            contentResolver = contentResolver,
            permissionHandler = permissionHandler,
            activityManager = activityManager,
            calendarContentUri = calendarContentUri,
            eventContentUri = eventContentUri,
            remindersContentUri = remindersContentUri,
            attendeesContentUri = attendeesContentUri
        )
    }

    @Test
    fun createReminder_withGrantedPermission_createsReminderSuccessfully() = runTest {
        mockPermissionGranted(permissionHandler)

        val eventId = "1"
        val minutes = 10L
        every { contentResolver.insert(remindersContentUri, any()) } returns mockk<Uri>(relaxed = true)

        val eventCursor = mockk<Cursor>(relaxed = true)
        every { contentResolver.query(eventContentUri, any(), any(), any(), any()) } returns eventCursor
        every { eventCursor.moveToNext() } returnsMany listOf(true, false)

        // Mock column indices for events
        every { eventCursor.getColumnIndexOrThrow(CalendarContract.Events._ID) } returns 0
        every { eventCursor.getColumnIndexOrThrow(CalendarContract.Events.TITLE) } returns 1
        every { eventCursor.getColumnIndexOrThrow(CalendarContract.Events.DESCRIPTION) } returns 2
        every { eventCursor.getColumnIndexOrThrow(CalendarContract.Events.CALENDAR_ID) } returns 3
        every { eventCursor.getColumnIndexOrThrow(CalendarContract.Events.DTSTART) } returns 4
        every { eventCursor.getColumnIndexOrThrow(CalendarContract.Events.DTEND) } returns 5
        every { eventCursor.getColumnIndexOrThrow(CalendarContract.Events.ALL_DAY) } returns 6

        // Mock values for each column
        every { eventCursor.getString(0) } returns "1"
        every { eventCursor.getString(1) } returns "Test Event"
        every { eventCursor.getString(2) } returns null
        every { eventCursor.getString(3) } returns "1"
        every { eventCursor.getLong(4) } returns 0L
        every { eventCursor.getLong(5) } returns 0L
        every { eventCursor.getInt(6) } returns 0

        val remindersCursor = mockk<Cursor>(relaxed = true)
        every { contentResolver.query(remindersContentUri, any(), any(), any(), any()) } returns remindersCursor
        every { remindersCursor.moveToNext() } returnsMany listOf(true, false)

        // Mock column indices for reminders
        every { remindersCursor.getColumnIndexOrThrow(CalendarContract.Reminders._ID) } returns 0
        every { remindersCursor.getColumnIndexOrThrow(CalendarContract.Reminders.MINUTES) } returns 1
        every { remindersCursor.getColumnIndexOrThrow(CalendarContract.Reminders.METHOD) } returns 2

        // Mock values for each column
        every { remindersCursor.getLong(1) } returns 10L
        every { remindersCursor.getInt(2) } returns 0

        var result: Result<Event>? = null
        val latch = CountDownLatch(1)
        calendarImplem.createReminder(minutes, eventId) {
            result = it
            latch.countDown()
        }

        latch.await()

        assertTrue(result!!.isSuccess)
    }

    @Test
    fun createReminder_withDeniedPermission_failsToCreateReminder() = runTest {
        mockPermissionDenied(permissionHandler)

        val eventId = "1"
        val minutes = 10L

        var result: Result<Event>? = null
        calendarImplem.createReminder(minutes, eventId) {
            result = it
        }

        assertTrue(result!!.isFailure)
    }

    @Test
    fun createReminder_withException_failsToCreateReminder() = runTest {
        mockPermissionGranted(permissionHandler)

        val eventId = "1"
        val minutes = 10L
        every { contentResolver.insert(remindersContentUri, any()) } throws Exception("Insert failed")

        var result: Result<Event>? = null
        val latch = CountDownLatch(1)
        calendarImplem.createReminder(minutes, eventId) {
            result = it
            latch.countDown()
        }

        latch.await()

        assertTrue(result!!.isFailure)
    }

    @Test
    fun deleteReminder_withGrantedPermission_deletesReminderSuccessfully() = runTest {
        mockPermissionGranted(permissionHandler)

        val eventId = "1"
        val minutes = 10L
        every { contentResolver.delete(remindersContentUri, any(), any()) } returns 1

        val eventCursor = mockk<Cursor>(relaxed = true)
        every { contentResolver.query(eventContentUri, any(), any(), any(), any()) } returns eventCursor
        every { eventCursor.moveToNext() } returnsMany listOf(true, false)

        // Mock column indices for events
        every { eventCursor.getColumnIndexOrThrow(CalendarContract.Events._ID) } returns 0
        every { eventCursor.getColumnIndexOrThrow(CalendarContract.Events.TITLE) } returns 1
        every { eventCursor.getColumnIndexOrThrow(CalendarContract.Events.DESCRIPTION) } returns 2
        every { eventCursor.getColumnIndexOrThrow(CalendarContract.Events.CALENDAR_ID) } returns 3
        every { eventCursor.getColumnIndexOrThrow(CalendarContract.Events.DTSTART) } returns 4
        every { eventCursor.getColumnIndexOrThrow(CalendarContract.Events.DTEND) } returns 5
        every { eventCursor.getColumnIndexOrThrow(CalendarContract.Events.ALL_DAY) } returns 6

        // Mock values for each column
        every { eventCursor.getString(0) } returns "1"
        every { eventCursor.getString(1) } returns "Test Event"
        every { eventCursor.getString(2) } returns null
        every { eventCursor.getString(3) } returns "1"
        every { eventCursor.getLong(4) } returns 0L
        every { eventCursor.getLong(5) } returns 0L
        every { eventCursor.getInt(6) } returns 0

        val remindersCursor = mockk<Cursor>(relaxed = true)
        every { contentResolver.query(remindersContentUri, any(), any(), any(), any()) } returns remindersCursor
        every { remindersCursor.moveToNext() } returnsMany listOf(false, false)

        var result: Result<Event>? = null
        val latch = CountDownLatch(1)
        calendarImplem.deleteReminder(minutes, eventId) {
            result = it
            latch.countDown()
        }

        latch.await()

        assertTrue(result!!.isSuccess)
    }

    @Test
    fun deleteReminder_withDeniedPermission_failsToDeleteReminder() = runTest {
        mockPermissionDenied(permissionHandler)

        val eventId = "1"
        val minutes = 10L

        var result: Result<Event>? = null
        calendarImplem.deleteReminder(minutes, eventId) {
            result = it
        }

        assertTrue(result!!.isFailure)
    }

    @Test
    fun deleteReminder_withException_failsToDeleteReminder() = runTest {
        mockPermissionGranted(permissionHandler)

        val eventId = "1"
        val minutes = 10L
        every { contentResolver.delete(eventContentUri, any(), any()) } throws Exception("Delete failed")

        var result: Result<Event>? = null
        val latch = CountDownLatch(1)
        calendarImplem.deleteReminder(minutes, eventId) {
            result = it
            latch.countDown()
        }

        latch.await()

        assertTrue(result!!.isFailure)
    }

    @Test
    fun deleteReminder_withNoRowsDeleted_failsToDeleteReminder() = runTest {
        mockPermissionGranted(permissionHandler)

        val eventId = "1"
        val minutes = 10L
        every { contentResolver.delete(remindersContentUri, any(), any()) } returns 0

        var result: Result<Event>? = null
        val latch = CountDownLatch(1)
        calendarImplem.deleteReminder(minutes, eventId) {
            result = it
            latch.countDown()
        }

        latch.await()

        assertTrue(result!!.isFailure)
    }
}
