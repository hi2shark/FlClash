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
    /**
     * True when the proxy is forced to resume by an external reason (currently:
     * the system default network switched to Cellular), overriding WiFi SSID
     * trust. Lets the UI explain *why* the proxy is active despite a trusted
     * SSID being present.
     */
    val forceResumed: Boolean = false,
    /**
     * Human-readable reason for [forceResumed] (null when not forced). Purely
     * diagnostic; not localized.
     */
    val reason: String? = null,
)
