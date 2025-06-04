package sncf.connect.tech.eventide

import android.content.ContentResolver
import android.content.ContentUris
import android.content.ContentValues
import android.database.Cursor
import android.net.Uri
import android.provider.CalendarContract
import androidx.core.database.getStringOrNull
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import sncf.connect.tech.eventide.ICalendarFormatter.formatDateTimeForICalendarUtc
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

class CalendarImplem(
    private var contentResolver: ContentResolver,
    private var permissionHandler: PermissionHandler,
    private var calendarContentUri: Uri = CalendarContract.Calendars.CONTENT_URI,
    private var eventContentUri: Uri = CalendarContract.Events.CONTENT_URI,
    private var remindersContentUri: Uri = CalendarContract.Reminders.CONTENT_URI,
    private var attendeesContentUri: Uri = CalendarContract.Attendees.CONTENT_URI,
    private var instancesContentUri: Uri = CalendarContract.Instances.CONTENT_URI
): CalendarApi {
    override fun requestCalendarPermission(callback: (Result<Boolean>) -> Unit) {
        val readLatch = CompletableDeferred<Boolean>()
        val writeLatch = CompletableDeferred<Boolean>()
        permissionHandler.requestReadPermission { granted ->
            readLatch.complete(granted)
        }
        permissionHandler.requestWritePermission { granted ->
            writeLatch.complete(granted)
        }

        CoroutineScope(Dispatchers.IO).launch {
            try {
                val readGranted = readLatch.await()
                val writeGranted = writeLatch.await()
                callback(Result.success(readGranted && writeGranted))
            } catch (e: Exception) {
                callback(Result.failure(e))
            }
        }
    }

    override fun createCalendar(
        title: String,
        color: Long,
        localAccountName: String,
        callback: (Result<Calendar>) -> Unit
    ) {
        permissionHandler.requestWritePermission { granted ->
            if (granted) {
                CoroutineScope(Dispatchers.IO).launch {
                    try {
                        val syncAdapterUri = calendarContentUri.buildUpon()
                            .appendQueryParameter(CalendarContract.CALLER_IS_SYNCADAPTER, "true")
                            .appendQueryParameter(CalendarContract.Calendars.ACCOUNT_NAME, localAccountName)
                            .appendQueryParameter(CalendarContract.Calendars.ACCOUNT_TYPE, CalendarContract.ACCOUNT_TYPE_LOCAL)
                            .build()

                        val values = ContentValues().apply {
                            put(CalendarContract.Calendars.ACCOUNT_NAME, localAccountName)
                            put(CalendarContract.Calendars.ACCOUNT_TYPE, CalendarContract.ACCOUNT_TYPE_LOCAL)
                            put(CalendarContract.Calendars.NAME, title)
                            put(CalendarContract.Calendars.CALENDAR_DISPLAY_NAME, title)
                            put(CalendarContract.Calendars.CALENDAR_COLOR, color)
                            put(CalendarContract.Calendars.CALENDAR_ACCESS_LEVEL, CalendarContract.Calendars.CAL_ACCESS_OWNER)
                            put(CalendarContract.Calendars.OWNER_ACCOUNT, localAccountName)
                        }

                        val calendarUri = contentResolver.insert(syncAdapterUri, values)
                        if (calendarUri != null) {
                            val calendarId = calendarUri.lastPathSegment
                            if (calendarId != null) {
                                val calendar = Calendar(
                                    id = calendarId,
                                    title = title,
                                    color = color,
                                    isWritable = true,
                                    account = Account(
                                        name = localAccountName,
                                        type = CalendarContract.ACCOUNT_TYPE_LOCAL
                                    )
                                )
                                callback(Result.success(calendar))
                            } else {
                                callback(
                                    Result.failure(
                                        FlutterError(
                                            code = "NOT_FOUND",
                                            message = "Failed to retrieve calendar ID. It might not have been created"
                                        )
                                    )
                                )
                            }
                        } else {
                            callback(
                                Result.failure(
                                    FlutterError(
                                        code = "GENERIC_ERROR",
                                        message = "Failed to create calendar"
                                    )
                                )
                            )
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
            } else {
                callback(
                    Result.failure(
                        FlutterError(
                            code = "ACCESS_REFUSED",
                            message = "Calendar access has been refused or has not been given yet",
                        )
                    )
                )
            }
        }
    }

    override fun retrieveCalendars(
        onlyWritableCalendars: Boolean,
        fromLocalAccountName: String?,
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

                        var selection: String? = null
                        var selectionArgs: Array<String>? = null

                        fromLocalAccountName?.let { localAccountName ->
                            selection =
                                CalendarContract.Calendars.ACCOUNT_NAME + " = ? AND " + CalendarContract.Calendars.ACCOUNT_TYPE + " = ?"
                            selectionArgs = arrayOf(localAccountName, CalendarContract.ACCOUNT_TYPE_LOCAL)
                        }

                        val cursor =
                            contentResolver.query(calendarContentUri, projection, selection, selectionArgs, null)
                        val calendars = mutableListOf<Calendar>()

                        cursor?.use {
                            while (it.moveToNext()) {
                                val id = it.getString(it.getColumnIndexOrThrow(CalendarContract.Calendars._ID))
                                val displayName = it.getString(it.getColumnIndexOrThrow(CalendarContract.Calendars.CALENDAR_DISPLAY_NAME))
                                val color = it.getLong(it.getColumnIndexOrThrow(CalendarContract.Calendars.CALENDAR_COLOR))
                                val accessLevel = it.getInt(it.getColumnIndexOrThrow(CalendarContract.Calendars.CALENDAR_ACCESS_LEVEL))
                                val accountName = it.getString(it.getColumnIndexOrThrow(CalendarContract.Calendars.ACCOUNT_NAME))
                                val accountType = it.getString(it.getColumnIndexOrThrow(CalendarContract.Calendars.ACCOUNT_TYPE))

                                val isWritable = accessLevel >= CalendarContract.Calendars.CAL_ACCESS_CONTRIBUTOR
                                if (!onlyWritableCalendars || isWritable) {
                                    val calendar = Calendar(
                                        id = id,
                                        title = displayName,
                                        color = color,
                                        isWritable = isWritable,
                                        account = Account(
                                            name = accountName,
                                            type = accountType
                                        )
                                    )

                                    calendars.add(calendar)
                                }
                            }
                        }

                        callback(Result.success(calendars))
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

            } else {
                callback(
                    Result.failure(
                        FlutterError(
                            code = "ACCESS_REFUSED",
                            message = "Calendar access has been refused or has not been given yet",
                        )
                    )
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

                        if (isCalendarWritable(calendarId)) {
                            val deleted = contentResolver.delete(calendarContentUri, selection, selectionArgs)
                            if (deleted > 0) {
                                callback(Result.success(Unit))
                            } else {
                                callback(
                                    Result.failure(
                                        FlutterError(
                                            code = "GENERIC_ERROR",
                                            message = "An error occurred during deletion"
                                        )
                                    )
                                )
                            }
                        } else {
                            callback(
                                Result.failure(
                                    FlutterError(
                                        code = "NOT_EDITABLE",
                                        message = "Calendar is not writable"
                                    )
                                )
                            )
                        }

                    } catch (e: FlutterError) {
                        callback(Result.failure(e))

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
            } else {
                callback(
                    Result.failure(
                        FlutterError(
                            code = "ACCESS_REFUSED",
                            message = "Calendar access has been refused or has not been given yet",
                        )
                    )
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
        rRule: String?,
        callback: (Result<Event>) -> Unit
    ) {
        permissionHandler.requestWritePermission { granted ->
            if (granted) {
                CoroutineScope(Dispatchers.IO).launch {
                    try {
                        if (isCalendarWritable(calendarId)) {
                            val eventValues = ContentValues().apply {
                                put(CalendarContract.Events.CALENDAR_ID, calendarId)
                                put(CalendarContract.Events.TITLE, title)
                                put(CalendarContract.Events.DESCRIPTION, description)
                                put(CalendarContract.Events.DTSTART, startDate)
                                put(CalendarContract.Events.EVENT_TIMEZONE, "UTC")
                                put(CalendarContract.Events.ALL_DAY, isAllDay)

                                if (rRule != null) {
                                    // https://developer.android.com/reference/android/provider/CalendarContract.Events#operations
                                    val durationInSeconds = (endDate - startDate) / 1000
                                    val days = durationInSeconds / (24 * 3600)
                                    val hours = (durationInSeconds % (24 * 3600)) / 3600
                                    val minutes = (durationInSeconds % 3600) / 60
                                    val seconds = durationInSeconds % 60

                                    val rfc2445Duration = "P" +
                                            (if (days > 0) "${days}D" else "") +
                                            "T" +
                                            (if (hours > 0) "${hours}H" else "") +
                                            (if (minutes > 0) "${minutes}M" else "") +
                                            (if (seconds > 0) "${seconds}S" else "")

                                    put(CalendarContract.Events.DURATION, rfc2445Duration)

                                    // https://stackoverflow.com/a/49515728/24891894
                                    if (!rRule.contains("COUNT=") && !rRule.contains("UNTIL=")) {
                                        rRule.plus(";COUNT=1000")
                                    }
                                    put(CalendarContract.Events.RRULE, rRule.replace("RRULE:", ""))
                                } else {
                                    put(CalendarContract.Events.DTEND, endDate)
                                }
                            }

                            val eventUri = contentResolver.insert(eventContentUri, eventValues)
                            if (eventUri != null) {
                                val eventId = eventUri.lastPathSegment
                                if (eventId != null) {
                                    val event = Event(
                                        id = eventId,
                                        title = title,
                                        startDate = startDate,
                                        endDate = endDate,
                                        calendarId = calendarId,
                                        description = description,
                                        isAllDay = isAllDay,
                                        reminders = emptyList(),
                                        attendees = emptyList(),
                                    )
                                    callback(Result.success(event))
                                } else {
                                    callback(
                                        Result.failure(
                                            FlutterError(
                                                code = "NOT_FOUND",
                                                message = "Failed to retrieve event ID"
                                            )
                                        )
                                    )
                                }
                            } else {
                                callback(
                                    Result.failure(
                                        FlutterError(
                                            code = "GENERIC_ERROR",
                                            message = "Failed to create event"
                                        )
                                    )
                                )
                            }
                        } else {
                            callback(
                                Result.failure(
                                    FlutterError(
                                        code = "NOT_EDITABLE",
                                        message = "Calendar is not writable"
                                    )
                                )
                            )
                        }

                    } catch (e: FlutterError) {
                        callback(Result.failure(e))

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
            } else {
                callback(
                    Result.failure(
                        FlutterError(
                            code = "ACCESS_REFUSED",
                            message = "Calendar access has been refused or has not been given yet",
                        )
                    )
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
                            CalendarContract.Instances._ID,
                            CalendarContract.Instances.EVENT_ID,
                            CalendarContract.Instances.TITLE,
                            CalendarContract.Instances.DESCRIPTION,
                            CalendarContract.Instances.BEGIN,
                            CalendarContract.Instances.END,
                            CalendarContract.Instances.DURATION,
                            CalendarContract.Instances.EVENT_TIMEZONE,
                            CalendarContract.Instances.ALL_DAY,
                            CalendarContract.Instances.RRULE,
                        )

                        val builder: Uri.Builder = instancesContentUri.buildUpon()
                        ContentUris.appendId(builder, startDate)
                        ContentUris.appendId(builder, endDate)

                        val selection = "${CalendarContract.Instances.CALENDAR_ID} = ?"
                        val selectionArgs = arrayOf(calendarId)
                        val sortOrder = CalendarContract.Instances.BEGIN + " ASC"

                        val cursor: Cursor? = contentResolver.query(
                            builder.build(),
                            projection,
                            selection,
                            selectionArgs,
                            sortOrder
                        )

                        val events = mutableListOf<Event>()

                        cursor?.use { c ->
                            while (c.moveToNext()) {
                                val id = c.getString(c.getColumnIndexOrThrow(CalendarContract.Instances._ID))
                                val originalId = c.getString(c.getColumnIndexOrThrow(CalendarContract.Instances.EVENT_ID))
                                val title = c.getString(c.getColumnIndexOrThrow(CalendarContract.Instances.TITLE))
                                val description =
                                    c.getString(c.getColumnIndexOrThrow(CalendarContract.Instances.DESCRIPTION))
                                val start = c.getLong(c.getColumnIndexOrThrow(CalendarContract.Instances.BEGIN))
                                val duration = c.getString(c.getColumnIndexOrThrow(CalendarContract.Instances.DURATION))
                                val end = c.getLong(c.getColumnIndexOrThrow(CalendarContract.Instances.END))
                                val isAllDay = c.getInt(c.getColumnIndexOrThrow(CalendarContract.Instances.ALL_DAY)) == 1
                                val rRule = c.getStringOrNull(c.getColumnIndexOrThrow(CalendarContract.Instances.RRULE))

                                val attendees = mutableListOf<Attendee>()
                                val attendeesLatch = CountDownLatch(1)
                                retrieveAttendees(id) { result ->
                                    result.onSuccess {
                                        attendees.addAll(it)
                                        attendeesLatch.countDown()
                                    }
                                    result.onFailure { error ->
                                        callback(Result.failure(error))
                                    }
                                }

                                val reminders = mutableListOf<Long>()
                                val remindersLatch = CountDownLatch(1)
                                retrieveReminders(id) { result ->
                                    result.onSuccess {
                                        reminders.addAll(it)
                                        remindersLatch.countDown()
                                    }
                                    result.onFailure { error ->
                                        callback(Result.failure(error))
                                    }
                                }

                                attendeesLatch.await()
                                remindersLatch.await()

                                val dtEnd = if (end == 0L) {
                                    start + rfc2445DurationToMillis(duration)
                                } else {
                                    end
                                }

                                events.add(
                                    Event(
                                        id = id,
                                        calendarId = calendarId,
                                        title = title,
                                        startDate = start,
                                        endDate = dtEnd,
                                        reminders = reminders,
                                        attendees = attendees,
                                        description = description,
                                        isAllDay = isAllDay,
                                        rRule = "RRULE:$rRule",
                                        originalEventId = originalId
                                    )
                                )
                            }
                        }

                        callback(Result.success(events))

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
            } else {
                callback(
                    Result.failure(
                        FlutterError(
                            code = "ACCESS_REFUSED",
                            message = "Calendar access has been refused or has not been given yet",
                        )
                    )
                )
            }
        }
    }

    override fun deleteEvent(
        calendarId: String,
        eventId: String,
        span: EventSpan,
        callback: (Result<Unit>) -> Unit
    ) {
        permissionHandler.requestWritePermission { granted ->
            if (!granted) {
                callback(Result.failure(
                    FlutterError(
                        code = "ACCESS_REFUSED",
                        message = "Calendar access has been refused or has not been given yet"
                    )
                ))
                return@requestWritePermission
            }

            CoroutineScope(Dispatchers.IO).launch {
                try {
                    if (!isCalendarWritable(calendarId)) {
                        callback(Result.failure(
                            FlutterError(
                                code = "NOT_EDITABLE",
                                message = "Calendar is not writable"
                            )
                        ))

                        return@launch
                    }

                    when (span) {
                        EventSpan.CURRENT_EVENT -> {
                            // Suppression d'une occurrence unique
                            val instanceCursor = CalendarContract.Instances.query(
                                contentResolver,
                                arrayOf(
                                    CalendarContract.Instances.BEGIN,
                                    CalendarContract.Instances._ID,
                                    CalendarContract.Instances.EVENT_ID
                                ),
                                Long.MIN_VALUE,
                                Long.MAX_VALUE
                            )

                            val values = ContentValues()
                            var originalEventId: Long? = null

                            while (instanceCursor.moveToNext()) {
                                val foundEventId = instanceCursor.getString(instanceCursor.getColumnIndexOrThrow(CalendarContract.Instances._ID))

                                if (foundEventId == eventId) {
                                    val instanceStartDate = instanceCursor.getLong(instanceCursor.getColumnIndexOrThrow(CalendarContract.Instances.BEGIN))
                                    values.put(CalendarContract.Events.STATUS, CalendarContract.Events.STATUS_CANCELED)
                                    values.put(CalendarContract.Events.ORIGINAL_INSTANCE_TIME, instanceStartDate)

                                    originalEventId = instanceCursor.getLong(instanceCursor.getColumnIndexOrThrow(CalendarContract.Instances.EVENT_ID))
                                    break
                                }
                            }

                            if (originalEventId == null) {
                                callback(Result.failure(
                                    FlutterError(
                                        code = "NOT_FOUND",
                                        message = "Failed to retrieve instance for deletion"
                                    )
                                ))
                                return@launch
                            }

                            val exceptionUriWithId = ContentUris.withAppendedId(CalendarContract.Events.CONTENT_EXCEPTION_URI, originalEventId)

                            if (contentResolver.insert(exceptionUriWithId, values) != null) {
                                callback(Result.success(Unit))
                            } else {
                                callback(
                                    Result.failure(
                                        FlutterError(
                                            code = "GENERIC_ERROR",
                                            message = "Failed to delete current event occurrence"
                                        )
                                    )
                                )
                            }
                        }
                        EventSpan.FUTURE_EVENTS -> {
                            val values = ContentValues()
                            var originalEventId: Long? = null

                            val instanceCursor = CalendarContract.Instances.query(
                                contentResolver,
                                arrayOf(
                                    CalendarContract.Instances._ID,
                                    CalendarContract.Instances.BEGIN,
                                    CalendarContract.Instances.EVENT_ID
                                ),
                                Long.MIN_VALUE,
                                Long.MAX_VALUE
                            )

                            while (instanceCursor.moveToFirst()) {
                                val foundEventId = instanceCursor.getString(instanceCursor.getColumnIndexOrThrow(CalendarContract.Instances._ID))

                                if (foundEventId == eventId) {
                                    val instanceStartDate =
                                        instanceCursor.getLong(instanceCursor.getColumnIndexOrThrow(CalendarContract.Instances.BEGIN))
                                    values.put(CalendarContract.Events.LAST_DATE, instanceStartDate)

                                    originalEventId =
                                        instanceCursor.getLong(instanceCursor.getColumnIndexOrThrow(CalendarContract.Instances.EVENT_ID))

                                    break
                                }
                            }

                            if (originalEventId == null) {
                                callback(Result.failure(
                                    FlutterError(
                                        code = "NOT_FOUND",
                                        message = "Failed to retrieve instance for update"
                                    )
                                ))
                                return@launch
                            }

                            val rowsUpdated = contentResolver.update(
                                ContentUris.withAppendedId(eventContentUri, originalEventId),
                                values,
                                null,
                                null
                            )

                            if (rowsUpdated > 0) {
                                callback(Result.success(Unit))
                            } else {
                                callback(
                                    Result.failure(
                                        FlutterError(
                                            code = "NOT_FOUND",
                                            message = "Failed to update recurring event"
                                        )
                                    )
                                )
                            }
                        }
                        EventSpan.ALL_EVENTS -> {
                            val uri = ContentUris.withAppendedId(eventContentUri, eventId.toLong())
                            val deleted = contentResolver.delete(uri, null, null)
                            if (deleted > 0) {
                                callback(Result.success(Unit))
                            } else {
                                callback(Result.failure(
                                    FlutterError(
                                        code = "NOT_FOUND",
                                        message = "Failed to delete recurring event"
                                    )
                                ))
                            }
                        }
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

                        retrieveInstance(eventId, callback)

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
            } else {
                callback(
                    Result.failure(
                        FlutterError(
                            code = "ACCESS_REFUSED",
                            message = "Calendar access has been refused or has not been given yet",
                        )
                    )
                )
            }
        }
    }

    override fun deleteReminder(reminder: Long, eventId: String, callback: (Result<Event>) -> Unit) {
        permissionHandler.requestWritePermission { granted ->
            if (granted) {
                CoroutineScope(Dispatchers.IO).launch {
                    try {
                        val selection =
                            CalendarContract.Reminders.EVENT_ID + " = ?" + " AND " + CalendarContract.Reminders.MINUTES + " = ?"
                        val selectionArgs = arrayOf(eventId, reminder.toString())

                        val deleted = contentResolver.delete(remindersContentUri, selection, selectionArgs)
                        if (deleted > 0) {
                            retrieveInstance(eventId, callback)
                        } else {
                            callback(
                                Result.failure(
                                    FlutterError(
                                        code = "NOT_FOUND",
                                        message = "Failed to delete reminder"
                                    )
                                )
                            )
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
            } else {
                callback(
                    Result.failure(
                        FlutterError(
                            code = "ACCESS_REFUSED",
                            message = "Calendar access has been refused or has not been given yet",
                        )
                    )
                )
            }
        }
    }

    override fun createAttendee(
        eventId: String,
        name: String,
        email: String,
        role: Long,
        type: Long,
        callback: (Result<Event>) -> Unit
    ) {
        permissionHandler.requestWritePermission { granted ->
            if (granted) {
                CoroutineScope(Dispatchers.IO).launch {
                    try {
                        val values = ContentValues().apply {
                            put(CalendarContract.Attendees.EVENT_ID, eventId)
                            put(CalendarContract.Attendees.ATTENDEE_NAME, name)
                            put(CalendarContract.Attendees.ATTENDEE_EMAIL, email)
                            put(CalendarContract.Attendees.ATTENDEE_RELATIONSHIP, type)
                            put(CalendarContract.Attendees.ATTENDEE_TYPE, role)
                        }
                        contentResolver.insert(attendeesContentUri, values)

                        retrieveInstance(eventId, callback)

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
            } else {
                callback(
                    Result.failure(
                        FlutterError(
                            code = "ACCESS_REFUSED",
                            message = "Calendar access has been refused or has not been given yet",
                        )
                    )
                )
            }
        }
    }

    override fun deleteAttendee(
        eventId: String,
        email: String,
        callback: (Result<Event>) -> Unit
    ) {
        permissionHandler.requestWritePermission { granted ->
            if (granted) {
                CoroutineScope(Dispatchers.IO).launch {
                    try {
                        val selection =
                            CalendarContract.Attendees.EVENT_ID + " = ?" + " AND " + CalendarContract.Attendees.ATTENDEE_EMAIL + " = ?"
                        val selectionArgs = arrayOf(eventId, email)

                        val deleted = contentResolver.delete(attendeesContentUri, selection, selectionArgs)
                        if (deleted > 0) {
                            retrieveInstance(eventId, callback)
                        } else {
                            callback(
                                Result.failure(
                                    FlutterError(
                                        code = "NOT_FOUND",
                                        message = "Failed to delete attendee"
                                    )
                                )
                            )
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
            } else {
                callback(
                    Result.failure(
                        FlutterError(
                            code = "ACCESS_REFUSED",
                            message = "Calendar access has been refused or has not been given yet",
                        )
                    )
                )
            }
        }
    }

    private fun isCalendarWritable(
        calendarId: String,
    ): Boolean {
        val projection = arrayOf(
            CalendarContract.Calendars.CALENDAR_ACCESS_LEVEL
        )
        val selection = CalendarContract.Calendars._ID + " = ?"
        val selectionArgs = arrayOf(calendarId)

        val cursor = contentResolver.query(calendarContentUri, projection, selection, selectionArgs, null)
        cursor?.use {
            if (it.moveToNext()) {
                val accessLevel = it.getInt(it.getColumnIndexOrThrow(CalendarContract.Calendars.CALENDAR_ACCESS_LEVEL))
                return accessLevel >= CalendarContract.Calendars.CAL_ACCESS_CONTRIBUTOR
            } else {
                throw FlutterError(
                    code = "NOT_FOUND",
                    message = "Failed to retrieve calendar"
                )
            }
        }

        throw FlutterError(
            code = "GENERIC_ERROR",
            message = "An error occurred"
        )
    }

    private fun retrieveInstance(
        eventId: String,
        callback: (Result<Event>) -> Unit
    ) {
        try {
            val projection = arrayOf(
                CalendarContract.Instances._ID,
                CalendarContract.Instances.EVENT_ID,
                CalendarContract.Instances.TITLE,
                CalendarContract.Instances.DESCRIPTION,
                CalendarContract.Instances.DTSTART,
                CalendarContract.Instances.DTEND,
                CalendarContract.Instances.EVENT_TIMEZONE,
                CalendarContract.Instances.CALENDAR_ID,
                CalendarContract.Instances.ALL_DAY,
                CalendarContract.Instances.RRULE,
            )
            val selection = "Instances._id = ?"
            val selectionArgs = arrayOf(eventId)

            val startMillis = 0L
            val endMillis = Long.MAX_VALUE

            val builder: Uri.Builder = instancesContentUri.buildUpon()
            ContentUris.appendId(builder, startMillis)
            ContentUris.appendId(builder, endMillis)

            val cursor = contentResolver.query(builder.build(), projection, selection, selectionArgs, null)
            var event: Event? = null

            cursor?.use { it ->
                if (it.moveToNext()) {
                    val id = it.getString(it.getColumnIndexOrThrow(CalendarContract.Instances._ID))
                    val originalId = it.getString(it.getColumnIndexOrThrow(CalendarContract.Instances.EVENT_ID))
                    val title = it.getString(it.getColumnIndexOrThrow(CalendarContract.Instances.TITLE))
                    val description = it.getString(it.getColumnIndexOrThrow(CalendarContract.Instances.DESCRIPTION))
                    val isAllDay = it.getInt(it.getColumnIndexOrThrow(CalendarContract.Instances.ALL_DAY)) == 1
                    val startDate = it.getLong(it.getColumnIndexOrThrow(CalendarContract.Instances.DTSTART))
                    val endDate = it.getLong(it.getColumnIndexOrThrow(CalendarContract.Instances.DTEND))
                    val calendarId = it.getString(it.getColumnIndexOrThrow(CalendarContract.Instances.CALENDAR_ID))
                    val rRule = it.getString(it.getColumnIndexOrThrow(CalendarContract.Instances.RRULE))

                    val attendees = mutableListOf<Attendee>()
                    val attendeesLatch = CountDownLatch(1)
                    retrieveAttendees(id) { result ->
                        result.onSuccess {
                            attendees.addAll(it)
                            attendeesLatch.countDown()
                        }
                        result.onFailure { error ->
                            callback(Result.failure(error))
                        }
                    }

                    val reminders = mutableListOf<Long>()
                    val remindersLatch = CountDownLatch(1)
                    retrieveReminders(id) { result ->
                        result.onSuccess {
                            reminders.addAll(it)
                            remindersLatch.countDown()
                        }
                        result.onFailure { error ->
                            callback(Result.failure(error))
                        }
                    }

                    attendeesLatch.await()
                    remindersLatch.await()

                    event = Event(
                        id = id,
                        originalEventId = originalId,
                        calendarId = calendarId,
                        title = title,
                        startDate = startDate,
                        endDate = endDate,
                        description = description,
                        isAllDay = isAllDay,
                        reminders = reminders,
                        attendees = attendees,
                        rRule = rRule
                    )
                }
            }

            if (event == null) {
                callback(
                    Result.failure(
                        FlutterError(
                            code = "NOT_FOUND",
                            message = "Failed to retrieve event instance"
                        )
                    )
                )
            } else {
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

    private fun retrieveOriginalTimeMillis(
        eventId: String,
        callback: (Result<Long>) -> Unit
    ) {
        try {
            val projection = arrayOf(
                CalendarContract.Events.DTSTART,
            )
            val selection = CalendarContract.Events._ID + " = ?"
            val selectionArgs = arrayOf(eventId)

            val cursor = contentResolver.query(eventContentUri, projection, selection, selectionArgs, null)
            var startDate: Long? = null

            cursor?.use { it ->
                if (it.moveToNext()) {
                    startDate = it.getLong(it.getColumnIndexOrThrow(CalendarContract.Events.DTSTART))
                }
            }

            if (startDate == null) {
                callback(
                    Result.failure(
                        FlutterError(
                            code = "NOT_FOUND",
                            message = "Failed to retrieve event original timeMillis"
                        )
                    )
                )
            } else {
                callback(Result.success(startDate!!))
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

    private fun retrieveAttendees(eventId: String, callback: (Result<List<Attendee>>) -> Unit) {
        try {
            val projection = arrayOf(
                CalendarContract.Attendees.ATTENDEE_NAME,
                CalendarContract.Attendees.ATTENDEE_EMAIL,
                CalendarContract.Attendees.ATTENDEE_RELATIONSHIP,
                CalendarContract.Attendees.ATTENDEE_STATUS,
                CalendarContract.Attendees.ATTENDEE_TYPE,
            )
            val selection = CalendarContract.Attendees.EVENT_ID + " = ?"
            val selectionArgs = arrayOf(eventId)

            val cursor = contentResolver.query(attendeesContentUri, projection, selection, selectionArgs, null)
            val attendees = mutableListOf<Attendee>()

            cursor?.use {
                while (it.moveToNext()) {
                    val name = it.getString(it.getColumnIndexOrThrow(CalendarContract.Attendees.ATTENDEE_NAME))
                    val email = it.getString(it.getColumnIndexOrThrow(CalendarContract.Attendees.ATTENDEE_EMAIL))
                    val relationship = it.getInt(it.getColumnIndexOrThrow(CalendarContract.Attendees.ATTENDEE_RELATIONSHIP))
                    val type = it.getInt(it.getColumnIndexOrThrow(CalendarContract.Attendees.ATTENDEE_TYPE))
                    val status = it.getInt(it.getColumnIndexOrThrow(CalendarContract.Attendees.ATTENDEE_STATUS))

                    val attendee = Attendee(
                        name = name,
                        email = email,
                        type = relationship.toLong(),
                        role = type.toLong(),
                        status = status.toLong(),
                    )

                    attendees.add(attendee)
                }
            }

            callback(Result.success(attendees))

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

    private fun rfc2445DurationToMillis(rfc2445Duration: String): Long {
        val regex = Regex("P(?:(\\d+)D)?T(?:(\\d+)H)?(?:(\\d+)M)?(?:(\\d+)S)?")
        val matchResult = regex.matchEntire(rfc2445Duration)
            ?: throw IllegalArgumentException("Invalid RFC2445 duration format")

        val days = matchResult.groups[1]?.value?.toLong() ?: 0
        val hours = matchResult.groups[2]?.value?.toLong() ?: 0
        val minutes = matchResult.groups[3]?.value?.toLong() ?: 0
        val seconds = matchResult.groups[4]?.value?.toLong() ?: 0

        return TimeUnit.DAYS.toMillis(days) +
                TimeUnit.HOURS.toMillis(hours) +
                TimeUnit.MINUTES.toMillis(minutes) +
                TimeUnit.SECONDS.toMillis(seconds)
    }

    private fun replaceUntilInRRule(rrule: String, newUntil: String): String {
        val untilRegex = Regex("UNTIL=\\d{8}T\\d{6}Z")
        return if (untilRegex.containsMatchIn(rrule)) {
            rrule.replace(untilRegex, "UNTIL=$newUntil")
        } else {
            if (rrule.endsWith(";") || rrule.isEmpty()) {
                "${rrule}UNTIL=$newUntil"
            } else {
                "$rrule;UNTIL=$newUntil"
            }
        }
    }

    private fun addExDateToRRule(
        eventId: String,
        timestamp: Long,
        isAllDay: Boolean,
        callback: (Result<Unit>) -> Unit
    ) {
        try {
            val eventUri = CalendarContract.Events.CONTENT_URI.buildUpon().appendPath(eventId).build()
            val projection = arrayOf(CalendarContract.Events.RRULE)
            var rrule: String? = null

            contentResolver.query(eventUri, projection, null, null, null)?.use { cursor ->
                if (cursor.moveToFirst()) {
                    rrule = cursor.getString(cursor.getColumnIndexOrThrow(CalendarContract.Events.RRULE))
                }
            }

            if (rrule == null) {
                callback(Result.failure(
                    FlutterError(
                        code = "NOT_FOUND",
                        message = "RRULE not found for the event"
                    )
                ))
                return
            }

            val exdate = formatDateTimeForICalendarUtc(timestamp, isAllDay)
            val newRrule = if (rrule!!.contains("EXDATE=")) {
                rrule!!.replace(Regex("EXDATE=([^;]*)")) { matchResult ->
                    val existing = matchResult.groupValues[1]
                    "EXDATE=${existing},$exdate"
                }
            } else {
                if (rrule!!.endsWith(";") || rrule!!.isEmpty()) {
                    "${rrule}EXDATE=$exdate"
                } else {
                    "$rrule;EXDATE=$exdate"
                }
            }

            val values = ContentValues().apply {
                put(CalendarContract.Events.RRULE, newRrule)
            }

            val rows = contentResolver.update(eventUri, values, null, null)
            if (rows > 0) {
                callback(Result.success(Unit))
            } else {
                callback(Result.failure(
                    FlutterError(
                        code = "UPDATE_FAILED",
                        message = "Failed to update RRULE with EXDATE"
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
}
