package com.follow.clash.service

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
