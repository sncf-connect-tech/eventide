package sncf.connect.tech.flutter_calendar_connect

import android.content.ContentResolver
import android.database.Cursor
import android.net.Uri
import io.mockk.*
import kotlinx.coroutines.delay
import kotlinx.coroutines.test.runTest
import org.junit.jupiter.api.Assertions.*
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import java.time.Instant

private class Lock {
    private var locked = true

    fun unlock() {
        locked = false
    }

    fun isLocked() = locked
}

class CalendarImplemTest {
    private lateinit var contentResolver: ContentResolver
    private lateinit var permissionHandler: PermissionHandler
    private lateinit var calendarImplem: CalendarImplem

    @BeforeEach
    fun setup() {
        contentResolver = mockk(relaxed = true)
        permissionHandler = mockk(relaxed = true)
        calendarImplem = CalendarImplem(
            contentResolver,
            permissionHandler,
            mockk(relaxed = true)
        )
    }

    @Test
    fun requestCalendarPermission_withGrantedPermission_returnsTrue() = runTest {
        every { permissionHandler.requestWritePermission(any()) } answers {
            firstArg<(Boolean) -> Unit>().invoke(true)
        }

        var result: Result<Boolean>? = null
        val lock = Lock()
        calendarImplem.requestCalendarPermission {
            result = it
            lock.unlock()
        }

        while (lock.isLocked()) {
            delay(100)
        }

        assertTrue(result!!.isSuccess)
        assertTrue(result!!.getOrNull()!!)
    }

    @Test
    fun requestCalendarPermission_withDeniedPermission_returnsFalse() = runTest {
        every { permissionHandler.requestWritePermission(any()) } answers {
            firstArg<(Boolean) -> Unit>().invoke(false)
        }

        var result: Result<Boolean>? = null
        val lock = Lock()
        calendarImplem.requestCalendarPermission {
            result = it
            lock.unlock()
        }

        while (lock.isLocked()) {
            delay(100)
        }

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
        val lock = Lock()
        calendarImplem.createCalendar("Test Calendar", 0xFF0000) {
            result = it
            lock.unlock()
        }

        while(lock.isLocked()) {
            delay(100)
        }

        assertTrue(result!!.isSuccess)
        assertEquals("1", result!!.getOrNull()?.id)
    }

    @Test
    fun createCalendar_withDeniedPermission_failsToCreateCalendar() = runTest {
        every { permissionHandler.requestWritePermission(any()) } answers {
            firstArg<(Boolean) -> Unit>().invoke(false)
        }

        var result: Result<Calendar>? = null
        calendarImplem.createCalendar("Test Calendar", 0xFF0000) {
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
        val lock = Lock()
        calendarImplem.createCalendar("Test Calendar", 0xFF0000) {
            result = it
            lock.unlock()
        }

        while (lock.isLocked()) {
            delay(100)
        }

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
        val lock = Lock()
        calendarImplem.createCalendar("Test Calendar", 0xFF0000) {
            result = it
            lock.unlock()
        }

        while(lock.isLocked()) {
            delay(100)
        }

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
        val lock = Lock()
        calendarImplem.retrieveCalendars(false) {
            result = it
            lock.unlock()
        }

        while (lock.isLocked()) {
            delay(100)
        }

        assertTrue(result!!.isSuccess)
        assertEquals(1, result!!.getOrNull()?.size)
    }

    @Test
    fun retrieveCalendars_withDeniedPermission_failsToRetrieveCalendars() = runTest {
        every { permissionHandler.requestReadPermission(any()) } answers {
            firstArg<(Boolean) -> Unit>().invoke(false)
        }

        var result: Result<List<Calendar>>? = null
        calendarImplem.retrieveCalendars(false) {
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
        val lock = Lock()
        calendarImplem.retrieveCalendars(false) {
            result = it
            lock.unlock()
        }

        while(lock.isLocked()) {
            delay(100)
        }

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
        val lock = Lock()
        calendarImplem.deleteCalendar("1") {
            result = it
            lock.unlock()
        }

        while (lock.isLocked()) {
            delay(100)
        }

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
        val lock = Lock()
        calendarImplem.deleteCalendar("1") {
            result = it
            lock.unlock()
        }

        while (lock.isLocked()) {
            delay(100)
        }

        assertTrue(result!!.isFailure)
    }

    @Test
    fun deleteCalendar_withNoRowsDeleted_failsToDeleteCalendar() = runTest {
        every { permissionHandler.requestWritePermission(any()) } answers {
            firstArg<(Boolean) -> Unit>().invoke(true)
        }
        every { contentResolver.delete(any(), any(), any()) } returns 0

        var result: Result<Unit>? = null
        val lock = Lock()
        calendarImplem.deleteCalendar("1") {
            result = it
            lock.unlock()
        }

        while (lock.isLocked()) {
            delay(100)
        }

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
        val lock = Lock()
        calendarImplem.createEvent(
            title = "Test Event",
            startDate = startMilli,
            endDate = endMilli,
            timeZone = "UTC",
            calendarId = "1",
            description = "Description",
            url = null,
            alarms = emptyList()
        ) {
            result = it
            lock.unlock()
        }

        while(lock.isLocked()) {
            delay(100)
        }

        assertTrue(result!!.isSuccess)
        assertEquals(Event(
            id = "1",
            title = "Test Event",
            startDate = startMilli,
            endDate = endMilli,
            timeZone = "UTC",
            calendarId = "1",
            description = "Description",
            alarms = emptyList()
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
            timeZone = "UTC",
            calendarId = "1",
            description = "Description",
            url = null,
            alarms = emptyList()
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
        val lock = Lock()
        calendarImplem.createEvent(
            title = "Test Event",
            startDate = Instant.now().toEpochMilli(),
            endDate = Instant.now().toEpochMilli(),
            timeZone = "UTC",
            calendarId = "1",
            description = "Description",
            url = null,
            alarms = emptyList()
        ) {
            result = it
            lock.unlock()
        }

        while(lock.isLocked()) {
            delay(100)
        }

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
        val lock = Lock()
        calendarImplem.retrieveEvents("1", 0L, 0L) {
            result = it
            lock.unlock()
        }

        while (lock.isLocked()) {
            delay(100)
        }

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
        val lock = Lock()
        calendarImplem.retrieveEvents("1", 0L, 0L) {
            result = it
            lock.unlock()
        }

        while (lock.isLocked()) {
            delay(100)
        }

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
        val lock = Lock()
        calendarImplem.retrieveEvents("1", 0L, 0L) {
            result = it
            lock.unlock()
        }

        while (lock.isLocked()) {
            delay(100)
        }

        assertTrue(result!!.isFailure)
    }

    @Test
    fun deleteEvent_withGrantedPermission_deletesEventSuccessfully() = runTest {
        every { permissionHandler.requestWritePermission(any()) } answers {
            firstArg<(Boolean) -> Unit>().invoke(true)
        }
        every { contentResolver.delete(any(), any(), any()) } returns 1

        var result: Result<Unit>? = null
        val lock = Lock()
        calendarImplem.deleteEvent("1", "1") {
            result = it
            lock.unlock()
        }

        while (lock.isLocked()) {
            delay(100)
        }

        assertTrue(result!!.isSuccess)
    }

    @Test
    fun deleteEvent_withDeniedPermission_failsToDeleteEvent() = runTest {
        every { permissionHandler.requestWritePermission(any()) } answers {
            firstArg<(Boolean) -> Unit>().invoke(false)
        }

        var result: Result<Unit>? = null
        calendarImplem.deleteEvent("1", "1") {
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
        val lock = Lock()
        calendarImplem.deleteEvent("1", "1") {
            result = it
            lock.unlock()
        }

        while (lock.isLocked()) {
            delay(100)
        }

        assertTrue(result!!.isFailure)
    }

    @Test
    fun deleteEvent_withNoRowsDeleted_failsToDeleteEvent() = runTest {
        every { permissionHandler.requestWritePermission(any()) } answers {
            firstArg<(Boolean) -> Unit>().invoke(true)
        }
        every { contentResolver.delete(any(), any(), any()) } returns 0

        var result: Result<Unit>? = null
        val lock = Lock()
        calendarImplem.deleteEvent("1", "1") {
            result = it
            lock.unlock()
        }

        while (lock.isLocked()) {
            delay(100)
        }

        assertTrue(result!!.isFailure)
    }
}
