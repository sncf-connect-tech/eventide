package sncf.connect.tech.eventide

import android.accounts.AccountManager
import android.app.Activity
import android.app.Application
import android.content.ContentResolver
import android.content.ContentValues
import android.content.Context
import android.content.pm.PackageManager
import android.net.Uri
import android.provider.CalendarContract
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.PluginRegistry
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import sncf.connect.tech.eventide.handler.CalendarActivityManager
import sncf.connect.tech.eventide.handler.DescriptionUrlHelper
import sncf.connect.tech.eventide.handler.IcsEventManager
import sncf.connect.tech.eventide.handler.PermissionHandler
import sncf.connect.tech.eventide.handler.RecurrenceHelper
import java.util.concurrent.CountDownLatch

class CalendarImplem(
    private val context: Context,
    private val permissionHandler: PermissionHandler = PermissionHandler(),
    private val calendarActivityManager: CalendarActivityManager = CalendarActivityManager(),
    private val icsEventManager: IcsEventManager = IcsEventManager(context),
    private val accountManager: AccountManager = AccountManager.get(context),
    private val packageManager: PackageManager = context.packageManager,
    private val contentResolver: ContentResolver = context.contentResolver,
    private val calendarContentUri: Uri = CalendarContract.Calendars.CONTENT_URI,
    private val eventContentUri: Uri = CalendarContract.Events.CONTENT_URI,
    private val remindersContentUri: Uri = CalendarContract.Reminders.CONTENT_URI,
    private val attendeesContentUri: Uri = CalendarContract.Attendees.CONTENT_URI,
    private val instancesContentUri: Uri? = null,
): CalendarApi, EventidePlugin.ActivityComponent {
    private var activity: Activity? = null

    // ------------------- PluginActivityComponent implementation ------------------
    override val requestPermissionsResultListener: PluginRegistry.RequestPermissionsResultListener
        get() = permissionHandler
    
    override val calendarActivityLifecycleListener: Application.ActivityLifecycleCallbacks
        get() = calendarActivityManager
    
    override fun updateActivity(binding: ActivityPluginBinding?) {
        activity = binding?.activity
        permissionHandler.activity = activity
        calendarActivityManager.activity = activity
    }

    // ------------------- CalendarApi implementation ------------------
    override fun createCalendar(
        title: String,
        color: Long,
        account: Account?,
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
                    // Use provided accountName or default to device name
                    val finalAccountName = account?.name ?: "local"

                    val syncAdapterUri = calendarContentUri.buildUpon()
                        .appendQueryParameter(CalendarContract.CALLER_IS_SYNCADAPTER, "true")
                        .appendQueryParameter(CalendarContract.Calendars.ACCOUNT_NAME, finalAccountName)
                        .appendQueryParameter(CalendarContract.Calendars.ACCOUNT_TYPE, CalendarContract.ACCOUNT_TYPE_LOCAL)
                        .build()

                    val values = ContentValues().apply {
                        put(CalendarContract.Calendars.ACCOUNT_NAME, finalAccountName)
                        put(CalendarContract.Calendars.ACCOUNT_TYPE, CalendarContract.ACCOUNT_TYPE_LOCAL)
                        put(CalendarContract.Calendars.NAME, title)
                        put(CalendarContract.Calendars.CALENDAR_DISPLAY_NAME, title)
                        put(CalendarContract.Calendars.CALENDAR_COLOR, color)
                        put(CalendarContract.Calendars.CALENDAR_ACCESS_LEVEL, CalendarContract.Calendars.CAL_ACCESS_OWNER)
                        put(CalendarContract.Calendars.OWNER_ACCOUNT, finalAccountName)
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
                                    id = finalAccountName,
                                    name = finalAccountName,
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
                                message = e.message,
                                details = e.cause
                            )
                        )
                    )
                }
            }
        }
    }

    override fun retrieveCalendars(
        onlyWritableCalendars: Boolean,
        account: Account?,
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

                    account?.let {
                        selection = CalendarContract.Calendars.ACCOUNT_NAME + " = ? AND " + CalendarContract.Calendars.ACCOUNT_TYPE + " = ?"
                        selectionArgs = arrayOf(it.name, it.type)
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
                            val displayAccountName = getSystemAccountLabel(accountType) ?: accountName

                            val isWritable = accessLevel >= CalendarContract.Calendars.CAL_ACCESS_CONTRIBUTOR
                            if (!onlyWritableCalendars || isWritable) {
                                val calendar = Calendar(
                                    id = id,
                                    title = displayName,
                                    color = color,
                                    isWritable = isWritable,
                                    account = Account(
                                        id = accountName,
                                        name = displayAccountName,
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
                                message = e.message,
                                details = e.cause
                            )
                        )
                    )
                }
            }

        }
    }

    override fun retrieveAccounts(callback: (Result<List<Account>>) -> Unit) {
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
                        CalendarContract.Calendars.ACCOUNT_NAME,
                        CalendarContract.Calendars.ACCOUNT_TYPE
                    )

                    val cursor = contentResolver.query(
                        calendarContentUri,
                        projection,
                        null,
                        null,
                        null
                    )

                    val accountsSet = mutableSetOf<Account>()

                    cursor?.use {
                        while (it.moveToNext()) {
                            val accountName = it.getString(it.getColumnIndexOrThrow(CalendarContract.Calendars.ACCOUNT_NAME))
                            val accountType = it.getString(it.getColumnIndexOrThrow(CalendarContract.Calendars.ACCOUNT_TYPE))
                            val displayAccountName = getSystemAccountLabel(accountType) ?: accountName

                            accountsSet.add(Account(
                                id = accountName,
                                name = displayAccountName,
                                type = accountType
                            ))
                        }
                    }

                    callback(Result.success(accountsSet.toList()))
                } catch (e: Exception) {
                    callback(
                        Result.failure(
                            FlutterError(
                                code = "GENERIC_ERROR",
                                message = e.message,
                                details = e.cause
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
                                message = e.message,
                                details = e.cause
                            )
                        )
                    )
                }
            }
        }
    }

    override fun updateCalendar(
        calendarId: String,
        title: String,
        color: Long,
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
                    if (isCalendarWritable(calendarId)) {
                        val values = ContentValues().apply {
                            put(CalendarContract.Calendars.NAME, title)
                            put(CalendarContract.Calendars.CALENDAR_DISPLAY_NAME, title)
                            put(CalendarContract.Calendars.CALENDAR_COLOR, color)
                        }

                        val selection = CalendarContract.Calendars._ID + " = ?"
                        val selectionArgs = arrayOf(calendarId)

                        val updated = contentResolver.update(calendarContentUri, values, selection, selectionArgs)
                        if (updated > 0) {
                            retrieveCalendar(calendarId, callback)
                        } else {
                            callback(
                                Result.failure(
                                    FlutterError(
                                        code = "NOT_FOUND",
                                        message = "Failed to update calendar"
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
                                message = e.message,
                                details = e.cause
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
        location: String?,
        reminders: List<Long>?,
        recurrenceRule: String?,
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
                    if (isCalendarWritable(calendarId)) {
                        val descriptionUrlHelper = DescriptionUrlHelper()
                        val mergedDescription = descriptionUrlHelper.mergeDescriptionAndUrl(description, url)

                        val eventValues = ContentValues().apply {
                            put(CalendarContract.Events.CALENDAR_ID, calendarId)
                            put(CalendarContract.Events.TITLE, title)
                            put(CalendarContract.Events.DESCRIPTION, mergedDescription)
                            put(CalendarContract.Events.EVENT_LOCATION, location)
                            put(CalendarContract.Events.DTSTART, startDate)
                            put(CalendarContract.Events.DTEND, endDate)
                            put(CalendarContract.Events.EVENT_TIMEZONE, "UTC")
                            put(CalendarContract.Events.ALL_DAY, isAllDay.toInt())
                            if (recurrenceRule != null) {
                                put(CalendarContract.Events.RRULE, recurrenceRule)
                            }
                        }

                        val eventUri = contentResolver.insert(eventContentUri, eventValues)
                        if (eventUri != null) {
                            val eventId = eventUri.lastPathSegment

                            if (reminders != null) {
                                val remindersLatch = CountDownLatch(reminders.size)
                                reminders.forEach { reminder ->
                                    val reminderValues = ContentValues().apply {
                                        put(CalendarContract.Reminders.EVENT_ID, eventId)
                                        put(CalendarContract.Reminders.MINUTES, reminder)
                                        put(CalendarContract.Reminders.METHOD, CalendarContract.Reminders.METHOD_ALERT)
                                    }
                                    contentResolver.insert(remindersContentUri, reminderValues)
                                    remindersLatch.countDown()
                                }
                                remindersLatch.await()
                            }

                            if (eventId != null) {
                                val event = Event(
                                    id = eventId,
                                    title = title,
                                    startDate = startDate,
                                    endDate = endDate,
                                    calendarId = calendarId,
                                    description = description,
                                    url = url,
                                    location = location,
                                    isAllDay = isAllDay,
                                    reminders = reminders ?: emptyList(),
                                    attendees = emptyList(),
                                    recurrenceRule = recurrenceRule,
                                    originalInstanceTime = null,
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
                                message = e.message,
                                details = e.cause
                            )
                        )
                    )
                }
            }
        }
    }

    override fun updateEvent(
        eventId: String,
        calendarId: String,
        title: String,
        startDate: Long,
        endDate: Long,
        isAllDay: Boolean,
        description: String?,
        url: String?,
        location: String?,
        reminders: List<Long>?,
        recurrenceRule: String?,
        span: String,
        originalInstanceTime: Long?,
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
                    if (isCalendarWritable(calendarId)) {
                        when (span) {
                            "thisEvent" -> if (originalInstanceTime != null) {
                                updateThisEventOccurrence(
                                    eventId, calendarId, title, startDate, endDate, isAllDay,
                                    description, url, location, reminders,
                                    originalInstanceTime, callback,
                                )
                            } else {
                                // No originalInstanceTime provided (e.g. non-recurring event, legacy
                                // caller) -- fall back to the "allEvents" behavior for backward compat.
                                updateAllEvents(
                                    eventId, calendarId, title, startDate, endDate, isAllDay,
                                    description, url, location, reminders, recurrenceRule, callback,
                                )
                            }
                            "thisAndFuture" -> if (originalInstanceTime != null) {
                                updateThisAndFutureEvents(
                                    eventId, calendarId, title, startDate, endDate, isAllDay,
                                    description, url, location, reminders, recurrenceRule,
                                    originalInstanceTime, callback,
                                )
                            } else {
                                updateAllEvents(
                                    eventId, calendarId, title, startDate, endDate, isAllDay,
                                    description, url, location, reminders, recurrenceRule, callback,
                                )
                            }
                            else -> updateAllEvents( // "allEvents" and unrecognized spans
                                eventId, calendarId, title, startDate, endDate, isAllDay,
                                description, url, location, reminders, recurrenceRule, callback,
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
                                message = e.message,
                                details = e.cause
                            )
                        )
                    )
                }
            }
        }
    }

    /**
     * Replaces all reminders for [targetEventId] with [reminders] (no-op when
     * [reminders] is null). Shared by all `updateEvent` span branches.
     */
    private fun replaceReminders(targetEventId: String, reminders: List<Long>?) {
        if (reminders == null) return

        val reminderSelection = CalendarContract.Reminders.EVENT_ID + " = ?"
        contentResolver.delete(remindersContentUri, reminderSelection, arrayOf(targetEventId))

        reminders.forEach { reminder ->
            val reminderValues = ContentValues().apply {
                put(CalendarContract.Reminders.EVENT_ID, targetEventId)
                put(CalendarContract.Reminders.MINUTES, reminder)
                put(CalendarContract.Reminders.METHOD, CalendarContract.Reminders.METHOD_ALERT)
            }
            contentResolver.insert(remindersContentUri, reminderValues)
        }
    }

    /**
     * "allEvents" span (and safe fallback for unrecognized spans): updates the
     * master event row in place, exactly as the pre-recurrence `updateEvent`
     * behaved, plus persisting [recurrenceRule] on the master row when provided.
     */
    private fun updateAllEvents(
        eventId: String,
        calendarId: String,
        title: String,
        startDate: Long,
        endDate: Long,
        isAllDay: Boolean,
        description: String?,
        url: String?,
        location: String?,
        reminders: List<Long>?,
        recurrenceRule: String?,
        callback: (Result<Event>) -> Unit,
    ) {
        val descriptionUrlHelper = DescriptionUrlHelper()
        val mergedDescription = descriptionUrlHelper.mergeDescriptionAndUrl(description, url)

        val eventValues = ContentValues().apply {
            put(CalendarContract.Events.CALENDAR_ID, calendarId)
            put(CalendarContract.Events.TITLE, title)
            put(CalendarContract.Events.DESCRIPTION, mergedDescription)
            put(CalendarContract.Events.EVENT_LOCATION, location)
            put(CalendarContract.Events.DTSTART, startDate)
            put(CalendarContract.Events.DTEND, endDate)
            put(CalendarContract.Events.EVENT_TIMEZONE, "UTC")
            put(CalendarContract.Events.ALL_DAY, if (isAllDay) 1 else 0)
            if (recurrenceRule != null) put(CalendarContract.Events.RRULE, recurrenceRule)
        }

        val selection = CalendarContract.Events._ID + " = ?"
        val selectionArgs = arrayOf(eventId)

        val updated = contentResolver.update(eventContentUri, eventValues, selection, selectionArgs)

        replaceReminders(eventId, reminders)

        if (updated > 0) {
            retrieveEvent(eventId, callback)
        } else {
            callback(
                Result.failure(
                    FlutterError(
                        code = "NOT_FOUND",
                        message = "Failed to update event"
                    )
                )
            )
        }
    }

    /**
     * "thisEvent" span: inserts a new recurrence-exception row (rather than
     * updating the master row), carrying the edited fields for that single
     * occurrence only.
     */
    private fun updateThisEventOccurrence(
        eventId: String,
        calendarId: String,
        title: String,
        startDate: Long,
        endDate: Long,
        isAllDay: Boolean,
        description: String?,
        url: String?,
        location: String?,
        reminders: List<Long>?,
        originalInstanceTime: Long,
        callback: (Result<Event>) -> Unit,
    ) {
        val descriptionUrlHelper = DescriptionUrlHelper()
        val mergedDescription = descriptionUrlHelper.mergeDescriptionAndUrl(description, url)

        val values = ContentValues().apply {
            put(CalendarContract.Events.ORIGINAL_ID, eventId.toLong())
            put(CalendarContract.Events.ORIGINAL_INSTANCE_TIME, originalInstanceTime)
            put(CalendarContract.Events.DTSTART, startDate)
            put(CalendarContract.Events.DTEND, endDate)
            put(CalendarContract.Events.ALL_DAY, if (isAllDay) 1 else 0)
            put(CalendarContract.Events.TITLE, title)
            put(CalendarContract.Events.DESCRIPTION, mergedDescription)
            put(CalendarContract.Events.EVENT_LOCATION, location)
            put(CalendarContract.Events.CALENDAR_ID, calendarId.toLong())
            put(CalendarContract.Events.EVENT_TIMEZONE, "UTC")
            put(CalendarContract.Events.STATUS, CalendarContract.Events.STATUS_CONFIRMED)
        }

        val uri = contentResolver.insert(eventContentUri, values)
        val newId = uri?.lastPathSegment ?: eventId

        replaceReminders(newId, reminders)

        retrieveEvent(newId, callback)
    }

    /**
     * "thisAndFuture" span: truncates the existing master series with an
     * UNTIL right before [originalInstanceTime] (when it recurs), then inserts
     * a brand-new master event starting at [originalInstanceTime] carrying the
     * edited fields and continuing the series (using [recurrenceRule] if
     * provided, otherwise the old RRULE stripped of any COUNT/UNTIL so the new
     * tail continues indefinitely unless the caller set a new end condition).
     */
    private fun updateThisAndFutureEvents(
        eventId: String,
        calendarId: String,
        title: String,
        startDate: Long,
        endDate: Long,
        isAllDay: Boolean,
        description: String?,
        url: String?,
        location: String?,
        reminders: List<Long>?,
        recurrenceRule: String?,
        originalInstanceTime: Long,
        callback: (Result<Event>) -> Unit,
    ) {
        val existingRrule = RecurrenceHelper.getMasterRrule(contentResolver, eventContentUri, eventId)
        if (existingRrule != null) {
            val patchedRrule = RecurrenceHelper.patchWithUntil(existingRrule, originalInstanceTime)
            val truncateValues = ContentValues().apply { put(CalendarContract.Events.RRULE, patchedRrule) }
            val selection = CalendarContract.Events._ID + " = ?"
            val selectionArgs = arrayOf(eventId)
            contentResolver.update(eventContentUri, truncateValues, selection, selectionArgs)
        }

        val newRrule = recurrenceRule
            ?: existingRrule?.let { RecurrenceHelper.stripUntilAndCount(it) }

        val duration = endDate - startDate
        val descriptionUrlHelper = DescriptionUrlHelper()
        val mergedDescription = descriptionUrlHelper.mergeDescriptionAndUrl(description, url)

        val insertValues = ContentValues().apply {
            put(CalendarContract.Events.CALENDAR_ID, calendarId.toLong())
            put(CalendarContract.Events.TITLE, title)
            put(CalendarContract.Events.DTSTART, originalInstanceTime)
            put(CalendarContract.Events.DTEND, originalInstanceTime + duration)
            put(CalendarContract.Events.ALL_DAY, if (isAllDay) 1 else 0)
            put(CalendarContract.Events.DESCRIPTION, mergedDescription)
            put(CalendarContract.Events.EVENT_LOCATION, location)
            put(CalendarContract.Events.EVENT_TIMEZONE, "UTC")
            if (newRrule != null) put(CalendarContract.Events.RRULE, newRrule)
        }

        val uri = contentResolver.insert(eventContentUri, insertValues)
        val newId = uri?.lastPathSegment ?: eventId

        replaceReminders(newId, reminders)

        retrieveEvent(newId, callback)
    }

    override fun createEventInDefaultCalendar(
        title: String,
        startDate: Long,
        endDate: Long,
        isAllDay: Boolean,
        description: String?,
        url: String?,
        location: String?,
        reminders: List<Long>?,
        recurrenceRule: String?,
        callback: (Result<Unit>) -> Unit
    ) = shareEventAsIcs(
        title = title,
        startDate = startDate,
        endDate = endDate,
        isAllDay = isAllDay,
        description = description,
        url = url,
        location = location,
        reminders = reminders,
        recurrenceRule = recurrenceRule,
        callback = callback
    )

    override fun createEventThroughNativePlatform(
        title: String?,
        startDate: Long?,
        endDate: Long?,
        isAllDay: Boolean?,
        description: String?,
        url: String?,
        location: String?,
        reminders: List<Long>?,
        recurrenceRule: String?,
        callback: (Result<Unit>) -> Unit
    ) = shareEventAsIcs(
        title = title,
        startDate = startDate,
        endDate = endDate,
        isAllDay = isAllDay,
        description = description,
        url = url,
        location = location,
        reminders = reminders,
        recurrenceRule = recurrenceRule,
        callback = callback
    )

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
                    val instancesUri = (instancesContentUri ?: CalendarContract.Instances.CONTENT_URI).buildUpon()
                        .appendPath(startDate.toString())
                        .appendPath(endDate.toString())
                        .build()

                    val projection = arrayOf(
                        CalendarContract.Instances.EVENT_ID,
                        CalendarContract.Instances.TITLE,
                        CalendarContract.Instances.DESCRIPTION,
                        CalendarContract.Instances.EVENT_LOCATION,
                        CalendarContract.Instances.BEGIN,
                        CalendarContract.Instances.END,
                        CalendarContract.Instances.RRULE,
                        CalendarContract.Instances.ALL_DAY,
                    )
                    val selection = CalendarContract.Instances.CALENDAR_ID + " = ?"
                    val selectionArgs = arrayOf(calendarId)

                    val cursor = contentResolver.query(instancesUri, projection, selection, selectionArgs, null)
                    val events = mutableListOf<Event>()

                    cursor?.use { c ->
                        val descriptionUrlHelper = DescriptionUrlHelper()
                        while (c.moveToNext()) {
                            val id = c.getString(c.getColumnIndexOrThrow(CalendarContract.Instances.EVENT_ID))
                            val title = c.getString(c.getColumnIndexOrThrow(CalendarContract.Instances.TITLE))
                            val storedDescription =
                                c.getString(c.getColumnIndexOrThrow(CalendarContract.Instances.DESCRIPTION))
                            val (parsedDescription, parsedUrl) = descriptionUrlHelper.splitDescriptionAndUrl(storedDescription)
                            val eventLocation = c.getString(c.getColumnIndexOrThrow(CalendarContract.Instances.EVENT_LOCATION))
                            val start = c.getLong(c.getColumnIndexOrThrow(CalendarContract.Instances.BEGIN))
                            val end = c.getLong(c.getColumnIndexOrThrow(CalendarContract.Instances.END))
                            val recurrenceRule = c.getString(c.getColumnIndexOrThrow(CalendarContract.Instances.RRULE))
                            val isAllDay = c.getInt(c.getColumnIndexOrThrow(CalendarContract.Instances.ALL_DAY)).toBoolean()

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
                                    description = parsedDescription,
                                    url = parsedUrl,
                                    location = eventLocation,
                                    isAllDay = isAllDay,
                                    reminders = reminders,
                                    attendees = attendees,
                                    recurrenceRule = recurrenceRule,
                                    originalInstanceTime = if (recurrenceRule != null) start else null
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
                                message = e.message,
                                details = e.cause
                            )
                        )
                    )
                }
            }

        }
    }

    override fun deleteEvent(eventId: String, span: String, originalInstanceTime: Long?, callback: (Result<Unit>) -> Unit) {
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
                        when (span) {
                            "thisEvent" -> if (originalInstanceTime != null) {
                                deleteThisEventOccurrence(eventId, calendarId, originalInstanceTime, callback)
                            } else {
                                // No originalInstanceTime provided (e.g. non-recurring event, legacy
                                // caller) -- fall back to the "allEvents" behavior for backward compat.
                                deleteMasterEventRow(eventId, callback)
                            }
                            "thisAndFuture" -> if (originalInstanceTime != null) {
                                deleteThisAndFutureEvents(eventId, originalInstanceTime, callback)
                            } else {
                                deleteMasterEventRow(eventId, callback)
                            }
                            else -> deleteMasterEventRow(eventId, callback) // "allEvents" and unknown spans
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
                                message = e.message,
                                details = e.cause
                            )
                        )
                    )
                }
            }
        }
    }

    /**
     * Deletes the master event row (and, transitively, all of its recurrence
     * exceptions/instances). Used for the "allEvents" span, and as a safe
     * fallback for unrecognized spans or non-recurring events.
     */
    private fun deleteMasterEventRow(eventId: String, callback: (Result<Unit>) -> Unit) {
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
    }

    /**
     * "thisEvent" span: instead of removing the master row, inserts a
     * canceled recurrence exception row for [originalInstanceTime], leaving
     * the rest of the series untouched.
     */
    private fun deleteThisEventOccurrence(
        eventId: String,
        calendarId: String,
        originalInstanceTime: Long,
        callback: (Result<Unit>) -> Unit,
    ) {
        val durationMs = RecurrenceHelper.getMasterEventDurationMs(contentResolver, eventContentUri, eventId)

        val values = ContentValues().apply {
            put(CalendarContract.Events.ORIGINAL_ID, eventId.toLong())
            put(CalendarContract.Events.ORIGINAL_INSTANCE_TIME, originalInstanceTime)
            put(CalendarContract.Events.DTSTART, originalInstanceTime)
            put(CalendarContract.Events.DTEND, originalInstanceTime + durationMs)
            put(CalendarContract.Events.STATUS, CalendarContract.Events.STATUS_CANCELED)
            put(CalendarContract.Events.CALENDAR_ID, calendarId.toLong())
            put(CalendarContract.Events.EVENT_TIMEZONE, "UTC")
        }

        contentResolver.insert(eventContentUri, values)
        callback(Result.success(Unit))
    }

    /**
     * "thisAndFuture" span: patches the master event's RRULE with an UNTIL
     * that ends the series right before [originalInstanceTime], so the target
     * occurrence and all later ones are dropped. Falls back to deleting the
     * whole master row when the event is not recurring (no RRULE).
     */
    private fun deleteThisAndFutureEvents(
        eventId: String,
        originalInstanceTime: Long,
        callback: (Result<Unit>) -> Unit,
    ) {
        val rrule = RecurrenceHelper.getMasterRrule(contentResolver, eventContentUri, eventId)
        if (rrule == null) {
            deleteMasterEventRow(eventId, callback)
            return
        }

        val patchedRrule = RecurrenceHelper.patchWithUntil(rrule, originalInstanceTime)
        val values = ContentValues().apply {
            put(CalendarContract.Events.RRULE, patchedRrule)
        }

        val selection = CalendarContract.Events._ID + " = ?"
        val selectionArgs = arrayOf(eventId)
        contentResolver.update(eventContentUri, values, selection, selectionArgs)
        callback(Result.success(Unit))
    }

    override fun createReminder(reminder: Long, eventId: String, callback: (Result<Event>) -> Unit) {
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
                        put(CalendarContract.Reminders.EVENT_ID, eventId)
                        put(CalendarContract.Reminders.MINUTES, reminder)
                        put(CalendarContract.Reminders.METHOD, CalendarContract.Reminders.METHOD_ALERT)
                    }
                    contentResolver.insert(remindersContentUri, values)

                    retrieveEvent(eventId, callback)

                } catch (e: Exception) {
                    callback(
                        Result.failure(
                            FlutterError(
                                code = "GENERIC_ERROR",
                                message = e.message,
                                details = e.cause
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
                                message = e.message,
                                details = e.cause
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
                                message = e.message,
                                details = e.cause
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
                                message = e.message,
                                details = e.cause
                            )
                        )
                    )
                }
            }
        }
    }

    // ------------------- Private methods -------------------
    private fun retrieveCalendar(calendarId: String, callback: (Result<Calendar>) -> Unit) {
        try {
            val projection = arrayOf(
                CalendarContract.Calendars._ID,
                CalendarContract.Calendars.CALENDAR_DISPLAY_NAME,
                CalendarContract.Calendars.CALENDAR_COLOR,
                CalendarContract.Calendars.CALENDAR_ACCESS_LEVEL,
                CalendarContract.Calendars.ACCOUNT_NAME,
                CalendarContract.Calendars.ACCOUNT_TYPE
            )
            val selection = CalendarContract.Calendars._ID + " = ?"
            val selectionArgs = arrayOf(calendarId)

            val cursor = contentResolver.query(calendarContentUri, projection, selection, selectionArgs, null)
            cursor?.use {
                if (it.moveToNext()) {
                    val id = it.getString(it.getColumnIndexOrThrow(CalendarContract.Calendars._ID))
                    val displayName = it.getString(it.getColumnIndexOrThrow(CalendarContract.Calendars.CALENDAR_DISPLAY_NAME))
                    val color = it.getLong(it.getColumnIndexOrThrow(CalendarContract.Calendars.CALENDAR_COLOR))
                    val accessLevel = it.getInt(it.getColumnIndexOrThrow(CalendarContract.Calendars.CALENDAR_ACCESS_LEVEL))
                    val accountName = it.getString(it.getColumnIndexOrThrow(CalendarContract.Calendars.ACCOUNT_NAME))
                    val accountType = it.getString(it.getColumnIndexOrThrow(CalendarContract.Calendars.ACCOUNT_TYPE))
                    val displayAccountName = getSystemAccountLabel(accountType) ?: accountName

                    val isWritable = accessLevel >= CalendarContract.Calendars.CAL_ACCESS_CONTRIBUTOR
                    callback(
                        Result.success(
                            Calendar(
                                id = id,
                                title = displayName,
                                color = color,
                                isWritable = isWritable,
                                account = Account(
                                    id = accountName,
                                    name = displayAccountName,
                                    type = accountType
                                )
                            )
                        )
                    )
                } else {
                    callback(
                        Result.failure(
                            FlutterError(
                                code = "NOT_FOUND",
                                message = "Failed to retrieve calendar"
                            )
                        )
                    )
                }
            } ?: callback(
                Result.failure(
                    FlutterError(
                        code = "GENERIC_ERROR",
                        message = "An error occurred"
                    )
                )
            )
        } catch (e: Exception) {
            callback(
                Result.failure(
                    FlutterError(
                        code = "GENERIC_ERROR",
                        message = e.message,
                        details = e.cause
                    )
                )
            )
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
                CalendarContract.Events.EVENT_LOCATION,
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
                val descriptionUrlHelper = DescriptionUrlHelper()
                if (it.moveToNext()) {
                    val id = it.getString(it.getColumnIndexOrThrow(CalendarContract.Events._ID))
                    val title = it.getString(it.getColumnIndexOrThrow(CalendarContract.Events.TITLE))
                    val storedDescription = it.getString(it.getColumnIndexOrThrow(CalendarContract.Events.DESCRIPTION))
                    val (parsedDescription, parsedUrl) = descriptionUrlHelper.splitDescriptionAndUrl(storedDescription)
                    val eventLocation = it.getString(it.getColumnIndexOrThrow(CalendarContract.Events.EVENT_LOCATION))
                    val isAllDay = it.getInt(it.getColumnIndexOrThrow(CalendarContract.Events.ALL_DAY)).toBoolean()
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
                        description = parsedDescription,
                        url = parsedUrl,
                        location = eventLocation,
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
                        message = e.message,
                        details = e.cause
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
                    message = e.message,
                    details = e.cause
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
                    message = e.message,
                    details = e.cause
                )
            ))
        }
    }

    private fun getSystemAccountLabel(accountType: String): String? {
        val authenticator = accountManager.authenticatorTypes.find { it.type == accountType }

        return authenticator?.let { auth ->
            try {
                packageManager.getText(auth.packageName, auth.labelId, null)?.toString()
            } catch (_: Exception) {
                null
            }
        }
    }

    private fun shareEventAsIcs(
        title: String?,
        startDate: Long?,
        endDate: Long?,
        isAllDay: Boolean?,
        description: String?,
        url: String?,
        location: String?,
        reminders: List<Long>?,
        recurrenceRule: String?,
        callback: (Result<Unit>) -> Unit
    ) {
        try {
            val descriptionUrlHelper = DescriptionUrlHelper()
            val mergedDescription = descriptionUrlHelper.mergeDescriptionAndUrl(description, url)
            val icsContent = icsEventManager.generateIcsContent(
                title = title,
                startDate = startDate,
                endDate = endDate,
                isAllDay = isAllDay,
                description = mergedDescription,
                location = location,
                reminders = reminders,
                recurrenceRule = recurrenceRule
            )

            calendarActivityManager.createShareIntent(icsContent) {
                callback(Result.success(Unit))
            }
        } catch (e: Exception) {
            callback(
                Result.failure(
                    FlutterError(
                        code = "GENERIC_ERROR",
                        message = e.message,
                        details = e.cause
                    )
                )
            )
        }
    }
}

private fun Boolean.toInt() = if (this) 1 else 0

private fun Int.toBoolean() = this != 0
