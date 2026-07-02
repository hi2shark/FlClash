package com.hi2shark.flclash_nw

import android.net.VpnService
import com.hi2shark.flclash_nw.common.GlobalState
import com.hi2shark.flclash_nw.models.SharedState
import com.hi2shark.flclash_nw.plugins.AppPlugin
import com.hi2shark.flclash_nw.plugins.TilePlugin
import com.hi2shark.flclash_nw.service.models.NotificationParams
import com.google.gson.Gson
import io.flutter.embedding.engine.FlutterEngine
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlin.coroutines.resume

enum class RunState {
    START, PENDING, STOP
}


object State {

    val runLock = Mutex()

    var runTime: Long = 0

    var sharedState: SharedState = SharedState()

    val runStateFlow: MutableStateFlow<RunState> = MutableStateFlow(RunState.STOP)

    var flutterEngine: FlutterEngine? = null

    val appPlugin: AppPlugin?
        get() = flutterEngine?.plugin<AppPlugin>()

    val tilePlugin: TilePlugin?
        get() = flutterEngine?.plugin<TilePlugin>()

    suspend fun handleToggleAction() {
        var action: (suspend () -> Unit)?
        runLock.withLock {
            action = when (runStateFlow.value) {
                RunState.PENDING -> null
                RunState.START -> ::handleStopServiceAction
                RunState.STOP -> ::handleStartServiceAction
            }
        }
        action?.invoke()
    }

    suspend fun handleSyncState() {
        runLock.withLock {
            try {
                Service.bind()
                runTime = Service.getRunTime()
                val runState = when (runTime == 0L) {
                    true -> RunState.STOP
                    false -> RunState.START
                }
                runStateFlow.tryEmit(runState)
            } catch (_: Exception) {
                runStateFlow.tryEmit(RunState.STOP)
            }
        }
    }

    suspend fun handleStartServiceAction() {
        runLock.withLock {
            if (runStateFlow.value != RunState.STOP) {
                return
            }
            tilePlugin?.handleStart()
            if (flutterEngine != null) {
                return
            }
            startServiceWithPref()
        }

    }

    suspend fun handleStopServiceAction() {
        if (flutterEngine == null && runStateFlow.value != RunState.START) {
            handleSyncState()
        }
        runLock.withLock {
            if (runStateFlow.value != RunState.START) {
                return
            }
            tilePlugin?.handleStop()
            if (flutterEngine != null) {
                return
            }
            GlobalState.application.showToast(sharedState.stopTip)
            shouldStopService()
        }
    }

    private suspend fun AppPlugin.awaitNotificationsPermission(): Boolean {
        return suspendCancellableCoroutine { continuation ->
            requestNotificationsPermission {
                if (continuation.isActive) {
                    continuation.resume(it)
                }
            }
        }
    }

    private suspend fun AppPlugin.awaitPrepare(needPrepare: Boolean): Boolean {
        return suspendCancellableCoroutine { continuation ->
            prepare(needPrepare) {
                if (continuation.isActive) {
                    continuation.resume(it)
                }
            }
        }
    }

    suspend fun handleStartService(): Boolean {
        val appPlugin = flutterEngine?.plugin<AppPlugin>()
        if (appPlugin != null) {
            if (!appPlugin.awaitNotificationsPermission()) {
                return false
            }
        }
        return startService()
    }

    private fun startServiceWithPref() {
        GlobalState.launch {
            runLock.withLock {
                if (runStateFlow.value != RunState.STOP) {
                    return@launch
                }
                sharedState = GlobalState.application.sharedState
                setupAndStart()
            }
        }
    }

    suspend fun syncState() {
        GlobalState.setCrashlytics(sharedState.crashlytics)
        Service.updateNotificationParams(
            NotificationParams(
                title = sharedState.currentProfileName,
                stopText = sharedState.stopText,
                onlyStatisticsProxy = sharedState.onlyStatisticsProxy
            )
        )
        Service.setCrashlytics(sharedState.crashlytics)
    }

    private suspend fun setupAndStart() {
        Service.bind()
        syncState()
        GlobalState.application.showToast(sharedState.startTip)
        val initParams = mutableMapOf<String, Any>()
        initParams["home-dir"] = GlobalState.application.filesDir.path
        initParams["version"] = android.os.Build.VERSION.SDK_INT
        val initParamsString = Gson().toJson(initParams)
        val setupParamsString = Gson().toJson(sharedState.setupParams)
        Service.quickSetup(
            initParamsString,
            setupParamsString,
            onStarted = {
                GlobalState.launch {
                    startService()
                }
            },
            onResult = {
                if (it.isNotEmpty()) {
                    GlobalState.application.showToast(it)
                }
            },
        )
    }

    private suspend fun startService(): Boolean {
        return runLock.withLock {
            if (runStateFlow.value != RunState.STOP) {
                return@withLock false
            }
            try {
                runStateFlow.tryEmit(RunState.PENDING)
                val options = sharedState.vpnOptions ?: return@withLock false
                val prepared = appPlugin?.awaitPrepare(options.enable) ?: when {
                    options.enable -> VpnService.prepare(GlobalState.application) == null
                    else -> true
                }
                if (!prepared) {
                    return@withLock false
                }
                val nextRunTime = Service.startService(options, runTime)
                if (nextRunTime == 0L) {
                    return@withLock false
                }
                runTime = nextRunTime
                runStateFlow.tryEmit(RunState.START)
                true
            } finally {
                if (runStateFlow.value == RunState.PENDING) {
                    runStateFlow.tryEmit(RunState.STOP)
                }
            }
        }
    }

    private fun shouldStopService() {
        GlobalState.launch {
            handleStopService()
        }
    }

    suspend fun handleStopService(): Boolean {
        return runLock.withLock {
            if (runStateFlow.value != RunState.START) {
                return@withLock false
            }
            try {
                runStateFlow.tryEmit(RunState.PENDING)
                runTime = Service.stopService()
                runStateFlow.tryEmit(RunState.STOP)
                true
            } finally {
                if (runStateFlow.value == RunState.PENDING) {
                    runStateFlow.tryEmit(RunState.START)
                }
            }
        }
    }
}

