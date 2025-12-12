package sncf.connect.tech.eventide

import android.Manifest.permission.READ_CALENDAR
import android.Manifest.permission.WRITE_CALENDAR
import android.app.Activity
import android.content.pm.PackageManager.PERMISSION_GRANTED
import androidx.core.app.ActivityCompat
import io.flutter.plugin.common.PluginRegistry.RequestPermissionsResultListener

class PermissionHandler(private val activity: Activity): RequestPermissionsResultListener {
    private var permissionCallback: (Boolean) -> Unit = {}

    companion object {
        @JvmStatic val requestCode = 1001
    }

    fun requestReadAndWritePermissions(callback: (Boolean) -> Unit) {
        val hasRead = ActivityCompat.checkSelfPermission(activity, READ_CALENDAR) == PERMISSION_GRANTED
        val hasWrite = ActivityCompat.checkSelfPermission(activity, WRITE_CALENDAR) == PERMISSION_GRANTED

        if (hasRead && hasWrite) {
            callback(true)
        } else if (!hasRead && !hasWrite) {
            // Les deux permissions manquent - demander les deux
            permissionCallback = callback
            ActivityCompat.requestPermissions(activity, arrayOf(READ_CALENDAR, WRITE_CALENDAR), requestCode)
        } else if (!hasRead) {
            // Seule la permission de lecture manque
            permissionCallback = callback
            ActivityCompat.requestPermissions(activity, arrayOf(READ_CALENDAR), requestCode)
        } else {
            // Seule la permission d'écriture manque
            permissionCallback = callback
            ActivityCompat.requestPermissions(activity, arrayOf(WRITE_CALENDAR), requestCode)
        }
    }

    fun requestReadPermission(callback: (Boolean) -> Unit) {
        val hasReadPermission = ActivityCompat.checkSelfPermission(activity, READ_CALENDAR) == PERMISSION_GRANTED
        if (hasReadPermission) {
            callback(true)
        } else {
            permissionCallback = callback
            ActivityCompat.requestPermissions(activity, arrayOf(READ_CALENDAR), requestCode)
        }
    }

    fun requestWritePermission(callback: (Boolean) -> Unit) {
        val hasWritePermission = ActivityCompat.checkSelfPermission(activity, WRITE_CALENDAR) == PERMISSION_GRANTED
        if (hasWritePermission) {
            callback(true)
        } else {
            permissionCallback = callback
            ActivityCompat.requestPermissions(activity, arrayOf(WRITE_CALENDAR), requestCode)
        }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray): Boolean {
        if (requestCode == PermissionHandler.requestCode) {
            val allGranted = grantResults.isNotEmpty() && grantResults.all { it == PERMISSION_GRANTED }
            permissionCallback(allGranted)
            return true
        }
        return false
    }
}
