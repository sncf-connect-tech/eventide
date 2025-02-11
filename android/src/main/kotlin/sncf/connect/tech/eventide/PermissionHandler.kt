package sncf.connect.tech.eventide

import android.Manifest.permission.READ_CALENDAR
import android.Manifest.permission.WRITE_CALENDAR
import android.app.Activity
import android.content.pm.PackageManager.PERMISSION_GRANTED
import androidx.core.app.ActivityCompat
import io.flutter.plugin.common.PluginRegistry.RequestPermissionsResultListener

open class PermissionHandler(private val activity: Activity): RequestPermissionsResultListener {
    protected var readPermissionCallback: (Boolean) -> Unit = {}
    protected var writePermissionCallback: (Boolean) -> Unit = {}

    companion object {
        @JvmStatic val readRequestCode = 1001
        @JvmStatic val writeRequestCode = 1002
    }

    fun requestReadPermission(callback: (Boolean) -> Unit) {
        val hasReadPermission = ActivityCompat.checkSelfPermission(activity, READ_CALENDAR) == PERMISSION_GRANTED
        if (hasReadPermission) {
            callback(true)
        } else {
            readPermissionCallback = callback
            ActivityCompat.requestPermissions(activity, arrayOf(READ_CALENDAR), readRequestCode)
        }
    }

    fun requestWritePermission(callback: (Boolean) -> Unit) {
        val hasWritePermission = ActivityCompat.checkSelfPermission(activity, WRITE_CALENDAR) == PERMISSION_GRANTED
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
