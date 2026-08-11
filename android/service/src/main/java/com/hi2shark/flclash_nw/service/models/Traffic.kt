package com.hi2shark.flclash_nw.service.models

import com.hi2shark.flclash_nw.common.GlobalState
import com.hi2shark.flclash_nw.common.formatBytes
import com.hi2shark.flclash_nw.core.Core
import com.google.gson.Gson

data class Traffic(
    val up: Long,
    val down: Long,
)

val Traffic.speedText: String
    get() = "${up.formatBytes}/s↑  ${down.formatBytes}/s↓"

private var cachedSpeedText: String = ""
private var cachedSpeedAtMs: Long = 0L
private var cachedOnlyStatisticsProxy: Boolean = false

fun Core.getSpeedTrafficText(onlyStatisticsProxy: Boolean): String {
    val now = System.currentTimeMillis()
    if (
        cachedSpeedText.isNotEmpty() &&
        onlyStatisticsProxy == cachedOnlyStatisticsProxy &&
        now - cachedSpeedAtMs < 900L
    ) {
        return cachedSpeedText
    }
    try {
        val res = getTraffic(onlyStatisticsProxy)
        val traffic = Gson().fromJson(res, Traffic::class.java)
        val text = traffic.speedText
        cachedSpeedText = text
        cachedSpeedAtMs = now
        cachedOnlyStatisticsProxy = onlyStatisticsProxy
        return text
    } catch (e: Exception) {
        GlobalState.log(e.message + "")
        return ""
    }
}
