package com.hi2shark.flclash_nw.service

internal class ServiceSuspensionReasons {
    var externalSuspended: Boolean = false
        private set

    var wifiSuspended: Boolean = false
        private set

    /**
     * Driven by screen state and Doze idle mode (see SuspendModule). Composes
     * with the other two reasons so the proxy is suspended if ANY reason wants
     * it suspended, and resumes only when ALL reasons clear.
     */
    var idleSuspended: Boolean = false
        private set

    val shouldSuspend: Boolean
        get() = externalSuspended || wifiSuspended || idleSuspended

    fun setExternalSuspended(suspended: Boolean) {
        externalSuspended = suspended
    }

    fun setWifiSuspended(suspended: Boolean) {
        wifiSuspended = suspended
    }

    fun setIdleSuspended(suspended: Boolean) {
        idleSuspended = suspended
    }

    fun reset() {
        externalSuspended = false
        wifiSuspended = false
        idleSuspended = false
    }
}
