package sncf.connect.tech.flutter_calendar_connect

import Calendar
import CalendarActions
import Event
import android.Manifest.permission.READ_CALENDAR
import android.Manifest.permission.WRITE_CALENDAR
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager.PERMISSION_GRANTED
import android.net.Uri
import android.provider.CalendarContract
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.PluginRegistry.RequestPermissionsResultListener
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex

class CalendarApi(
    private val pluginActivity: Activity,
): CalendarActions, RequestPermissionsResultListener {
    private val calendarRequestCode = 956
    private var arePermissionsGranted = false
    private var permissionResponseHandleCallback: (Result<Boolean>) -> Unit = {}

    override fun createCalendar(
        title: String,
        hexColor: String,
        callback: (Result<Calendar>) -> Unit
    ) {
        TODO("Not yet implemented")
    }

    override fun retrieveCalendars(callback: (Result<List<Calendar>>) -> Unit) {
        if (!arePermissionsGranted) {
            callback(Result.failure(Exception("Calendar permissions not granted")))
            return
        }

        val cursor = pluginActivity.contentResolver.query(
            Uri.parse("content://com.android.calendar/calendars"),
            Array(3) {
                CalendarContract.Calendars._ID
                CalendarContract.Calendars.NAME
                CalendarContract.Calendars.CALENDAR_COLOR
            },
            null,
            null,
            null,
        )

        if (cursor == null) {
            callback(Result.failure(Exception("No calendars found")))
            return
        }

        val calendars = mutableListOf<Calendar>()
        cursor.moveToFirst()

        do {
            val id = cursor.getLong(0)
            val name = cursor.getString(1)
            val color = cursor.getInt(2)
            calendars.add(Calendar(id.toString(), name, color.toString()))

        } while (cursor.moveToNext())

        cursor.close()
    }

    override fun createOrUpdateEvent(
        flutterEvent: Event,
        callback: (Result<Boolean>) -> Unit
    ) {
        TODO("Not yet implemented")
    }

    override fun requestCalendarAccess(callback: (Result<Boolean>) -> Unit) {
        checkPermissions()

        if (arePermissionsGranted) {
            callback(Result.success(true))

        } else {
            ActivityCompat.requestPermissions(
                pluginActivity,
                arrayOf(READ_CALENDAR, WRITE_CALENDAR),
                calendarRequestCode,
            )

            permissionResponseHandleCallback = callback
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ): Boolean {
        var handled = false

        when (requestCode) {
            calendarRequestCode -> {
                arePermissionsGranted = grantResults.isNotEmpty()
                        && grantResults.fold(true) { acc, i -> acc && i == PERMISSION_GRANTED }

                permissionResponseHandleCallback(Result.success(arePermissionsGranted))

                handled = true
            }
        }

        return handled
    }

    private fun checkPermissions() {
        val hasReadPermission = ContextCompat.checkSelfPermission(pluginActivity.applicationContext, READ_CALENDAR)
        val hasWritePermission = ContextCompat.checkSelfPermission(pluginActivity.applicationContext, WRITE_CALENDAR)

        arePermissionsGranted = hasReadPermission == PERMISSION_GRANTED
                && hasWritePermission == PERMISSION_GRANTED
    }
}