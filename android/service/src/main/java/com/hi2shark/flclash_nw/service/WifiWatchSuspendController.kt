package com.hi2shark.flclash_nw.service

internal class WifiWatchSuspendController(
    private val suspendDelayMillis: Long = SUSPEND_DELAY_MILLIS,
    private val scheduler: (Long, () -> Unit) -> Cancellable,
    private val setWifiSuspended: (Boolean) -> Unit,
    private val logger: (String) -> Unit = {},
) {
    fun interface Cancellable {
        fun cancel()
    }

    private val lock = Any()
    private var suspendOnWifiSsids: Set<String> = emptySet()
    private var wifiNetworkObserved = false
    private var wifiSsid: String? = null
    private var wifiValidated = false
    private var pendingSuspend: Cancellable? = null
    private var generation = 0

    fun updateSuspendOnWifiSsids(value: Set<String>) {
        val action = synchronized(lock) {
            suspendOnWifiSsids = value
            logLocked("suspend-on SSIDs updated count=${value.size}")
            if (wifiNetworkObserved) evaluateLocked() else null
        }
        action?.invoke()
    }

    fun updateWifiNetwork(ssid: String?, validated: Boolean) {
        val action = synchronized(lock) {
            wifiNetworkObserved = true
            wifiSsid = ssid
            wifiValidated = validated
            evaluateLocked()
        }
        action?.invoke()
    }

    fun cancel() {
        synchronized(lock) {
            cancelPendingLocked("controller cancelled")
            generation++
        }
    }

    private fun evaluateLocked(): (() -> Unit)? {
        val currentGeneration = ++generation
        cancelPendingLocked("state changed")

        val ssid = wifiSsid
        val trusted = isTrustedWifiLocked()
        logLocked(
            "evaluate ssid=${ssid ?: "<none>"} validated=$wifiValidated " +
                "trusted=$trusted delay=${suspendDelayMillis}ms"
        )

        if (!trusted) {
            logLocked("resume immediately")
            return { setWifiSuspended(false) }
        }

        logLocked("schedule suspend in ${suspendDelayMillis}ms")
        pendingSuspend = scheduler(suspendDelayMillis) {
            val action = synchronized(lock) {
                pendingSuspend = null
                val stillTrusted = currentGeneration == generation && isTrustedWifiLocked()
                logLocked(
                    "delayed suspend fired generation=$currentGeneration " +
                        "current=$generation trusted=$stillTrusted"
                )
                if (stillTrusted) {
                    { setWifiSuspended(true) }
                } else {
                    null
                }
            }
            action?.invoke()
        }
        return null
    }

    private fun isTrustedWifiLocked(): Boolean {
        val ssid = wifiSsid ?: return false
        return wifiValidated && suspendOnWifiSsids.contains(ssid)
    }

    private fun cancelPendingLocked(reason: String) {
        if (pendingSuspend != null) {
            logLocked("cancel pending suspend: $reason")
        }
        pendingSuspend?.cancel()
        pendingSuspend = null
    }

    private fun logLocked(message: String) {
        logger("WiFi-watch $message")
    }

    companion object {
        const val SUSPEND_DELAY_MILLIS = 5000L
    }
}
