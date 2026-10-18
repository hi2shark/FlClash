package com.hi2shark.flclash_nw.service

/**
 * Shared arbiter for the three suspend reasons (external/user, WiFi-watch,
 * screen/idle). Serializes reason updates and applies the combined decision,
 * rolling the reason back when the apply step fails so a rejected transition
 * cannot leave a stale reason latched.
 */
internal class SuspensionController(
    private val serviceName: String,
    private val isRunning: () -> Boolean,
    private val applySuspended: (Boolean) -> ServiceStartResult,
    private val onSuspendedChanged: (Boolean) -> Unit,
) {
    private val lock = Any()
    private val reasons = ServiceSuspensionReasons()

    @Volatile
    private var suspended = false

    val isSuspended: Boolean
        get() = suspended

    fun setExternalSuspended(suspended: Boolean): ServiceStartResult =
        synchronized(lock) {
            val previous = reasons.externalSuspended
            reasons.setExternalSuspended(suspended)
            applyDesiredLocked().also { result ->
                if (!result.success) {
                    reasons.setExternalSuspended(previous)
                }
            }
        }

    fun setWifiSuspended(suspended: Boolean): ServiceStartResult =
        synchronized(lock) {
            val previous = reasons.wifiSuspended
            reasons.setWifiSuspended(suspended)
            applyDesiredLocked().also { result ->
                if (!result.success) {
                    reasons.setWifiSuspended(previous)
                }
            }
        }

    fun setIdleSuspended(suspended: Boolean): ServiceStartResult =
        synchronized(lock) {
            val previous = reasons.idleSuspended
            reasons.setIdleSuspended(suspended)
            applyDesiredLocked().also { result ->
                if (!result.success) {
                    reasons.setIdleSuspended(previous)
                }
            }
        }

    fun reset() = synchronized(lock) {
        reasons.reset()
        suspended = false
    }

    private fun applyDesiredLocked(): ServiceStartResult =
        applySuspendedLocked(reasons.shouldSuspend)

    private fun applySuspendedLocked(next: Boolean): ServiceStartResult {
        if (!isRunning()) {
            return ServiceStartResult.failure("$serviceName is not running")
        }
        if (suspended == next) {
            return ServiceStartResult.success()
        }
        val result = runCatching {
            applySuspended(next)
        }.getOrElse { error ->
            ServiceStartResult.failure(error.message ?: "$serviceName suspend update failed")
        }
        if (!result.success) {
            return result
        }
        suspended = next
        onSuspendedChanged(next)
        return ServiceStartResult.success()
    }
}
