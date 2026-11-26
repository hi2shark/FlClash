package com.hi2shark.hi2nw.service.models

data class NotificationParams(
    val title: String = "HI2NW",
    val stopText: String = "STOP",
    val onlyStatisticsProxy: Boolean = false,
    val suspendedText: String = "Suspended...",
    val showStopAction: Boolean = true,
)
