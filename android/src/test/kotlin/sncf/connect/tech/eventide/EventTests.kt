package sncf.connect.tech.eventide

import android.content.ContentResolver
import android.database.Cursor
import android.net.Uri
import android.provider.CalendarContract
import io.mockk.every
import io.mockk.mockk
import kotlinx.coroutines.test.runTest
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import java.time.Instant
import java.util.concurrent.CountDownLatch

class EventTests {
    private lateinit var contentResolver: ContentResolver
    private lateinit var permissionHandler: PermissionHandler
    private lateinit var calendarImplem: CalendarImplem
    private lateinit var calendarContentUri: Uri
    private lateinit var eventContentUri: Uri
    private lateinit var remindersContentUri: Uri
    private lateinit var attendeesContentUri: Uri

    @BeforeEach
    fun setup() {
        contentResolver = mockk(relaxed = true)
        permissionHandler = mockk(relaxed = true)
        calendarContentUri = mockk(relaxed = true)
        eventContentUri = mockk(relaxed = true)
        remindersContentUri = mockk(relaxed = true)
        attendeesContentUri = mockk(relaxed = true)

        calendarImplem = CalendarImplem(
            contentResolver = contentResolver,
            permissionHandler = permissionHandler,
            calendarContentUri = calendarContentUri,
            eventContentUri = eventContentUri,
            remindersContentUri = remindersContentUri,
            attendeesContentUri = attendeesContentUri
        )
    }

    private fun mockWritableCalendar() {
        val cursor = mockk<Cursor>(relaxed = true)
        every { contentResolver.query(calendarContentUri, any(), any(), any(), any()) } returns cursor
        every { cursor.moveToNext() } returns true
        every { cursor.getInt(any()) } returns CalendarContract.Calendars.CAL_ACCESS_CONTRIBUTOR
    }

    private fun mockNotWritableCalendar() {
        val cursor = mockk<Cursor>(relaxed = true)
        every { contentResolver.query(calendarContentUri, any(), any(), any(), any()) } returns cursor
        every { cursor.moveToNext() } returns true
        every { cursor.getInt(any()) } returns CalendarContract.Calendars.CAL_ACCESS_READ
    }

    private fun mockCalendarNotFound() {
        val cursor = mockk<Cursor>(relaxed = true)
        every { contentResolver.query(calendarContentUri, any(), any(), any(), any()) } returns cursor
        every { cursor.moveToNext() } returns false
    }

    private fun mockCalendarIdFound() {
        val cursor = mockk<Cursor>(relaxed = true)
        every { contentResolver.query(eventContentUri, any(), any(), any(), any()) } returns cursor
        every { cursor.moveToNext() } returns true
        every { cursor.getLong(any()) } returns 1L
    }

    private fun mockCalendarIdNotFound() {
        val cursor = mockk<Cursor>(relaxed = true)
        every { contentResolver.query(eventContentUri, any(), any(), any(), any()) } returns cursor
        every { cursor.moveToNext() } returns false
    }

    @Test
    fun createEvent_withGrantedPermission_andWritableCalendar_createsEventSuccessfully() = runTest {
        mockPermissionGranted(permissionHandler)
        mockWritableCalendar()

        val uri = mockk<Uri>(relaxed = true)
        every { contentResolver.insert(any(), any()) } returns uri
        every { uri.lastPathSegment } returns "1"

        val startMilli = Instant.now().toEpochMilli()
        val endMilli = Instant.now().toEpochMilli()

        var result: Result<Event>? = null
        val latch = CountDownLatch(1)
        calendarImplem.createEvent(
            title = "Test Event",
            startDate = startMilli,
            endDate = endMilli,
            calendarId = "1",
            description = "Description",
            isAllDay = false,
            url = null,
            reminders = null
        ) {
            result = it
            latch.countDown()
        }

        latch.await()

        assertTrue(result!!.isSuccess)
        assertEquals(Event(
            id = "1",
            title = "Test Event",
            startDate = startMilli,
            endDate = endMilli,
            calendarId = "1",
            description = "Description",
            isAllDay = false,
            reminders = emptyList(),
            attendees = emptyList()
        ), result.getOrNull()!!)
    }

    @Test
    fun createEvent_withGrantedPermission_andNotWritableCalendar_returnsNotEditableError() = runTest {
        mockPermissionGranted(permissionHandler)
        mockNotWritableCalendar()

        var result: Result<Event>? = null
        val latch = CountDownLatch(1)
        calendarImplem.createEvent(
            title = "Test Event",
            startDate = Instant.now().toEpochMilli(),
            endDate = Instant.now().toEpochMilli(),
            calendarId = "1",
            description = "Description",
            isAllDay = false,
            url = null,
            reminders = null
        ) {
            result = it
            latch.countDown()
        }

        latch.await()

        assertTrue(result!!.isFailure)
        assertEquals("NOT_EDITABLE", (result.exceptionOrNull() as FlutterError).code)
    }

    @Test
    fun createEvent_withGrantedPermission_andNotFoundCalendar_returnsNotFoundError() = runTest {
        mockPermissionGranted(permissionHandler)
        mockCalendarNotFound()

        var result: Result<Event>? = null
        val latch = CountDownLatch(1)
        calendarImplem.createEvent(
            title = "Test Event",
            startDate = Instant.now().toEpochMilli(),
            endDate = Instant.now().toEpochMilli(),
            calendarId = "1",
            description = "Description",
            isAllDay = false,
            url = null,
            reminders = null
        ) {
            result = it
            latch.countDown()
        }

        latch.await()

        assertTrue(result!!.isFailure)
        assertEquals("NOT_FOUND", (result.exceptionOrNull() as FlutterError).code)
    }

    @Test
    fun createEvent_withDeniedPermission_returnsAccessRefusedError() = runTest {
        mockPermissionDenied(permissionHandler)

        var result: Result<Event>? = null
        calendarImplem.createEvent(
            title = "Test Event",
            startDate = Instant.now().toEpochMilli(),
            endDate = Instant.now().toEpochMilli(),
            calendarId = "1",
            description = "Description",
            isAllDay = false,
            url = null,
            reminders = null
        ) {
            result = it
        }

        assertTrue(result!!.isFailure)
        assertEquals("ACCESS_REFUSED", (result.exceptionOrNull() as FlutterError).code)
    }

    @Test
    fun createEvent_withInvalidUri_returnsNotFoundError() = runTest {
        mockPermissionGranted(permissionHandler)

        every { contentResolver.insert(any(), any()) } returns null

        var result: Result<Event>? = null
        val latch = CountDownLatch(1)
        calendarImplem.createEvent(
            title = "Test Event",
            startDate = Instant.now().toEpochMilli(),
            endDate = Instant.now().toEpochMilli(),
            calendarId = "1",
            description = "Description",
            isAllDay = false,
            url = null,
            reminders = null

        ) {
            result = it
            latch.countDown()
        }

        latch.await()

        assertTrue(result!!.isFailure)
        assertEquals("NOT_FOUND", (result.exceptionOrNull() as FlutterError).code)
    }

    @Test
    fun retrieveEvents_withGrantedPermission_returnsEvents() = runTest {
        mockPermissionGranted(permissionHandler)

        mockRetrieveEvents(contentResolver, eventContentUri)
        mockRetrieveAttendees(contentResolver, attendeesContentUri)
        mockRetrieveReminders(contentResolver, remindersContentUri)

        var result: Result<List<Event>>? = null
        val latch = CountDownLatch(1)
        calendarImplem.retrieveEvents("1", 0L, 0L) {
            result = it
            latch.countDown()
        }

        latch.await()

        assertTrue(result!!.isSuccess)
        assertEquals(1, result.getOrNull()?.size)
    }

    @Test
    fun retrieveEvents_withDeniedPermission_returnsAccessRefusedError() = runTest {
        mockPermissionDenied(permissionHandler)

        var result: Result<List<Event>>? = null
        calendarImplem.retrieveEvents("1", 0L, 0L) {
            result = it
        }

        assertTrue(result!!.isFailure)
        assertEquals("ACCESS_REFUSED", (result.exceptionOrNull() as FlutterError).code)
    }

    @Test
    fun retrieveEvents_withEmptyCursor_returnsEmptyList() = runTest {
        mockPermissionGranted(permissionHandler)

        val cursor = mockk<Cursor>(relaxed = true)
        every { contentResolver.query(eventContentUri, any(), any(), any(), any()) } returns cursor
        every { cursor.moveToNext() } returns false

        var result: Result<List<Event>>? = null
        val latch = CountDownLatch(1)
        calendarImplem.retrieveEvents("1", 0L, 0L) {
            result = it
            latch.countDown()
        }

        latch.await()

        assertTrue(result!!.isSuccess)
        assertTrue(result.getOrNull()?.isEmpty()!!)
    }

    @Test
    fun retrieveEvents_withException_returnsGenericError() = runTest {
        mockPermissionGranted(permissionHandler)

        every { contentResolver.query(eventContentUri, any(), any(), any(), any()) } throws Exception("Query failed")

        var result: Result<List<Event>>? = null
        val latch = CountDownLatch(1)
        calendarImplem.retrieveEvents("1", 0L, 0L) {
            result = it
            latch.countDown()
        }

        latch.await()

        assertTrue(result!!.isFailure)
        assertEquals("GENERIC_ERROR", (result.exceptionOrNull() as FlutterError).code)
    }

    @Test
    fun deleteEvent_withGrantedPermission_deletesEventSuccessfully() = runTest {
        mockPermissionGranted(permissionHandler)
        mockCalendarIdFound()
        mockWritableCalendar()

        every { contentResolver.delete(eventContentUri, any(), any()) } returns 1

        var result: Result<Unit>? = null
        val latch = CountDownLatch(1)
        calendarImplem.deleteEvent("1") {
            result = it
            latch.countDown()
        }

        latch.await()

        assertTrue(result!!.isSuccess)
    }

    @Test
    fun deleteEvent_withDeniedPermission_returnsAccessRefusedError() = runTest {
        mockPermissionDenied(permissionHandler)

        var result: Result<Unit>? = null
        calendarImplem.deleteEvent("1") {
            result = it
        }

        assertTrue(result!!.isFailure)
    }

    @Test
    fun deleteEvent_withException_returnsGenericError() = runTest {
        mockPermissionGranted(permissionHandler)
        mockCalendarIdFound()
        mockWritableCalendar()

        every { contentResolver.delete(eventContentUri, any(), any()) } throws Exception("Delete failed")

        var result: Result<Unit>? = null
        val latch = CountDownLatch(1)
        calendarImplem.deleteEvent("1") {
            result = it
            latch.countDown()
        }

        latch.await()

        assertTrue(result!!.isFailure)
        assertEquals("GENERIC_ERROR", (result.exceptionOrNull() as FlutterError).code)
    }

    @Test
    fun deleteEvent_withNoRowsDeleted_returnsNotFoundError() = runTest {
        mockPermissionGranted(permissionHandler)
        mockCalendarIdFound()
        mockWritableCalendar()

        every { contentResolver.delete(eventContentUri, any(), any()) } returns 0

        var result: Result<Unit>? = null
        val latch = CountDownLatch(1)
        calendarImplem.deleteEvent("1") {
            result = it
            latch.countDown()
        }

        latch.await()

        assertTrue(result!!.isFailure)
        assertEquals("NOT_FOUND", (result.exceptionOrNull() as FlutterError).code)
    }

    @Test
    fun deleteEvent_withCalendarIdNotFound_returnsNotFoundError() = runTest {
        mockPermissionGranted(permissionHandler)
        mockCalendarIdNotFound()

        var result: Result<Unit>? = null
        val latch = CountDownLatch(1)
        calendarImplem.deleteEvent("1") {
            result = it
            latch.countDown()
        }

        latch.await()

        assertTrue(result!!.isFailure)
        assertEquals("NOT_FOUND", (result.exceptionOrNull() as FlutterError).code)
    }

    @Test
    fun createEventInDefaultCalendar_withGrantedPermissions_andWritablePrimaryCalendar_createsEventSuccessfully() = runTest {
        mockPermissionGranted(permissionHandler)
        mockPrimaryCalendarFound(contentResolver, calendarContentUri, "1")

        val uri = mockk<Uri>(relaxed = true)
        every { contentResolver.insert(any(), any()) } returns uri
        every { uri.lastPathSegment } returns "1"

        val startMilli = Instant.now().toEpochMilli()
        val endMilli = Instant.now().toEpochMilli()

        var result: Result<Unit>? = null
        val latch = CountDownLatch(1)
        calendarImplem.createEventInDefaultCalendar(
            title = "Test Event",
            startDate = startMilli,
            endDate = endMilli,
            isAllDay = false,
            description = "Description",
            url = null,
            reminders = null
        ) {
            result = it
            latch.countDown()
        }

        latch.await()

        assertTrue(result!!.isSuccess)
    }

    @Test
    fun createEventInDefaultCalendar_withDeniedPermissions_returnsAccessRefusedError() = runTest {
        mockPermissionDenied(permissionHandler)

        var result: Result<Unit>? = null
        calendarImplem.createEventInDefaultCalendar(
            title = "Test Event",
            startDate = Instant.now().toEpochMilli(),
            endDate = Instant.now().toEpochMilli(),
            isAllDay = false,
            description = "Description",
            url = null,
            reminders = null
        ) {
            result = it
        }

        assertTrue(result!!.isFailure)
        assertEquals("ACCESS_REFUSED", (result.exceptionOrNull() as FlutterError).code)
    }

    @Test
    fun createEventInDefaultCalendar_withNoPrimaryCalendar_returnsNotFoundError() = runTest {
        mockPermissionGranted(permissionHandler)
        mockPrimaryCalendarNotFound(contentResolver, calendarContentUri)

        var result: Result<Unit>? = null
        val latch = CountDownLatch(1)
        calendarImplem.createEventInDefaultCalendar(
            title = "Test Event",
            startDate = Instant.now().toEpochMilli(),
            endDate = Instant.now().toEpochMilli(),
            isAllDay = false,
            description = "Description",
            url = null,
            reminders = null
        ) {
            result = it
            latch.countDown()
        }

        latch.await()

        assertTrue(result!!.isFailure)
        assertEquals("NOT_FOUND", (result.exceptionOrNull() as FlutterError).code)
    }

    @Test
    fun createEventInDefaultCalendar_withNotWritablePrimaryCalendar_returnsNotFoundError() = runTest {
        mockPermissionGranted(permissionHandler)
        mockPrimaryCalendarNotWritable(contentResolver, calendarContentUri)

        var result: Result<Unit>? = null
        val latch = CountDownLatch(1)
        calendarImplem.createEventInDefaultCalendar(
            title = "Test Event",
            startDate = Instant.now().toEpochMilli(),
            endDate = Instant.now().toEpochMilli(),
            isAllDay = false,
            description = "Description",
            url = null,
            reminders = null
        ) {
            result = it
            latch.countDown()
        }

        latch.await()

        assertTrue(result!!.isFailure)
        assertEquals("NOT_FOUND", (result.exceptionOrNull() as FlutterError).code)
    }

    @Test
    fun createEventInDefaultCalendar_withInsertFailure_returnsGenericError() = runTest {
        mockPermissionGranted(permissionHandler)
        mockPrimaryCalendarFound(contentResolver, calendarContentUri, "1")

        every { contentResolver.insert(any(), any()) } returns null

        var result: Result<Unit>? = null
        val latch = CountDownLatch(1)
        calendarImplem.createEventInDefaultCalendar(
            title = "Test Event",
            startDate = Instant.now().toEpochMilli(),
            endDate = Instant.now().toEpochMilli(),
            isAllDay = false,
            description = "Description",
            url = null,
            reminders = null
        ) {
            result = it
            latch.countDown()
        }

        latch.await()

        assertTrue(result!!.isFailure)
        assertEquals("GENERIC_ERROR", (result.exceptionOrNull() as FlutterError).code)
    }

    @Test
    fun createEventInDefaultCalendar_withNullEventId_returnsNotFoundError() = runTest {
        mockPermissionGranted(permissionHandler)
        mockPrimaryCalendarFound(contentResolver, calendarContentUri, "1")

        val uri = mockk<Uri>(relaxed = true)
        every { contentResolver.insert(any(), any()) } returns uri
        every { uri.lastPathSegment } returns null

        var result: Result<Unit>? = null
        val latch = CountDownLatch(1)
        calendarImplem.createEventInDefaultCalendar(
            title = "Test Event",
            startDate = Instant.now().toEpochMilli(),
            endDate = Instant.now().toEpochMilli(),
            isAllDay = false,
            description = "Description",
            url = null,
            reminders = null
        ) {
            result = it
            latch.countDown()
        }

        latch.await()

        assertTrue(result!!.isFailure)
        assertEquals("NOT_FOUND", (result.exceptionOrNull() as FlutterError).code)
    }

    @Test
    fun createEventInDefaultCalendar_withException_returnsGenericError() = runTest {
        mockPermissionGranted(permissionHandler)

        every { contentResolver.query(calendarContentUri, any(), any(), any(), any()) } throws Exception("Calendar query failed")

        var result: Result<Unit>? = null
        val latch = CountDownLatch(1)
        calendarImplem.createEventInDefaultCalendar(
            title = "Test Event",
            startDate = Instant.now().toEpochMilli(),
            endDate = Instant.now().toEpochMilli(),
            isAllDay = false,
            description = "Description",
            url = null,
            reminders = null
        ) {
            result = it
            latch.countDown()
        }

        latch.await()

        assertTrue(result!!.isFailure)
        assertEquals("GENERIC_ERROR", (result.exceptionOrNull() as FlutterError).code)
    }

    @Test
    fun createEventInDefaultCalendar_withAllDayEvent_createsEventSuccessfully() = runTest {
        mockPermissionGranted(permissionHandler)
        mockPrimaryCalendarFound(contentResolver, calendarContentUri, "1")

        val uri = mockk<Uri>(relaxed = true)
        every { contentResolver.insert(any(), any()) } returns uri
        every { uri.lastPathSegment } returns "1"

        val startMilli = Instant.now().toEpochMilli()
        val endMilli = Instant.now().toEpochMilli()

        var result: Result<Unit>? = null
        val latch = CountDownLatch(1)
        calendarImplem.createEventInDefaultCalendar(
            title = "All Day Event",
            startDate = startMilli,
            endDate = endMilli,
            isAllDay = true,
            description = "All day description",
            url = "https://example.com",
            reminders = null
        ) {
            result = it
            latch.countDown()
        }

        latch.await()

        assertTrue(result!!.isSuccess)
    }
}
