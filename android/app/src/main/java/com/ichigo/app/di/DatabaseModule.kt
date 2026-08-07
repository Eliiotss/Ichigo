package com.ichigo.app.di

import android.content.Context
import androidx.room.Room
import com.ichigo.app.data.local.IchigoDatabase
import com.ichigo.app.data.local.dao.KanaCountDao
import com.ichigo.app.data.local.dao.NewCardTodayDao
import com.ichigo.app.data.local.dao.ProgressDao
import com.ichigo.app.data.local.dao.ReviewLogDao
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

/** Provides the Room database and its DAOs to the Hilt graph. */
@Module
@InstallIn(SingletonComponent::class)
object DatabaseModule {

    @Provides
    @Singleton
    fun provideDatabase(@ApplicationContext context: Context): IchigoDatabase =
        Room.databaseBuilder(context, IchigoDatabase::class.java, IchigoDatabase.NAME)
            .fallbackToDestructiveMigration()
            .build()

    @Provides fun provideProgressDao(db: IchigoDatabase): ProgressDao = db.progressDao()
    @Provides fun provideReviewLogDao(db: IchigoDatabase): ReviewLogDao = db.reviewLogDao()
    @Provides fun provideKanaCountDao(db: IchigoDatabase): KanaCountDao = db.kanaCountDao()
    @Provides fun provideNewCardTodayDao(db: IchigoDatabase): NewCardTodayDao = db.newCardTodayDao()
}
