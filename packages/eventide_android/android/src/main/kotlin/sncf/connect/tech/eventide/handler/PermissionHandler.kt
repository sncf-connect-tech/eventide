package sncf.connect.tech.eventide.handler

import android.Manifest.permission.READ_CALENDAR
import android.Manifest.permission.WRITE_CALENDAR
import android.app.Activity
import android.content.pm.PackageManager.PERMISSION_GRANTED
import androidx.core.app.ActivityCompat
import io.flutter.plugin.common.PluginRegistry.RequestPermissionsResultListener

class PermissionHandler(): RequestPermissionsResultListener {
    var activity: Activity? = null
    private val callbacks = mutableListOf<(Boolean) -> Unit>()

    companion object {
        @JvmStatic val requestCode = 1001
    }

    fun requestReadAndWritePermissions(callback: (Boolean) -> Unit) {
        withActivity { activity ->
            val hasRead = ActivityCompat.checkSelfPermission(activity, READ_CALENDAR) == PERMISSION_GRANTED
            val hasWrite = ActivityCompat.checkSelfPermission(activity, WRITE_CALENDAR) == PERMISSION_GRANTED

            if (hasRead && hasWrite) {
                callback(true)
            } else {
                callbacks.add(callback)
                val perms = when {
                    !hasRead && !hasWrite -> arrayOf(READ_CALENDAR, WRITE_CALENDAR)
                    !hasRead -> arrayOf(READ_CALENDAR)
                    else -> arrayOf(WRITE_CALENDAR)
                }
                ActivityCompat.requestPermissions(activity, perms, requestCode)
            }
        }
    }

    fun requestReadPermission(callback: (Boolean) -> Unit) {
        withActivity { activity ->
            val hasReadPermission = ActivityCompat.checkSelfPermission(activity, READ_CALENDAR) == PERMISSION_GRANTED
            if (hasReadPermission) {
                callback(true)
            } else {
                callbacks.add(callback)
                ActivityCompat.requestPermissions(activity, arrayOf(READ_CALENDAR), requestCode)
            }
        }
    }

    fun requestWritePermission(callback: (Boolean) -> Unit) {
        withActivity { activity ->
            val hasWritePermission = ActivityCompat.checkSelfPermission(activity, WRITE_CALENDAR) == PERMISSION_GRANTED
            if (hasWritePermission) {
                callback(true)
            } else {
                callbacks.add(callback)
                ActivityCompat.requestPermissions(activity, arrayOf(WRITE_CALENDAR), requestCode)
            }
        }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray): Boolean {
        if (requestCode == PermissionHandler.requestCode) {
            val allGranted = grantResults.isNotEmpty() && grantResults.all { it == PERMISSION_GRANTED }
            val pending = callbacks.toList()
            callbacks.clear()
            pending.forEach { it(allGranted) }
            return true
        }
        return false
    }

    private fun withActivity(block: (Activity) -> Unit) {
        activity?.let { block(it) }
            ?: throw IllegalStateException("ActivityPluginBinding is not correctly set.")
    }
}
