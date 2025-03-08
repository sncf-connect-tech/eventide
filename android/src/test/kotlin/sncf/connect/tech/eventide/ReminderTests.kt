package sncf.connect.tech.eventide

import android.content.ContentResolver
import android.database.Cursor
import android.net.Uri
import io.mockk.*
import kotlinx.coroutines.test.runTest
import org.junit.jupiter.api.Assertions.*
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import java.util.concurrent.CountDownLatch

class ReminderTests {
    private lateinit var contentResolver: ContentResolver
    private lateinit var permissionHandler: PermissionHandler
    private lateinit var calendarImplem: CalendarImplem
    private lateinit var calendarContentUri: Uri
    private lateinit var eventContentUri: Uri
    private lateinit var remindersContentUri: Uri

    @BeforeEach
    fun setup() {
        contentResolver = mockk(relaxed = true)
        permissionHandler = mockk(relaxed = true)
        calendarContentUri = mockk(relaxed = true)
        eventContentUri = mockk(relaxed = true)
        remindersContentUri = mockk(relaxed = true)

        calendarImplem = CalendarImplem(
            contentResolver = contentResolver,
            permissionHandler = permissionHandler,
            calendarContentUri = calendarContentUri,
            eventContentUri = eventContentUri,
            remindersContentUri = remindersContentUri,
        )
    }

    private fun mockPermissionGranted() {
        every { permissionHandler.requestWritePermission(any()) } answers {
            firstArg<(Boolean) -> Unit>().invoke(true)
        }
    }

    private fun mockPermissionDenied() {
        every { permissionHandler.requestWritePermission(any()) } answers {
            firstArg<(Boolean) -> Unit>().invoke(false)
        }
    }

    @Test
    fun createReminder_withGrantedPermission_createsReminderSuccessfully() = runTest {
        mockPermissionGranted()

        val eventId = "1"
        val minutes = 10L
        every { contentResolver.insert(remindersContentUri, any()) } returns mockk<Uri>(relaxed = true)

        val eventCursor = mockk<Cursor>(relaxed = true)
        every { contentResolver.query(eventContentUri, any(), any(), any(), any()) } returns eventCursor
        every { eventCursor.moveToNext() } returnsMany listOf(true, false)
        every { eventCursor.getLong(any()) } returns 1L
        every { eventCursor.getString(any()) } returns "Test Event"
        every { eventCursor.getLong(any()) } returns 0L

        val remindersCursor = mockk<Cursor>(relaxed = true)
        every { contentResolver.query(remindersContentUri, any(), any(), any(), any()) } returns remindersCursor
        every { remindersCursor.moveToNext() } returnsMany listOf(true, false)
        every { remindersCursor.getLong(any()) } returns 10L

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
        mockPermissionDenied()

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
        mockPermissionGranted()

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
        mockPermissionGranted()

        val eventId = "1"
        val minutes = 10L
        every { contentResolver.delete(remindersContentUri, any(), any()) } returns 1

        val eventCursor = mockk<Cursor>(relaxed = true)
        every { contentResolver.query(eventContentUri, any(), any(), any(), any()) } returns eventCursor
        every { eventCursor.moveToNext() } returnsMany listOf(true, false)
        every { eventCursor.getLong(any()) } returns 1L
        every { eventCursor.getString(any()) } returns "Test Event"
        every { eventCursor.getLong(any()) } returns 0L


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
        mockPermissionDenied()

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
        mockPermissionGranted()

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
        mockPermissionGranted()

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
