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

    data class Status(
        val ssid: String?,
        val validated: Boolean,
        val wifiPresent: Boolean,
        val pendingSuspendDeadline: Long?,
    )

    private val lock = Any()
    private var suspendOnWifiSsids: Set<String> = emptySet()
    private var wifiNetworkObserved = false
    private var wifiSsid: String? = null
    private var wifiValidated = false
    private var wifiPresent = false
    private var wifiResolutionPending = false
    private var pendingSuspend: Cancellable? = null
    private var pendingResolutionFallback: Cancellable? = null
    private var pendingSuspendDeadline: Long? = null
    private var generation = 0
    // Last value passed to setWifiSuspended. Used so repeated evaluate() calls
    // (force-resume hold, trusted blips) do not re-emit the same action.
    private var lastRequestedSuspended: Boolean? = null
    // When true, the proxy is forced to resume while a previously trusted WiFi
    // handoff settles. Cleared when the WiFi disappears, becomes untrusted,
    // resolves to a non-matching SSID, or the default leaves Cellular/our VPN.
    private var forceResumed = false
    private var persistentForceResume = false

    fun currentStatus(): Status = synchronized(lock) {
        Status(
            ssid = wifiSsid,
            validated = wifiValidated,
            wifiPresent = wifiPresent,
            pendingSuspendDeadline = pendingSuspendDeadline,
        )
    }

    fun updateSuspendOnWifiSsids(value: Set<String>) {
        val action = synchronized(lock) {
            suspendOnWifiSsids = value
            logLocked("suspend-on SSIDs updated count=${value.size}")
            if (
                forceResumed &&
                !persistentForceResume &&
                (wifiSsid == null || !value.contains(wifiSsid))
            ) {
                forceResumed = false
                persistentForceResume = false
                logLocked("clear force resume — current WiFi no longer suspend-on")
            }
            when {
                !wifiNetworkObserved -> null
                value.isEmpty() -> {
                    if (!persistentForceResume) {
                        forceResumed = false
                    }
                    cancelResolutionFallbackLocked("suspend-on SSIDs disabled")
                    wifiResolutionPending = false
                    evaluateLocked()
                }
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

            if (
                forceResumed &&
                !persistentForceResume &&
                (
                    !wifiPresent ||
                        (
                            ssid != null &&
                                !suspendOnWifiSsids.contains(ssid)
                        )
                )
            ) {
                forceResumed = false
                logLocked("clear force resume — WiFi left suspend-on network")
            }

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

    /**
     * Force the proxy to resume immediately. If the current WiFi is still a
     * trusted suspend-on network, retain a temporary hold so stale callbacks
     * cannot re-suspend while the Cellular-to-VPN handoff settles. Otherwise a
     * one-shot resume is sufficient. Cancels any pending delayed suspend.
     */
    fun forceResume(reason: String, persistent: Boolean = false) {
        val action = synchronized(lock) {
            val holdResume = persistent || isTrustedWifiLocked()
            if (forceResumed) {
                if (persistent && !persistentForceResume) {
                    persistentForceResume = true
                    logLocked("upgrade force resume to persistent — $reason")
                } else {
                    logLocked("force resume already active — $reason")
                }
                return@synchronized null
            }
            forceResumed = holdResume
            persistentForceResume = holdResume && persistent
            logLocked(
                "force resume hold=$holdResume persistent=$persistentForceResume — $reason"
            )
            evaluateLocked()
        }
        action?.invoke()
    }

    /**
     * Lift the [forceResume] hold and re-evaluate the suspend decision based on
     * the current WiFi state. Called when the system default network is known
     * to be neither Cellular nor our own VPN. Idempotent.
     */
    fun clearForceResume(reason: String) {
        val action = synchronized(lock) {
            if (!forceResumed) {
                return@synchronized null
            }
            forceResumed = false
            persistentForceResume = false
            logLocked("clear force resume — $reason")
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
        val trusted = isTrustedWifiLocked()
        logLocked(
            "evaluate ssid=${wifiSsid ?: "<none>"} validated=$wifiValidated " +
                "trusted=$trusted wifiPresent=$wifiPresent " +
                "forceResumed=$forceResumed delay=${suspendDelayMillis}ms"
        )

        if (forceResumed) {
            cancelResolutionFallbackLocked("state changed")
            cancelPendingLocked("force resume")
            generation++
            logLocked("resume immediately (forced)")
            return requestSuspendedLocked(false)
        }

        if (!trusted) {
            cancelResolutionFallbackLocked("state changed")
            cancelPendingLocked("untrusted")
            generation++
            logLocked("resume immediately")
            return requestSuspendedLocked(false)
        }

        // Still trusted: if a suspend is already pending, keep the original
        // deadline. Capability / RSSI blips must not reset the 5s stability
        // window or suspend can be deferred forever.
        if (pendingSuspend != null) {
            logLocked(
                "trusted and suspend already pending — keep deadline " +
                    "pendingSuspendDeadline=$pendingSuspendDeadline"
            )
            return null
        }

        cancelResolutionFallbackLocked("state changed")
        val currentGeneration = ++generation
        logLocked("schedule suspend in ${suspendDelayMillis}ms")
        val deadline = System.currentTimeMillis() + suspendDelayMillis
        pendingSuspendDeadline = deadline
        pendingSuspend = scheduler(suspendDelayMillis) {
            val action = synchronized(lock) {
                pendingSuspend = null
                pendingSuspendDeadline = null
                val stillTrusted = currentGeneration == generation && isTrustedWifiLocked()
                logLocked(
                    "delayed suspend fired generation=$currentGeneration " +
                        "current=$generation trusted=$stillTrusted"
                )
                if (stillTrusted) {
                    requestSuspendedLocked(true)
                } else {
                    null
                }
            }
            action?.invoke()
        }
        return null
    }

    private fun requestSuspendedLocked(suspended: Boolean): (() -> Unit)? {
        if (lastRequestedSuspended == suspended) {
            logLocked("skip duplicate setWifiSuspended($suspended)")
            return null
        }
        lastRequestedSuspended = suspended
        return { applySuspendedRequest(suspended) }
    }

    private fun applySuspendedRequest(suspended: Boolean) {
        var next = suspended
        while (true) {
            setWifiSuspended(next)
            val latest = synchronized(lock) {
                lastRequestedSuspended?.takeIf { it != next }
            } ?: return
            logLocked("correct stale setWifiSuspended($next) with latest=$latest")
            next = latest
        }
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
                if (!persistentForceResume) {
                    forceResumed = false
                }
                generation++
                cancelPendingLocked("SSID resolution grace expired")
                logLocked("SSID resolution grace expired — resume to safe default")
                return@synchronized requestSuspendedLocked(false)
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
        pendingSuspendDeadline = null
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
