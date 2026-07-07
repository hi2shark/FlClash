package com.hi2shark.flclash_nw.service

import com.hi2shark.flclash_nw.common.BroadcastAction
import com.hi2shark.flclash_nw.common.BroadcastExtra
import com.hi2shark.flclash_nw.common.GlobalState
import com.hi2shark.flclash_nw.common.sendBroadcast

interface IBaseService {
    val isRunning: Boolean

    val isSuspended: Boolean

    /**
     * Whether this service drives a system VPN tunnel. VpnService returns true,
     * CommonService (proxy-only mode) returns false. The WiFi-watch module uses
     * this to distinguish its own tunnel from third-party VPNs when deciding how
     * to judge WiFi trust — only an own VPN tunnel obscures the underlying
     * WiFi's NET_CAPABILITY_VALIDATED.
     */
    val isVpn: Boolean

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

    /**
     * Driven by SuspendModule based on screen state and Doze idle mode. Routed
     * through the shared suspension arbiter so that idle suspension composes
     * correctly with external (user) and WiFi-watch suspensions, and so that the
     * resulting state change always goes through applyDesiredSuspended +
     * notifySuspendedChanged (keeping Core and the broadcast listeners in sync).
     */
    fun setIdleSuspended(suspended: Boolean): ServiceStartResult

    /**
     * Returns a JSON representation of the current WiFi-watch state.
     */
    fun getWifiWatchStateJson(): String {
        return "{}"
    }

    fun notifySuspendedChanged(suspended: Boolean) {
        State.runtimeState.setSuspended(suspended)
        BroadcastAction.SERVICE_SUSPENDED_CHANGED.sendBroadcast {
            putExtra(BroadcastExtra.SUSPENDED, suspended)
        }
        // Notification refresh on suspend/resume is handled by
        // NotificationModule subscribing to runtimeState.isSuspendedFlow, so
        // no extra kick is needed here — the StateFlow emission from
        // setSuspended above drives the combine immediately.
    }

    /**
     * Push the current WiFi-watch state to the app process so the UI can update
     * event-driven instead of polling. Mirrors notifySuspendedChanged.
     */
    fun notifyWifiWatchStateChanged(stateJson: String) {
        BroadcastAction.WIFI_WATCH_STATE_CHANGED.sendBroadcast {
            putExtra(BroadcastExtra.WIFI_WATCH_STATE, stateJson)
        }
    }

    fun stop()
}
