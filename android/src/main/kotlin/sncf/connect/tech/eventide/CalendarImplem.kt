package sncf.connect.tech.eventide

import android.content.ContentResolver
import android.content.ContentValues
import android.net.Uri
import android.provider.CalendarContract
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.util.concurrent.CountDownLatch

class CalendarImplem(
    private var contentResolver: ContentResolver,
    private var permissionHandler: PermissionHandler,
    private var calendarContentUri: Uri = CalendarContract.Calendars.CONTENT_URI,
    private var eventContentUri: Uri = CalendarContract.Events.CONTENT_URI,
    private var remindersContentUri: Uri = CalendarContract.Reminders.CONTENT_URI
): CalendarApi {
    override fun requestCalendarPermission(callback: (Result<Boolean>) -> Unit) {
        permissionHandler.requestWritePermission { granted ->
            callback(Result.success(granted))
        }
    }

    override fun createCalendar(
        title: String,
        color: Long,
        account: Account?,
        callback: (Result<Calendar>) -> Unit
    ) {
        permissionHandler.requestWritePermission { granted ->
            if (granted) {
                CoroutineScope(Dispatchers.IO).launch {
                    try {
                        val resolvedAccount = account ?: Account("eventide", CalendarContract.ACCOUNT_TYPE_LOCAL)
                        val values = ContentValues().apply {
                            put(CalendarContract.Calendars.ACCOUNT_NAME, resolvedAccount.name)
                            put(CalendarContract.Calendars.ACCOUNT_TYPE, resolvedAccount.type)
                            put(CalendarContract.Calendars.NAME, title)
                            put(CalendarContract.Calendars.CALENDAR_DISPLAY_NAME, title)
                            put(CalendarContract.Calendars.CALENDAR_COLOR, color)
                            put(CalendarContract.Calendars.CALENDAR_ACCESS_LEVEL, CalendarContract.Calendars.CAL_ACCESS_OWNER)
                            put(CalendarContract.Calendars.OWNER_ACCOUNT, resolvedAccount.name)
                            put(CalendarContract.Calendars.VISIBLE, 1)
                            put(CalendarContract.Calendars.SYNC_EVENTS, 1)
                        }

                        val uri = calendarContentUri
                            .buildUpon()
                            .appendQueryParameter(CalendarContract.CALLER_IS_SYNCADAPTER, "true")
                            .appendQueryParameter(CalendarContract.Calendars.ACCOUNT_NAME, resolvedAccount.name)
                            .appendQueryParameter(CalendarContract.Calendars.ACCOUNT_TYPE, resolvedAccount.type)
                            .build()

                        val calendarUri = contentResolver.insert(uri, values)
                        if (calendarUri != null) {
                            val calendarId = calendarUri.lastPathSegment?.toLong()
                            if (calendarId != null) {
                                val calendar = Calendar(
                                    id = calendarId.toString(),
                                    title = title,
                                    color = color,
                                    isWritable = true,
                                    account = resolvedAccount
                                )
                                callback(Result.success(calendar))
                            } else {
                                callback(Result.failure(
                                    FlutterError(
                                        code = "NOT_FOUND",
                                        message = "Failed to retrieve calendar ID"
                                    )
                                ))
                            }
                        } else {
                            callback(Result.failure(
                                FlutterError(
                                    code = "GENERIC_ERROR",
                                    message = "Failed to create calendar"
                                )
                            ))
                        }
                    } catch (e: Exception) { 
                        callback(Result.failure(
                            FlutterError(
                                code = "GENERIC_ERROR",
                                message = "An error occurred",
                                details = e.message
                            )
                        ))
                    }
                }
            } else {
                callback(Result.failure(
                    FlutterError(
                        code = "ACCESS_REFUSED",
                        message = "Calendar access has been refused or has not been given yet",
                    ))
                )
            }
        }
    }

    override fun retrieveCalendars(
        onlyWritableCalendars: Boolean,
        from: Account?,
        callback: (Result<List<Calendar>>) -> Unit
    ) {
        permissionHandler.requestReadPermission { granted ->
            if (granted) {
                CoroutineScope(Dispatchers.IO).launch {
                    try {
                        val projection = arrayOf(
                            CalendarContract.Calendars._ID,
                            CalendarContract.Calendars.CALENDAR_DISPLAY_NAME,
                            CalendarContract.Calendars.CALENDAR_COLOR,
                            CalendarContract.Calendars.CALENDAR_ACCESS_LEVEL,
                            CalendarContract.Calendars.ACCOUNT_NAME,
                            CalendarContract.Calendars.ACCOUNT_TYPE
                        )

                        val (selection, selectionArgs) = Pair(onlyWritableCalendars, from).let { (onlyWritable, account) ->
                            if (onlyWritable && account != null) {
                                val selection = CalendarContract.Calendars.CALENDAR_ACCESS_LEVEL + " >= ? AND " + CalendarContract.Calendars.ACCOUNT_NAME + " = ? AND " + CalendarContract.Calendars.ACCOUNT_TYPE + " = ?"
                                val selectionArgs = arrayOf(CalendarContract.Calendars.CAL_ACCESS_CONTRIBUTOR.toString(), account.name, account.type)
                                return@let Pair(selection, selectionArgs)
                            } else if (onlyWritable) {
                                val selection = CalendarContract.Calendars.CALENDAR_ACCESS_LEVEL + " >= ?"
                                val selectionArgs = arrayOf(CalendarContract.Calendars.CAL_ACCESS_CONTRIBUTOR.toString())
                                return@let Pair(selection, selectionArgs)
                            } else if (account != null) {
                                val selection = CalendarContract.Calendars.ACCOUNT_NAME + " = ? AND " + CalendarContract.Calendars.ACCOUNT_TYPE + " = ?"
                                val selectionArgs = arrayOf(account.name, account.type)
                                return@let Pair(selection, selectionArgs)
                            } else {
                                return@let Pair(null, null)
                            }
                        }

                        val cursor = contentResolver.query(calendarContentUri, projection, selection, selectionArgs, null)
                        val calendars = mutableListOf<Calendar>()

                        cursor?.use {
                            while (it.moveToNext()) {
                                val id = it.getLong(it.getColumnIndexOrThrow(CalendarContract.Calendars._ID)).toString()
                                val displayName = it.getString(it.getColumnIndexOrThrow(CalendarContract.Calendars.CALENDAR_DISPLAY_NAME))
                                val color = it.getLong(it.getColumnIndexOrThrow(CalendarContract.Calendars.CALENDAR_COLOR))
                                val accessLevel = it.getInt(it.getColumnIndexOrThrow(CalendarContract.Calendars.CALENDAR_ACCESS_LEVEL))
                                val accountName = it.getString(it.getColumnIndexOrThrow(CalendarContract.Calendars.ACCOUNT_NAME))
                                val accountType = it.getString(it.getColumnIndexOrThrow(CalendarContract.Calendars.ACCOUNT_TYPE))

                                val calendar = Calendar(
                                    id = id,
                                    title = displayName,
                                    color = color,
                                    isWritable = accessLevel >= CalendarContract.Calendars.CAL_ACCESS_CONTRIBUTOR,
                                    account = Account(
                                        name = accountName,
                                        type = accountType
                                    )
                                )

                                calendars.add(calendar)
                            }
                        }

                        callback(Result.success(calendars))
                    } catch (e: Exception) {
                        callback(Result.failure(
                            FlutterError(
                                code = "GENERIC_ERROR",
                                message = "An error occurred",
                                details = e.message
                            )
                        ))
                    }
                }

            } else {
                callback(Result.failure(
                    FlutterError(
                        code = "ACCESS_REFUSED",
                        message = "Calendar access has been refused or has not been given yet",
                    ))
                )
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
                            callback(Result.failure(
                                FlutterError(
                                    code = "NOT_FOUND",
                                    message = "Failed to delete calendar"
                                )
                            ))
                        }
                    } catch (e: Exception) {
                        callback(Result.failure(
                            FlutterError(
                                code = "GENERIC_ERROR",
                                message = "An error occurred",
                                details = e.message
                            )
                        ))
                    }
                }
            } else {
                callback(Result.failure(
                    FlutterError(
                        code = "ACCESS_REFUSED",
                        message = "Calendar access has been refused or has not been given yet",
                    ))
                )
            }
        }
    }

    override fun createEvent(
        calendarId: String,
        title: String,
        startDate: Long,
        endDate: Long,
        isAllDay: Boolean,
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
                            put(CalendarContract.Events.EVENT_TIMEZONE, "UTC")
                            put(CalendarContract.Events.ALL_DAY, isAllDay)
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
                                    calendarId = calendarId,
                                    description = description,
                                    isAllDay = isAllDay
                                )
                                callback(Result.success(event))
                            } else {
                                callback(Result.failure(
                                    FlutterError(
                                        code = "NOT_FOUND",
                                        message = "Failed to retrieve event ID"
                                    )
                                ))
                            }
                        } else {
                            callback(Result.failure(
                                FlutterError(
                                    code = "GENERIC_ERROR",
                                    message = "Failed to create event"
                                )
                            ))
                        }
                    } catch (e: Exception) {
                        callback(Result.failure(
                            FlutterError(
                                code = "GENERIC_ERROR",
                                message = "An error occurred",
                                details = e.message
                            )
                        ))
                    }
                }
            } else {
                callback(Result.failure(
                    FlutterError(
                        code = "ACCESS_REFUSED",
                        message = "Calendar access has been refused or has not been given yet",
                    ))
                )
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
                            CalendarContract.Events.ALL_DAY,
                        )
                        val selection = CalendarContract.Events.CALENDAR_ID + " = ? AND " + CalendarContract.Events.DTSTART + " >= ? AND " + CalendarContract.Events.DTEND + " <= ?"
                        val selectionArgs = arrayOf(calendarId, startDate.toString(), endDate.toString())

                        val cursor = contentResolver.query(eventContentUri, projection, selection, selectionArgs, null)
                        val tmp = mutableListOf<Event>()

                        cursor?.use {
                            while (it.moveToNext()) {
                                val id = it.getLong(it.getColumnIndexOrThrow(CalendarContract.Events._ID)).toString()
                                val title = it.getString(it.getColumnIndexOrThrow(CalendarContract.Events.TITLE))
                                val description = it.getString(it.getColumnIndexOrThrow(CalendarContract.Events.DESCRIPTION))
                                val start = it.getLong(it.getColumnIndexOrThrow(CalendarContract.Events.DTSTART))
                                val end = it.getLong(it.getColumnIndexOrThrow(CalendarContract.Events.DTEND))
                                val isAllDay = it.getInt(it.getColumnIndexOrThrow(CalendarContract.Events.ALL_DAY)) == 1

                                tmp.add(Event(
                                    id = id,
                                    title = title,
                                    startDate = start,
                                    endDate = end,
                                    calendarId = calendarId,
                                    description = description,
                                    isAllDay = isAllDay
                                ))
                            }
                        }

                        val events = mutableListOf<Event>()

                        val latch = CountDownLatch(tmp.size)
                        for (event in tmp) {
                            retrieveReminders(event.id) { result ->
                                result.onSuccess { reminders ->
                                    events.add(
                                        Event(
                                            id = event.id,
                                            title = event.title,
                                            startDate = event.startDate,
                                            endDate = event.endDate,
                                            calendarId = event.calendarId,
                                            description = event.description,
                                            reminders = reminders,
                                            isAllDay = event.isAllDay
                                        )
                                    )
                                }
                                result.onFailure { error ->
                                    callback(Result.failure(error))
                                }
                                latch.countDown()
                            }
                        }
                        latch.await()

                        callback(Result.success(events))

                    } catch (e: Exception) {
                        callback(Result.failure(
                            FlutterError(
                                code = "GENERIC_ERROR",
                                message = "An error occurred",
                                details = e.message
                            )
                        ))
                    }
                }

            } else {
                callback(Result.failure(
                    FlutterError(
                        code = "ACCESS_REFUSED",
                        message = "Calendar access has been refused or has not been given yet",
                    ))
                )
            }
        }
    }

    override fun deleteEvent(eventId: String, callback: (Result<Unit>) -> Unit) {
        permissionHandler.requestWritePermission { granted ->
            if (granted) {
                CoroutineScope(Dispatchers.IO).launch {
                    try {
                        val selection = CalendarContract.Events._ID + " = ?"
                        val selectionArgs = arrayOf(eventId)

                        val deleted = contentResolver.delete(eventContentUri, selection, selectionArgs)
                        if (deleted > 0) {
                            callback(Result.success(Unit))
                        } else {
                            callback(Result.failure(
                                FlutterError(
                                    code = "NOT_FOUND",
                                    message = "Failed to delete event"
                                )
                            ))
                        }
                    } catch (e: Exception) {
                        callback(Result.failure(
                            FlutterError(
                                code = "GENERIC_ERROR",
                                message = "An error occurred",
                                details = e.message
                            )
                        ))
                    }
                }
            } else {
                callback(Result.failure(
                    FlutterError(
                        code = "ACCESS_REFUSED",
                        message = "Calendar access has been refused or has not been given yet",
                    ))
                )
            }
        }
    }

    override fun createReminder(reminder: Long, eventId: String, callback: (Result<Event>) -> Unit) {
        permissionHandler.requestWritePermission { granted ->
            if (granted) {
                CoroutineScope(Dispatchers.IO).launch {
                    try {
                        val values = ContentValues().apply {
                            put(CalendarContract.Reminders.EVENT_ID, eventId)
                            put(CalendarContract.Reminders.MINUTES, reminder)
                            put(CalendarContract.Reminders.METHOD, CalendarContract.Reminders.METHOD_ALERT)
                        }
                        contentResolver.insert(remindersContentUri, values)

                        retrieveEvent(eventId, callback)

                    } catch (e: Exception) {
                        callback(Result.failure(
                            FlutterError(
                                code = "GENERIC_ERROR",
                                message = "An error occurred",
                                details = e.message
                            )
                        ))
                    }
                }
            } else {
                callback(Result.failure(
                    FlutterError(
                        code = "ACCESS_REFUSED",
                        message = "Calendar access has been refused or has not been given yet",
                    )
                ))
            }
        }
    }

    override fun deleteReminder(reminder: Long, eventId: String, callback: (Result<Event>) -> Unit) {
        permissionHandler.requestWritePermission { granted ->
            if (granted) {
                CoroutineScope(Dispatchers.IO).launch {
                    try {
                        val selection = CalendarContract.Reminders.EVENT_ID + " = ?" + " AND " + CalendarContract.Reminders.MINUTES + " = ?"
                        val selectionArgs = arrayOf(eventId, reminder.toString())

                        val deleted = contentResolver.delete(remindersContentUri, selection, selectionArgs)
                        if (deleted > 0) {
                            retrieveEvent(eventId, callback)
                        } else {
                            callback(Result.failure(
                                FlutterError(
                                    code = "NOT_FOUND",
                                    message = "Failed to delete reminder"
                                )
                            ))
                        }
                    } catch (e: Exception) {
                        callback(Result.failure(
                            FlutterError(
                                code = "GENERIC_ERROR",
                                message = "An error occurred",
                                details = e.message
                            )
                        ))
                    }
                }
            } else {
                callback(Result.failure(
                    FlutterError(
                        code = "ACCESS_REFUSED",
                        message = "Calendar access has been refused or has not been given yet",
                    )
                ))
            }
        }
    }

    private fun retrieveEvent(
        eventId: String,
        callback: (Result<Event>) -> Unit
    ) {
        try {
            val projection = arrayOf(
                CalendarContract.Events._ID,
                CalendarContract.Events.TITLE,
                CalendarContract.Events.DESCRIPTION,
                CalendarContract.Events.DTSTART,
                CalendarContract.Events.DTEND,
                CalendarContract.Events.EVENT_TIMEZONE,
                CalendarContract.Events.CALENDAR_ID,
                CalendarContract.Events.ALL_DAY,
            )
            val selection = CalendarContract.Events._ID + " = ?"
            val selectionArgs = arrayOf(eventId)

            val cursor = contentResolver.query(eventContentUri, projection, selection, selectionArgs, null)
            var event: Event? = null
            val latch = CountDownLatch(1)

            cursor?.use {
                if (it.moveToNext()) {
                    retrieveReminders(eventId) { result ->
                        result.onSuccess { reminders ->
                            event = Event(
                                id = it.getLong(it.getColumnIndexOrThrow(CalendarContract.Events._ID)).toString(),
                                title = it.getString(it.getColumnIndexOrThrow(CalendarContract.Events.TITLE)),
                                description = it.getString(it.getColumnIndexOrThrow(CalendarContract.Events.DESCRIPTION)),
                                startDate = it.getLong(it.getColumnIndexOrThrow(CalendarContract.Events.DTSTART)),
                                endDate = it.getLong(it.getColumnIndexOrThrow(CalendarContract.Events.DTEND)),
                                calendarId = it.getLong(it.getColumnIndexOrThrow(CalendarContract.Events.CALENDAR_ID))
                                    .toString(),
                                reminders = reminders,
                                isAllDay = it.getInt(it.getColumnIndexOrThrow(CalendarContract.Events.ALL_DAY)) == 1
                            )
                        }
                        result.onFailure { error ->
                            callback(Result.failure(error))
                        }
                    }
                    latch.countDown()
                }
            }

            if (event == null) {
                callback(
                    Result.failure(
                        FlutterError(
                            code = "NOT_FOUND",
                            message = "Failed to retrieve event"
                        )
                    )
                )
            } else {
                latch.await()
                callback(Result.success(event!!))
            }


        } catch (e: Exception) {
            callback(
                Result.failure(
                    FlutterError(
                        code = "GENERIC_ERROR",
                        message = "An error occurred",
                        details = e.message
                    )
                )
            )
        }
    }

    private fun retrieveReminders(eventId: String, callback: (Result<List<Long>>) -> Unit) {
        try {
            val reminders = mutableListOf<Long>()
            val projection = arrayOf(
                CalendarContract.Reminders._ID,
                CalendarContract.Reminders.MINUTES,
                CalendarContract.Reminders.METHOD
            )
            val selection = CalendarContract.Reminders.EVENT_ID + " = ?"
            val selectionArgs = arrayOf(eventId)

            val cursor = contentResolver.query(remindersContentUri, projection, selection, selectionArgs, null)
            cursor?.use {
                while (it.moveToNext()) {
                    val minutes = it.getLong(it.getColumnIndexOrThrow(CalendarContract.Reminders.MINUTES))
                    reminders.add(minutes)
                }
            }

            callback(Result.success(reminders))

        } catch (e: Exception) {
            callback(Result.failure(
                FlutterError(
                    code = "GENERIC_ERROR",
                    message = "An error occurred",
                    details = e.message
                )
            ))
        }
    }
}
