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
}

object BroadcastExtra {
    const val SUSPENDED = "suspended"
}

enum class AccessControlMode {
    @SerializedName("acceptSelected")
    ACCEPT_SELECTED,

    @SerializedName("rejectSelected")
    REJECT_SELECTED,
}
