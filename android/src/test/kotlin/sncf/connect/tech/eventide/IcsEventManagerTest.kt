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
}
