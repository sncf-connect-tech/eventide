package sncf.connect.tech.eventide

import android.content.ContentResolver
import android.content.Context
import android.net.Uri
import io.mockk.every
import io.mockk.mockk
import kotlinx.coroutines.test.runTest
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import sncf.connect.tech.eventide.Mocks.Companion.mockPermissionDenied
import sncf.connect.tech.eventide.Mocks.Companion.mockPermissionGranted
import sncf.connect.tech.eventide.Mocks.Companion.mockRetrieveAttendees
import sncf.connect.tech.eventide.Mocks.Companion.mockRetrieveEvents
import java.util.concurrent.CountDownLatch

class AttendeeTests {
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
    fun createAttendee_withGrantedPermission_createsAttendeeSuccessfully() = runTest {
        mockPermissionGranted(permissionHandler)

        val insertionUri = mockk<Uri>(relaxed = true)
        every { contentResolver.insert(attendeesContentUri, any()) } returns insertionUri

        mockRetrieveEvents(contentResolver, eventContentUri)
        mockRetrieveAttendees(contentResolver, attendeesContentUri)
        mockRetrieveAttendees(contentResolver, remindersContentUri)

        var result: Result<Event>? = null
        val latch = CountDownLatch(1)
        calendarImplem.createAttendee("1", "John Doe", "john.doe@example.com", 1, 1) {
            result = it
            latch.countDown()
        }

        latch.await()

        assertTrue(result!!.isSuccess)
        val attendee = result.getOrNull()?.attendees?.get(0)
        assertEquals("John Doe", attendee!!.name)
        assertEquals("john.doe@example.com", attendee.email)
        assertEquals(1, attendee.role)
        assertEquals(1, attendee.type)
        assertEquals(1, attendee.status)
    }

    @Test
    fun createAttendee_withDeniedPermission_failsToCreateAttendee() = runTest {
        mockPermissionDenied(permissionHandler)

        var result: Result<Event>? = null
        calendarImplem.createAttendee("1", "John Doe", "john.doe@example.com", 1, 1) {
            result = it
        }

        assertTrue(result!!.isFailure)
    }

    @Test
    fun deleteAttendee_withGrantedPermission_deletesAttendeeSuccessfully() = runTest {
        mockPermissionGranted(permissionHandler)
        every { contentResolver.delete(attendeesContentUri, any(), any()) } returns 1

        mockRetrieveEvents(contentResolver, eventContentUri)
        mockRetrieveAttendees(contentResolver, attendeesContentUri)
        mockRetrieveAttendees(contentResolver, remindersContentUri)

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
        mockPermissionDenied(permissionHandler)

        var result: Result<Event>? = null
        calendarImplem.deleteAttendee("1", "john.doe@example.com") {
            result = it
        }

        assertTrue(result!!.isFailure)
    }

    @Test
    fun deleteAttendee_withException_failsToDeleteAttendee() = runTest {
        mockPermissionGranted(permissionHandler)

        every { contentResolver.delete(attendeesContentUri, any(), any()) } throws Exception("Delete failed")

        var result: Result<Event>? = null
        val latch = CountDownLatch(1)
        calendarImplem.deleteAttendee("eventId", "john.doe@example.com") {
            result = it
            latch.countDown()
        }

        latch.await()

        assertTrue(result!!.isFailure)
    }

    @Test
    fun deleteAttendee_withNoRowsDeleted_failsToDeleteAttendee() = runTest {
        mockPermissionGranted(permissionHandler)

        every { contentResolver.delete(attendeesContentUri, any(), any()) } returns 0

        var result: Result<Event>? = null
        val latch = CountDownLatch(1)
        calendarImplem.deleteAttendee("eventId", "john.doe@example.com") {
            result = it
            latch.countDown()
        }

        latch.await()

        assertTrue(result!!.isFailure)
    }
}
