package sncf.connect.tech.flutter_calendar_connect

import android.content.ContentResolver
import android.content.ContentValues
import android.net.Uri
import android.provider.CalendarContract
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class CalendarImplem(
    private var contentResolver: ContentResolver,
    private var permissionHandler: PermissionHandler,
    private var contentUri: Uri = CalendarContract.Calendars.CONTENT_URI
): CalendarApi {

    override fun createCalendar(
        title: String,
        color: Long,
        callback: (Result<Calendar>) -> Unit
    ) {
        permissionHandler.requestWritePermission { granted ->
            if (granted) {
                CoroutineScope(Dispatchers.IO).launch {
                    try {
                        val values = ContentValues().apply {
                            put(CalendarContract.Calendars.ACCOUNT_NAME, "account_name")
                            put(CalendarContract.Calendars.ACCOUNT_TYPE, CalendarContract.ACCOUNT_TYPE_LOCAL)
                            put(CalendarContract.Calendars.NAME, title)
                            put(CalendarContract.Calendars.CALENDAR_DISPLAY_NAME, title)
                            put(CalendarContract.Calendars.CALENDAR_COLOR, color)
                            put(CalendarContract.Calendars.CALENDAR_ACCESS_LEVEL, CalendarContract.Calendars.CAL_ACCESS_OWNER)
                            put(CalendarContract.Calendars.OWNER_ACCOUNT, "owner_account")
                            put(CalendarContract.Calendars.VISIBLE, 1)
                            put(CalendarContract.Calendars.SYNC_EVENTS, 1)
                        }

                        val uri = contentUri
                            .buildUpon()
                            .appendQueryParameter(CalendarContract.CALLER_IS_SYNCADAPTER, "true")
                            .appendQueryParameter(CalendarContract.Calendars.ACCOUNT_NAME, "account_name")
                            .appendQueryParameter(CalendarContract.Calendars.ACCOUNT_TYPE, CalendarContract.ACCOUNT_TYPE_LOCAL)
                            .build()

                        val calendarUri = contentResolver.insert(uri, values)
                        if (calendarUri != null) {
                            val calendarId = calendarUri.lastPathSegment?.toLong()
                            if (calendarId != null) {
                                val calendar = Calendar(calendarId.toString(), title, color)
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
            } else {
                callback(Result.failure(Exception("Calendar permissions not granted")))
            }
        }
    }

    override fun retrieveCalendars(onlyWritableCalendars: Boolean, callback: (Result<List<Calendar>>) -> Unit) {
        permissionHandler.requestReadPermission { granted ->
            if (granted) {
                CoroutineScope(Dispatchers.IO).launch {
                    try {
                        val uri: Uri = contentUri
                        val projection = arrayOf(
                            CalendarContract.Calendars._ID,
                            CalendarContract.Calendars.CALENDAR_DISPLAY_NAME,
                            CalendarContract.Calendars.CALENDAR_COLOR,
                        )
                        val selection = if (onlyWritableCalendars) ("(" + CalendarContract.Calendars.CALENDAR_ACCESS_LEVEL + " >=  ?)") else null
                        val selectionArgs = if (onlyWritableCalendars) arrayOf(CalendarContract.Calendars.CAL_ACCESS_CONTRIBUTOR.toString()) else null

                        val cursor = contentResolver.query(uri, projection, selection, selectionArgs, null)
                        val calendars = mutableListOf<Calendar>()

                        cursor?.use {
                            while (it.moveToNext()) {
                                val id = it.getLong(it.getColumnIndexOrThrow(CalendarContract.Calendars._ID)).toString()
                                val displayName = it.getString(it.getColumnIndexOrThrow(CalendarContract.Calendars.CALENDAR_DISPLAY_NAME))
                                val color = it.getLong(it.getColumnIndexOrThrow(CalendarContract.Calendars.CALENDAR_COLOR))

                                calendars.add(Calendar(id, displayName, color))
                            }
                        }

                        callback(Result.success(calendars))
                    } catch (e: Exception) {
                        callback(Result.failure(e))
                    }
                }

            } else {
                callback(Result.failure(Exception("Calendar permissions not granted")))
            }
        }
    }

    override fun createOrUpdateEvent(
        event: Event,
        callback: (Result<Boolean>) -> Unit
    ) {
        permissionHandler.requestWritePermission { granted ->
            if (granted) {
                CoroutineScope(Dispatchers.IO).launch {
                    try {
                        val eventValues = ContentValues().apply {
                            put(CalendarContract.Events.CALENDAR_ID, event.calendarId)
                            put(CalendarContract.Events.TITLE, event.title)
                            put(CalendarContract.Events.DESCRIPTION, event.description)
                            put(CalendarContract.Events.DTSTART, event.startDate)
                            put(CalendarContract.Events.DTEND, event.endDate)
                            put(CalendarContract.Events.EVENT_TIMEZONE, event.timeZone)

                            // TODO: location
                            // TODO: alarms
                            // TODO: url
                        }

                        val eventUri = contentResolver.insert(CalendarContract.Events.CONTENT_URI, eventValues)
                        if (eventUri != null) {
                            callback(Result.success(true))
                        } else {
                            callback(Result.failure(Exception("Failed to create event")))
                        }
                    } catch (e: Exception) {
                        callback(Result.failure(e))
                    }
                }
            } else {
                callback(Result.failure(Exception("Calendar permissions not granted")))
            }
        }
    }
}
