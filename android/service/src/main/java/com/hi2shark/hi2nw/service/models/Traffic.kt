package com.hi2shark.hi2nw.service.models

import com.hi2shark.hi2nw.common.GlobalState
import com.hi2shark.hi2nw.core.Core
import com.google.gson.Gson

private val gson = Gson()

data class Traffic(
    val up: Long,
    val down: Long,
)

private val Long.formatBytes: String
    get() {
        val units = arrayOf("B", "KB", "MB", "GB", "TB")
        var value = toDouble()
        var unit = 0
        while (value >= 1024 && unit < units.lastIndex) {
            value /= 1024
            unit++
        }
        return if (unit == 0) {
            "${value.toLong()}${units[unit]}"
        } else {
            "%.1f${units[unit]}".format(value)
        }
    }

val Traffic.speedText: String
    get() = "${up.formatBytes}/s↑  ${down.formatBytes}/s↓"

fun parseTrafficBytes(bytes: ByteArray?): Traffic? {
    if (bytes == null || bytes.size != 16) {
        return null
    }
    return Traffic(
        up = bytes.readLongBE(0),
        down = bytes.readLongBE(8),
    )
}

private fun ByteArray.readLongBE(offset: Int): Long {
    var value = 0L
    for (i in 0 until 8) {
        value = (value shl 8) or (this[offset + i].toLong() and 0xffL)
    }
    return value
}

fun Core.getSpeedTrafficText(onlyStatisticsProxy: Boolean): String {
    return runCatching {
        val traffic = parseTrafficBytes(getTrafficBytes(onlyStatisticsProxy))
            ?: gson.fromJson(getTraffic(onlyStatisticsProxy), Traffic::class.java)
        traffic.speedText
    }.onFailure { error ->
        GlobalState.log("Unable to read traffic: $error")
    }.getOrDefault("")
}
