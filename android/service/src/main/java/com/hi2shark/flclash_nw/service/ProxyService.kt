package com.hi2shark.flclash_nw.service

import android.app.Service
import android.content.Intent
import android.os.Binder
import android.os.IBinder
import com.hi2shark.flclash_nw.core.Core
import com.hi2shark.flclash_nw.service.modules.ServiceModules
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

    override fun setIdleSuspended(suspended: Boolean): ServiceStartResult =
        suspensionController.setIdleSuspended(suspended)

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
        Core.forceGC()
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

    private fun cleanup() = modules.stop()
}
