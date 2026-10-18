package com.hi2shark.flclash_nw

import com.hi2shark.flclash_nw.models.SharedState
import io.flutter.embedding.engine.FlutterEngine
import kotlinx.coroutines.Deferred

object ServiceState {
    private val machine = ServiceStateMachine(AndroidServiceStateHost)

    val runState = machine.runState

    val isRunRequested: Boolean
        get() = machine.isRunRequested

    fun attachFlutterEngine(engine: FlutterEngine) =
        AndroidServiceStateHost.attachFlutterEngine(engine)

    fun detachFlutterEngine(engine: FlutterEngine) =
        AndroidServiceStateHost.detachFlutterEngine(engine)

    suspend fun handleToggleAction() = machine.handleToggleAction()

    suspend fun handleStartAction() = machine.handleStartAction()

    suspend fun handleStopAction() = machine.handleStopAction()

    suspend fun handleVpnRevokeAction() = machine.handleVpnRevokeAction()

    fun handleServiceSuspendedChanged(suspended: Boolean) =
        AndroidServiceStateHost.notifySuspendedChanged(suspended)

    fun handleWifiWatchStateChanged(stateJson: String) =
        AndroidServiceStateHost.notifyWifiWatchStateChanged(stateJson)

    suspend fun awaitRunTime(): Long = machine.awaitRunTime()

    fun requestStart(): Deferred<Boolean> = machine.requestStart()

    fun requestStop(): Deferred<Boolean> = machine.requestStop()

    fun syncSharedState(state: SharedState) = machine.syncSharedState(state)

    internal fun captureRequestToken(): RunRequest = machine.captureRequestToken()

    internal suspend fun handleServiceLost(token: RunRequest) = machine.handleServiceLost(token)
}
