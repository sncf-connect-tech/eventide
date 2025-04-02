package sncf.connect.tech.eventide

import android.content.ContentResolver
import android.database.Cursor
import android.net.Uri
import android.provider.CalendarContract
import io.mockk.every
import io.mockk.mockk
import io.mockk.verify
import kotlinx.coroutines.test.runTest
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import java.util.concurrent.CountDownLatch

class CalendarTests {
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

    @Test
    fun createCalendar_withGrantedPermission_createsCalendarSuccessfully() = runTest {
        mockPermissionGranted(permissionHandler)

        val uri = mockk<Uri>(relaxed = true)
        every { contentResolver.insert(calendarContentUri, any()) } returns uri
        every { uri.lastPathSegment } returns "1"

        var result: Result<Calendar>? = null
        val latch = CountDownLatch(1)
        calendarImplem.createCalendar("Test Calendar", 0x00FF00, Account("1", "Test Account")) {
            result = it
            latch.countDown()
        }

        latch.await()

        assertTrue(result!!.isSuccess)
        assertTrue(result!!.getOrNull()!!.title == "Test Calendar")
        assertTrue(result!!.getOrNull()!!.color.toInt() == 0x00FF00)
        assertTrue(result!!.getOrNull()!!.account.name == "1")
        assertTrue(result!!.getOrNull()!!.account.type == "Test Account")
        assertEquals("1", result!!.getOrNull()?.id)
    }

    @Test
    fun createCalendar_withDeniedPermission_returnsAccessRefusedError() = runTest {
        mockPermissionDenied(permissionHandler)

        var result: Result<Calendar>? = null
        calendarImplem.createCalendar("Test Calendar", 0xFF0000, null) {
            result = it
        }

        assertTrue(result!!.isFailure)
        assertEquals("ACCESS_REFUSED", (result!!.exceptionOrNull() as FlutterError).code)
    }

    @Test
    fun createCalendar_withInvalidUri_returnsGenericError() = runTest {
        mockPermissionGranted(permissionHandler)

        every { contentResolver.insert(calendarContentUri, any()) } returns null

        var result: Result<Calendar>? = null
        val latch = CountDownLatch(1)
        calendarImplem.createCalendar("Test Calendar", 0xFF0000, null) {
            result = it
            latch.countDown()
        }

        latch.await()

        assertTrue(result!!.isFailure)
        assertEquals("GENERIC_ERROR", (result!!.exceptionOrNull() as FlutterError).code)
    }

    @Test
    fun createCalendar_withNullLastPathSegment_returnsNotFoundError() = runTest {
        mockPermissionGranted(permissionHandler)

        val uri = mockk<Uri>(relaxed = true)
        every { contentResolver.insert(calendarContentUri, any()) } returns uri
        every { uri.lastPathSegment } returns null

        var result: Result<Calendar>? = null
        val latch = CountDownLatch(1)
        calendarImplem.createCalendar("Test Calendar", 0xFF0000, null) {
            result = it
            latch.countDown()
        }

        latch.await()

        assertTrue(result!!.isFailure)
        assertEquals("NOT_FOUND", (result!!.exceptionOrNull() as FlutterError).code)
    }

    @Test
    fun createCalendar_withException_returnsGenericError() = runTest {
        mockPermissionGranted(permissionHandler)

        every { contentResolver.insert(calendarContentUri, any()) } throws Exception("Insert failed")

        var result: Result<Calendar>? = null
        val latch = CountDownLatch(1)
        calendarImplem.createCalendar("Test Calendar", 0xFF0000, null) {
            result = it
            latch.countDown()
        }

        latch.await()

        assertTrue(result!!.isFailure)
        assertEquals("GENERIC_ERROR", (result!!.exceptionOrNull() as FlutterError).code)
    }

    @Test
    fun retrieveCalendars_withGrantedPermission_returnsCalendars() = runTest {
        mockPermissionGranted(permissionHandler)
        val cursor = mockk<Cursor>(relaxed = true)
        every { contentResolver.query(calendarContentUri, any(), any(), any(), any()) } returns cursor
        every { cursor.moveToNext() } returnsMany listOf(true, true, false)
        every { cursor.getLong(any()) } returnsMany listOf(0xFF0000, 0xFF0000)
        every { cursor.getString(any()) } returnsMany listOf("id", "Test Calendar", "Test Account", "Test Account Type", "id2", "Test Calendar2", "Test Account", "Test Account Type")
        every { cursor.getInt(any()) } returnsMany listOf(CalendarContract.Calendars.CAL_ACCESS_OWNER, CalendarContract.Calendars.CAL_ACCESS_OWNER)

        var result: Result<List<Calendar>>? = null
        val latch = CountDownLatch(1)
        calendarImplem.retrieveCalendars(false, null) {
            result = it
            latch.countDown()
        }

        latch.await()

        assertTrue(result!!.isSuccess)
        assertEquals(2, result!!.getOrNull()?.size)
        assertEquals("Test Calendar", result!!.getOrNull()?.get(0)?.title)
        assertEquals("Test Calendar2", result!!.getOrNull()?.get(1)?.title)
    }

    @Test
    fun retrieveCalendars_withGrantedPermission_returnsOnlyWritableCalendars() = runTest {
        mockPermissionGranted(permissionHandler)
        
        val cursor = mockk<Cursor>(relaxed = true)
        every { contentResolver.query(calendarContentUri, any(), any(), any(), any()) } returns cursor
        every { cursor.moveToNext() } returnsMany listOf(true, true, false)
        every { cursor.getLong(any()) } returnsMany listOf(0xFF0000, 0xFF0000)
        every { cursor.getString(any()) } returnsMany listOf("id1", "Test Calendar", "Test Account", "Test Account Type", "id2", "Test Calendar", "Test Account", "Test Account Type")
        every { cursor.getInt(any()) } returnsMany listOf(CalendarContract.Calendars.CAL_ACCESS_OWNER, CalendarContract.Calendars.CAL_ACCESS_READ)

        var result: Result<List<Calendar>>? = null
        val latch = CountDownLatch(1)
        calendarImplem.retrieveCalendars(true, null) {
            result = it
            latch.countDown()
        }

        latch.await()

        assertTrue(result!!.isSuccess)
        assertEquals(1, result!!.getOrNull()?.size)
        assertEquals("Test Calendar", result!!.getOrNull()?.get(0)?.title)
    }

    @Test
    fun retrieveCalendars_accountFilter_appliesCorrectSelection() = runTest {
        mockPermissionGranted(permissionHandler)

        val cursor = mockk<Cursor>(relaxed = true)
        every { contentResolver.query(calendarContentUri, any(), any(), any(), any()) } returns cursor

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
    fun retrieveCalendars_noFilter_appliesCorrectSelection() = runTest {
        mockPermissionGranted(permissionHandler)

        val cursor = mockk<Cursor>(relaxed = true)
        every { contentResolver.query(calendarContentUri, any(), any(), any(), any()) } returns cursor

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
    fun retrieveCalendars_withDeniedPermission_returnsAccessRefusedError() = runTest {
        mockPermissionDenied(permissionHandler)

        var result: Result<List<Calendar>>? = null
        calendarImplem.retrieveCalendars(false, null) {
            result = it
        }

        assertTrue(result!!.isFailure)
        assertEquals("ACCESS_REFUSED", (result!!.exceptionOrNull() as FlutterError).code)
    }

    @Test
    fun retrieveCalendars_withEmptyCursor_returnsEmptyList() = runTest {
        mockPermissionGranted(permissionHandler)

        val cursor = mockk<Cursor>(relaxed = true)
        every { contentResolver.query(calendarContentUri, any(), any(), any(), any()) } returns cursor
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
    fun retrieveCalendars_withException_returnsGenericError() = runTest {
        mockPermissionGranted(permissionHandler)

        every { contentResolver.query(calendarContentUri, any(), any(), any(), any()) } throws Exception("Query failed")

        var result: Result<List<Calendar>>? = null
        val latch = CountDownLatch(1)
        calendarImplem.retrieveCalendars(false, null) {
            result = it
            latch.countDown()
        }

        latch.await()

        assertTrue(result!!.isFailure)
        assertEquals("GENERIC_ERROR", (result!!.exceptionOrNull() as FlutterError).code)
    }

    @Test
    fun deleteCalendar_withGrantedPermission_andWritableCalendar_deletesCalendarSuccessfully() = runTest {
        mockPermissionGranted(permissionHandler)
        mockWritableCalendar()

        every { contentResolver.delete(calendarContentUri, any(), any()) } returns 1

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
    fun deleteCalendar_withGrantedPermission_andNotWritableCalendar_deletesCalendarSuccessfully() = runTest {
        mockPermissionGranted(permissionHandler)
        mockNotWritableCalendar()

        var result: Result<Unit>? = null
        val latch = CountDownLatch(1)
        calendarImplem.deleteCalendar("1") {
            result = it
            latch.countDown()
        }

        latch.await()

        assertTrue(result!!.isFailure)
        assertEquals("NOT_EDITABLE", (result!!.exceptionOrNull() as FlutterError).code)
    }

    @Test
    fun deleteCalendar_withDeniedPermission_returnsAccessRefusedError() = runTest {
        mockPermissionDenied(permissionHandler)

        var result: Result<Unit>? = null
        calendarImplem.deleteCalendar("1") {
            result = it
        }

        assertTrue(result!!.isFailure)
        assertEquals("ACCESS_REFUSED", (result!!.exceptionOrNull() as FlutterError).code)
    }

    @Test
    fun deleteCalendar_withException_returnsGenericError() = runTest {
        mockPermissionGranted(permissionHandler)
        mockWritableCalendar()

        every { contentResolver.delete(calendarContentUri, any(), any()) } throws Exception("Delete failed")

        var result: Result<Unit>? = null
        val latch = CountDownLatch(1)
        calendarImplem.deleteCalendar("1") {
            result = it
            latch.countDown()
        }

        latch.await()

        assertTrue(result!!.isFailure)
        assertEquals("GENERIC_ERROR", (result!!.exceptionOrNull() as FlutterError).code)
    }

    @Test
    fun deleteCalendar_withNoRowsDeleted_returnsGenericError() = runTest {
        mockPermissionGranted(permissionHandler)
        mockWritableCalendar()

        every { contentResolver.delete(calendarContentUri, any(), any()) } returns 0

        var result: Result<Unit>? = null
        val latch = CountDownLatch(1)
        calendarImplem.deleteCalendar("1") {
            result = it
            latch.countDown()
        }

        latch.await()

        assertTrue(result!!.isFailure)
        assertEquals("GENERIC_ERROR", (result!!.exceptionOrNull() as FlutterError).code)
    }

    @Test
    fun deleteCalendar_withNotWritableCalendar_returnsNotEditableError() = runTest {
        mockPermissionGranted(permissionHandler)
        mockNotWritableCalendar()

        every { contentResolver.delete(calendarContentUri, any(), any()) } returns 0

        var result: Result<Unit>? = null
        val latch = CountDownLatch(1)
        calendarImplem.deleteCalendar("1") {
            result = it
            latch.countDown()
        }

        latch.await()

        assertTrue(result!!.isFailure)
        assertEquals("NOT_EDITABLE", (result!!.exceptionOrNull() as FlutterError).code)
    }

    @Test
    fun deleteCalendar_withNotFoundCalendar_returnsNotFoundError() = runTest {
        mockPermissionGranted(permissionHandler)
        mockCalendarNotFound()

        every { contentResolver.delete(calendarContentUri, any(), any()) } returns 0

        var result: Result<Unit>? = null
        val latch = CountDownLatch(1)
        calendarImplem.deleteCalendar("1") {
            result = it
            latch.countDown()
        }

        latch.await()

        assertTrue(result!!.isFailure)
        assertEquals("NOT_FOUND", (result!!.exceptionOrNull() as FlutterError).code)
    }
}
