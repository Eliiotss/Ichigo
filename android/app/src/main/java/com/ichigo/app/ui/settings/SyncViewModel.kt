package com.ichigo.app.ui.settings

import android.content.Intent
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.ichigo.app.data.backup.DriveSyncManager
import com.ichigo.app.data.local.AppPreferences
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import javax.inject.Inject

/** Bridges the Settings UI to [DriveSyncManager]. */
@HiltViewModel
class SyncViewModel @Inject constructor(
    private val sync: DriveSyncManager,
    private val prefs: AppPreferences,
) : ViewModel() {

    val state: StateFlow<DriveSyncManager.DriveState> = sync.state
    val recoveryIntent: StateFlow<Intent?> = sync.recoveryIntent
    val autoSync: StateFlow<Boolean> =
        prefs.autoSync.stateIn(viewModelScope, SharingStarted.Eagerly, false)

    init { viewModelScope.launch { sync.refreshState() } }

    fun signInIntent(): Intent = sync.signInIntent()
    fun onSignInResult(data: Intent?) = viewModelScope.launch { sync.onSignInResult(data) }
    fun syncNow() = viewModelScope.launch { sync.syncNow() }
    fun signOut() = viewModelScope.launch { sync.signOut(); sync.clearGoogleEmail() }
    fun setAutoSync(value: Boolean) = viewModelScope.launch { prefs.setAutoSync(value) }
    fun refresh() = viewModelScope.launch { sync.refreshState() }

    /** Called after the user completes the Drive consent recovery intent. */
    fun onRecoveryDone() = viewModelScope.launch {
        sync.consumeRecoveryIntent()
        sync.syncNow()
    }
}
