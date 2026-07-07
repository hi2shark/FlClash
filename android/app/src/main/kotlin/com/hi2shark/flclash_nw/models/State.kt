package com.hi2shark.flclash_nw.models

import com.google.gson.annotations.SerializedName
import com.hi2shark.flclash_nw.service.models.VpnOptions

data class SharedState(
    val startTip: String = "Starting VPN...",
    val stopTip: String = "Stopping VPN...",
    val crashlytics: Boolean = true,
    val currentProfileName: String = "FlClash",
    val stopText: String = "Stop",
    val suspendedText: String = "Suspended...",
    val onlyStatisticsProxy: Boolean = false,
    val vpnOptions: VpnOptions? = null,
    val setupParams: SetupParams? = null,
    @SerializedName(value = "suspendOnWifiSsids", alternate = ["excludeSSIDs"])
    val suspendOnWifiSsids: List<String> = emptyList(),
)

data class SetupParams(
    @SerializedName("test-url")
    val testUrl: String,
    @SerializedName("selected-map")
    val selectedMap: Map<String, String>,
)
