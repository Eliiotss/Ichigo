package com.ichigo.app.data.local

import androidx.room.Database
import androidx.room.RoomDatabase
import com.ichigo.app.data.local.dao.KanaCountDao
import com.ichigo.app.data.local.dao.NewCardTodayDao
import com.ichigo.app.data.local.dao.ProgressDao
import com.ichigo.app.data.local.dao.ReviewLogDao
import com.ichigo.app.data.local.entity.KanaCountEntity
import com.ichigo.app.data.local.entity.NewCardTodayEntity
import com.ichigo.app.data.local.entity.ProgressEntity
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
    ],
    version = 1,
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

    companion object {
        const val NAME = "ichigo.db"
    }
}
