package com.hi2shark.flclash_nw.service

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

    var isSuspended: Boolean = false
        private set

    val isRunning: Boolean
        get() = runTime != 0L

    fun markStarted(previousRunTime: Long = runTime): Long {
        runTime = when (previousRunTime != 0L) {
            true -> previousRunTime
            false -> now()
        }
        isSuspended = false
        return runTime
    }

    fun markStopped() {
        runTime = 0L
        isSuspended = false
    }

    fun markStartFailed() {
        markStopped()
    }

    fun markDisconnected() {
        markStopped()
    }

    fun setSuspended(value: Boolean): Long {
        if (isRunning) {
            isSuspended = value
        }
        return runTime
    }
}
