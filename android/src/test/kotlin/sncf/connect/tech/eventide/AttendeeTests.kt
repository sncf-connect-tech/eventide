package sncf.connect.tech.eventide

import android.content.ContentResolver
import android.database.Cursor
import android.net.Uri
import io.mockk.every
import io.mockk.mockk
import kotlinx.coroutines.test.runTest
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import java.util.concurrent.CountDownLatch

class AttendeeTests {
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

    @Test
    fun createAttendee_withGrantedPermission_createsAttendeeSuccessfully() = runTest {
        every { permissionHandler.requestWritePermission(any()) } answers {
            firstArg<(Boolean) -> Unit>().invoke(true)
        }

        val insertionUri = mockk<Uri>(relaxed = true)
        every { contentResolver.insert(attendeesContentUri, any()) } returns insertionUri

        val cursor = mockk<Cursor>(relaxed = true)
        every { contentResolver.query(attendeesContentUri, any(), any(), any(), any()) } returns cursor
        every { cursor.moveToNext() } returns true
        every { cursor.getString(any()) } returns "John Doe"
        every { cursor.getInt(any()) } returnsMany listOf(1, 1, 1)

        var result: Result<Attendee>? = null
        val latch = CountDownLatch(1)
        calendarImplem.createAttendee("1", "John Doe", "john.doe@example.com", 1, 1) {
            result = it
            latch.countDown()
        }

        latch.await()

        assertTrue(result!!.isSuccess)
        assertEquals("John Doe", result!!.getOrNull()?.name)
        assertEquals("john.doe@example.com", result!!.getOrNull()?.email)
        assertEquals(1, result!!.getOrNull()?.role)
        assertEquals(1, result!!.getOrNull()?.type)
        assertEquals(1, result!!.getOrNull()?.status)
    }

    @Test
    fun createAttendee_withDeniedPermission_failsToCreateAttendee() = runTest {
        every { permissionHandler.requestWritePermission(any()) } answers {
            firstArg<(Boolean) -> Unit>().invoke(false)
        }

        var result: Result<Attendee>? = null
        calendarImplem.createAttendee("1", "John Doe", "john.doe@example.com", 1, 1) {
            result = it
        }

        assertTrue(result!!.isFailure)
    }

    @Test
    fun retrieveAttendees_withGrantedPermission_returnsAttendees() = runTest {
        every { permissionHandler.requestReadPermission(any()) } answers {
            firstArg<(Boolean) -> Unit>().invoke(true)
        }
        val cursor = mockk<Cursor>(relaxed = true)
        every { contentResolver.query(attendeesContentUri, any(), any(), any(), any()) } returns cursor
        every { cursor.moveToNext() } returnsMany listOf(true, true, false)
        every { cursor.getString(any()) } returnsMany listOf("John Doe", "john.doe@example.com", "Jane Doe", "jane.doe@example.com")
        every { cursor.getInt(any()) } returnsMany listOf(1, 1, 1, 2, 2, 2)

        var result: Result<List<Attendee>>? = null
        val latch = CountDownLatch(1)
        calendarImplem.retrieveAttendees("1") {
            result = it
            latch.countDown()
        }

        latch.await()

        assertTrue(result!!.isSuccess)
        assertEquals(2, result!!.getOrNull()?.size)
        assertEquals("John Doe", result!!.getOrNull()?.get(0)?.name)
        assertEquals("john.doe@example.com", result!!.getOrNull()?.get(0)?.email)
        assertEquals(1, result!!.getOrNull()?.get(0)?.role)
        assertEquals(1, result!!.getOrNull()?.get(0)?.type)
        assertEquals(1, result!!.getOrNull()?.get(0)?.status)
        assertEquals("Jane Doe", result!!.getOrNull()?.get(1)?.name)
        assertEquals("jane.doe@example.com", result!!.getOrNull()?.get(1)?.email)
        assertEquals(2, result!!.getOrNull()?.get(1)?.role)
        assertEquals(2, result!!.getOrNull()?.get(1)?.type)
        assertEquals(2, result!!.getOrNull()?.get(1)?.status)
    }

    @Test
    fun retrieveAttendees_withDeniedPermission_failsToRetrieveAttendees() = runTest {
        every { permissionHandler.requestReadPermission(any()) } answers {
            firstArg<(Boolean) -> Unit>().invoke(false)
        }

        var result: Result<List<Attendee>>? = null
        calendarImplem.retrieveAttendees("1") {
            result = it
        }

        assertTrue(result!!.isFailure)
    }

    @Test
    fun deleteAttendee_withGrantedPermission_deletesAttendeeSuccessfully() = runTest {
        every { permissionHandler.requestWritePermission(any()) } answers {
            firstArg<(Boolean) -> Unit>().invoke(true)
        }
        every { contentResolver.delete(attendeesContentUri, any(), any()) } returns 1

        var result: Result<Unit>? = null
        val latch = CountDownLatch(1)
        calendarImplem.deleteAttendee("1", "john.doe@example.com") {
            result = it
            latch.countDown()
        }

        latch.await()

        assertTrue(result!!.isSuccess)
    }

    @Test
    fun deleteAttendee_withDeniedPermission_failsToDeleteAttendee() = runTest {
        every { permissionHandler.requestWritePermission(any()) } answers {
            firstArg<(Boolean) -> Unit>().invoke(false)
        }

        var result: Result<Unit>? = null
        calendarImplem.deleteAttendee("1", "john.doe@example.com") {
            result = it
        }

        assertTrue(result!!.isFailure)
    }
}
