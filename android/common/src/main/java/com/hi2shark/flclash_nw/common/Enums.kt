package com.hi2shark.flclash_nw.common

import com.google.gson.annotations.SerializedName


enum class QuickAction {
    STOP,
    START,
    TOGGLE,
}

enum class BroadcastAction {
    SERVICE_CREATED,
    SERVICE_DESTROYED,
    SERVICE_SUSPENDED_CHANGED,
    WIFI_WATCH_STATE_CHANGED,
}

object BroadcastExtra {
    const val SUSPENDED = "suspended"
    const val WIFI_WATCH_STATE = "wifiWatchState"
}

enum class AccessControlMode {
    @SerializedName("acceptSelected")
    ACCEPT_SELECTED,

    @SerializedName("rejectSelected")
    REJECT_SELECTED,
}
