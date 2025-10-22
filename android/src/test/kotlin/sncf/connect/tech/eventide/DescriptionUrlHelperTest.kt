package sncf.connect.tech.eventide

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

class DescriptionUrlHelperTest {

    @Test
    fun merge_bothProvided_returnsDescriptionAndUrlSeparated() {
        val desc = "Team meeting"
        val url = "https://meet.example/abc"
        val merged = DescriptionUrlHelper.mergeDescriptionAndUrl(desc, url)
        assertEquals("Team meeting\n\nhttps://meet.example/abc", merged)
    }

    @Test
    fun merge_descriptionNull_returnsUrl() {
        val merged = DescriptionUrlHelper.mergeDescriptionAndUrl(null, "https://example.com")
        assertEquals("https://example.com", merged)
    }

    @Test
    fun merge_urlNull_returnsDescription() {
        val merged = DescriptionUrlHelper.mergeDescriptionAndUrl("Simple text", null)
        assertEquals("Simple text", merged)
    }

    @Test
    fun merge_bothBlank_returnsNull() {
        val merged = DescriptionUrlHelper.mergeDescriptionAndUrl("   ", "  ")
        assertNull(merged)
    }

    @Test
    fun split_doubleNewline_extractsUrl() {
        val stored = "Event details\n\nhttps://example.com/path"
        val (desc, url) = DescriptionUrlHelper.splitDescriptionAndUrl(stored)
        assertEquals("Event details", desc)
        assertEquals("https://example.com/path", url)
    }

    @Test
    fun split_urlOnly_returnsUrlAndNullDescription() {
        val stored = "https://only.example"
        val (desc, url) = DescriptionUrlHelper.splitDescriptionAndUrl(stored)
        assertNull(desc)
        assertEquals("https://only.example", url)
    }

    @Test
    fun split_lastLineUrl_withoutDoubleNewline_extractsUrl() {
        val stored = "First line\nhttps://last.example"
        val (desc, url) = DescriptionUrlHelper.splitDescriptionAndUrl(stored)
        assertEquals("First line", desc)
        assertEquals("https://last.example", url)
    }

    @Test
    fun split_urlEmbeddedInText_doesNotExtract() {
        val stored = "Visit https://example.com for more information"
        val (desc, url) = DescriptionUrlHelper.splitDescriptionAndUrl(stored)
        assertEquals("Visit https://example.com for more information", desc)
        assertNull(url)
    }

    @Test
    fun split_emptyOrBlank_returnsNulls() {
        val (d1, u1) = DescriptionUrlHelper.splitDescriptionAndUrl(null)
        assertNull(d1)
        assertNull(u1)

        val (d2, u2) = DescriptionUrlHelper.splitDescriptionAndUrl("   ")
        assertNull(d2)
        assertNull(u2)
    }

    @Test
    fun split_urlWithTrailingPunctuation_stripsPunctuation() {
        val stored = "Note\n\nhttps://example.com/page."
        val (desc, url) = DescriptionUrlHelper.splitDescriptionAndUrl(stored)
        assertEquals("Note", desc)
        // trailing '.' should be removed by the helper
        assertEquals("https://example.com/page", url)
    }
}
