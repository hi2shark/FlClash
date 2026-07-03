package com.hi2shark.flclash_nw.service

import android.app.Service
import android.content.Intent
import android.os.Binder
import android.os.IBinder
import com.hi2shark.flclash_nw.core.Core
import com.hi2shark.flclash_nw.service.modules.NetworkObserveModule
import com.hi2shark.flclash_nw.service.modules.NotificationModule
import com.hi2shark.flclash_nw.service.modules.SuspendModule
import com.hi2shark.flclash_nw.service.modules.WifiWatchModule
import com.hi2shark.flclash_nw.service.modules.moduleLoader
import com.hi2shark.flclash_nw.service.modules.startForegroundWithNotification
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers

class CommonService : Service(), IBaseService,
    CoroutineScope by CoroutineScope(Dispatchers.Default) {

    private val self: CommonService
        get() = this

    private val loader = moduleLoader {
        install(NetworkObserveModule(self))
        install(NotificationModule(self))
        install(SuspendModule(self))
        install(WifiWatchModule(self))
    }

    override var isRunning: Boolean = false
        private set

    override var isSuspended: Boolean = false
        private set

    override val wifiSuspended: Boolean
        get() = suspensionReasons.wifiSuspended

    private val suspensionReasons = ServiceSuspensionReasons()

    override fun onCreate() {
        super.onCreate()
        handleCreate()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startForegroundWithNotification()
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        handleDestroy()
        super.onDestroy()
    }

    override fun onLowMemory() {
        Core.forceGC()
        super.onLowMemory()
    }

    private val binder = LocalBinder()

    inner class LocalBinder : Binder() {
        fun getService(): CommonService = this@CommonService
    }

    override fun onBind(intent: Intent): IBinder {
        return binder
    }

    override fun start(): ServiceStartResult {
        return try {
            startForegroundWithNotification()
            loader.load()
            isRunning = true
            isSuspended = false
            suspensionReasons.reset()
            notifySuspendedChanged(false)
            ServiceStartResult.success()
        } catch (_: Exception) {
            stop()
            ServiceStartResult.failure("Common service start failed")
        }
    }

    override fun setSuspended(suspended: Boolean): ServiceStartResult {
        val previous = suspensionReasons.externalSuspended
        suspensionReasons.setExternalSuspended(suspended)
        val result = applyDesiredSuspended()
        if (!result.success) {
            suspensionReasons.setExternalSuspended(previous)
        }
        return result
    }

    override fun setWifiSuspended(suspended: Boolean): ServiceStartResult {
        val previous = suspensionReasons.wifiSuspended
        suspensionReasons.setWifiSuspended(suspended)
        val result = applyDesiredSuspended()
        if (!result.success) {
            suspensionReasons.setWifiSuspended(previous)
        }
        return result
    }

    private fun applyDesiredSuspended(): ServiceStartResult {
        return applySuspended(suspensionReasons.shouldSuspend)
    }

    private fun applySuspended(suspended: Boolean): ServiceStartResult {
        if (!isRunning) {
            return ServiceStartResult.failure("Common service is not running")
        }
        if (isSuspended == suspended) {
            return ServiceStartResult.success()
        }
        val success = when (suspended) {
            true -> AndroidCoreActions.stopListener()
            false -> AndroidCoreActions.startListener()
        }
        if (!success) {
            return ServiceStartResult.failure("Common service suspend update failed")
        }
        isSuspended = suspended
        notifySuspendedChanged(suspended)
        return ServiceStartResult.success()
    }

    override fun stop() {
        AndroidCoreActions.stopListener()
        isRunning = false
        isSuspended = false
        suspensionReasons.reset()
        notifySuspendedChanged(false)
        loader.cancel()
        stopSelf()
    }
}
