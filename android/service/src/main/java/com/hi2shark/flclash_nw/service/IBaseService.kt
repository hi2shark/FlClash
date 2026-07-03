package com.hi2shark.flclash_nw.service

import com.hi2shark.flclash_nw.common.BroadcastAction
import com.hi2shark.flclash_nw.common.BroadcastExtra
import com.hi2shark.flclash_nw.common.GlobalState
import com.hi2shark.flclash_nw.common.sendBroadcast

interface IBaseService {
    val isRunning: Boolean

    val isSuspended: Boolean

    /**
     * When true, the service should remain suspended regardless of screen/idle state.
     * Currently driven by the WiFi-watch feature (exclude SSID list).
     */
    val wifiSuspended: Boolean

    fun handleCreate() {
        GlobalState.log("Service create")
        BroadcastAction.SERVICE_CREATED.sendBroadcast()
    }

    fun handleDestroy() {
        GlobalState.log("Service destroy")
        BroadcastAction.SERVICE_DESTROYED.sendBroadcast()
    }

    fun start(): ServiceStartResult

    fun setSuspended(suspended: Boolean): ServiceStartResult

    fun setWifiSuspended(suspended: Boolean): ServiceStartResult

    fun notifySuspendedChanged(suspended: Boolean) {
        State.runtimeState.setSuspended(suspended)
        BroadcastAction.SERVICE_SUSPENDED_CHANGED.sendBroadcast {
            putExtra(BroadcastExtra.SUSPENDED, suspended)
        }
    }

    fun stop()
}
