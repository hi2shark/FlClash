package com.hi2shark.flclash_nw.service

/**
 * Snapshot of the WiFi-watch / on-demand state exposed to the UI.
 */
data class WifiWatchState(
    val ssid: String?,
    val rssi: Int?,
    val validated: Boolean,
    val wifiPresent: Boolean,
    val suspended: Boolean,
    val pendingSuspendDeadline: Long?,
)
