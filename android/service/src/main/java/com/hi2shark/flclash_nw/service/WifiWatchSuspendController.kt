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
    private var wifiPresent = false
    private var wifiResolutionPending = false
    private var pendingSuspend: Cancellable? = null
    private var pendingResolutionFallback: Cancellable? = null
    private var generation = 0

    fun updateSuspendOnWifiSsids(value: Set<String>) {
        val action = synchronized(lock) {
            suspendOnWifiSsids = value
            logLocked("suspend-on SSIDs updated count=${value.size}")
            when {
                !wifiNetworkObserved -> null
                wifiResolutionPending -> {
                    logLocked("SSID resolution pending — defer suspend-on SSID re-evaluation")
                    null
                }
                else -> evaluateLocked()
            }
        }
        action?.invoke()
    }

    /**
     * @param ssid current WiFi SSID, or null while it is being resolved
     * @param validated whether the current network should be treated as trusted
     * @param wifiPresent whether any WiFi network is still tracked by the
     *     module. This distinguishes a transient null SSID (an AP switch in
     *     progress — location info not yet populated, but a WiFi transport is
     *     still present) from the WiFi genuinely going away (all networks
     *     lost/unavailable). The former must not perturb the suspend state;
     *     the latter resumes immediately.
     */
    fun updateWifiNetwork(ssid: String?, validated: Boolean, wifiPresent: Boolean) {
        val action = synchronized(lock) {
            wifiNetworkObserved = true

            // Transient null SSID while a WiFi transport is still present: this
            // is an AP switch / location-info-not-yet-resolved blip, not a real
            // state change. Keep the current suspend state briefly while
            // waiting for a concrete SSID or a full WiFi loss signal.
            if (ssid == null && wifiPresent) {
                val wasWifiPresent = this.wifiPresent
                if (wifiResolutionPending) {
                    this.wifiPresent = true
                    logLocked(
                        "transient null SSID while WiFi present — continue waiting " +
                            "(pendingSuspend=${pendingSuspend != null})"
                    )
                    return@synchronized null
                }
                if (wifiSsid == null && wasWifiPresent) {
                    this.wifiPresent = true
                    logLocked("unresolved WiFi without SSID already fell back — keep active")
                    return@synchronized null
                }
                this.wifiPresent = true
                wifiResolutionPending = true
                scheduleResolutionFallbackLocked()
                return@synchronized null
            }

            cancelResolutionFallbackLocked("WiFi state resolved")
            wifiResolutionPending = false
            wifiSsid = ssid
            wifiValidated = validated
            this.wifiPresent = wifiPresent
            evaluateLocked()
        }
        action?.invoke()
    }

    fun cancel() {
        synchronized(lock) {
            cancelResolutionFallbackLocked("controller cancelled")
            cancelPendingLocked("controller cancelled")
            generation++
        }
    }

    private fun evaluateLocked(): (() -> Unit)? {
        val currentGeneration = ++generation
        cancelResolutionFallbackLocked("state changed")
        cancelPendingLocked("state changed")

        val ssid = wifiSsid
        val trusted = isTrustedWifiLocked()
        logLocked(
            "evaluate ssid=${ssid ?: "<none>"} validated=$wifiValidated " +
                "trusted=$trusted wifiPresent=$wifiPresent delay=${suspendDelayMillis}ms"
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

    private fun scheduleResolutionFallbackLocked() {
        if (pendingResolutionFallback != null) {
            logLocked("SSID resolution grace already pending")
            return
        }
        logLocked(
            "transient null SSID while WiFi present — hold state for " +
                "${SSID_RESOLUTION_GRACE_MILLIS}ms (pendingSuspend=${pendingSuspend != null})"
        )
        pendingResolutionFallback = scheduler(SSID_RESOLUTION_GRACE_MILLIS) {
            val action = synchronized(lock) {
                if (!wifiResolutionPending) {
                    pendingResolutionFallback = null
                    return@synchronized null
                }
                pendingResolutionFallback = null
                wifiResolutionPending = false
                wifiSsid = null
                wifiValidated = false
                generation++
                cancelPendingLocked("SSID resolution grace expired")
                logLocked("SSID resolution grace expired — resume to safe default")
                return@synchronized { setWifiSuspended(false) }
            }
            action?.invoke()
        }
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

    private fun cancelResolutionFallbackLocked(reason: String) {
        if (pendingResolutionFallback != null) {
            logLocked("cancel SSID resolution grace: $reason")
        }
        pendingResolutionFallback?.cancel()
        pendingResolutionFallback = null
    }

    private fun logLocked(message: String) {
        logger("WiFi-watch $message")
    }

    companion object {
        const val SUSPEND_DELAY_MILLIS = 5000L
        const val SSID_RESOLUTION_GRACE_MILLIS = 2000L
    }
}
