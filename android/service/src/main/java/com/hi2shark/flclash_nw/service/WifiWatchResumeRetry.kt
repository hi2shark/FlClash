package com.hi2shark.flclash_nw.service

/**
 * Retries failed [setWifiSuspended](false) attempts with backoff so a single
 * establish/startListener failure after a long Doze suspend cannot leave the
 * proxy permanently hung. Suspend requests cancel any pending resume retries.
 *
 * When the configured retry budget is exhausted, [needsResume] stays true so a
 * later evaluate / reconcile can call [apply] again instead of treating the
 * failed resume as settled.
 */
internal class WifiWatchResumeRetry(
    private val delaysMillis: List<Long> = DEFAULT_DELAYS_MILLIS,
    private val scheduler: (Long, () -> Unit) -> WifiWatchSuspendController.Cancellable,
    private val applySuspended: (Boolean) -> ServiceStartResult,
    private val onAttemptFinished: () -> Unit = {},
    private val logger: (String) -> Unit = {},
) {
    private val lock = Any()
    private var pendingRetry: WifiWatchSuspendController.Cancellable? = null
    private var attemptIndex = 0
    private var generation = 0
    private var needsResumeFlag = false

    val needsResume: Boolean
        get() = synchronized(lock) { needsResumeFlag }

    fun apply(suspended: Boolean): ServiceStartResult {
        val result: ServiceStartResult
        synchronized(lock) {
            if (suspended) {
                cancelRetryLocked("suspend requested")
                needsResumeFlag = false
                result = applySuspended(true)
            } else {
                cancelRetryLocked("new resume request")
                result = applySuspended(false)
                if (!result.success) {
                    needsResumeFlag = true
                    logger("resume failed: ${result.message} — scheduling retry")
                    scheduleNextRetryLocked()
                } else {
                    needsResumeFlag = false
                    attemptIndex = 0
                }
            }
        }
        onAttemptFinished()
        return result
    }

    /**
     * Re-attempt resume when a previous budget was exhausted but the controller
     * still wants the proxy active. Interrupts the long post-exhaust reconcile
     * timer on a fresh WiFi capability event; does not cancel in-flight short
     * backoff retries.
     */
    fun reconcileIfNeeded() {
        val shouldApply: Boolean
        synchronized(lock) {
            if (!needsResumeFlag) {
                shouldApply = false
            } else if (pendingRetry != null && attemptIndex != 0) {
                // Short backoff still running — let it finish.
                shouldApply = false
            } else {
                if (pendingRetry != null) {
                    cancelRetryLocked("capability-driven reconcile")
                }
                logger("reconcile resume after exhausted retries")
                attemptIndex = 0
                shouldApply = true
            }
        }
        if (shouldApply) {
            apply(false)
        }
    }

    fun cancel(reason: String) {
        synchronized(lock) {
            cancelRetryLocked(reason)
            needsResumeFlag = false
        }
    }

    private fun scheduleNextRetryLocked() {
        if (attemptIndex >= delaysMillis.size) {
            logger(
                "resume retry exhausted after ${delaysMillis.size} attempts — " +
                    "keeping needsResume; reconcile in ${RECONCILE_DELAY_MILLIS}ms"
            )
            // Keep needsResumeFlag=true and schedule a longer reconcile so a
            // quiet network (no further capability events) can still recover.
            attemptIndex = 0
            scheduleReconcileLocked()
            return
        }
        val delay = delaysMillis[attemptIndex]
        val attempt = attemptIndex + 1
        attemptIndex++
        val currentGeneration = ++generation
        logger("schedule resume retry attempt=$attempt/${delaysMillis.size} in ${delay}ms")
        pendingRetry = scheduler(delay) {
            val notify = synchronized(lock) {
                if (currentGeneration != generation) {
                    return@synchronized false
                }
                pendingRetry = null
                val result = applySuspended(false)
                if (result.success) {
                    logger("resume retry attempt=$attempt succeeded")
                    needsResumeFlag = false
                    attemptIndex = 0
                } else {
                    logger("resume retry attempt=$attempt failed: ${result.message}")
                    needsResumeFlag = true
                    scheduleNextRetryLocked()
                }
                true
            }
            if (notify) {
                onAttemptFinished()
            }
        }
    }

    private fun scheduleReconcileLocked() {
        val currentGeneration = ++generation
        pendingRetry = scheduler(RECONCILE_DELAY_MILLIS) {
            val notify = synchronized(lock) {
                if (currentGeneration != generation || !needsResumeFlag) {
                    pendingRetry = null
                    return@synchronized false
                }
                pendingRetry = null
                logger("reconcile resume after exhausted retries")
                attemptIndex = 0
                val result = applySuspended(false)
                if (result.success) {
                    needsResumeFlag = false
                } else {
                    needsResumeFlag = true
                    scheduleNextRetryLocked()
                }
                true
            }
            if (notify) {
                onAttemptFinished()
            }
        }
    }

    private fun cancelRetryLocked(reason: String) {
        if (pendingRetry != null) {
            logger("cancel resume retry: $reason")
        }
        pendingRetry?.cancel()
        pendingRetry = null
        generation++
        attemptIndex = 0
    }

    companion object {
        val DEFAULT_DELAYS_MILLIS = listOf(500L, 1500L, 3000L)
        const val RECONCILE_DELAY_MILLIS = 10_000L
    }
}
