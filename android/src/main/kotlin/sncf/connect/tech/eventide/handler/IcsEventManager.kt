package sncf.connect.tech.eventide.handler

import android.content.Context
import java.text.SimpleDateFormat
import java.util.*

class IcsEventManager(private val context: Context) {
    private val icsDateTimeFormat = SimpleDateFormat("yyyyMMdd'T'HHmmss'Z'", Locale.US).apply {
        timeZone = TimeZone.getTimeZone("UTC")
    }
    private val icsDateFormat = SimpleDateFormat("yyyyMMdd", Locale.US).apply {
        timeZone = TimeZone.getDefault()
    }

    /**
     * https://datatracker.ietf.org/doc/html/rfc5545#section-3.6.1
     */
    fun generateIcsContent(
        title: String?,
        startDate: Long?,
        endDate: Long?,
        isAllDay: Boolean?,
        description: String?,
        location: String?,
        reminders: List<Long>?
    ): String = StringBuilder().apply {
        val prodId = "-//${context.packageName}//EventidePlugin//FR"

        appendLine("BEGIN:VCALENDAR\n")
        appendLine("VERSION:2.0\n")
        appendLine("PRODID:$prodId\n")
        appendLine("CALSCALE:GREGORIAN")
        appendLine("BEGIN:VEVENT\n")

        appendLine("UID:${UUID.randomUUID()}@${context.packageName}")
        appendLine("DTSTAMP:${icsDateTimeFormat.format(Calendar.getInstance().getTime())}")

        val startDate = startDate ?: Calendar.getInstance().timeInMillis
        val endDate = endDate ?: (startDate + 60 * 60 * 1000)

        if (isAllDay ?: false) {
            appendLine("DTSTART;VALUE=DATE:${icsDateFormat.format(Date(startDate))}\n")
            appendLine("DTEND;VALUE=DATE:${icsDateFormat.format(Date(endDate))}\n")
        } else {
            appendLine("DTSTART:${icsDateTimeFormat.format(Date(startDate))}\n")
            appendLine("DTEND:${icsDateTimeFormat.format(Date(endDate))}\n")
        }

        title?.let { appendLine(foldLine("SUMMARY:${escape(it)}\n")) }
        description?.let { appendLine(foldLine("DESCRIPTION:${escape(it)}\n")) }
        location?.let { appendLine(foldLine("LOCATION:${escape(it)}\n")) }

        reminders?.forEach { minutes ->
            appendLine("BEGIN:VALARM\n")
            appendLine("TRIGGER:-PT${minutes}M\n")
            appendLine("ACTION:DISPLAY\n")
            appendLine("END:VALARM\n")
        }

        appendLine("END:VEVENT\n")
        appendLine("END:VCALENDAR")
    }.toString()

    /**
     * https://datatracker.ietf.org/doc/html/rfc5545#section-3.3.11
     */
    private fun escape(str: String): String = str
        .replace("\\", "\\\\")
        .replace(";", "\\;")
        .replace(",", "\\,")
        .replace("\n", "\\n")

    /**
     * https://datatracker.ietf.org/doc/html/rfc5545#section-3.1
     */
    private fun foldLine(line: String): String {
        val sb = StringBuilder()
        var currentLine = line
        while (currentLine.length > 75) {
            sb.append(currentLine.take(75)).append("\r\n ")
            currentLine = currentLine.substring(75)
        }
        sb.append(currentLine).append("\r\n")
        return sb.toString()
    }
}
