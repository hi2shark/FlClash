package com.hi2shark.flclash_nw.service

internal enum class DefaultNetworkResumeAction {
    FORCE,
    KEEP,
    CLEAR,
}

internal fun defaultNetworkResumeAction(
    isCellular: Boolean,
    isOwnVpn: Boolean,
): DefaultNetworkResumeAction {
    return when {
        isCellular -> DefaultNetworkResumeAction.FORCE
        isOwnVpn -> DefaultNetworkResumeAction.KEEP
        else -> DefaultNetworkResumeAction.CLEAR
    }
}
