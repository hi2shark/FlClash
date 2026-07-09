package com.hi2shark.flclash_nw.service

/**
 * Retries failed [setWifiSuspended](false) attempts with backoff so a single
 * establish/startListener failure after a long Doze suspend cannot leave the
 * proxy permanently hung. Suspend requests cancel any pending resume retries.
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

    fun apply(suspended: Boolean): ServiceStartResult {
        val result: ServiceStartResult
        synchronized(lock) {
            if (suspended) {
                cancelRetryLocked("suspend requested")
                result = applySuspended(true)
            } else {
                cancelRetryLocked("new resume request")
                result = applySuspended(false)
                if (!result.success) {
                    logger("resume failed: ${result.message} — scheduling retry")
                    scheduleNextRetryLocked()
                } else {
                    attemptIndex = 0
                }
            }
        }
        onAttemptFinished()
        return result
    }

    fun cancel(reason: String) {
        synchronized(lock) {
            cancelRetryLocked(reason)
        }
    }

    private fun scheduleNextRetryLocked() {
        if (attemptIndex >= delaysMillis.size) {
            logger("resume retry exhausted after ${delaysMillis.size} attempts")
            attemptIndex = 0
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
                    attemptIndex = 0
                } else {
                    logger("resume retry attempt=$attempt failed: ${result.message}")
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
    }
}
