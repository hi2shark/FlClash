package com.hi2shark.flclash_nw.service.models

data class NotificationParams(
    val title: String = "FlClash",
    val stopText: String = "STOP",
    val onlyStatisticsProxy: Boolean = false,
    val suspendedText: String = "Suspended...",
    val showStopAction: Boolean = true,
)
