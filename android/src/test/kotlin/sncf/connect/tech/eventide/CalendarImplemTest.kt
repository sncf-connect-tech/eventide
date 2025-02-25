package sncf.connect.tech.eventide

import android.content.ContentResolver
import android.database.Cursor
import android.net.Uri
import android.provider.CalendarContract
import io.mockk.*
import kotlinx.coroutines.delay
import kotlinx.coroutines.test.runTest
import org.junit.jupiter.api.Assertions.*
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import java.time.Instant
import java.util.concurrent.CountDownLatch

class CalendarImplemTest {
    private lateinit var contentResolver: ContentResolver
    private lateinit var permissionHandler: PermissionHandler
    private lateinit var calendarImplem: CalendarImplem
    private lateinit var calendarContentUri: Uri
    private lateinit var eventContentUri: Uri
    private lateinit var remindersContentUri: Uri

    @BeforeEach
    fun setup() {
        calendarContentUri = mockk(relaxed = true)
        eventContentUri = mockk(relaxed = true)
        remindersContentUri = mockk(relaxed = true)

        contentResolver = mockk(relaxed = true)
        permissionHandler = mockk(relaxed = true)
        calendarImplem = CalendarImplem(
            contentResolver = contentResolver,
            permissionHandler = permissionHandler,
            calendarContentUri = calendarContentUri,
            eventContentUri = eventContentUri,
            remindersContentUri = remindersContentUri,
        )
    }

    @Test
    fun requestCalendarPermission_withGrantedPermission_returnsTrue() = runTest {
        every { permissionHandler.requestWritePermission(any()) } answers {
            firstArg<(Boolean) -> Unit>().invoke(true)
        }

        var result: Result<Boolean>? = null
        val latch = CountDownLatch(1)
        calendarImplem.requestCalendarPermission {
            result = it
            latch.countDown()
        }

        latch.await()

        assertTrue(result!!.isSuccess)
        assertTrue(result!!.getOrNull()!!)
    }

    @Test
    fun requestCalendarPermission_withDeniedPermission_returnsFalse() = runTest {
        every { permissionHandler.requestWritePermission(any()) } answers {
            firstArg<(Boolean) -> Unit>().invoke(false)
        }

        var result: Result<Boolean>? = null
        val latch = CountDownLatch(1)
        calendarImplem.requestCalendarPermission {
            result = it
            latch.countDown()
        }

        latch.await()

        assertTrue(result!!.isSuccess)
        assertFalse(result!!.getOrNull()!!)
    }

    @Test
    fun createCalendar_withGrantedPermission_createsCalendarSuccessfully() = runTest {
        every { permissionHandler.requestWritePermission(any()) } answers {
            firstArg<(Boolean) -> Unit>().invoke(true)
        }
        val uri = mockk<Uri>(relaxed = true)
        every { contentResolver.insert(any(), any()) } returns uri
        every { uri.lastPathSegment } returns "1"

        var result: Result<Calendar>? = null
        val latch = CountDownLatch(1)
        calendarImplem.createCalendar("Test Calendar", 0xFF0000, Account("1", "Test Account")) {
            result = it
            latch.countDown()
        }

        latch.await()

        assertTrue(result!!.isSuccess)
        assertEquals("1", result!!.getOrNull()?.id)
    }

    @Test
    fun createCalendar_withDeniedPermission_failsToCreateCalendar() = runTest {
        every { permissionHandler.requestWritePermission(any()) } answers {
            firstArg<(Boolean) -> Unit>().invoke(false)
        }

        var result: Result<Calendar>? = null
        calendarImplem.createCalendar("Test Calendar", 0xFF0000, null) {
            result = it
        }

        assertTrue(result!!.isFailure)
    }

    @Test
    fun createCalendar_withInvalidUri_failsToCreateCalendar() = runTest {
        every { permissionHandler.requestWritePermission(any()) } answers {
            firstArg<(Boolean) -> Unit>().invoke(true)
        }
        every { contentResolver.insert(any(), any()) } returns null

        var result: Result<Calendar>? = null
        val latch = CountDownLatch(1)
        calendarImplem.createCalendar("Test Calendar", 0xFF0000, null) {
            result = it
            latch.countDown()
        }

        latch.await()

        assertTrue(result!!.isFailure)
    }

    @Test
    fun createCalendar_withNullLastPathSegment_failsToRetrieveCalendarId() = runTest {
        every { permissionHandler.requestWritePermission(any()) } answers {
            firstArg<(Boolean) -> Unit>().invoke(true)
        }
        val uri = mockk<Uri>(relaxed = true)
        every { contentResolver.insert(any(), any()) } returns uri
        every { uri.lastPathSegment } returns null

        var result: Result<Calendar>? = null
        val latch = CountDownLatch(1)
        calendarImplem.createCalendar("Test Calendar", 0xFF0000, null) {
            result = it
            latch.countDown()
        }

        latch.await()

        assertTrue(result!!.isFailure)
    }

    @Test
    fun retrieveCalendars_withGrantedPermission_returnsCalendars() = runTest {
        every { permissionHandler.requestReadPermission(any()) } answers {
            firstArg<(Boolean) -> Unit>().invoke(true)
        }
        val cursor = mockk<Cursor>(relaxed = true)
        every { contentResolver.query(any(), any(), any(), any(), any()) } returns cursor
        every { cursor.moveToNext() } returnsMany listOf(true, false)
        every { cursor.getLong(any()) } returns 1L
        every { cursor.getString(any()) } returns "Test Calendar"
        every { cursor.getLong(any()) } returns 0xFF0000

        var result: Result<List<Calendar>>? = null
        val latch = CountDownLatch(1)
        calendarImplem.retrieveCalendars(false, null) {
            result = it
            latch.countDown()
        }

        latch.await()

        assertTrue(result!!.isSuccess)
        assertEquals(1, result!!.getOrNull()?.size)
    }

    @Test
    fun retrieveCalendars_onlyWritableAndAccountFilter_appliesCorrectSelection() = runTest {
        every { permissionHandler.requestReadPermission(any()) } answers {
            firstArg<(Boolean) -> Unit>().invoke(true)
        }
        val cursor = mockk<Cursor>(relaxed = true)
        every { contentResolver.query(any(), any(), any(), any(), any()) } returns cursor
        every { cursor.moveToNext() } returns false

        var result: Result<List<Calendar>>? = null
        val latch = CountDownLatch(1)
        calendarImplem.retrieveCalendars(true, Account("testAccount", "testType")) {
            result = it
            latch.countDown()
        }

        latch.await()

        val expectedSelection = "${CalendarContract.Calendars.CALENDAR_ACCESS_LEVEL} >= ? AND ${CalendarContract.Calendars.ACCOUNT_NAME} = ? AND ${CalendarContract.Calendars.ACCOUNT_TYPE} = ?"
        val expectedSelectionArgs = arrayOf(CalendarContract.Calendars.CAL_ACCESS_CONTRIBUTOR.toString(), "testAccount", "testType")

        verify {
            contentResolver.query(
                calendarContentUri,
                any(),
                expectedSelection,
                expectedSelectionArgs,
                any()
            )
        }

        assertTrue(result!!.isSuccess)
        assertTrue(result!!.getOrNull()?.isEmpty()!!)
    }

    @Test
    fun retrieveCalendars_accountFilter_appliesCorrectSelection() = runTest {
        every { permissionHandler.requestReadPermission(any()) } answers {
            firstArg<(Boolean) -> Unit>().invoke(true)
        }
        val cursor = mockk<Cursor>(relaxed = true)
        every { contentResolver.query(any(), any(), any(), any(), any()) } returns cursor
        every { cursor.moveToNext() } returns false

        var result: Result<List<Calendar>>? = null
        val latch = CountDownLatch(1)
        calendarImplem.retrieveCalendars(false, Account("testAccount", "testType")) {
            result = it
            latch.countDown()
        }

        latch.await()

        val expectedSelection = "${CalendarContract.Calendars.ACCOUNT_NAME} = ? AND ${CalendarContract.Calendars.ACCOUNT_TYPE} = ?"
        val expectedSelectionArgs = arrayOf("testAccount", "testType")

        verify {
            contentResolver.query(
                calendarContentUri,
                any(),
                expectedSelection,
                expectedSelectionArgs,
                any()
            )
        }

        assertTrue(result!!.isSuccess)
        assertTrue(result!!.getOrNull()?.isEmpty()!!)
    }

    @Test
    fun retrieveCalendars_onlyWritable_appliesCorrectSelection() = runTest {
        every { permissionHandler.requestReadPermission(any()) } answers {
            firstArg<(Boolean) -> Unit>().invoke(true)
        }
        val cursor = mockk<Cursor>(relaxed = true)
        every { contentResolver.query(any(), any(), any(), any(), any()) } returns cursor
        every { cursor.moveToNext() } returns false

        var result: Result<List<Calendar>>? = null
        val latch = CountDownLatch(1)
        calendarImplem.retrieveCalendars(true, null) {
            result = it
            latch.countDown()
        }

        latch.await()

        val expectedSelection = "${CalendarContract.Calendars.CALENDAR_ACCESS_LEVEL} >= ?"
        val expectedSelectionArgs = arrayOf(CalendarContract.Calendars.CAL_ACCESS_CONTRIBUTOR.toString())

        verify {
            contentResolver.query(
                calendarContentUri,
                any(),
                expectedSelection,
                expectedSelectionArgs,
                any()
            )
        }

        assertTrue(result!!.isSuccess)
        assertTrue(result!!.getOrNull()?.isEmpty()!!)
    }

    @Test
    fun retrieveCalendars_noFilter_appliesCorrectSelection() = runTest {
        every { permissionHandler.requestReadPermission(any()) } answers {
            firstArg<(Boolean) -> Unit>().invoke(true)
        }
        val cursor = mockk<Cursor>(relaxed = true)
        every { contentResolver.query(any(), any(), any(), any(), any()) } returns cursor
        every { cursor.moveToNext() } returns false

        var result: Result<List<Calendar>>? = null
        val latch = CountDownLatch(1)
        calendarImplem.retrieveCalendars(false, null) {
            result = it
            latch.countDown()
        }

        latch.await()

        verify {
            contentResolver.query(
                calendarContentUri,
                any(),
                null,
                null,
                any()
            )
        }

        assertTrue(result!!.isSuccess)
        assertTrue(result!!.getOrNull()?.isEmpty()!!)
    }

    @Test
    fun retrieveCalendars_withDeniedPermission_failsToRetrieveCalendars() = runTest {
        every { permissionHandler.requestReadPermission(any()) } answers {
            firstArg<(Boolean) -> Unit>().invoke(false)
        }

        var result: Result<List<Calendar>>? = null
        calendarImplem.retrieveCalendars(false, null) {
            result = it
        }

        assertTrue(result!!.isFailure)
    }

    @Test
    fun retrieveCalendars_withEmptyCursor_returnsEmptyList() = runTest {
        every { permissionHandler.requestReadPermission(any()) } answers {
            firstArg<(Boolean) -> Unit>().invoke(true)
        }
        val cursor = mockk<Cursor>(relaxed = true)
        every { contentResolver.query(any(), any(), any(), any(), any()) } returns cursor
        every { cursor.moveToNext() } returns false

        var result: Result<List<Calendar>>? = null
        val latch = CountDownLatch(1)
        calendarImplem.retrieveCalendars(false, null) {
            result = it
            latch.countDown()
        }

        latch.await()

        assertTrue(result!!.isSuccess)
        assertTrue(result!!.getOrNull()?.isEmpty()!!)
    }

    @Test
    fun deleteCalendar_withGrantedPermission_deletesCalendarSuccessfully() = runTest {
        every { permissionHandler.requestWritePermission(any()) } answers {
            firstArg<(Boolean) -> Unit>().invoke(true)
        }
        every { contentResolver.delete(any(), any(), any()) } returns 1

        var result: Result<Unit>? = null
        val latch = CountDownLatch(1)
        calendarImplem.deleteCalendar("1") {
            result = it
            latch.countDown()
        }

        latch.await()

        assertTrue(result!!.isSuccess)
    }

    @Test
    fun deleteCalendar_withDeniedPermission_failsToDeleteCalendar() = runTest {
        every { permissionHandler.requestWritePermission(any()) } answers {
            firstArg<(Boolean) -> Unit>().invoke(false)
        }

        var result: Result<Unit>? = null
        calendarImplem.deleteCalendar("1") {
            result = it
        }

        assertTrue(result!!.isFailure)
    }

    @Test
    fun deleteCalendar_withException_failsToDeleteCalendar() = runTest {
        every { permissionHandler.requestWritePermission(any()) } answers {
            firstArg<(Boolean) -> Unit>().invoke(true)
        }
        every { contentResolver.delete(any(), any(), any()) } throws Exception("Delete failed")

        var result: Result<Unit>? = null
        val latch = CountDownLatch(1)
        calendarImplem.deleteCalendar("1") {
            result = it
            latch.countDown()
        }

        latch.await()

        assertTrue(result!!.isFailure)
    }

    @Test
    fun deleteCalendar_withNoRowsDeleted_failsToDeleteCalendar() = runTest {
        every { permissionHandler.requestWritePermission(any()) } answers {
            firstArg<(Boolean) -> Unit>().invoke(true)
        }
        every { contentResolver.delete(any(), any(), any()) } returns 0

        var result: Result<Unit>? = null
        val latch = CountDownLatch(1)
        calendarImplem.deleteCalendar("1") {
            result = it
            latch.countDown()
        }

        latch.await()

        assertTrue(result!!.isFailure)
    }

    @Test
    fun createEvent_withGrantedPermission_createsEventSuccessfully() = runTest {
        every { permissionHandler.requestWritePermission(any()) } answers {
            firstArg<(Boolean) -> Unit>().invoke(true)
        }
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
            url = null
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
        ), result!!.getOrNull()!!)
    }

    @Test
    fun createEvent_withDeniedPermission_failsToCreateEvent() = runTest {
        every { permissionHandler.requestWritePermission(any()) } answers {
            firstArg<(Boolean) -> Unit>().invoke(false)
        }

        var result: Result<Event>? = null
        calendarImplem.createEvent(
            title = "Test Event",
            startDate = Instant.now().toEpochMilli(),
            endDate = Instant.now().toEpochMilli(),
            calendarId = "1",
            description = "Description",
            isAllDay = false,
            url = null
        ) {
            result = it
        }

        assertTrue(result!!.isFailure)
    }

    @Test
    fun createEvent_withInvalidUri_failsToCreateEvent() = runTest {
        every { permissionHandler.requestWritePermission(any()) } answers {
            firstArg<(Boolean) -> Unit>().invoke(true)
        }
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
            url = null
        ) {
            result = it
            latch.countDown()
        }

        latch.await()

        assertTrue(result!!.isFailure)
    }

    @Test
    fun retrieveEvents_withGrantedPermission_returnsEvents() = runTest {
        every { permissionHandler.requestReadPermission(any()) } answers {
            firstArg<(Boolean) -> Unit>().invoke(true)
        }
        val cursor = mockk<Cursor>(relaxed = true)
        every { contentResolver.query(any(), any(), any(), any(), any()) } returns cursor
        every { cursor.moveToNext() } returnsMany listOf(true, false)
        every { cursor.getLong(any()) } returns 1L
        every { cursor.getString(any()) } returns "Test Event"
        every { cursor.getLong(any()) } returns 0L

        var result: Result<List<Event>>? = null
        val latch = CountDownLatch(1)
        calendarImplem.retrieveEvents("1", 0L, 0L) {
            result = it
            latch.countDown()
        }

        latch.await()

        assertTrue(result!!.isSuccess)
        assertEquals(1, result!!.getOrNull()?.size)
        assertEquals("Test Event", result!!.getOrNull()?.get(0)?.title)
    }

    @Test
    fun retrieveEvents_withDeniedPermission_failsToRetrieveEvents() = runTest {
        every { permissionHandler.requestReadPermission(any()) } answers {
            firstArg<(Boolean) -> Unit>().invoke(false)
        }

        var result: Result<List<Event>>? = null
        calendarImplem.retrieveEvents("1", 0L, 0L) {
            result = it
        }

        assertTrue(result!!.isFailure)
    }

    @Test
    fun retrieveEvents_withEmptyCursor_returnsEmptyList() = runTest {
        every { permissionHandler.requestReadPermission(any()) } answers {
            firstArg<(Boolean) -> Unit>().invoke(true)
        }
        val cursor = mockk<Cursor>(relaxed = true)
        every { contentResolver.query(any(), any(), any(), any(), any()) } returns cursor
        every { cursor.moveToNext() } returns false

        var result: Result<List<Event>>? = null
        val latch = CountDownLatch(1)
        calendarImplem.retrieveEvents("1", 0L, 0L) {
            result = it
            latch.countDown()
        }

        latch.await()

        assertTrue(result!!.isSuccess)
        assertTrue(result!!.getOrNull()?.isEmpty()!!)
    }

    @Test
    fun retrieveEvents_withException_failsToRetrieveEvents() = runTest {
        every { permissionHandler.requestReadPermission(any()) } answers {
            firstArg<(Boolean) -> Unit>().invoke(true)
        }
        every { contentResolver.query(any(), any(), any(), any(), any()) } throws Exception("Query failed")

        var result: Result<List<Event>>? = null
        val latch = CountDownLatch(1)
        calendarImplem.retrieveEvents("1", 0L, 0L) {
            result = it
            latch.countDown()
        }

        latch.await()

        assertTrue(result!!.isFailure)
    }

    @Test
    fun deleteEvent_withGrantedPermission_deletesEventSuccessfully() = runTest {
        every { permissionHandler.requestWritePermission(any()) } answers {
            firstArg<(Boolean) -> Unit>().invoke(true)
        }
        every { contentResolver.delete(any(), any(), any()) } returns 1

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
    fun deleteEvent_withDeniedPermission_failsToDeleteEvent() = runTest {
        every { permissionHandler.requestWritePermission(any()) } answers {
            firstArg<(Boolean) -> Unit>().invoke(false)
        }

        var result: Result<Unit>? = null
        calendarImplem.deleteEvent("1") {
            result = it
        }

        assertTrue(result!!.isFailure)
    }

    @Test
    fun deleteEvent_withException_failsToDeleteEvent() = runTest {
        every { permissionHandler.requestWritePermission(any()) } answers {
            firstArg<(Boolean) -> Unit>().invoke(true)
        }
        every { contentResolver.delete(any(), any(), any()) } throws Exception("Delete failed")

        var result: Result<Unit>? = null
        val latch = CountDownLatch(1)
        calendarImplem.deleteEvent("1") {
            result = it
            latch.countDown()
        }

        latch.await()

        assertTrue(result!!.isFailure)
    }

    @Test
    fun deleteEvent_withNoRowsDeleted_failsToDeleteEvent() = runTest {
        every { permissionHandler.requestWritePermission(any()) } answers {
            firstArg<(Boolean) -> Unit>().invoke(true)
        }
        every { contentResolver.delete(any(), any(), any()) } returns 0

        var result: Result<Unit>? = null
        val latch = CountDownLatch(1)
        calendarImplem.deleteEvent("1") {
            result = it
            latch.countDown()
        }

        latch.await()

        assertTrue(result!!.isFailure)
    }

    @Test
    fun createReminder_withGrantedPermission_createsReminderSuccessfully() = runTest {
        every { permissionHandler.requestWritePermission(any()) } answers {
            firstArg<(Boolean) -> Unit>().invoke(true)
        }
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
        every { permissionHandler.requestWritePermission(any()) } answers {
            firstArg<(Boolean) -> Unit>().invoke(false)
        }
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
        every { permissionHandler.requestWritePermission(any()) } answers {
            firstArg<(Boolean) -> Unit>().invoke(true)
        }
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
        val eventId = "1"
        val minutes = 10L
        every { permissionHandler.requestWritePermission(any()) } answers {
            firstArg<(Boolean) -> Unit>().invoke(true)
        }
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
        val eventId = "1"
        val minutes = 10L
        every { permissionHandler.requestWritePermission(any()) } answers {
            firstArg<(Boolean) -> Unit>().invoke(false)
        }

        var result: Result<Event>? = null
        calendarImplem.deleteReminder(minutes, eventId) {
            result = it
        }

        assertTrue(result!!.isFailure)
    }

    @Test
    fun deleteReminder_withException_failsToDeleteReminder() = runTest {
        val eventId = "1"
        val minutes = 10L
        every { permissionHandler.requestWritePermission(any()) } answers {
            firstArg<(Boolean) -> Unit>().invoke(true)
        }
        every { contentResolver.delete(any(), any(), any()) } throws Exception("Delete failed")

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
        val eventId = "1"
        val minutes = 10L
        every { permissionHandler.requestWritePermission(any()) } answers {
            firstArg<(Boolean) -> Unit>().invoke(true)
        }
        every { contentResolver.delete(any(), any(), any()) } returns 0

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
