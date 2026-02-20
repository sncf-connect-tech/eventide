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
import kotlinx.coroutines.test.runTest
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import java.util.concurrent.CountDownLatch
import sncf.connect.tech.eventide.Mocks.Companion.mockPermissionDenied
import sncf.connect.tech.eventide.Mocks.Companion.mockPermissionGranted
import sncf.connect.tech.eventide.handler.CalendarActivityManager
import sncf.connect.tech.eventide.handler.IcsEventManager
import sncf.connect.tech.eventide.handler.PermissionHandler

class AccountTests {
    private lateinit var context: Context
    private lateinit var contentResolver: ContentResolver
    private lateinit var permissionHandler: PermissionHandler
    private lateinit var icsEventManager: IcsEventManager
    private lateinit var accountManager: AccountManager
    private lateinit var packageManager: PackageManager
    private lateinit var calendarActivityManager: CalendarActivityManager
    private lateinit var calendarImplem: CalendarImplem
    private lateinit var calendarContentUri: Uri

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

        every { accountManager.authenticatorTypes } returns emptyArray()

        calendarImplem = CalendarImplem(
            context = context,
            contentResolver = contentResolver,
            permissionHandler = permissionHandler,
            icsEventManager = icsEventManager,
            accountManager = accountManager,
            packageManager = packageManager,
            calendarContentUri = calendarContentUri,
            calendarActivityManager = calendarActivityManager,
            eventContentUri = mockk(relaxed = true),
            remindersContentUri = mockk(relaxed = true),
            attendeesContentUri = mockk(relaxed = true),
        )
    }

    @Test
    fun retrieveAccounts_withGrantedPermission_returnsAccountsSuccessfully() = runTest {
        mockPermissionGranted(permissionHandler)

        val cursor = mockk<Cursor>(relaxed = true)
        every { contentResolver.query(calendarContentUri, any(), any(), any(), any()) } returns cursor
        every { cursor.moveToNext() } returnsMany listOf(true, true, false)

        // Mock column indices
        every { cursor.getColumnIndexOrThrow(CalendarContract.Calendars.ACCOUNT_NAME) } returns 1
        every { cursor.getColumnIndexOrThrow(CalendarContract.Calendars.ACCOUNT_TYPE) } returns 2

        // Mock values for each row and column
        every { cursor.getString(1) } returnsMany listOf("Test Account 1", "Test Account 2")
        every { cursor.getString(2) } returnsMany listOf("Microsoft", "Google")

        var result: Result<List<Account>>? = null
        val latch = CountDownLatch(1)
        calendarImplem.retrieveAccounts {
            result = it
            latch.countDown()
        }

        latch.await()

        assertTrue(result!!.isSuccess)
        assertEquals(2, result.getOrNull()?.size)
        assertEquals("Test Account 1", result.getOrNull()?.get(0)?.name)
        assertEquals("Microsoft", result.getOrNull()?.get(0)?.type)
        assertEquals("Test Account 2", result.getOrNull()?.get(1)?.name)
        assertEquals("Google", result.getOrNull()?.get(1)?.type)
    }

    @Test
    fun retrieveAccounts_withDeniedPermission_returnsAccessRefusedError() = runTest {
        mockPermissionDenied(permissionHandler)

        var result: Result<List<Account>>? = null
        calendarImplem.retrieveAccounts {
            result = it
        }

        assertTrue(result!!.isFailure)
        assertEquals("ACCESS_REFUSED", (result.exceptionOrNull() as FlutterError).code)
    }

    @Test
    fun retrieveAccounts_withEmptyCursor_returnsEmptyList() = runTest {
        mockPermissionGranted(permissionHandler)

        val cursor = mockk<Cursor>(relaxed = true)
        every { contentResolver.query(calendarContentUri, any(), any(), any(), any()) } returns cursor
        every { cursor.moveToNext() } returns false

        var result: Result<List<Account>>? = null
        val latch = CountDownLatch(1)
        calendarImplem.retrieveAccounts {
            result = it
            latch.countDown()
        }

        latch.await()

        assertTrue(result!!.isSuccess)
        assertTrue(result.getOrNull()?.isEmpty()!!)
    }

    @Test
    fun retrieveCalendars_withException_returnsGenericError() = runTest {
        mockPermissionGranted(permissionHandler)

        every { contentResolver.query(calendarContentUri, any(), any(), any(), any()) } throws Exception("Query failed")

        var result: Result<List<Account>>? = null
        val latch = CountDownLatch(1)
        calendarImplem.retrieveAccounts {
            result = it
            latch.countDown()
        }

        latch.await()

        assertTrue(result!!.isFailure)
        assertEquals("GENERIC_ERROR", (result.exceptionOrNull() as FlutterError).code)
    }
}
