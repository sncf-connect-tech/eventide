package sncf.connect.tech.flutter_calendar_connect

import Calendar
import CalendarActions
import Event
import android.Manifest.permission.READ_CALENDAR
import android.Manifest.permission.WRITE_CALENDAR
import android.app.Activity
import android.content.ContentValues
import android.content.pm.PackageManager.PERMISSION_GRANTED
import android.graphics.Color
import android.net.Uri
import android.provider.CalendarContract
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.PluginRegistry.RequestPermissionsResultListener
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch


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
        if (!arePermissionsGranted) {
            callback(Result.failure(Exception("Calendar permissions not granted")))
            return
        }

        CoroutineScope(Dispatchers.IO).launch {
            try {
            val values = ContentValues().apply {
                put(CalendarContract.Calendars.ACCOUNT_NAME, "account_name")
                put(CalendarContract.Calendars.ACCOUNT_TYPE, CalendarContract.ACCOUNT_TYPE_LOCAL)
                put(CalendarContract.Calendars.NAME, title)
                put(CalendarContract.Calendars.CALENDAR_DISPLAY_NAME, title)
                put(CalendarContract.Calendars.CALENDAR_COLOR, Color.parseColor(hexColor))
                put(CalendarContract.Calendars.CALENDAR_ACCESS_LEVEL, CalendarContract.Calendars.CAL_ACCESS_OWNER)
                put(CalendarContract.Calendars.OWNER_ACCOUNT, "owner_account")
                put(CalendarContract.Calendars.VISIBLE, 1)
                put(CalendarContract.Calendars.SYNC_EVENTS, 1)
            }

            val uri = CalendarContract.Calendars.CONTENT_URI
                .buildUpon()
                .appendQueryParameter(CalendarContract.CALLER_IS_SYNCADAPTER, "true")
                .appendQueryParameter(CalendarContract.Calendars.ACCOUNT_NAME, "account_name")
                .appendQueryParameter(CalendarContract.Calendars.ACCOUNT_TYPE, CalendarContract.ACCOUNT_TYPE_LOCAL)
                .build()

            val calendarUri = pluginActivity.contentResolver.insert(uri, values)
            if (calendarUri != null) {
                val calendarId = calendarUri.lastPathSegment?.toLong()
                if (calendarId != null) {
                    val calendar = Calendar(calendarId.toString(), title, hexColor)
                    callback(Result.success(calendar))
                } else {
                    callback(Result.failure(Exception("Failed to retrieve calendar ID")))
                }
            } else {
                callback(Result.failure(Exception("Failed to create calendar")))
            }
            } catch (e: Exception) {
                callback(Result.failure(e))
            }
        }
    }

    override fun retrieveCalendars(onlyWritableCalendars: Boolean, callback: (Result<List<Calendar>>) -> Unit) {
        if (!arePermissionsGranted) {
            callback(Result.failure(Exception("Calendar permissions not granted")))
            return
        }
        
        CoroutineScope(Dispatchers.IO).launch {
            try {
                val uri: Uri = CalendarContract.Calendars.CONTENT_URI
                val projection = arrayOf(
                    CalendarContract.Calendars._ID,
                    CalendarContract.Calendars.CALENDAR_DISPLAY_NAME,
                    CalendarContract.Calendars.CALENDAR_COLOR,
                )
                val selection = if (onlyWritableCalendars) ("(" + CalendarContract.Calendars.CALENDAR_ACCESS_LEVEL + " >=  ?)") else null
                val selectionArgs = if (onlyWritableCalendars) arrayOf(CalendarContract.Calendars.CAL_ACCESS_CONTRIBUTOR.toString()) else null

                val cursor = pluginActivity.contentResolver.query(uri, projection, selection, selectionArgs, null)
                val calendars = mutableListOf<Calendar>()

                cursor?.use {
                    while (it.moveToNext()) {
                        val id = it.getLong(it.getColumnIndexOrThrow(CalendarContract.Calendars._ID)).toString()
                        val displayName = it.getString(it.getColumnIndexOrThrow(CalendarContract.Calendars.CALENDAR_DISPLAY_NAME))
                        val color = it.getString(it.getColumnIndexOrThrow(CalendarContract.Calendars.CALENDAR_COLOR))

                        calendars.add(Calendar(id, displayName, color))
                    }
                }

                callback(Result.success(calendars))
            } catch (e: Exception) {
                callback(Result.failure(e))
            }
        }
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
