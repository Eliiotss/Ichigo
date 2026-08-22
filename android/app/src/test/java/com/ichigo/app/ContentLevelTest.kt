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
 * json files, every level unlocked (all datasets — including N1 Grammar — have
 * now shipped Android-first), and json filenames that match the "<Kind><Id>"
 * convention the loader relies on. Pure JVM.
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
    fun everyLevelIsUnlocked() {
        // All datasets have shipped Android-first, including N1 Grammar, so no
        // level stays gated any more.
        all.forEach { (kind, levels) ->
            levels.forEach { level ->
                assertFalse("$kind ${level.id} should be unlocked", level.isLocked)
            }
        }
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
