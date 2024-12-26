package sncf.connect.tech.flutter_calendar_connect

import android.Manifest.permission.READ_CALENDAR
import android.Manifest.permission.WRITE_CALENDAR
import android.app.Activity
import android.content.pm.PackageManager.PERMISSION_GRANTED
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.PluginRegistry.RequestPermissionsResultListener

class PermissionHandler(private val activity: Activity): RequestPermissionsResultListener {
    private val readRequestCode = 1001
    private val writeRequestCode = 1002
    private var readPermissionCallback: (Boolean) -> Unit = {}
    private var writePermissionCallback: (Boolean) -> Unit = {}

    fun requestReadPermission(callback: (Boolean) -> Unit) {
        val hasReadPermission = ContextCompat.checkSelfPermission(activity, READ_CALENDAR) == PERMISSION_GRANTED
        if (hasReadPermission) {
            callback(true)
        } else {
            readPermissionCallback = callback
            ActivityCompat.requestPermissions(activity, arrayOf(READ_CALENDAR), readRequestCode)
        }
    }

    fun requestWritePermission(callback: (Boolean) -> Unit) {
        val hasWritePermission = ContextCompat.checkSelfPermission(activity, WRITE_CALENDAR) == PERMISSION_GRANTED
        if (hasWritePermission) {
            callback(true)
        } else {
            writePermissionCallback = callback
            ActivityCompat.requestPermissions(activity, arrayOf(WRITE_CALENDAR), writeRequestCode)
        }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray): Boolean {
        when (requestCode) {
            readRequestCode -> {
                val granted = grantResults.isNotEmpty() && grantResults[0] == PERMISSION_GRANTED
                readPermissionCallback(granted)
                return true
            }
            writeRequestCode -> {
                val granted = grantResults.isNotEmpty() && grantResults[0] == PERMISSION_GRANTED
                writePermissionCallback(granted)
                return true
            }
        }
        return false
    }
}
