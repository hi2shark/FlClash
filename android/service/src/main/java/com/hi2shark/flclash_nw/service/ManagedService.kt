package com.hi2shark.flclash_nw.service

import android.app.Service
import android.content.ComponentCallbacks2
import com.hi2shark.flclash_nw.common.BroadcastAction
import com.hi2shark.flclash_nw.common.BroadcastExtra
import com.hi2shark.flclash_nw.common.GlobalState
import com.hi2shark.flclash_nw.common.sendBroadcast
import com.hi2shark.flclash_nw.core.Core

interface ManagedService {
    fun start()

    fun stop()

    val isSuspended: Boolean

    /** VpnService true, ProxyService false. WifiWatchModule uses this to tell its own tunnel from a third-party VPN. */
    val isVpn: Boolean

    fun setSuspended(suspended: Boolean): ServiceStartResult
    fun setWifiSuspended(suspended: Boolean): ServiceStartResult
    fun setIdleSuspended(suspended: Boolean): ServiceStartResult

    fun getWifiWatchStateJson(): String = "{}"

    fun publishWifiWatchState() {
        notifyWifiWatchStateChanged(getWifiWatchStateJson())
    }

    fun notifySuspendedChanged(suspended: Boolean) {
        ServiceConfig.runtimeState.setSuspended(suspended)
        BroadcastAction.SERVICE_SUSPENDED_CHANGED.sendBroadcast {
            putExtra(BroadcastExtra.SUSPENDED, suspended)
        }
    }

    fun notifyWifiWatchStateChanged(stateJson: String) {
        BroadcastAction.WIFI_WATCH_STATE_CHANGED.sendBroadcast {
            putExtra(BroadcastExtra.WIFI_WATCH_STATE, stateJson)
        }
    }
}

const val ACTION_HOST_FOREGROUND_START =
    "com.hi2shark.flclash_nw.service.action.HOST_FOREGROUND_START"

internal fun Service.notifyVpnStartRequested() {
    GlobalState.log("Service start requested")
    BroadcastAction.VPN_START_REQUESTED.sendBroadcast()
}

internal fun Service.notifyVpnRevoked() {
    GlobalState.log("VPN permission revoked")
    BroadcastAction.VPN_REVOKED.sendBroadcast()
}

@Suppress("DEPRECATION")
fun trimCoreMemory(level: Int) {
    when (level) {
        ComponentCallbacks2.TRIM_MEMORY_UI_HIDDEN,
        ComponentCallbacks2.TRIM_MEMORY_BACKGROUND,
        ComponentCallbacks2.TRIM_MEMORY_MODERATE,
        ComponentCallbacks2.TRIM_MEMORY_COMPLETE,
        ComponentCallbacks2.TRIM_MEMORY_RUNNING_LOW,
        ComponentCallbacks2.TRIM_MEMORY_RUNNING_CRITICAL,
        -> Core.forceGCIfLoaded()
    }
}
