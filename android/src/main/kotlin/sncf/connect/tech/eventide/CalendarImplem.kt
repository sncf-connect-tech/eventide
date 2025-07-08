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
    private var remindersContentUri: Uri = CalendarContract.Reminders.CONTENT_URI,
    private var attendeesContentUri: Uri = CalendarContract.Attendees.CONTENT_URI
): CalendarApi {
    override fun createCalendar(
        title: String,
        color: Long,
        localAccountName: String,
        callback: (Result<Calendar>) -> Unit
    ) {
        permissionHandler.requestWritePermission { granted ->
            if (!granted) {
                callback(
                    Result.failure(
                        FlutterError(
                            code = "ACCESS_REFUSED",
                            message = "Calendar access has been refused or has not been given yet",
                        )
                    )
                )
                return@requestWritePermission
            }

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
        }
    }

    override fun retrieveDefaultCalendar(fromLocalAccountName: String?, callback: (Result<Calendar?>) -> Unit) {
        permissionHandler.requestReadPermission { granted ->
            if (!granted) {
                callback(
                    Result.failure(
                        FlutterError(
                            code = "ACCESS_REFUSED",
                            message = "Calendar access has been refused or has not been given yet",
                        )
                    )
                )
                return@requestReadPermission
            }

            CoroutineScope(Dispatchers.IO).launch {
                try {
                    val projection = arrayOf(
                        CalendarContract.Calendars._ID,
                        CalendarContract.Calendars.CALENDAR_DISPLAY_NAME,
                        CalendarContract.Calendars.CALENDAR_COLOR,
                        CalendarContract.Calendars.CALENDAR_ACCESS_LEVEL,
                        CalendarContract.Calendars.ACCOUNT_NAME,
                        CalendarContract.Calendars.ACCOUNT_TYPE,
                        CalendarContract.Calendars.IS_PRIMARY
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

                    var found = false

                    cursor?.use {
                        while (it.moveToNext() && !found) {
                            found = it.getInt(it.getColumnIndexOrThrow(CalendarContract.Calendars.IS_PRIMARY)) == 1

                            if (found) {
                                val id = it.getString(it.getColumnIndexOrThrow(CalendarContract.Calendars._ID))
                                val displayName = it.getString(it.getColumnIndexOrThrow(CalendarContract.Calendars.CALENDAR_DISPLAY_NAME))
                                val color = it.getLong(it.getColumnIndexOrThrow(CalendarContract.Calendars.CALENDAR_COLOR))
                                val accessLevel = it.getInt(it.getColumnIndexOrThrow(CalendarContract.Calendars.CALENDAR_ACCESS_LEVEL))
                                val accountName = it.getString(it.getColumnIndexOrThrow(CalendarContract.Calendars.ACCOUNT_NAME))
                                val accountType = it.getString(it.getColumnIndexOrThrow(CalendarContract.Calendars.ACCOUNT_TYPE))

                                val isWritable = accessLevel >= CalendarContract.Calendars.CAL_ACCESS_CONTRIBUTOR

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

                                callback(Result.success(calendar))
                            }
                        }
                    }

                    if (!found) {
                        callback(Result.success(null)) // No primary calendar found
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
        }
    }

    override fun retrieveCalendars(
        onlyWritableCalendars: Boolean,
        fromLocalAccountName: String?,
        callback: (Result<List<Calendar>>) -> Unit
    ) {
        permissionHandler.requestReadPermission { granted ->
            if (!granted) {
                callback(
                    Result.failure(
                        FlutterError(
                            code = "ACCESS_REFUSED",
                            message = "Calendar access has been refused or has not been given yet",
                        )
                    )
                )
                return@requestReadPermission
            }

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

        }
    }

    override fun deleteCalendar(calendarId: String, callback: (Result<Unit>) -> Unit) {
        permissionHandler.requestWritePermission { granted ->
            if (!granted) {
                callback(
                    Result.failure(
                        FlutterError(
                            code = "ACCESS_REFUSED",
                            message = "Calendar access has been refused or has not been given yet",
                        )
                    )
                )
                return@requestWritePermission
            }

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
        reminders: List<Long>?,
        callback: (Result<Unit>) -> Unit
    ) {
        permissionHandler.requestWritePermission { granted ->
            if (!granted) {
                callback(
                    Result.failure(
                        FlutterError(
                            code = "ACCESS_REFUSED",
                            message = "Calendar access has been refused or has not been given yet",
                        )
                    )
                )
                return@requestWritePermission
            }

            CoroutineScope(Dispatchers.IO).launch {
                try {
                    if (isCalendarWritable(calendarId)) {
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
                            val eventId = eventUri.lastPathSegment
                            if (eventId != null) {
                                reminders?.forEach { reminder ->
                                    val reminderValues = ContentValues().apply {
                                        put(CalendarContract.Reminders.EVENT_ID, eventId)
                                        put(CalendarContract.Reminders.MINUTES, reminder)
                                        put(CalendarContract.Reminders.METHOD, CalendarContract.Reminders.METHOD_ALERT)
                                    }
                                    contentResolver.insert(remindersContentUri, reminderValues)
                                }
                                callback(Result.success(Unit))
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
        }
    }

    override fun retrieveEvents(
        calendarId: String,
        startDate: Long,
        endDate: Long,
        callback: (Result<List<Event>>) -> Unit
    ) {
        permissionHandler.requestReadPermission { granted ->
            if (!granted) {
                callback(
                    Result.failure(
                        FlutterError(
                            code = "ACCESS_REFUSED",
                            message = "Calendar access has been refused or has not been given yet",
                        )
                    )
                )
                return@requestReadPermission
            }

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
                    val selection =
                        CalendarContract.Events.CALENDAR_ID + " = ? AND " + CalendarContract.Events.DTSTART + " >= ? AND " + CalendarContract.Events.DTEND + " <= ?"
                    val selectionArgs = arrayOf(calendarId, startDate.toString(), endDate.toString())

                    val cursor = contentResolver.query(eventContentUri, projection, selection, selectionArgs, null)
                    val events = mutableListOf<Event>()

                    cursor?.use { c ->
                        while (c.moveToNext()) {
                            val id = c.getString(c.getColumnIndexOrThrow(CalendarContract.Events._ID))
                            val title = c.getString(c.getColumnIndexOrThrow(CalendarContract.Events.TITLE))
                            val description =
                                c.getString(c.getColumnIndexOrThrow(CalendarContract.Events.DESCRIPTION))
                            val start = c.getLong(c.getColumnIndexOrThrow(CalendarContract.Events.DTSTART))
                            val end = c.getLong(c.getColumnIndexOrThrow(CalendarContract.Events.DTEND))
                            val isAllDay = c.getInt(c.getColumnIndexOrThrow(CalendarContract.Events.ALL_DAY)) == 1

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

                            events.add(
                                Event(
                                    id = id,
                                    title = title,
                                    startDate = start,
                                    endDate = end,
                                    calendarId = calendarId,
                                    description = description,
                                    isAllDay = isAllDay,
                                    reminders = reminders,
                                    attendees = attendees
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

        }
    }

    override fun deleteEvent(eventId: String, callback: (Result<Unit>) -> Unit) {
        permissionHandler.requestWritePermission { granted ->
            if (!granted) {
                callback(
                    Result.failure(
                        FlutterError(
                            code = "ACCESS_REFUSED",
                            message = "Calendar access has been refused or has not been given yet",
                        )
                    )
                )
                return@requestWritePermission
            }

            CoroutineScope(Dispatchers.IO).launch {
                try {
                    val calendarId = getCalendarId(eventId)
                    if (isCalendarWritable(calendarId)) {
                        val selection = CalendarContract.Events._ID + " = ?"
                        val selectionArgs = arrayOf(eventId)

                        val deleted = contentResolver.delete(eventContentUri, selection, selectionArgs)
                        if (deleted > 0) {
                            callback(Result.success(Unit))
                        } else {
                            callback(
                                Result.failure(
                                    FlutterError(
                                        code = "NOT_FOUND",
                                        message = "Failed to delete event"
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
        }
    }

    override fun deleteReminder(reminder: Long, eventId: String, callback: (Result<Event>) -> Unit) {
        permissionHandler.requestWritePermission { granted ->
            if (!granted) {
                callback(
                    Result.failure(
                        FlutterError(
                            code = "ACCESS_REFUSED",
                            message = "Calendar access has been refused or has not been given yet",
                        )
                    )
                )
                return@requestWritePermission
            }

            CoroutineScope(Dispatchers.IO).launch {
                try {
                    val selection =
                        CalendarContract.Reminders.EVENT_ID + " = ?" + " AND " + CalendarContract.Reminders.MINUTES + " = ?"
                    val selectionArgs = arrayOf(eventId, reminder.toString())

                    val deleted = contentResolver.delete(remindersContentUri, selection, selectionArgs)
                    if (deleted > 0) {
                        retrieveEvent(eventId, callback)
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
            if (!granted) {
                callback(
                    Result.failure(
                        FlutterError(
                            code = "ACCESS_REFUSED",
                            message = "Calendar access has been refused or has not been given yet",
                        )
                    )
                )
                return@requestWritePermission
            }

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

                    retrieveEvent(eventId, callback)

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
        }
    }

    override fun deleteAttendee(
        eventId: String,
        email: String,
        callback: (Result<Event>) -> Unit
    ) {
        permissionHandler.requestWritePermission { granted ->
            if (!granted) {
                callback(
                    Result.failure(
                        FlutterError(
                            code = "ACCESS_REFUSED",
                            message = "Calendar access has been refused or has not been given yet",
                        )
                    )
                )
                return@requestWritePermission
            }

            CoroutineScope(Dispatchers.IO).launch {
                try {
                    val selection =
                        CalendarContract.Attendees.EVENT_ID + " = ?" + " AND " + CalendarContract.Attendees.ATTENDEE_EMAIL + " = ?"
                    val selectionArgs = arrayOf(eventId, email)

                    val deleted = contentResolver.delete(attendeesContentUri, selection, selectionArgs)
                    if (deleted > 0) {
                        retrieveEvent(eventId, callback)
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

    private fun getCalendarId(
        eventId: String,
    ): String {
        val projection = arrayOf(
            CalendarContract.Events.CALENDAR_ID
        )
        val selection = CalendarContract.Events._ID + " = ?"
        val selectionArgs = arrayOf(eventId)

        val cursor = contentResolver.query(eventContentUri, projection, selection, selectionArgs, null)
        cursor?.use {
            if (it.moveToNext()) {
                return it.getString(it.getColumnIndexOrThrow(CalendarContract.Events.CALENDAR_ID))
            } else {
                throw FlutterError(
                    code = "NOT_FOUND",
                    message = "Failed to retrieve event"
                )
            }
        }

        throw FlutterError(
            code = "GENERIC_ERROR",
            message = "An error occurred"
        )
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

            cursor?.use { it ->
                if (it.moveToNext()) {
                    val id = it.getString(it.getColumnIndexOrThrow(CalendarContract.Events._ID))
                    val title = it.getString(it.getColumnIndexOrThrow(CalendarContract.Events.TITLE))
                    val description = it.getString(it.getColumnIndexOrThrow(CalendarContract.Events.DESCRIPTION))
                    val isAllDay = it.getInt(it.getColumnIndexOrThrow(CalendarContract.Events.ALL_DAY)) == 1
                    val startDate = it.getLong(it.getColumnIndexOrThrow(CalendarContract.Events.DTSTART))
                    val endDate = it.getLong(it.getColumnIndexOrThrow(CalendarContract.Events.DTEND))
                    val calendarId = it.getString(it.getColumnIndexOrThrow(CalendarContract.Events.CALENDAR_ID))

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
                        title = title,
                        startDate = startDate,
                        endDate = endDate,
                        calendarId = calendarId,
                        description = description,
                        isAllDay = isAllDay,
                        reminders = reminders,
                        attendees = attendees
                    )
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
                callback(Result.success(event))
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
}
