package com.follow.clash.service

import android.app.Service
import android.content.ComponentCallbacks2
import com.follow.clash.common.BroadcastAction
import com.follow.clash.common.BroadcastExtra
import com.follow.clash.common.GlobalState
import com.follow.clash.common.sendBroadcast
import com.follow.clash.core.Core

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

internal fun Service.notifyVpnStartRequested() {
    GlobalState.log("VPN start requested")
    BroadcastAction.VPN_START_REQUESTED.sendBroadcast()
}

internal fun Service.notifyVpnRevoked() {
    GlobalState.log("VPN permission revoked")
    BroadcastAction.VPN_REVOKED.sendBroadcast()
}

// UI_HIDDEN reaches the services too, since they share the activity's process,
// and Android 14 stopped delivering the running levels this answers to.
@Suppress("DEPRECATION")
internal fun trimCoreMemory(level: Int) {
    if (level == ComponentCallbacks2.TRIM_MEMORY_RUNNING_LOW ||
        level == ComponentCallbacks2.TRIM_MEMORY_RUNNING_CRITICAL
    ) {
        Core.forceGC()
    }
}
