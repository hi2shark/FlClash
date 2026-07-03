package com.hi2shark.flclash_nw.service

internal class VpnSuspendController<T>(
    private val currentOptions: () -> T?,
    private val stopTun: () -> Unit,
    private val startTun: (T) -> Unit,
    private val isSuspended: (() -> Boolean)? = null,
) {
    fun setSuspended(suspended: Boolean): ServiceStartResult {
        if (isSuspended?.invoke() == suspended) {
            return ServiceStartResult.success()
        }
        if (suspended) {
            stopTun()
            return ServiceStartResult.success()
        }
        val options = currentOptions()
            ?: return ServiceStartResult.failure("VPN options empty")
        try {
            startTun(options)
        } catch (e: Exception) {
            stopTun()
            throw e
        }
        return ServiceStartResult.success()
    }
}
