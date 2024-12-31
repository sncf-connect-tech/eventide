package sncf.connect.tech.flutter_calendar_connect

import android.Manifest.permission.READ_CALENDAR
import android.Manifest.permission.WRITE_CALENDAR
import android.app.Activity
import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import io.mockk.every
import io.mockk.mockk
import io.mockk.mockkStatic
import io.mockk.verify
import org.junit.jupiter.api.Test
import sncf.connect.tech.flutter_calendar_connect.PermissionHandler.Companion.readRequestCode
import sncf.connect.tech.flutter_calendar_connect.PermissionHandler.Companion.writeRequestCode
import kotlin.test.BeforeTest
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class PermissionHandlerTest {
  @BeforeTest
  fun setup() {
    mockkStatic(ActivityCompat::class)
  }

  @Test
  fun requestReadPermission_grantedImmediately() {
    val activity: Activity = mockk<Activity>(relaxed = true)
    val permissionHandler = PermissionHandler(activity)

    every { ActivityCompat.checkSelfPermission(activity, READ_CALENDAR) } returns PackageManager.PERMISSION_GRANTED

    var permissionGranted = false
    permissionHandler.requestReadPermission { granted ->
      permissionGranted = granted
    }

    assertTrue(permissionGranted)
  }

  @Test
  fun requestReadPermission_requestsPermission() {
    val activity: Activity = mockk<Activity>(relaxed = true)
    val permissionHandler = PermissionHandler(activity)

    every { ActivityCompat.checkSelfPermission(activity, READ_CALENDAR) } returns PackageManager.PERMISSION_DENIED
    every { ActivityCompat.requestPermissions(activity, arrayOf(READ_CALENDAR), readRequestCode) } returns Unit

    permissionHandler.requestReadPermission { }

    verify { ActivityCompat.requestPermissions(activity, arrayOf(READ_CALENDAR), readRequestCode) }
  }

  @Test
  fun onRequestPermissionsResult_readPermissionGranted() {
    val activity: Activity = mockk<Activity>(relaxed = true)
    val permissionHandler = PermissionHandler(activity)

    var permissionGranted = false
    permissionHandler.requestReadPermission { granted ->
      permissionGranted = granted
    }

    val result = permissionHandler.onRequestPermissionsResult(readRequestCode, arrayOf(READ_CALENDAR), intArrayOf(PackageManager.PERMISSION_GRANTED))

    assertTrue(result)
    assertTrue(permissionGranted)
  }

  @Test
  fun onRequestPermissionsResult_readPermissionDenied() {
    val activity: Activity = mockk<Activity>(relaxed = true)
    val permissionHandler = PermissionHandler(activity)

    every { ActivityCompat.checkSelfPermission(activity, READ_CALENDAR) } returns PackageManager.PERMISSION_DENIED

    var permissionGranted = false
    permissionHandler.requestReadPermission { granted ->
      permissionGranted = granted
    }

    val result = permissionHandler.onRequestPermissionsResult(readRequestCode, arrayOf(READ_CALENDAR), intArrayOf(PackageManager.PERMISSION_DENIED))

    assertTrue(result)
    assertFalse(permissionGranted)
  }

  @Test
  fun requestWritePermission_grantedImmediately() {
    val activity: Activity = mockk<Activity>(relaxed = true)
    val permissionHandler = PermissionHandler(activity)

    every { ActivityCompat.checkSelfPermission(activity, WRITE_CALENDAR) } returns PackageManager.PERMISSION_GRANTED

    var permissionGranted = false
    permissionHandler.requestWritePermission { granted ->
      permissionGranted = granted
    }

    assertTrue(permissionGranted)
  }

  @Test
  fun requestWritePermission_requestsPermission() {
    val activity: Activity = mockk<Activity>(relaxed = true)
    val permissionHandler = PermissionHandler(activity)

    every { ActivityCompat.checkSelfPermission(activity, WRITE_CALENDAR) } returns PackageManager.PERMISSION_DENIED
    every { ActivityCompat.requestPermissions(activity, arrayOf(WRITE_CALENDAR), writeRequestCode) } returns Unit

    permissionHandler.requestWritePermission { }

    verify { ActivityCompat.requestPermissions(activity, arrayOf(WRITE_CALENDAR), writeRequestCode) }
  }

  @Test
  fun onRequestPermissionsResult_writePermissionGranted() {
    val activity: Activity = mockk<Activity>(relaxed = true)
    val permissionHandler = PermissionHandler(activity)

    var permissionGranted = false
    permissionHandler.requestWritePermission { granted ->
      permissionGranted = granted
    }

    val handled = permissionHandler.onRequestPermissionsResult(writeRequestCode, arrayOf(WRITE_CALENDAR), intArrayOf(PackageManager.PERMISSION_GRANTED))

    assertTrue(handled)
    assertTrue(permissionGranted)
  }

  @Test
  fun onRequestPermissionsResult_writePermissionDenied() {
    val activity: Activity = mockk<Activity>(relaxed = true)
    val permissionHandler = PermissionHandler(activity)

    every { ActivityCompat.checkSelfPermission(activity, WRITE_CALENDAR) } returns PackageManager.PERMISSION_DENIED

    var permissionGranted = false
    permissionHandler.requestWritePermission { granted ->
      permissionGranted = granted
    }

    val handled = permissionHandler.onRequestPermissionsResult(writeRequestCode, arrayOf(WRITE_CALENDAR), intArrayOf(PackageManager.PERMISSION_DENIED))

    assertTrue(handled)
    assertFalse(permissionGranted)
  }

  @Test
  fun onRequestPermissionsResult_unknownCodeReturnsFalse() {
    val activity: Activity = mockk<Activity>(relaxed = true)
    val permissionHandler = PermissionHandler(activity)

    every { ActivityCompat.checkSelfPermission(activity, WRITE_CALENDAR) } returns PackageManager.PERMISSION_DENIED

    var permissionGranted = false
    permissionHandler.requestWritePermission { granted ->
      permissionGranted = granted
    }

    val handled = permissionHandler.onRequestPermissionsResult(10, arrayOf(WRITE_CALENDAR), intArrayOf(PackageManager.PERMISSION_DENIED))

    assertFalse(handled)
    assertFalse(permissionGranted)
  }

  @Test
  fun onRequestPermissionsResult_emptyReadGrantResultsReturnsFalse() {
    val activity: Activity = mockk<Activity>(relaxed = true)
    val permissionHandler = PermissionHandler(activity)

    every { ActivityCompat.checkSelfPermission(activity, READ_CALENDAR) } returns PackageManager.PERMISSION_DENIED

    var permissionGranted = false
    permissionHandler.requestReadPermission { granted ->
      permissionGranted = granted
    }

    val handled = permissionHandler.onRequestPermissionsResult(readRequestCode, arrayOf(READ_CALENDAR), intArrayOf())

    assertTrue(handled)
    assertFalse(permissionGranted)
  }

  @Test
  fun onRequestPermissionsResult_emptyWriteGrantResultsReturnsFalse() {
    val activity: Activity = mockk<Activity>(relaxed = true)
    val permissionHandler = PermissionHandler(activity)

    every { ActivityCompat.checkSelfPermission(activity, WRITE_CALENDAR) } returns PackageManager.PERMISSION_DENIED

    var permissionGranted = false
    permissionHandler.requestWritePermission { granted ->
      permissionGranted = granted
    }

    val handled = permissionHandler.onRequestPermissionsResult(writeRequestCode, arrayOf(WRITE_CALENDAR), intArrayOf())

    assertTrue(handled)
    assertFalse(permissionGranted)
  }
}
