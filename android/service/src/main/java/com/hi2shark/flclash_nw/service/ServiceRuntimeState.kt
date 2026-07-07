package com.hi2shark.flclash_nw.service

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

data class ServiceStartResult(
    val success: Boolean,
    val message: String = "",
) {
    companion object {
        fun success(): ServiceStartResult = ServiceStartResult(success = true)

        fun failure(message: String): ServiceStartResult = ServiceStartResult(
            success = false,
            message = message,
        )
    }
}

class ServiceRuntimeState(
    private val now: () -> Long = System::currentTimeMillis,
) {
    var runTime: Long = 0L
        private set

    private val _isSuspended = MutableStateFlow(false)

    /**
     * Whether the service is currently suspended (by the user, WiFi-watch, or
     * Doze idle). Backed by a [StateFlow] so observers — notably the
     * NotificationModule — react to suspend/resume transitions immediately,
     * without waiting for the 1s notification ticker.
     */
    val isSuspended: Boolean
        get() = _isSuspended.value

    val isSuspendedFlow: StateFlow<Boolean> = _isSuspended.asStateFlow()

    val isRunning: Boolean
        get() = runTime != 0L

    fun markStarted(previousRunTime: Long = runTime): Long {
        runTime = when (previousRunTime != 0L) {
            true -> previousRunTime
            false -> now()
        }
        _isSuspended.value = false
        return runTime
    }

    fun markStopped() {
        runTime = 0L
        _isSuspended.value = false
    }

    fun markStartFailed() {
        markStopped()
    }

    fun markDisconnected() {
        markStopped()
    }

    fun setSuspended(value: Boolean): Long {
        if (isRunning) {
            _isSuspended.value = value
        }
        return runTime
    }
}
