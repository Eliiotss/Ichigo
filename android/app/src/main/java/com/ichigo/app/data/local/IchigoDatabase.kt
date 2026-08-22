package com.ichigo.app.data.local

import androidx.room.Database
import androidx.room.RoomDatabase
import androidx.room.migration.Migration
import androidx.sqlite.db.SupportSQLiteDatabase
import com.ichigo.app.data.local.dao.KanaCountDao
import com.ichigo.app.data.local.dao.NewCardTodayDao
import com.ichigo.app.data.local.dao.ProgressDao
import com.ichigo.app.data.local.dao.QuizResultDao
import com.ichigo.app.data.local.dao.ReviewLogDao
import com.ichigo.app.data.local.entity.KanaCountEntity
import com.ichigo.app.data.local.entity.NewCardTodayEntity
import com.ichigo.app.data.local.entity.ProgressEntity
import com.ichigo.app.data.local.entity.QuizResultEntity
import com.ichigo.app.data.local.entity.ReviewLogEntity

/**
 * Room database holding all local learning state — the SQLite counterpart of the
 * iOS `UserDefaults` stores in FlashcardModel.swift. Single-user, single-file.
 */
@Database(
    entities = [
        ProgressEntity::class,
        ReviewLogEntity::class,
        KanaCountEntity::class,
        NewCardTodayEntity::class,
        QuizResultEntity::class,
    ],
    version = 2,
    // Schemas are exported to app/schemas/ so a future version bump can ship a
    // real Migration (verified against the committed JSON) instead of relying on
    // a destructive fallback that would erase the user's progress.
    exportSchema = true,
)
abstract class IchigoDatabase : RoomDatabase() {
    abstract fun progressDao(): ProgressDao
    abstract fun reviewLogDao(): ReviewLogDao
    abstract fun kanaCountDao(): KanaCountDao
    abstract fun newCardTodayDao(): NewCardTodayDao
    abstract fun quizResultDao(): QuizResultDao

    companion object {
        const val NAME = "ichigo.db"

        /**
         * v1 → v2: adds the `quiz_result` table for the Vocab multiple-choice
         * quiz. Purely additive — no existing FSRS data is read or touched, so
         * every card's progress survives the upgrade. The CREATE statement must
         * match Room's generated schema for [QuizResultEntity] exactly (verified
         * against app/schemas/…/2.json).
         */
        val MIGRATION_1_2 = object : Migration(1, 2) {
            override fun migrate(db: SupportSQLiteDatabase) {
                db.execSQL(
                    "CREATE TABLE IF NOT EXISTS `quiz_result` (" +
                        "`wordId` TEXT NOT NULL, `score` INTEGER NOT NULL, " +
                        "`lastAnswered` INTEGER NOT NULL, PRIMARY KEY(`wordId`))",
                )
            }
        }
    }
}
