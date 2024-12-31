package sncf.connect.tech.flutter_calendar_connect

import android.content.ContentResolver
import android.database.Cursor
import android.net.Uri
import io.mockk.*
import kotlinx.coroutines.delay
import kotlinx.coroutines.runBlocking
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
    fun createCalendar_withGrantedPermission_createsCalendarSuccessfully() = runBlocking {
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
    fun createCalendar_withDeniedPermission_failsToCreateCalendar() = runBlocking {
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
    fun createCalendar_withInvalidUri_failsToCreateCalendar() = runBlocking {
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
    fun createCalendar_withNullLastPathSegment_failsToRetrieveCalendarId() = runBlocking {
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
    fun retrieveCalendars_withGrantedPermission_returnsCalendars() = runBlocking {
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
    fun retrieveCalendars_withDeniedPermission_failsToRetrieveCalendars() = runBlocking {
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
    fun retrieveCalendars_withEmptyCursor_returnsEmptyList() = runBlocking {
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
    fun createOrUpdateEvent_withGrantedPermission_createsEventSuccessfully() = runBlocking {
        every { permissionHandler.requestWritePermission(any()) } answers {
            firstArg<(Boolean) -> Unit>().invoke(true)
        }
        val uri = mockk<Uri>(relaxed = true)
        every { contentResolver.insert(any(), any()) } returns uri

        val event = Event(
            id = "1",
            title = "Test Event",
            startDate = Instant.now().toEpochMilli(),
            endDate = Instant.now().toEpochMilli(),
            timeZone = "UTC",
            calendarId = "1",
            description = "Description",
            alarms = emptyList()
        )

        var result: Result<Boolean>? = null
        val lock = Lock()
        calendarImplem.createOrUpdateEvent(event) {
            result = it
            lock.unlock()
        }

        while(lock.isLocked()) {
            delay(100)
        }

        assertTrue(result!!.isSuccess)
        assertTrue(result!!.getOrNull()!!)
    }

    @Test
    fun createOrUpdateEvent_withDeniedPermission_failsToCreateEvent() = runBlocking {
        every { permissionHandler.requestWritePermission(any()) } answers {
            firstArg<(Boolean) -> Unit>().invoke(false)
        }

        val event = Event(
            id = "1",
            title = "Test Event",
            startDate = Instant.now().toEpochMilli(),
            endDate = Instant.now().toEpochMilli(),
            timeZone = "UTC",
            calendarId = "1",
            description = "Description",
            alarms = emptyList()
        )

        var result: Result<Boolean>? = null
        calendarImplem.createOrUpdateEvent(event) {
            result = it
        }

        assertTrue(result!!.isFailure)
    }

    @Test
    fun createOrUpdateEvent_withInvalidUri_failsToCreateEvent() = runBlocking {
        every { permissionHandler.requestWritePermission(any()) } answers {
            firstArg<(Boolean) -> Unit>().invoke(true)
        }
        every { contentResolver.insert(any(), any()) } returns null

        val event = Event(
            id = "1",
            title = "Test Event",
            startDate = Instant.now().toEpochMilli(),
            endDate = Instant.now().toEpochMilli(),
            timeZone = "UTC",
            calendarId = "1",
            description = "Description",
            alarms = emptyList()
        )

        var result: Result<Boolean>? = null
        val lock = Lock()
        calendarImplem.createOrUpdateEvent(event) {
            result = it
            lock.unlock()
        }

        while(lock.isLocked()) {
            delay(100)
        }

        assertTrue(result!!.isFailure)
    }
}
