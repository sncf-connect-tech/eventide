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
    private var calendarContentUri: Uri = CalendarContract.Calendars.CONTENT_URI,
    private var eventContentUri: Uri = CalendarContract.Events.CONTENT_URI,
    ): CalendarApi {
    override fun requestCalendarPermission(callback: (Result<Boolean>) -> Unit) {
        permissionHandler.requestWritePermission { granted ->
            callback(Result.success(granted))
        }
    }

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

                        val uri = calendarContentUri
                            .buildUpon()
                            .appendQueryParameter(CalendarContract.CALLER_IS_SYNCADAPTER, "true")
                            .appendQueryParameter(CalendarContract.Calendars.ACCOUNT_NAME, "account_name")
                            .appendQueryParameter(CalendarContract.Calendars.ACCOUNT_TYPE, CalendarContract.ACCOUNT_TYPE_LOCAL)
                            .build()

                        val calendarUri = contentResolver.insert(uri, values)
                        if (calendarUri != null) {
                            val calendarId = calendarUri.lastPathSegment?.toLong()
                            if (calendarId != null) {
                                val calendar = Calendar(calendarId.toString(), title, color, isWritable = true)
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
                        val projection = arrayOf(
                            CalendarContract.Calendars._ID,
                            CalendarContract.Calendars.CALENDAR_DISPLAY_NAME,
                            CalendarContract.Calendars.CALENDAR_COLOR,
                            CalendarContract.Calendars.CALENDAR_ACCESS_LEVEL
                        )
                        val selection = if (onlyWritableCalendars) ("(" + CalendarContract.Calendars.CALENDAR_ACCESS_LEVEL + " >=  ?)") else null
                        val selectionArgs = if (onlyWritableCalendars) arrayOf(CalendarContract.Calendars.CAL_ACCESS_CONTRIBUTOR.toString()) else null

                        val cursor = contentResolver.query(calendarContentUri, projection, selection, selectionArgs, null)
                        val calendars = mutableListOf<Calendar>()

                        cursor?.use {
                            while (it.moveToNext()) {
                                val id = it.getLong(it.getColumnIndexOrThrow(CalendarContract.Calendars._ID)).toString()
                                val displayName = it.getString(it.getColumnIndexOrThrow(CalendarContract.Calendars.CALENDAR_DISPLAY_NAME))
                                val color = it.getLong(it.getColumnIndexOrThrow(CalendarContract.Calendars.CALENDAR_COLOR))
                                val accessLevel = it.getInt(it.getColumnIndexOrThrow(CalendarContract.Calendars.CALENDAR_ACCESS_LEVEL))

                                val calendar = Calendar(
                                    id,
                                    displayName,
                                    color,
                                    isWritable = accessLevel >= CalendarContract.Calendars.CAL_ACCESS_CONTRIBUTOR
                                )

                                calendars.add(calendar)
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

    override fun deleteCalendar(calendarId: String, callback: (Result<Unit>) -> Unit) {
        permissionHandler.requestWritePermission { granted ->
            if (granted) {
                CoroutineScope(Dispatchers.IO).launch {
                    try {
                        val selection = CalendarContract.Calendars._ID + " = ?"
                        val selectionArgs = arrayOf(calendarId)

                        val deleted = contentResolver.delete(calendarContentUri, selection, selectionArgs)
                        if (deleted > 0) {
                            callback(Result.success(Unit))
                        } else {
                            callback(Result.failure(Exception("Failed to delete calendar")))
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

    override fun createEvent(
        title: String,
        startDate: Long,
        endDate: Long,
        calendarId: String,
        timeZone: String,
        description: String?,
        url: String?,
        callback: (Result<Event>) -> Unit
    ) {
        permissionHandler.requestWritePermission { granted ->
            if (granted) {
                CoroutineScope(Dispatchers.IO).launch {
                    try {
                        val eventValues = ContentValues().apply {
                            put(CalendarContract.Events.CALENDAR_ID, calendarId)
                            put(CalendarContract.Events.TITLE, title)
                            put(CalendarContract.Events.DESCRIPTION, description)
                            put(CalendarContract.Events.DTSTART, startDate)
                            put(CalendarContract.Events.DTEND, endDate)
                            put(CalendarContract.Events.EVENT_TIMEZONE, timeZone)

                            // TODO: location
                            // TODO: alarms
                            // TODO: url
                        }

                        val eventUri = contentResolver.insert(eventContentUri, eventValues)
                        if (eventUri != null) {
                            val eventId = eventUri.lastPathSegment?.toLong()
                            if (eventId != null) {
                                val event = Event(
                                    id = eventId.toString(),
                                    title = title,
                                    startDate = startDate,
                                    endDate = endDate,
                                    timeZone = timeZone,
                                    calendarId = calendarId,
                                    description = description
                                )
                                callback(Result.success(event))
                            } else {
                                callback(Result.failure(Exception("Failed to retrieve event ID")))
                            }
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

    override fun retrieveEvents(
        calendarId: String,
        startDate: Long,
        endDate: Long,
        callback: (Result<List<Event>>) -> Unit
    ) {
        permissionHandler.requestReadPermission { granted ->
            if (granted) {
                CoroutineScope(Dispatchers.IO).launch {
                    try {
                        val projection = arrayOf(
                            CalendarContract.Events._ID,
                            CalendarContract.Events.TITLE,
                            CalendarContract.Events.DESCRIPTION,
                            CalendarContract.Events.DTSTART,
                            CalendarContract.Events.DTEND,
                            CalendarContract.Events.EVENT_TIMEZONE,
                        )
                        val selection = CalendarContract.Events.CALENDAR_ID + " = ? AND " + CalendarContract.Events.DTSTART + " >= ? AND " + CalendarContract.Events.DTEND + " <= ?"
                        val selectionArgs = arrayOf(calendarId, startDate.toString(), endDate.toString())

                        val cursor = contentResolver.query(eventContentUri, projection, selection, selectionArgs, null)
                        val events = mutableListOf<Event>()

                        cursor?.use {
                            while (it.moveToNext()) {
                                val id = it.getLong(it.getColumnIndexOrThrow(CalendarContract.Events._ID)).toString()
                                val title = it.getString(it.getColumnIndexOrThrow(CalendarContract.Events.TITLE))
                                val description = it.getString(it.getColumnIndexOrThrow(CalendarContract.Events.DESCRIPTION))
                                val start = it.getLong(it.getColumnIndexOrThrow(CalendarContract.Events.DTSTART))
                                val end = it.getLong(it.getColumnIndexOrThrow(CalendarContract.Events.DTEND))
                                val timeZone = it.getString(it.getColumnIndexOrThrow(CalendarContract.Events.EVENT_TIMEZONE))

                                events.add(Event(
                                    id = id,
                                    title = title,
                                    startDate = start,
                                    endDate = end,
                                    timeZone = timeZone,
                                    calendarId = calendarId,
                                    description = description,
                                ))
                            }
                        }

                        callback(Result.success(events))

                    } catch (e: Exception) {
                        callback(Result.failure(e))
                    }
                }

            } else {
                callback(Result.failure(Exception("Calendar permissions not granted")))
            }
        }
    }

    override fun deleteEvent(eventId: String, calendarId: String, callback: (Result<Unit>) -> Unit) {
        permissionHandler.requestWritePermission { granted ->
            if (granted) {
                CoroutineScope(Dispatchers.IO).launch {
                    try {
                        val selection = CalendarContract.Events._ID + " = ? AND " + CalendarContract.Events.CALENDAR_ID + " = ?"
                        val selectionArgs = arrayOf(eventId, calendarId)

                        val deleted = contentResolver.delete(eventContentUri, selection, selectionArgs)
                        if (deleted > 0) {
                            callback(Result.success(Unit))
                        } else {
                            callback(Result.failure(Exception("Failed to delete event")))
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
