package com.hi2shark.flclash_nw.service

internal class ServiceSuspensionReasons {
    var externalSuspended: Boolean = false
        private set

    var wifiSuspended: Boolean = false
        private set

    val shouldSuspend: Boolean
        get() = externalSuspended || wifiSuspended

    fun setExternalSuspended(suspended: Boolean) {
        externalSuspended = suspended
    }

    fun setWifiSuspended(suspended: Boolean) {
        wifiSuspended = suspended
    }

    fun reset() {
        externalSuspended = false
        wifiSuspended = false
    }
}
