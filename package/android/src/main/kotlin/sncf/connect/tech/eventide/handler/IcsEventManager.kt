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
        reminders: List<Long>?,
        recurrenceRule: String? = null
    ): String = StringBuilder().apply {
        val prodId = "-//${context.packageName}//EventidePlugin//FR"

        crlf("BEGIN:VCALENDAR")
        crlf("VERSION:2.0")
        crlf("PRODID:$prodId")
        crlf("CALSCALE:GREGORIAN")
        crlf("BEGIN:VEVENT")

        crlf("UID:${UUID.randomUUID()}@${context.packageName}")
        crlf("DTSTAMP:${icsDateTimeFormat.format(Calendar.getInstance().getTime())}")

        val startDate = startDate ?: Calendar.getInstance().timeInMillis
        val endDate = endDate ?: (startDate + 60 * 60 * 1000)

        if (isAllDay ?: false) {
            crlf("DTSTART;VALUE=DATE:${icsDateFormat.format(Date(startDate))}")
            crlf("DTEND;VALUE=DATE:${icsDateFormat.format(Date(endDate))}")
        } else {
            crlf("DTSTART:${icsDateTimeFormat.format(Date(startDate))}")
            crlf("DTEND:${icsDateTimeFormat.format(Date(endDate))}")
        }

        recurrenceRule?.let { crlf("RRULE:$it") }

        title?.let { append(foldLine("SUMMARY:${escape(it)}")) }
        description?.let { append(foldLine("DESCRIPTION:${escape(it)}")) }
        location?.let { append(foldLine("LOCATION:${escape(it)}")) }

        reminders?.forEach { minutes ->
            crlf("BEGIN:VALARM")
            crlf("TRIGGER:-PT${minutes}M")
            crlf("ACTION:DISPLAY")
            crlf("END:VALARM")
        }

        crlf("END:VEVENT")
        crlf("END:VCALENDAR")
    }.toString()

    private fun StringBuilder.crlf(line: String) = append(line).append("\r\n")

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
     * Folds on 75-byte boundaries (not characters) as required by RFC 5545.
     */
    private fun foldLine(line: String): String {
        val sb = StringBuilder()
        val bytes = line.toByteArray(Charsets.UTF_8)
        var offset = 0
        var firstChunk = true
        
        while (offset < bytes.size) {
            val limit = if (firstChunk) 75 else 74 // continuation lines start with a space (1 byte)
            val chunkBytes = bytes.copyOfRange(offset, minOf(offset + limit, bytes.size))
            
            // Trim to a valid UTF-8 boundary
            var chunkLen = chunkBytes.size
        
            // Find the last non-continuation byte
            var leadPos = chunkLen - 1
        
            while (leadPos >= 0 && (chunkBytes[leadPos].toInt() and 0xC0) == 0x80) {
                leadPos--
            }

            // If that leading byte starts an incomplete multi-byte sequence, exclude it too
            if (leadPos >= 0) {
                val leadByte = chunkBytes[leadPos].toInt() and 0xFF
                
                val expectedContinuation = when {
                    leadByte and 0xE0 == 0xC0 -> 1
                    leadByte and 0xF0 == 0xE0 -> 2
                    leadByte and 0xF8 == 0xF0 -> 3
                    else -> 0
                }

                if (chunkLen - 1 - leadPos < expectedContinuation) {
                    chunkLen = leadPos
                }
            }

            val chunk = String(bytes.copyOfRange(offset, offset + chunkLen), Charsets.UTF_8)
            
            if (!firstChunk) {
                sb.append(' ')
            }

            sb.append(chunk)
            offset += chunkLen
            
            if (offset < bytes.size) {
                sb.append("\r\n")
            }

            firstChunk = false
        }

        sb.append("\r\n")
        
        return sb.toString()
    }
}
