package com.hi2shark.hi2nw.models

import com.hi2shark.hi2nw.service.models.VpnOptions
import com.google.gson.JsonObject

data class SharedState(
    val startTip: String = "Starting VPN...",
    val stopTip: String = "Stopping VPN...",
    val localNetworkTip: String =
        "Local network permission denied: using the gvisor stack, LAN is unreachable.",
    val currentProfileName: String = "HI2NW",
    val stopText: String = "Stop",
    val suspendedText: String = "Suspended...",
    val onlyStatisticsProxy: Boolean = false,
    val showStopAction: Boolean = true,
    val suspendOnWifiSsids: List<String> = emptyList(),
    val mitm: Boolean = false,
    val vpnOptions: VpnOptions? = null,
    // The Core's own setup params, handed on as Flutter wrote them.
    val setupParams: JsonObject? = null,
)
