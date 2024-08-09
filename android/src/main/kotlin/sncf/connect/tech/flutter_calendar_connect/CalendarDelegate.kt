package com.evoyageurs.invictus.plugins.calendar


import Calendar
import CalendarActions
import Event
import android.Manifest.permission.READ_CALENDAR
import android.Manifest.permission.WRITE_CALENDAR
import android.content.Context
import android.content.pm.PackageManager.PERMISSION_GRANTED
import android.net.Uri
import android.provider.CalendarContract
import androidx.core.app.ActivityCompat
import androidx.core.app.ActivityCompat.OnRequestPermissionsResultCallback
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding

class CalendarDelegate(
    private val binding: ActivityPluginBinding,
    private val context: Context,
): CalendarActions, OnRequestPermissionsResultCallback {
    private val CALENDAR_REQUEST_CODE = 956
    private var arePermissionsGranted = false

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

        val cursor = context.contentResolver.query(
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
        checkPermissionsGranted()

        if (arePermissionsGranted) {
            callback(Result.success(true))
            return
        }

        ActivityCompat.requestPermissions(
            binding.activity,
            arrayOf(READ_CALENDAR, WRITE_CALENDAR),
            CALENDAR_REQUEST_CODE,
        )
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        arePermissionsGranted = requestCode == CALENDAR_REQUEST_CODE
                && grantResults.isNotEmpty()
                && grantResults.fold(true) { acc, i -> acc && i == PERMISSION_GRANTED }
    }

    private fun checkPermissionsGranted() {
        val hasReadPermission = ContextCompat.checkSelfPermission(binding.activity.applicationContext, READ_CALENDAR)
        val hasWritePermission = ContextCompat.checkSelfPermission(binding.activity.applicationContext, WRITE_CALENDAR)
        arePermissionsGranted = hasReadPermission == PERMISSION_GRANTED && hasWritePermission == PERMISSION_GRANTED
    }
}