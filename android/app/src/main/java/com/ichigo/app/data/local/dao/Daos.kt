package com.ichigo.app.data.local.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Upsert
import com.ichigo.app.data.local.entity.KanaCountEntity
import com.ichigo.app.data.local.entity.NewCardTodayEntity
import com.ichigo.app.data.local.entity.ProgressEntity
import com.ichigo.app.data.local.entity.ReviewLogEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface ProgressDao {
    @Query("SELECT * FROM progress")
    fun observeAll(): Flow<List<ProgressEntity>>

    @Query("SELECT * FROM progress")
    suspend fun getAll(): List<ProgressEntity>

    @Query("SELECT * FROM progress WHERE id = :id")
    suspend fun getById(id: String): ProgressEntity?

    @Upsert
    suspend fun upsert(entity: ProgressEntity)

    @Query("DELETE FROM progress")
    suspend fun deleteAll()
}

@Dao
interface ReviewLogDao {
    @Insert
    suspend fun insert(entity: ReviewLogEntity)

    /** Same-day count for a level, matching `FlashcardReviewStore.todayCount`. */
    @Query("SELECT COUNT(*) FROM review_logs WHERE levelId = :levelId AND reviewedAt >= :start AND reviewedAt < :end")
    suspend fun countBetween(levelId: String, start: Long, end: Long): Int

    @Query("SELECT COUNT(*) FROM review_logs")
    suspend fun count(): Int

    /** Keeps the newest [keep] logs, mirroring the 20 000-entry suffix cap. */
    @Query("DELETE FROM review_logs WHERE seq NOT IN (SELECT seq FROM review_logs ORDER BY seq DESC LIMIT :keep)")
    suspend fun trimTo(keep: Int)

    @Query("DELETE FROM review_logs")
    suspend fun deleteAll()

    /** Total reviews today across all levels (`studiedTodayTotal`). */
    @Query("SELECT COUNT(*) FROM review_logs WHERE reviewedAt >= :start AND reviewedAt < :end")
    suspend fun countAllBetween(start: Long, end: Long): Int

    /** Reactive so Home/Profile "studied today" refreshes after each review. */
    @Query("SELECT COUNT(*) FROM review_logs WHERE reviewedAt >= :start AND reviewedAt < :end")
    fun observeCountBetween(start: Long, end: Long): Flow<Int>
}

@Dao
interface KanaCountDao {
    @Query("SELECT * FROM kana_count")
    fun observeAll(): Flow<List<KanaCountEntity>>

    @Query("SELECT count FROM kana_count WHERE kana = :kana AND script = :script")
    suspend fun getCount(kana: String, script: String): Int?

    @Upsert
    suspend fun upsert(entity: KanaCountEntity)
}

@Dao
interface NewCardTodayDao {
    @Query("SELECT COUNT(*) FROM new_card_today WHERE levelKey = :levelKey AND day = :day")
    suspend fun countByLevelDay(levelKey: String, day: String): Int

    @Insert(onConflict = OnConflictStrategy.IGNORE)
    suspend fun insertIgnore(entity: NewCardTodayEntity)

    /** Housekeeping: drop entries from previous days. */
    @Query("DELETE FROM new_card_today WHERE day != :today")
    suspend fun deleteOtherDays(today: String)
}
