package sncf.connect.tech.eventide

import io.mockk.every
import io.mockk.mockk
import kotlinx.coroutines.test.runTest
import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import java.util.concurrent.CountDownLatch

class PermissionRequestTests {
    private lateinit var permissionHandler: PermissionHandler
    private lateinit var calendarImplem: CalendarImplem

    @BeforeEach
    fun setup() {
        permissionHandler = mockk(relaxed = true)
        calendarImplem = CalendarImplem(
            contentResolver = mockk(relaxed = true),
            permissionHandler = permissionHandler,
            calendarContentUri = mockk(relaxed = true),
            eventContentUri = mockk(relaxed = true),
            remindersContentUri = mockk(relaxed = true),
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
}
