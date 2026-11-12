package sncf.connect.tech.eventide

import android.content.Context
import io.mockk.*
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import sncf.connect.tech.eventide.handler.IcsEventManager
import java.io.File
import kotlin.test.assertTrue

class IcsEventManagerTest {
    private lateinit var context: Context
    private lateinit var icsEventManager: IcsEventManager
    private lateinit var cacheDir: File

    @BeforeEach
    fun setUp() {
        context = mockk(relaxed = true)
        cacheDir = mockk(relaxed = true)
        every { context.cacheDir } returns cacheDir
        every { context.packageName } returns "sncf.connect.tech.eventide"
        icsEventManager = IcsEventManager(context)
    }

    @Test
    fun `generateIcsContent contains no blank lines`() {
        val icsContent = icsEventManager.generateIcsContent(
            title = "Event",
            description = "Desc",
            location = "Paris",
            startDate = 1700000000000L,
            endDate = 1700003600000L,
            reminders = listOf(10L),
            isAllDay = false
        )

        val lines = icsContent.split("\r\n").dropLast(1) // drop trailing empty string after final CRLF
        val blankLines = lines.filter { it.isBlank() }
        assertTrue(blankLines.isEmpty(), "ICS content must not contain blank lines (RFC 5545), found ${blankLines.size}")
    }

    @Test
    fun `generateIcsContent uses CRLF line endings`() {
        val icsContent = icsEventManager.generateIcsContent(
            title = "Event",
            description = "Desc",
            location = "Paris",
            startDate = 1700000000000L,
            endDate = 1700003600000L,
            reminders = listOf(10L),
            isAllDay = false
        )

        assertTrue(!icsContent.contains("\r\n\r\n"), "ICS content must not contain blank lines")
        val lines = icsContent.split("\r\n").dropLast(1)
        assertTrue(lines.isNotEmpty(), "ICS content must contain CRLF-terminated lines")
        assertTrue(
            !icsContent.replace("\r\n", "").contains("\n"),
            "ICS content must use CRLF line endings only (RFC 5545), no bare LF allowed"
        )
    }

    @Test
    fun `generateIcsContent with all fields filled and reminders`() {
        val icsContent = icsEventManager.generateIcsContent(
            title = "Réunion importante",
            description = "Description de l'événement\n\nhttps://sncf.com",
            location = "Paris",
            startDate = 1700000000000L,
            endDate = 1700003600000L,
            reminders = listOf(10L, 30L),
            isAllDay = false
        )

        assertTrue(icsContent.contains("SUMMARY:Réunion importante"))
        assertTrue(icsContent.contains("DESCRIPTION:Description de l'événement\\n\\nhttps://sncf.com"))
        assertTrue(icsContent.contains("LOCATION:Paris"))
        assertTrue(icsContent.contains("BEGIN:VALARM"))
        assertTrue(icsContent.contains("TRIGGER:-PT10M"))
        assertTrue(icsContent.contains("TRIGGER:-PT30M"))
    }

    @Test
    fun `generateIcsContent includes RRULE line when recurrenceRule is provided`() {
        val ics = icsEventManager.generateIcsContent(
            title = "Standup",
            startDate = 1751880000000L,
            endDate = 1751883600000L,
            isAllDay = false,
            description = null,
            location = null,
            reminders = emptyList(),
            recurrenceRule = "FREQ=WEEKLY;BYDAY=MO",
        )
        assertTrue(ics.contains("RRULE:FREQ=WEEKLY;BYDAY=MO"), "Expected RRULE line, got:\n$ics")
    }

    @Test
    fun `generateIcsContent omits RRULE line when recurrenceRule is null`() {
        val ics = icsEventManager.generateIcsContent(
            title = "Standup",
            startDate = 1751880000000L,
            endDate = 1751883600000L,
            isAllDay = false,
            description = null,
            location = null,
            reminders = emptyList(),
            recurrenceRule = null,
        )
        assertTrue(!ics.contains("RRULE:"), "Expected no RRULE line, got:\n$ics")
    }
}
