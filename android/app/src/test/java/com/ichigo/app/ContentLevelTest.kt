package com.ichigo.app

import com.ichigo.app.data.model.ContentLevel
import com.ichigo.app.data.model.grammarLevels
import com.ichigo.app.data.model.kanjiLevels
import com.ichigo.app.data.model.vocabularyLevels
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Guards the level catalogue: five JLPT tiers per content type, unique ids and
 * json files, N5–N2 unlocked, N1 Vocab and N1 Kanji unlocked (their datasets have
 * shipped) while N1 Grammar stays locked, and json filenames that match the
 * "<Kind><Id>" convention the loader relies on. Pure JVM.
 */
class ContentLevelTest {

    private val all = mapOf(
        "Kanji" to kanjiLevels,
        "Vocab" to vocabularyLevels,
        "Grammar" to grammarLevels,
    )

    @Test
    fun everyTypeHasFiveTiersInOrder() {
        val expected = listOf("N5", "N4", "N3", "N2", "N1")
        all.forEach { (kind, levels) ->
            assertEquals("$kind ids", expected, levels.map { it.id })
        }
    }

    @Test
    fun idsAndJsonFilesAreUniquePerType() {
        all.forEach { (kind, levels) ->
            assertEquals("$kind ids unique", levels.size, levels.map { it.id }.toSet().size)
            assertEquals("$kind json unique", levels.size, levels.map { it.jsonFile }.toSet().size)
        }
    }

    @Test
    fun jsonFileFollowsKindPlusIdConvention() {
        all.forEach { (kind, levels) ->
            levels.forEach { level ->
                assertEquals("$kind ${level.id} json", "$kind${level.id}", level.jsonFile)
            }
        }
    }

    @Test
    fun n5ThroughN2Unlocked_n1VocabUnlockedElseLocked() {
        all.forEach { (_, levels) ->
            val byId = levels.associateBy { it.id }
            listOf("N5", "N4", "N3", "N2").forEach { id ->
                assertFalse("$id should be unlocked", byId.getValue(id).isLocked)
            }
        }
        // N1 Vocab and N1 Kanji have shipped their Android-first datasets so both
        // are unlocked; N1 Grammar still has no dataset and remains locked.
        assertFalse("Vocab N1 should be unlocked", vocabularyLevels.first { it.id == "N1" }.isLocked)
        assertFalse("Kanji N1 should be unlocked", kanjiLevels.first { it.id == "N1" }.isLocked)
        assertTrue("Grammar N1 should be locked", grammarLevels.first { it.id == "N1" }.isLocked)
    }

    @Test
    fun unlockedLevelsAdvertiseANumericCount() {
        // Mirrors scripts/check_dataset_counts.py: a shipped (unlocked) level's
        // subtitle opens with a real count, never a bare label.
        all.values.flatten().filter { !it.isLocked }.forEach { level: ContentLevel ->
            assertTrue(
                "'${level.description}' should start with a digit",
                level.description.trimStart().firstOrNull()?.isDigit() == true,
            )
        }
    }

    @Test
    fun n2IsUnlockedEverywhere() {
        all.forEach { (kind, levels) ->
            val n2 = levels.first { it.id == "N2" }
            assertFalse("$kind N2 unlocked", n2.isLocked)
        }
    }
}
