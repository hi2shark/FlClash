package com.hi2shark.hi2nw.service

import android.app.Service
import android.content.Intent
import android.os.Binder
import android.os.IBinder
import com.hi2shark.hi2nw.core.Core
import com.hi2shark.hi2nw.service.modules.ServiceModules
import com.hi2shark.hi2nw.service.modules.promoteToInitialForeground
import com.hi2shark.hi2nw.service.modules.stopForegroundCompat
import com.google.gson.Gson

class ProxyService : Service(), ManagedService {
    private val modules = ServiceModules(this)
    private val binder = LocalBinder()

    @Volatile
    private var running = false

    private val suspensionController = SuspensionController(
        serviceName = "Proxy service",
        isRunning = { running },
        applySuspended = {
            val success = if (it) {
                AndroidCoreActions.stopListener()
            } else {
                AndroidCoreActions.startListener()
            }
            if (success) {
                ServiceStartResult.success()
            } else {
                ServiceStartResult.failure("Proxy service suspend update failed")
            }
        },
        onSuspendedChanged = { notifySuspendedChanged(it) },
    )

    override val isVpn: Boolean = false

    override val isSuspended: Boolean
        get() = suspensionController.isSuspended

    override fun setSuspended(suspended: Boolean): ServiceStartResult =
        suspensionController.setExternalSuspended(suspended)

    override fun setWifiSuspended(suspended: Boolean): ServiceStartResult =
        suspensionController.setWifiSuspended(suspended)

    override fun getWifiWatchStateJson(): String = Gson().toJson(
        modules.wifiWatchModule?.currentState(isSuspended)
            ?: WifiWatchState(
                ssid = null,
                rssi = null,
                validated = false,
                wifiPresent = false,
                suspended = isSuspended,
                pendingSuspendDeadline = null,
            ),
    )

    override fun onDestroy() {
        try {
            cleanup()
        } finally {
            super.onDestroy()
        }
    }

    override fun onLowMemory() {
        lowCoreMemory()
        super.onLowMemory()
    }

    override fun onTrimMemory(level: Int) {
        trimCoreMemory(level)
        super.onTrimMemory(level)
    }

    inner class LocalBinder : Binder() {
        val service: ProxyService
            get() = this@ProxyService
    }

    override fun onBind(intent: Intent): IBinder = binder

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (!running) {
            promoteToInitialForeground()
        }
        if (intent?.action != ACTION_HOST_FOREGROUND_START) {
            notifyVpnStartRequested()
        }
        return START_STICKY
    }

    override fun start() {
        try {
            modules.start()
            running = true
            // runtimeState gates setSuspended on isRunning, so it must lead.
            ServiceConfig.runtimeState.markStarted()
            suspensionController.reset()
            notifySuspendedChanged(false)
        } catch (error: Exception) {
            stop()
            ServiceConfig.runtimeState.markStartFailed()
            throw error
        }
    }

    override fun stop() {
        try {
            running = false
            suspensionController.reset()
            notifySuspendedChanged(false)
            ServiceConfig.runtimeState.markStopped()
            cleanup()
        } finally {
            stopSelf()
        }
    }

    private fun cleanup() {
        try {
            modules.stop()
        } finally {
            stopForegroundCompat()
        }
    }
}
