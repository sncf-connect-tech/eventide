package sncf.connect.tech.eventide

import android.content.ContentResolver
import android.content.ContentValues
import android.provider.CalendarContract
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale
import java.util.TimeZone

/**
 * Helper object for formatting dates/times into iCalendar (RFC 5545) strings.
 * Assumes all date/time inputs are in UTC.
 */
object ICalendarFormatter {

    /**
     * Formats a given timestamp into an iCalendar string.
     * All dates/times are treated as UTC.
     *
     * @param timestampMillis The timestamp in milliseconds (expected to be in UTC).
     * @param isAllDay True if the event is an all-day event.
     * If true, format will be YYYYMMDD.
     * If false, format will be YYYYMMDDTHHmmssZ.
     * @return The formatted iCalendar date/time string.
     */
    fun formatDateTimeForICalendarUtc(timestampMillis: Long, isAllDay: Boolean): String {
        val calendar = Calendar.getInstance()
        calendar.timeInMillis = timestampMillis

        val sdf: SimpleDateFormat

        if (isAllDay) {
            sdf = SimpleDateFormat("yyyyMMdd", Locale.US)
            sdf.timeZone = TimeZone.getTimeZone("UTC")
        } else {
            sdf = SimpleDateFormat("yyyyMMdd'T'HHmmss'Z'", Locale.US)
            sdf.timeZone = TimeZone.getTimeZone("UTC")
        }

        return sdf.format(calendar.time)
    }
}

/**
 * Adds one or more exception dates (EXDATEs) to a recurring event in CalendarContract.
 *
 * @param contentResolver The ContentResolver instance.
 * @param eventId The `_ID` of the main recurring event to modify.
 * @param occurrencesToExcludeMillis An array of timestamps (in UTC) for the specific occurrences
 * that should be excluded from the recurring series.
 * @param isRecurringEventAllDay True if the recurring event itself is an all-day event.
 * This affects the EXDATE format.
 * @return True if the update was successful, false otherwise.
 */
fun addExdatesToRecurringEvent(
    contentResolver: ContentResolver,
    eventId: Long,
    occurrencesToExcludeMillis: LongArray,
    isRecurringEventAllDay: Boolean
): Boolean {
    val eventUri = CalendarContract.Events.CONTENT_URI.buildUpon().appendPath(eventId.toString()).build()
    val projection = arrayOf(CalendarContract.Events.EXDATE)
    var existingExdate: String? = null

    contentResolver.query(eventUri, projection, null, null, null)?.use { cursor ->
        if (cursor.moveToFirst()) {
            val exdateColumnIndex = cursor.getColumnIndex(CalendarContract.Events.EXDATE)
            if (exdateColumnIndex != -1) {
                existingExdate = cursor.getString(exdateColumnIndex)
            }
        }
    }

    // 2. Build the new EXDATE string
    val exdateBuilder = StringBuilder(existingExdate ?: "")

    for (timestamp in occurrencesToExcludeMillis) {
        val formattedDate = ICalendarFormatter.formatDateTimeForICalendarUtc(timestamp, isRecurringEventAllDay)
        if (exdateBuilder.isNotEmpty()) {
            exdateBuilder.append(",")
        }
        exdateBuilder.append(formattedDate)
    }

    val finalExdate = exdateBuilder.toString()

    // 3. Update the event with the new EXDATE string
    val values = ContentValues().apply {
        put(CalendarContract.Events.EXDATE, finalExdate)
    }

    val rowsAffected = contentResolver.update(eventUri, values, null, null)

    return rowsAffected > 0
}
