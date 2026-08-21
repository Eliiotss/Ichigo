package com.ichigo.app.data.local.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Upsert
import com.ichigo.app.data.local.entity.KanaCountEntity
import com.ichigo.app.data.local.entity.NewCardDayCount
import com.ichigo.app.data.local.entity.NewCardTodayEntity
import com.ichigo.app.data.local.entity.ProgressEntity
import com.ichigo.app.data.local.entity.ReviewLogEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface ProgressDao {
    @Query("SELECT * FROM progress")
    suspend fun getAll(): List<ProgressEntity>

    /**
     * Cards whose due date has passed. Counted in SQL so Home/Profile no longer
     * need every deck decoded into memory just to show a number.
     */
    @Query("SELECT COUNT(*) FROM progress WHERE dueDate <= :now")
    suspend fun countDue(now: Long): Int

    /**
     * Cards considered mastered. Mirrors `FlashcardProgress.isMastered`
     * (state REVIEW and a scheduled interval of at least 21 days).
     */
    @Query("SELECT COUNT(*) FROM progress WHERE state = 'review' AND scheduledDays >= :minScheduledDays")
    suspend fun countMastered(minScheduledDays: Int): Int

    @Upsert
    suspend fun upsert(entity: ProgressEntity)

    @Query("DELETE FROM progress")
    suspend fun deleteAll()
}

@Dao
interface ReviewLogDao {
    @Insert
    suspend fun insert(entity: ReviewLogEntity)

    /** Keeps the newest [keep] logs, mirroring the 20 000-entry suffix cap. */
    @Query("DELETE FROM review_logs WHERE seq NOT IN (SELECT seq FROM review_logs ORDER BY seq DESC LIMIT :keep)")
    suspend fun trimTo(keep: Int)

    @Query("DELETE FROM review_logs")
    suspend fun deleteAll()

    /** Total reviews today across all levels (`studiedTodayTotal`). */
    @Query("SELECT COUNT(*) FROM review_logs WHERE reviewedAt >= :start AND reviewedAt < :end")
    suspend fun countAllBetween(start: Long, end: Long): Int
}

@Dao
interface KanaCountDao {
    @Query("SELECT * FROM kana_count")
    fun observeAll(): Flow<List<KanaCountEntity>>

    @Query("SELECT * FROM kana_count")
    suspend fun getAll(): List<KanaCountEntity>

    @Query("SELECT count FROM kana_count WHERE kana = :kana AND script = :script")
    suspend fun getCount(kana: String, script: String): Int?

    @Upsert
    suspend fun upsert(entity: KanaCountEntity)
}

@Dao
interface NewCardTodayDao {
    @Query("SELECT COUNT(*) FROM new_card_today WHERE levelKey = :levelKey AND day = :day")
    suspend fun countByLevelDay(levelKey: String, day: String): Int

    /**
     * Per-deck new-card usage for today, in one query. Used by the Home/Profile
     * "due" total so it agrees with the per-deck quota the session queue applies.
     */
    @Query("SELECT levelKey, COUNT(*) AS total FROM new_card_today WHERE day = :day GROUP BY levelKey")
    suspend fun countByDayGrouped(day: String): List<NewCardDayCount>

    @Insert(onConflict = OnConflictStrategy.IGNORE)
    suspend fun insertIgnore(entity: NewCardTodayEntity)

    /** Housekeeping: drop entries from previous days. */
    @Query("DELETE FROM new_card_today WHERE day != :today")
    suspend fun deleteOtherDays(today: String)

    @Query("DELETE FROM new_card_today")
    suspend fun deleteAll()

    @Query("SELECT * FROM new_card_today")
    suspend fun getAll(): List<NewCardTodayEntity>
}
