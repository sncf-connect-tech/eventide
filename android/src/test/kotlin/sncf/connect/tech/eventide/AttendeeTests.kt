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

        mockRetrieveEvents(contentResolver, eventContentUri)
        mockRetrieveAttendees(contentResolver, attendeesContentUri)
        mockRetrieveReminders(contentResolver, remindersContentUri)

        var result: Result<Event>? = null
        val latch = CountDownLatch(1)
        calendarImplem.createAttendee("1", "John Doe", "john.doe@example.com", 1, 1) {
            result = it
            latch.countDown()
        }

        latch.await()

        assertTrue(result!!.isSuccess)
        val attendee = result!!.getOrNull()?.attendees?.get(0)
        assertEquals("John Doe", attendee!!.name)
        assertEquals("john.doe@example.com", attendee.email)
        assertEquals(1, attendee.role)
        assertEquals(1, attendee.type)
        assertEquals(1, attendee.status)
    }

    @Test
    fun createAttendee_withDeniedPermission_failsToCreateAttendee() = runTest {
        every { permissionHandler.requestWritePermission(any()) } answers {
            firstArg<(Boolean) -> Unit>().invoke(false)
        }

        var result: Result<Event>? = null
        calendarImplem.createAttendee("1", "John Doe", "john.doe@example.com", 1, 1) {
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

        mockRetrieveEvents(contentResolver, eventContentUri)
        mockRetrieveAttendees(contentResolver, attendeesContentUri)
        mockRetrieveReminders(contentResolver, remindersContentUri)

        var result: Result<Event>? = null
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

        var result: Result<Event>? = null
        calendarImplem.deleteAttendee("1", "john.doe@example.com") {
            result = it
        }

        assertTrue(result!!.isFailure)
    }
}
