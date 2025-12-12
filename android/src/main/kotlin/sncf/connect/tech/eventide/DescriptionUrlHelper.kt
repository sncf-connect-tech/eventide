package sncf.connect.tech.eventide

class DescriptionUrlHelper {
    fun mergeDescriptionAndUrl(description: String?, url: String?): String? {
        val desc = description?.trim().takeIf { !it.isNullOrBlank() }
        val u = url?.trim().takeIf { !it.isNullOrBlank() }
        return when {
            desc == null && u == null -> null
            desc == null -> u
            u == null -> desc
            else -> "${desc}\n\n${u}"
        }
    }

    fun splitDescriptionAndUrl(stored: String?): Pair<String?, String?> {
        if (stored.isNullOrBlank()) return Pair(null, null)

        val trimmedStored = stored.trimEnd()
        val urlPattern = Regex("^(https?://|mailto:|www\\.)\\S+$", RegexOption.IGNORE_CASE)

        // 1) If there is a double newline, treat the part after it as potential URL
        val parts = trimmedStored.split(Regex("\\r?\\n\\s*\\r?\\n"), limit = 2)
        if (parts.size == 2) {
            val candidate = parts[1].trim()
            if (urlPattern.matches(candidate)) {
                val cleaned = stripTrailingPunctuation(candidate)
                val desc = parts[0].trim().ifBlank { null }
                return Pair(desc, cleaned)
            }
        }

        // 2) Fallback: check last non-empty line
        val lines = trimmedStored.lines()
        val lastNonEmpty = lines.asReversed().firstOrNull { it.isNotBlank() }?.trim()
        if (lastNonEmpty != null && urlPattern.matches(lastNonEmpty)) {
            val cleaned = stripTrailingPunctuation(lastNonEmpty)
            val idx = trimmedStored.lastIndexOf(lastNonEmpty)
            val descPart = trimmedStored.substring(0, idx).trim().ifBlank { null }
            return Pair(descPart, cleaned)
        }

        // 3) Nothing recognized as URL
        return Pair(trimmedStored.ifBlank { null }, null)
    }

    // Remove common trailing punctuation that is likely not part of the URL when text is copied from a sentence.
    // Keeps characters that are commonly part of URLs (like '/', '?', '=', '&', '%', '#', '-')
    private fun stripTrailingPunctuation(candidate: String): String {
        val toStrip = setOf('.', ',', ';', ':', '!', '?', ')', ']', '}', '"', '\'')
        var cleaned = candidate
        while (cleaned.isNotEmpty() && cleaned.last() in toStrip) {
            cleaned = cleaned.dropLast(1)
        }
        return if (cleaned.isNotEmpty()) cleaned else candidate
    }
}
