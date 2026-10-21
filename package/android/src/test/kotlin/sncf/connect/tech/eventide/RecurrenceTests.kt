package sncf.connect.tech.eventide

import android.accounts.AccountManager
import android.content.ContentResolver
import android.content.Context
import android.content.pm.PackageManager
import android.database.Cursor
import android.net.Uri
import android.provider.CalendarContract
import io.mockk.every
import io.mockk.mockk
import io.mockk.verify
import kotlinx.coroutines.test.runTest
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertNull
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import sncf.connect.tech.eventide.Mocks.Companion.mockPermissionGranted
import sncf.connect.tech.eventide.Mocks.Companion.mockRetrieveAttendees
import sncf.connect.tech.eventide.Mocks.Companion.mockRetrieveEvents
import sncf.connect.tech.eventide.Mocks.Companion.mockRetrieveReminders
import sncf.connect.tech.eventide.handler.CalendarActivityManager
import sncf.connect.tech.eventide.handler.IcsEventManager
import sncf.connect.tech.eventide.handler.PermissionHandler
import sncf.connect.tech.eventide.handler.RecurrenceHelper
import java.time.Instant
import java.util.concurrent.CountDownLatch

// NOTE: android/build.gradle sets `unitTests.returnDefaultValues = true`, which stubs
// real Android classes (e.g. ContentValues.put/getAsString) to no-ops/defaults in these
// plain JVM unit tests. That means asserting against the *contents* of a captured
// ContentValues instance is unreliable here (see EventTests.kt, which never does this
// either). Instead, we assert on the `Event` object returned through the callback,
// which is a plain Kotlin data class unaffected by the stubbing.
class RecurrenceTests {
    private lateinit var context: Context
    private lateinit var contentResolver: ContentResolver
    private lateinit var permissionHandler: PermissionHandler
    private lateinit var icsEventManager: IcsEventManager
    private lateinit var accountManager: AccountManager
    private lateinit var packageManager: PackageManager
    private lateinit var calendarImplem: CalendarImplem
    private lateinit var calendarActivityManager: CalendarActivityManager
    private lateinit var calendarContentUri: Uri
    private lateinit var eventContentUri: Uri
    private lateinit var remindersContentUri: Uri
    private lateinit var attendeesContentUri: Uri
    private lateinit var instancesContentUri: Uri

    @BeforeEach
    fun setup() {
        context = mockk(relaxed = true)
        contentResolver = mockk(relaxed = true)
        permissionHandler = mockk(relaxed = true)
        icsEventManager = mockk(relaxed = true)
        accountManager = mockk(relaxed = true)
        packageManager = mockk(relaxed = true)
        calendarActivityManager = mockk(relaxed = true)
        calendarContentUri = mockk(relaxed = true)
        eventContentUri = mockk(relaxed = true)
        remindersContentUri = mockk(relaxed = true)
        attendeesContentUri = mockk(relaxed = true)
        instancesContentUri = mockk(relaxed = true)

        calendarImplem = CalendarImplem(
            context,
            permissionHandler,
            calendarActivityManager,
            icsEventManager,
            accountManager,
            packageManager,
            contentResolver,
            calendarContentUri,
            eventContentUri,
            remindersContentUri,
            attendeesContentUri,
            instancesContentUri
        )
    }

    /**
     * The real `retrieveEvents` implementation builds the query URI via
     * `instancesContentUri.buildUpon().appendPath(...).appendPath(...).build()`.
     * Since `instancesContentUri` is a relaxed mockk, `buildUpon()` returns a relaxed
     * `Uri.Builder` mock by default, whose chained calls also return relaxed mocks -
     * so no extra stubbing of the builder chain is required for the resulting URI
     * itself; we only need to stub `contentResolver.query` to match by URI matcher.
     */
    private fun mockWritableCalendar() {
        val cursor = mockk<Cursor>(relaxed = true)
        every { contentResolver.query(calendarContentUri, any(), any(), any(), any()) } returns cursor
        every { cursor.moveToNext() } returns true
        every { cursor.getInt(any()) } returns CalendarContract.Calendars.CAL_ACCESS_CONTRIBUTOR
    }

    /**
     * Mocks the `getCalendarId(eventId)` lookup (a broad `contentResolver.query(eventContentUri, ...)`
     * matcher). Mirrors `mockCalendarIdFound()` in EventTests.kt. Individual tests that also need to
     * stub more specific `eventContentUri` queries (e.g. RRULE, DTSTART/DTEND) should define those
     * `every {}` blocks *after* calling this helper, since MockK resolves the most-recently-declared
     * matching stub first.
     */
    private fun mockCalendarIdFound() {
        val cursor = mockk<Cursor>(relaxed = true)
        every { contentResolver.query(eventContentUri, any(), any(), any(), any()) } returns cursor
        every { cursor.moveToNext() } returns true
        every { cursor.getString(any()) } returns "1"
    }

    @Test
    fun `createEvent returns the RRULE in the resulting Event when recurrenceRule is provided`() = runTest {
        mockPermissionGranted(permissionHandler)
        mockWritableCalendar()

        val uri = mockk<Uri>(relaxed = true)
        every { contentResolver.insert(any(), any()) } returns uri
        every { uri.lastPathSegment } returns "42"

        val startMilli = Instant.now().toEpochMilli()
        val endMilli = Instant.now().toEpochMilli()

        var result: Result<Event>? = null
        val latch = CountDownLatch(1)
        calendarImplem.createEvent(
            calendarId = "1",
            title = "Standup",
            startDate = startMilli,
            endDate = endMilli,
            isAllDay = false,
            description = null,
            url = null,
            location = null,
            reminders = null,
            recurrenceRule = "FREQ=WEEKLY;BYDAY=MO",
        ) {
            result = it
            latch.countDown()
        }

        latch.await()

        assertTrue(result!!.isSuccess)
        assertEquals("FREQ=WEEKLY;BYDAY=MO", result.getOrNull()!!.recurrenceRule)
    }

    @Test
    fun `createEvent returns a null recurrenceRule in the resulting Event when none is provided`() = runTest {
        mockPermissionGranted(permissionHandler)
        mockWritableCalendar()

        val uri = mockk<Uri>(relaxed = true)
        every { contentResolver.insert(any(), any()) } returns uri
        every { uri.lastPathSegment } returns "43"

        val startMilli = Instant.now().toEpochMilli()
        val endMilli = Instant.now().toEpochMilli()

        var result: Result<Event>? = null
        val latch = CountDownLatch(1)
        calendarImplem.createEvent(
            calendarId = "1",
            title = "Standup",
            startDate = startMilli,
            endDate = endMilli,
            isAllDay = false,
            description = null,
            url = null,
            location = null,
            reminders = null,
            recurrenceRule = null,
        ) {
            result = it
            latch.countDown()
        }

        latch.await()

        assertTrue(result!!.isSuccess)
        assertNull(result.getOrNull()!!.recurrenceRule)
    }

    @Test
    fun `retrieveEvents returns recurrenceRule and originalInstanceTime from Instances BEGIN`() = runTest {
        mockPermissionGranted(permissionHandler)

        val instanceStart = 1751880000000L
        val instanceEnd = 1751883600000L

        // The master event Instances cursor: retrieveEvents now queries
        // CalendarContract.Instances (expanded occurrences), not CalendarContract.Events.
        val instancesCursor = mockk<Cursor>(relaxed = true)
        every { contentResolver.query(any(), any(), any(), any(), any()) } returns instancesCursor
        every { instancesCursor.moveToNext() } returnsMany listOf(true, false)

        every { instancesCursor.getColumnIndexOrThrow(CalendarContract.Instances.EVENT_ID) } returns 0
        every { instancesCursor.getColumnIndexOrThrow(CalendarContract.Instances.TITLE) } returns 1
        every { instancesCursor.getColumnIndexOrThrow(CalendarContract.Instances.DESCRIPTION) } returns 2
        every { instancesCursor.getColumnIndexOrThrow(CalendarContract.Instances.EVENT_LOCATION) } returns 3
        every { instancesCursor.getColumnIndexOrThrow(CalendarContract.Instances.BEGIN) } returns 4
        every { instancesCursor.getColumnIndexOrThrow(CalendarContract.Instances.END) } returns 5
        every { instancesCursor.getColumnIndexOrThrow(CalendarContract.Instances.RRULE) } returns 6
        every { instancesCursor.getColumnIndexOrThrow(CalendarContract.Instances.ALL_DAY) } returns 7

        every { instancesCursor.getString(0) } returns "42" // EVENT_ID -> master event id
        every { instancesCursor.getString(1) } returns "Standup"
        every { instancesCursor.getString(2) } returns null
        every { instancesCursor.getString(3) } returns null
        every { instancesCursor.getLong(4) } returns instanceStart // BEGIN
        every { instancesCursor.getLong(5) } returns instanceEnd // END
        every { instancesCursor.getString(6) } returns "FREQ=WEEKLY;BYDAY=MO" // RRULE
        every { instancesCursor.getInt(7) } returns 0
        mockNoExceptionColumns(instancesCursor)

        // Reminders/attendees are still looked up by the master EVENT_ID, unchanged.
        val emptyCursor = mockk<Cursor>(relaxed = true)
        every { emptyCursor.moveToNext() } returns false
        every { contentResolver.query(attendeesContentUri, any(), any(), any(), any()) } returns emptyCursor
        every { contentResolver.query(remindersContentUri, any(), any(), any(), any()) } returns emptyCursor

        var result: Result<List<Event>>? = null
        val latch = CountDownLatch(1)
        calendarImplem.retrieveEvents(
            calendarId = "1",
            startDate = instanceStart,
            endDate = instanceEnd,
        ) {
            result = it
            latch.countDown()
        }

        latch.await()

        assertTrue(result!!.isSuccess)
        val event = result.getOrNull()?.firstOrNull()
        assertEquals("42", event?.id)
        assertEquals("FREQ=WEEKLY;BYDAY=MO", event?.recurrenceRule)
        assertEquals(instanceStart, event?.originalInstanceTime)
        assertEquals(instanceStart, event?.startDate)
    }

    @Test
    fun `retrieveEvents returns a null originalInstanceTime for non-recurring events (no RRULE)`() = runTest {
        mockPermissionGranted(permissionHandler)

        val instanceStart = 1751880000000L
        val instanceEnd = 1751883600000L

        val instancesCursor = mockk<Cursor>(relaxed = true)
        every { contentResolver.query(any(), any(), any(), any(), any()) } returns instancesCursor
        every { instancesCursor.moveToNext() } returnsMany listOf(true, false)

        every { instancesCursor.getColumnIndexOrThrow(CalendarContract.Instances.EVENT_ID) } returns 0
        every { instancesCursor.getColumnIndexOrThrow(CalendarContract.Instances.TITLE) } returns 1
        every { instancesCursor.getColumnIndexOrThrow(CalendarContract.Instances.DESCRIPTION) } returns 2
        every { instancesCursor.getColumnIndexOrThrow(CalendarContract.Instances.EVENT_LOCATION) } returns 3
        every { instancesCursor.getColumnIndexOrThrow(CalendarContract.Instances.BEGIN) } returns 4
        every { instancesCursor.getColumnIndexOrThrow(CalendarContract.Instances.END) } returns 5
        every { instancesCursor.getColumnIndexOrThrow(CalendarContract.Instances.RRULE) } returns 6
        every { instancesCursor.getColumnIndexOrThrow(CalendarContract.Instances.ALL_DAY) } returns 7

        every { instancesCursor.getString(0) } returns "43" // EVENT_ID -> master event id
        every { instancesCursor.getString(1) } returns "One-off meeting"
        every { instancesCursor.getString(2) } returns null
        every { instancesCursor.getString(3) } returns null
        every { instancesCursor.getLong(4) } returns instanceStart // BEGIN
        every { instancesCursor.getLong(5) } returns instanceEnd // END
        every { instancesCursor.getString(6) } returns null // RRULE -> non-recurring
        every { instancesCursor.getInt(7) } returns 0
        mockNoExceptionColumns(instancesCursor)

        val emptyCursor = mockk<Cursor>(relaxed = true)
        every { emptyCursor.moveToNext() } returns false
        every { contentResolver.query(attendeesContentUri, any(), any(), any(), any()) } returns emptyCursor
        every { contentResolver.query(remindersContentUri, any(), any(), any(), any()) } returns emptyCursor

        var result: Result<List<Event>>? = null
        val latch = CountDownLatch(1)
        calendarImplem.retrieveEvents(
            calendarId = "1",
            startDate = instanceStart,
            endDate = instanceEnd,
        ) {
            result = it
            latch.countDown()
        }

        latch.await()

        assertTrue(result!!.isSuccess)
        val event = result.getOrNull()?.firstOrNull()
        assertEquals("43", event?.id)
        assertNull(event?.recurrenceRule)
        assertNull(event?.originalInstanceTime)
    }

    // ------------------------------------------------------------------
    // RecurrenceHelper.patchWithUntil - pure function, no mocking needed
    // ------------------------------------------------------------------

    /** The RDATE / ORIGINAL_ID / ORIGINAL_INSTANCE_TIME columns of an occurrence that is not an exception. */
    private fun mockNoExceptionColumns(cursor: Cursor) {
        every { cursor.getColumnIndexOrThrow(CalendarContract.Instances.RDATE) } returns 8
        every { cursor.getColumnIndexOrThrow(CalendarContract.Instances.ORIGINAL_ID) } returns 9
        every { cursor.getColumnIndexOrThrow(CalendarContract.Instances.ORIGINAL_INSTANCE_TIME) } returns 10
        every { cursor.getString(8) } returns null
        every { cursor.isNull(9) } returns true
        every { cursor.isNull(10) } returns true
    }

    /** One Instances row per entry: (EVENT_ID, BEGIN, RRULE, RDATE, ORIGINAL_ID, ORIGINAL_INSTANCE_TIME). */
    private companion object {
        /** kotlinx.coroutines' Dispatchers.IO default parallelism. */
        const val IO_POOL_THREADS = 64
    }

    private data class InstanceRow(
        val eventId: String,
        val begin: Long,
        val rrule: String? = null,
        val rdate: String? = null,
        val originalId: String? = null,
        val originalInstanceTime: Long? = null,
    )

    private fun mockInstances(vararg rows: InstanceRow): Cursor {
        val cursor = mockk<Cursor>(relaxed = true)
        every { contentResolver.query(any(), any(), any(), any(), any()) } returns cursor
        every { cursor.moveToNext() } returnsMany List(rows.size) { true } + false
        val columns = listOf(
            CalendarContract.Instances.EVENT_ID, CalendarContract.Instances.TITLE,
            CalendarContract.Instances.DESCRIPTION, CalendarContract.Instances.EVENT_LOCATION,
            CalendarContract.Instances.BEGIN, CalendarContract.Instances.END, CalendarContract.Instances.RRULE,
            CalendarContract.Instances.ALL_DAY, CalendarContract.Instances.RDATE,
            CalendarContract.Instances.ORIGINAL_ID, CalendarContract.Instances.ORIGINAL_INSTANCE_TIME,
        )
        columns.forEachIndexed { index, column -> every { cursor.getColumnIndexOrThrow(column) } returns index }
        every { cursor.getString(0) } returnsMany rows.map { it.eventId }
        every { cursor.getString(1) } returns "Standup"
        every { cursor.getLong(4) } returnsMany rows.map { it.begin }
        every { cursor.getLong(5) } returnsMany rows.map { it.begin + 3_600_000L }
        every { cursor.getString(6) } returnsMany rows.map { it.rrule }
        every { cursor.getString(8) } returnsMany rows.map { it.rdate }
        every { cursor.isNull(9) } returnsMany rows.map { it.originalId == null }
        every { cursor.getString(9) } returnsMany rows.map { it.originalId }
        every { cursor.isNull(10) } returnsMany rows.map { it.originalInstanceTime == null }
        every { cursor.getLong(10) } returnsMany rows.map { it.originalInstanceTime ?: 0L }
        return cursor
    }

    private fun mockNoDetails() {
        val emptyCursor = mockk<Cursor>(relaxed = true)
        every { emptyCursor.moveToNext() } returns false
        every { contentResolver.query(attendeesContentUri, any(), any(), any(), any()) } returns emptyCursor
        every { contentResolver.query(remindersContentUri, any(), any(), any(), any()) } returns emptyCursor
    }

    private fun retrieve(): Result<List<Event>> {
        var result: Result<List<Event>>? = null
        val latch = CountDownLatch(1)
        calendarImplem.retrieveEvents(calendarId = "1", startDate = 0L, endDate = 1L) {
            result = it
            latch.countDown()
        }
        assertTrue(latch.await(5, java.util.concurrent.TimeUnit.SECONDS), "retrieveEvents never called back")
        return result!!
    }

    @Test
    fun `retrieveEvents keys an occurrence moved on its own on its series and its original start`() = runTest {
        mockPermissionGranted(permissionHandler)
        val originalStart = 1751880000000L
        val movedStart = originalStart + 7_200_000L
        mockInstances(InstanceRow("77", movedStart, originalId = "42", originalInstanceTime = originalStart))
        mockNoDetails()

        val event = retrieve().getOrThrow().single()

        assertEquals("42", event.id)
        assertEquals(originalStart, event.originalInstanceTime)
        assertEquals(movedStart, event.startDate)
    }

    @Test
    fun `retrieveEvents treats an RDATE-only series as recurring`() = runTest {
        mockPermissionGranted(permissionHandler)
        mockInstances(InstanceRow("42", 1751880000000L, rdate = "20250707T090000Z,20250714T090000Z"))
        mockNoDetails()

        assertEquals(1751880000000L, retrieve().getOrThrow().single().originalInstanceTime)
    }

    @Test
    fun `retrieveEvents reads a series' attendees and reminders once, not once per occurrence`() = runTest {
        mockPermissionGranted(permissionHandler)
        val week = 7 * 24 * 3_600_000L
        mockInstances(
            InstanceRow("42", 1751880000000L, rrule = "FREQ=WEEKLY"),
            InstanceRow("42", 1751880000000L + week, rrule = "FREQ=WEEKLY"),
            InstanceRow("42", 1751880000000L + 2 * week, rrule = "FREQ=WEEKLY"),
        )
        mockNoDetails()

        assertEquals(3, retrieve().getOrThrow().size)
        verify(exactly = 1) { contentResolver.query(attendeesContentUri, any(), any(), any(), any()) }
        verify(exactly = 1) { contentResolver.query(remindersContentUri, any(), any(), any(), any()) }
    }

    @Test
    fun `retrieveEvents leaves out deleted events and cancelled ones`() = runTest {
        mockPermissionGranted(permissionHandler)
        mockInstances()
        mockNoDetails()
        val selection = io.mockk.slot<String>()
        every { contentResolver.query(any(), any(), capture(selection), any(), any()) } returns
            mockk<Cursor>(relaxed = true).also { every { it.moveToNext() } returns false }

        retrieve()

        assertTrue(selection.captured.contains("${CalendarContract.Events.DELETED} = 0"), selection.captured)
        assertTrue(
            selection.captured.contains("${CalendarContract.Instances.STATUS} != ${CalendarContract.Events.STATUS_CANCELED}"),
            selection.captured,
        )
    }

    /**
     * A failed attendee read used to report its failure and leave retrieveEvents' IO coroutine waiting on a latch
     * nobody counted down: one parked Dispatchers.IO thread per failure, until the pool (64 threads) is gone and
     * the next read never runs.
     */
    @Test
    fun `retrieveEvents reports failed attendee reads without parking an IO thread on each`() = runTest {
        mockPermissionGranted(permissionHandler)
        repeat(IO_POOL_THREADS + 1) {
            mockInstances(InstanceRow("42", 1751880000000L))
            every { contentResolver.query(attendeesContentUri, any(), any(), any(), any()) } throws
                IllegalStateException("provider gone")

            assertTrue(retrieve().isFailure)
        }
    }

    /** The exception row (id 77) already standing for series 42's occurrence at [originalInstanceTime]. */
    private fun mockExistingException(originalInstanceTime: Long) {
        val exceptionCursor = mockk<Cursor>(relaxed = true)
        every {
            contentResolver.query(
                eventContentUri,
                arrayOf(CalendarContract.Events._ID),
                any(),
                arrayOf("42", originalInstanceTime.toString()),
                null,
            )
        } returns exceptionCursor
        every { exceptionCursor.moveToFirst() } returns true
        every { exceptionCursor.getString(0) } returns "77"
    }

    @Test
    fun `deleteEvent with thisEvent span cancels the occurrence's existing exception instead of adding one`() = runTest {
        mockPermissionGranted(permissionHandler)
        mockCalendarIdFound()
        mockWritableCalendar()
        mockExistingException(1751880000000L)
        every { contentResolver.update(eventContentUri, any(), "_id = ?", arrayOf("77")) } returns 1

        var result: Result<Unit>? = null
        val latch = CountDownLatch(1)
        calendarImplem.deleteEvent(eventId = "42", span = "thisEvent", originalInstanceTime = 1751880000000L) {
            result = it
            latch.countDown()
        }
        latch.await()

        assertTrue(result!!.isSuccess)
        verify { contentResolver.update(eventContentUri, any(), "_id = ?", arrayOf("77")) }
        verify(exactly = 0) { contentResolver.insert(any(), any()) }
    }

    @Test
    fun `updateEvent with thisEvent span updates the occurrence's existing exception instead of adding one`() = runTest {
        mockPermissionGranted(permissionHandler)
        mockWritableCalendar()
        mockRetrieveEvents(contentResolver, eventContentUri)
        mockRetrieveAttendees(contentResolver, attendeesContentUri)
        mockRetrieveReminders(contentResolver, remindersContentUri)
        mockExistingException(1751880000000L)
        every { contentResolver.update(eventContentUri, any(), "_id = ?", arrayOf("77")) } returns 1

        var result: Result<Event>? = null
        val latch = CountDownLatch(1)
        calendarImplem.updateEvent(
            eventId = "42",
            calendarId = "1",
            title = "Moved again",
            startDate = 1751887200000L,
            endDate = 1751890800000L,
            isAllDay = false,
            description = null,
            url = null,
            location = null,
            reminders = null,
            recurrenceRule = null,
            span = "thisEvent",
            originalInstanceTime = 1751880000000L,
        ) {
            result = it
            latch.countDown()
        }
        latch.await()

        assertTrue(result!!.isSuccess)
        verify { contentResolver.update(eventContentUri, any(), "_id = ?", arrayOf("77")) }
        verify(exactly = 0) { contentResolver.insert(eventContentUri, any()) }
    }

    @Test
    fun `patchWithUntil appends UNTIL to a rrule with no COUNT or UNTIL`() {
        val patched = RecurrenceHelper.patchWithUntil("FREQ=WEEKLY;BYDAY=MO", 1751880000000L)

        assertEquals("FREQ=WEEKLY;BYDAY=MO;UNTIL=20250707T091959Z", patched)
    }

    @Test
    fun `patchWithUntil replaces an existing UNTIL`() {
        val patched = RecurrenceHelper.patchWithUntil(
            "FREQ=DAILY;UNTIL=20200101T000000Z",
            1751880000000L,
        )

        assertEquals("FREQ=DAILY;UNTIL=20250707T091959Z", patched)
    }

    @Test
    fun `patchWithUntil replaces an existing COUNT since COUNT and UNTIL are mutually exclusive`() {
        val patched = RecurrenceHelper.patchWithUntil("FREQ=DAILY;COUNT=10", 1751880000000L)

        assertTrue(!patched.contains("COUNT="))
        assertEquals("FREQ=DAILY;UNTIL=20250707T091959Z", patched)
    }

    @Test
    fun `stripUntilAndCount removes UNTIL and COUNT parts, leaving the rest of the rrule intact`() {
        val stripped = RecurrenceHelper.stripUntilAndCount("FREQ=DAILY;COUNT=10;BYDAY=MO")

        assertEquals("FREQ=DAILY;BYDAY=MO", stripped)
    }

    @Test
    fun `stripUntilAndCount is a no-op when the rrule has no UNTIL or COUNT`() {
        val stripped = RecurrenceHelper.stripUntilAndCount("FREQ=WEEKLY;BYDAY=MO")

        assertEquals("FREQ=WEEKLY;BYDAY=MO", stripped)
    }

    // ------------------------------------------------------------------
    // RecurrenceHelper.getMasterRrule / getMasterEventDurationMs
    // ------------------------------------------------------------------

    @Test
    fun `getMasterRrule returns the RRULE column value when the master event is found`() {
        val cursor = mockk<Cursor>(relaxed = true)
        every {
            contentResolver.query(eventContentUri, arrayOf(CalendarContract.Events.RRULE), "_id = ?", arrayOf("42"), null)
        } returns cursor
        every { cursor.moveToFirst() } returns true
        every { cursor.getString(0) } returns "FREQ=WEEKLY;BYDAY=MO"

        val rrule = RecurrenceHelper.getMasterRrule(contentResolver, eventContentUri, "42")

        assertEquals("FREQ=WEEKLY;BYDAY=MO", rrule)
    }

    @Test
    fun `getMasterRrule returns null when the master event is not found`() {
        val cursor = mockk<Cursor>(relaxed = true)
        every {
            contentResolver.query(eventContentUri, arrayOf(CalendarContract.Events.RRULE), "_id = ?", arrayOf("42"), null)
        } returns cursor
        every { cursor.moveToFirst() } returns false

        val rrule = RecurrenceHelper.getMasterRrule(contentResolver, eventContentUri, "42")

        assertNull(rrule)
    }

    @Test
    fun `getMasterEventDurationMs returns DTEND minus DTSTART when the master event is found`() {
        val cursor = mockk<Cursor>(relaxed = true)
        every {
            contentResolver.query(
                eventContentUri,
                arrayOf(CalendarContract.Events.DTSTART, CalendarContract.Events.DTEND),
                "_id = ?",
                arrayOf("42"),
                null,
            )
        } returns cursor
        every { cursor.moveToFirst() } returns true
        every { cursor.getLong(0) } returns 1751880000000L // DTSTART
        every { cursor.getLong(1) } returns 1751883600000L // DTEND

        val durationMs = RecurrenceHelper.getMasterEventDurationMs(contentResolver, eventContentUri, "42")

        assertEquals(3_600_000L, durationMs)
    }

    @Test
    fun `getMasterEventDurationMs defaults to one hour when the master event is not found`() {
        val cursor = mockk<Cursor>(relaxed = true)
        every {
            contentResolver.query(
                eventContentUri,
                arrayOf(CalendarContract.Events.DTSTART, CalendarContract.Events.DTEND),
                "_id = ?",
                arrayOf("42"),
                null,
            )
        } returns cursor
        every { cursor.moveToFirst() } returns false

        val durationMs = RecurrenceHelper.getMasterEventDurationMs(contentResolver, eventContentUri, "42")

        assertEquals(3_600_000L, durationMs)
    }

    // ------------------------------------------------------------------
    // deleteEvent - span-aware behavior
    // ------------------------------------------------------------------

    @Test
    fun `deleteEvent with allEvents span deletes the master event row`() = runTest {
        mockPermissionGranted(permissionHandler)
        mockCalendarIdFound()
        mockWritableCalendar()

        every { contentResolver.delete(eventContentUri, "_id = ?", arrayOf("42")) } returns 1

        var result: Result<Unit>? = null
        val latch = CountDownLatch(1)
        calendarImplem.deleteEvent(
            eventId = "42",
            span = "allEvents",
            originalInstanceTime = null,
        ) {
            result = it
            latch.countDown()
        }

        latch.await()

        assertTrue(result!!.isSuccess)
        verify { contentResolver.delete(eventContentUri, "_id = ?", arrayOf("42")) }
    }

    @Test
    fun `deleteEvent with an unrecognized span falls back to deleting the master event row`() = runTest {
        mockPermissionGranted(permissionHandler)
        mockCalendarIdFound()
        mockWritableCalendar()

        every { contentResolver.delete(eventContentUri, "_id = ?", arrayOf("42")) } returns 1

        var result: Result<Unit>? = null
        val latch = CountDownLatch(1)
        calendarImplem.deleteEvent(
            eventId = "42",
            span = "somethingUnexpected",
            originalInstanceTime = null,
        ) {
            result = it
            latch.countDown()
        }

        latch.await()

        assertTrue(result!!.isSuccess)
        verify { contentResolver.delete(eventContentUri, "_id = ?", arrayOf("42")) }
    }

    @Test
    fun `deleteEvent with thisEvent span inserts a STATUS_CANCELED exception row instead of deleting`() = runTest {
        mockPermissionGranted(permissionHandler)
        mockCalendarIdFound()
        mockWritableCalendar()

        // getMasterEventDurationMs query
        val durationCursor = mockk<Cursor>(relaxed = true)
        every {
            contentResolver.query(
                eventContentUri,
                arrayOf(CalendarContract.Events.DTSTART, CalendarContract.Events.DTEND),
                "_id = ?",
                arrayOf("42"),
                null,
            )
        } returns durationCursor
        every { durationCursor.moveToFirst() } returns true
        every { durationCursor.getLong(0) } returns 1751880000000L // DTSTART
        every { durationCursor.getLong(1) } returns 1751883600000L // DTEND

        every { contentResolver.insert(eventContentUri, any()) } returns
            mockk<Uri>(relaxed = true)

        var result: Result<Unit>? = null
        val latch = CountDownLatch(1)
        calendarImplem.deleteEvent(
            eventId = "42",
            span = "thisEvent",
            originalInstanceTime = 1751880000000L,
        ) {
            result = it
            latch.countDown()
        }

        latch.await()

        assertTrue(result!!.isSuccess)
        verify { contentResolver.insert(eventContentUri, any()) }
        verify(exactly = 0) { contentResolver.delete(any(), any(), any()) }
    }

    @Test
    fun `deleteEvent with thisAndFuture span patches the master RRULE with UNTIL when the event recurs`() = runTest {
        mockPermissionGranted(permissionHandler)
        mockCalendarIdFound()
        mockWritableCalendar()

        val rruleCursor = mockk<Cursor>(relaxed = true)
        every {
            contentResolver.query(eventContentUri, arrayOf(CalendarContract.Events.RRULE), "_id = ?", arrayOf("42"), null)
        } returns rruleCursor
        every { rruleCursor.moveToFirst() } returns true
        every { rruleCursor.getString(0) } returns "FREQ=WEEKLY;BYDAY=MO"

        every { contentResolver.update(eventContentUri, any(), "_id = ?", arrayOf("42")) } returns 1

        var result: Result<Unit>? = null
        val latch = CountDownLatch(1)
        calendarImplem.deleteEvent(
            eventId = "42",
            span = "thisAndFuture",
            originalInstanceTime = 1751880000000L,
        ) {
            result = it
            latch.countDown()
        }

        latch.await()

        assertTrue(result!!.isSuccess)
        verify { contentResolver.update(eventContentUri, any(), "_id = ?", arrayOf("42")) }
        verify(exactly = 0) { contentResolver.delete(any(), any(), any()) }
    }

    @Test
    fun `deleteEvent with thisEvent span and null originalInstanceTime falls back to deleting the master row (backward compat for pre-recurrence callers)`() = runTest {
        mockPermissionGranted(permissionHandler)
        mockCalendarIdFound()
        mockWritableCalendar()

        every { contentResolver.delete(eventContentUri, "_id = ?", arrayOf("42")) } returns 1

        var result: Result<Unit>? = null
        val latch = CountDownLatch(1)
        calendarImplem.deleteEvent(
            eventId = "42",
            span = "thisEvent",
            originalInstanceTime = null,
        ) {
            result = it
            latch.countDown()
        }

        latch.await()

        assertTrue(result!!.isSuccess)
        verify { contentResolver.delete(eventContentUri, "_id = ?", arrayOf("42")) }
        verify(exactly = 0) { contentResolver.insert(any(), any()) }
    }

    @Test
    fun `deleteEvent with thisAndFuture span and null originalInstanceTime falls back to deleting the master row (backward compat for pre-recurrence callers)`() = runTest {
        mockPermissionGranted(permissionHandler)
        mockCalendarIdFound()
        mockWritableCalendar()

        every { contentResolver.delete(eventContentUri, "_id = ?", arrayOf("42")) } returns 1

        var result: Result<Unit>? = null
        val latch = CountDownLatch(1)
        calendarImplem.deleteEvent(
            eventId = "42",
            span = "thisAndFuture",
            originalInstanceTime = null,
        ) {
            result = it
            latch.countDown()
        }

        latch.await()

        assertTrue(result!!.isSuccess)
        verify { contentResolver.delete(eventContentUri, "_id = ?", arrayOf("42")) }
        verify(exactly = 0) { contentResolver.update(any(), any(), any(), any()) }
    }

    @Test
    fun `deleteEvent with thisAndFuture span falls back to deleting the master row when the event is not recurring`() = runTest {
        mockPermissionGranted(permissionHandler)
        mockCalendarIdFound()
        mockWritableCalendar()

        val rruleCursor = mockk<Cursor>(relaxed = true)
        every {
            contentResolver.query(eventContentUri, arrayOf(CalendarContract.Events.RRULE), "_id = ?", arrayOf("42"), null)
        } returns rruleCursor
        every { rruleCursor.moveToFirst() } returns false // no RRULE -> non-recurring master

        every { contentResolver.delete(eventContentUri, "_id = ?", arrayOf("42")) } returns 1

        var result: Result<Unit>? = null
        val latch = CountDownLatch(1)
        calendarImplem.deleteEvent(
            eventId = "42",
            span = "thisAndFuture",
            originalInstanceTime = 1751880000000L,
        ) {
            result = it
            latch.countDown()
        }

        latch.await()

        assertTrue(result!!.isSuccess)
        verify { contentResolver.delete(eventContentUri, "_id = ?", arrayOf("42")) }
        verify(exactly = 0) { contentResolver.update(any(), any(), any(), any()) }
    }

    // ------------------------------------------------------------------
    // updateEvent - span-aware behavior
    // ------------------------------------------------------------------

    @Test
    fun `updateEvent with allEvents span updates the master event row in place`() = runTest {
        mockPermissionGranted(permissionHandler)
        mockWritableCalendar()

        every { contentResolver.update(eventContentUri, any(), "_id = ?", arrayOf("42")) } returns 1

        mockRetrieveEvents(contentResolver, eventContentUri)
        mockRetrieveAttendees(contentResolver, attendeesContentUri)
        mockRetrieveReminders(contentResolver, remindersContentUri)

        var result: Result<Event>? = null
        val latch = CountDownLatch(1)
        calendarImplem.updateEvent(
            eventId = "42",
            calendarId = "1",
            title = "Updated Standup",
            startDate = 1751880000000L,
            endDate = 1751883600000L,
            isAllDay = false,
            description = null,
            url = null,
            location = null,
            reminders = null,
            recurrenceRule = "FREQ=WEEKLY;BYDAY=MO,WE",
            span = "allEvents",
            originalInstanceTime = null,
        ) {
            result = it
            latch.countDown()
        }

        latch.await()

        assertTrue(result!!.isSuccess)
        verify { contentResolver.update(eventContentUri, any(), "_id = ?", arrayOf("42")) }
        verify(exactly = 0) { contentResolver.insert(eventContentUri, any()) }
    }

    @Test
    fun `updateEvent with an unrecognized span falls back to updating the master event row in place`() = runTest {
        mockPermissionGranted(permissionHandler)
        mockWritableCalendar()

        every { contentResolver.update(eventContentUri, any(), "_id = ?", arrayOf("42")) } returns 1

        mockRetrieveEvents(contentResolver, eventContentUri)
        mockRetrieveAttendees(contentResolver, attendeesContentUri)
        mockRetrieveReminders(contentResolver, remindersContentUri)

        var result: Result<Event>? = null
        val latch = CountDownLatch(1)
        calendarImplem.updateEvent(
            eventId = "42",
            calendarId = "1",
            title = "Updated Standup",
            startDate = 1751880000000L,
            endDate = 1751883600000L,
            isAllDay = false,
            description = null,
            url = null,
            location = null,
            reminders = null,
            recurrenceRule = null,
            span = "somethingUnexpected",
            originalInstanceTime = null,
        ) {
            result = it
            latch.countDown()
        }

        latch.await()

        assertTrue(result!!.isSuccess)
        verify { contentResolver.update(eventContentUri, any(), "_id = ?", arrayOf("42")) }
        verify(exactly = 0) { contentResolver.insert(eventContentUri, any()) }
    }

    @Test
    fun `updateEvent with thisEvent span and null originalInstanceTime falls back to updating the master row (backward compat for pre-recurrence callers)`() = runTest {
        mockPermissionGranted(permissionHandler)
        mockWritableCalendar()

        every { contentResolver.update(eventContentUri, any(), "_id = ?", arrayOf("42")) } returns 1

        mockRetrieveEvents(contentResolver, eventContentUri)
        mockRetrieveAttendees(contentResolver, attendeesContentUri)
        mockRetrieveReminders(contentResolver, remindersContentUri)

        var result: Result<Event>? = null
        val latch = CountDownLatch(1)
        calendarImplem.updateEvent(
            eventId = "42",
            calendarId = "1",
            title = "New title",
            startDate = 1751880000000L,
            endDate = 1751883600000L,
            isAllDay = false,
            description = null,
            url = null,
            location = null,
            reminders = null,
            recurrenceRule = null,
            span = "thisEvent",
            originalInstanceTime = null,
        ) {
            result = it
            latch.countDown()
        }

        latch.await()

        assertTrue(result!!.isSuccess)
        verify { contentResolver.update(eventContentUri, any(), "_id = ?", arrayOf("42")) }
        verify(exactly = 0) { contentResolver.insert(eventContentUri, any()) }
    }

    @Test
    fun `updateEvent with thisAndFuture span and null originalInstanceTime falls back to updating the master row (backward compat for pre-recurrence callers)`() = runTest {
        mockPermissionGranted(permissionHandler)
        mockWritableCalendar()

        every { contentResolver.update(eventContentUri, any(), "_id = ?", arrayOf("42")) } returns 1

        mockRetrieveEvents(contentResolver, eventContentUri)
        mockRetrieveAttendees(contentResolver, attendeesContentUri)
        mockRetrieveReminders(contentResolver, remindersContentUri)

        var result: Result<Event>? = null
        val latch = CountDownLatch(1)
        calendarImplem.updateEvent(
            eventId = "42",
            calendarId = "1",
            title = "New title",
            startDate = 1751880000000L,
            endDate = 1751883600000L,
            isAllDay = false,
            description = null,
            url = null,
            location = null,
            reminders = null,
            recurrenceRule = null,
            span = "thisAndFuture",
            originalInstanceTime = null,
        ) {
            result = it
            latch.countDown()
        }

        latch.await()

        assertTrue(result!!.isSuccess)
        verify { contentResolver.update(eventContentUri, any(), "_id = ?", arrayOf("42")) }
        verify(exactly = 0) { contentResolver.insert(eventContentUri, any()) }
    }

    @Test
    fun `updateEvent with thisEvent span inserts a new exception row instead of updating the master`() = runTest {
        mockPermissionGranted(permissionHandler)
        mockWritableCalendar()

        val insertedUri = mockk<Uri>(relaxed = true)
        every { contentResolver.insert(eventContentUri, any()) } returns insertedUri
        every { insertedUri.lastPathSegment } returns "99"

        mockRetrieveEvents(contentResolver, eventContentUri)
        mockRetrieveAttendees(contentResolver, attendeesContentUri)
        mockRetrieveReminders(contentResolver, remindersContentUri)

        var result: Result<Event>? = null
        val latch = CountDownLatch(1)
        calendarImplem.updateEvent(
            eventId = "42",
            calendarId = "1",
            title = "Just today",
            startDate = 1751880000000L,
            endDate = 1751883600000L,
            isAllDay = false,
            description = null,
            url = null,
            location = null,
            reminders = null,
            recurrenceRule = null,
            span = "thisEvent",
            originalInstanceTime = 1751880000000L,
        ) {
            result = it
            latch.countDown()
        }

        latch.await()

        assertTrue(result!!.isSuccess)
        verify { contentResolver.insert(eventContentUri, any()) }
        verify(exactly = 0) { contentResolver.update(eventContentUri, any(), any(), any()) }
    }

    @Test
    fun `updateEvent with thisAndFuture span truncates the master series and inserts a new one starting at originalInstanceTime`() = runTest {
        mockPermissionGranted(permissionHandler)
        mockWritableCalendar()

        // mockRetrieveEvents stubs a broad contentResolver.query(eventContentUri, any(), any(), any(), any())
        // matcher (used to re-fetch the event after the update completes). Since MockK resolves the
        // most-recently-declared matching stub first, the more specific RRULE-projection query below
        // must be declared *after* this call so it takes precedence for that exact call shape.
        mockRetrieveEvents(contentResolver, eventContentUri)
        mockRetrieveAttendees(contentResolver, attendeesContentUri)
        mockRetrieveReminders(contentResolver, remindersContentUri)

        val rruleCursor = mockk<Cursor>(relaxed = true)
        every {
            contentResolver.query(eventContentUri, arrayOf(CalendarContract.Events.RRULE), "_id = ?", arrayOf("42"), null)
        } returns rruleCursor
        every { rruleCursor.moveToFirst() } returns true
        every { rruleCursor.getString(0) } returns "FREQ=WEEKLY;BYDAY=MO"

        every { contentResolver.update(eventContentUri, any(), "_id = ?", arrayOf("42")) } returns 1

        val insertedUri = mockk<Uri>(relaxed = true)
        every { contentResolver.insert(eventContentUri, any()) } returns insertedUri
        every { insertedUri.lastPathSegment } returns "99"

        var result: Result<Event>? = null
        val latch = CountDownLatch(1)
        calendarImplem.updateEvent(
            eventId = "42",
            calendarId = "1",
            title = "Updated Standup",
            startDate = 1751880000000L,
            endDate = 1751883600000L,
            isAllDay = false,
            description = null,
            url = null,
            location = null,
            reminders = null,
            recurrenceRule = "FREQ=WEEKLY;BYDAY=MO,WE",
            span = "thisAndFuture",
            originalInstanceTime = 1751880000000L,
        ) {
            result = it
            latch.countDown()
        }

        latch.await()

        assertTrue(result!!.isSuccess)
        // Master series truncated (UNTIL patch) via update...
        verify { contentResolver.update(eventContentUri, any(), "_id = ?", arrayOf("42")) }
        // ...and a new master row inserted to continue the series.
        verify { contentResolver.insert(eventContentUri, any()) }
    }

    @Test
    fun `updateEvent with thisAndFuture span on a non-recurring master skips the truncation update but still inserts the new series`() = runTest {
        mockPermissionGranted(permissionHandler)
        mockWritableCalendar()

        // See ordering note in the previous test: declare the broad mockRetrieveEvents
        // stub first so the specific RRULE-projection query below takes precedence.
        mockRetrieveEvents(contentResolver, eventContentUri)
        mockRetrieveAttendees(contentResolver, attendeesContentUri)
        mockRetrieveReminders(contentResolver, remindersContentUri)

        val rruleCursor = mockk<Cursor>(relaxed = true)
        every {
            contentResolver.query(eventContentUri, arrayOf(CalendarContract.Events.RRULE), "_id = ?", arrayOf("42"), null)
        } returns rruleCursor
        every { rruleCursor.moveToFirst() } returns false // no RRULE -> non-recurring master

        val insertedUri = mockk<Uri>(relaxed = true)
        every { contentResolver.insert(eventContentUri, any()) } returns insertedUri
        every { insertedUri.lastPathSegment } returns "99"

        var result: Result<Event>? = null
        val latch = CountDownLatch(1)
        calendarImplem.updateEvent(
            eventId = "42",
            calendarId = "1",
            title = "Updated Standup",
            startDate = 1751880000000L,
            endDate = 1751883600000L,
            isAllDay = false,
            description = null,
            url = null,
            location = null,
            reminders = null,
            recurrenceRule = null,
            span = "thisAndFuture",
            originalInstanceTime = 1751880000000L,
        ) {
            result = it
            latch.countDown()
        }

        latch.await()

        assertTrue(result!!.isSuccess)
        verify(exactly = 0) { contentResolver.update(eventContentUri, any(), "_id = ?", arrayOf("42")) }
        verify { contentResolver.insert(eventContentUri, any()) }
    }
}
