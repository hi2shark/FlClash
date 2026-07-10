package com.hi2shark.flclash_nw.service

import android.app.Service
import android.content.Intent
import android.os.Binder
import android.os.IBinder
import com.google.gson.Gson
import com.hi2shark.flclash_nw.service.WifiWatchState
import com.hi2shark.flclash_nw.core.Core
import com.hi2shark.flclash_nw.service.modules.NetworkObserveModule
import com.hi2shark.flclash_nw.service.modules.NotificationModule
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
        // Assign the field before install(): install() runs onInstall()
        // synchronously, which can register the network callback and fire the
        // first onStateChanged() before this block continues. If the field
        // were assigned after install(), getWifiWatchStateJson() would read
        // wifiWatchModule == null and drop SSID/RSSI from the first push.
        val wifiWatchModule = WifiWatchModule(self) {
            notifyWifiWatchStateChanged(getWifiWatchStateJson())
        }
        this@CommonService.wifiWatchModule = wifiWatchModule
        install(wifiWatchModule)
    }

    @Volatile
    private var wifiWatchModule: WifiWatchModule? = null

    override fun getWifiWatchStateJson(): String {
        val state = wifiWatchModule?.currentState(isSuspended) ?: WifiWatchState(
            ssid = null,
            rssi = null,
            validated = false,
            wifiPresent = false,
            suspended = isSuspended,
            pendingSuspendDeadline = null,
        )
        return Gson().toJson(state)
    }

    override var isRunning: Boolean = false
        private set

    override var isSuspended: Boolean = false
        private set

    override val isVpn: Boolean = false

    override val wifiSuspended: Boolean
        get() = suspensionReasons.wifiSuspended

    private val suspensionReasons = ServiceSuspensionReasons()

    // Serializes start / stop / applySuspended so WifiWatch cannot race with
    // user-initiated stop (startListener / stopListener overlapping stopSelf).
    private val lifecycleLock = Any()

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
        synchronized(lifecycleLock) {
            return try {
                startForegroundWithNotification()
                loader.load()
                isRunning = true
                isSuspended = false
                suspensionReasons.reset()
                notifySuspendedChanged(false)
                ServiceStartResult.success()
            } catch (_: Exception) {
                stopLocked()
                ServiceStartResult.failure("Common service start failed")
            }
        }
    }

    override fun setSuspended(suspended: Boolean): ServiceStartResult {
        synchronized(lifecycleLock) {
            val previous = suspensionReasons.externalSuspended
            suspensionReasons.setExternalSuspended(suspended)
            val result = applyDesiredSuspendedLocked()
            if (!result.success) {
                suspensionReasons.setExternalSuspended(previous)
            }
            return result
        }
    }

    override fun setWifiSuspended(suspended: Boolean): ServiceStartResult {
        synchronized(lifecycleLock) {
            val previous = suspensionReasons.wifiSuspended
            suspensionReasons.setWifiSuspended(suspended)
            val result = applyDesiredSuspendedLocked()
            if (!result.success) {
                suspensionReasons.setWifiSuspended(previous)
            }
            return result
        }
    }

    override fun setIdleSuspended(suspended: Boolean): ServiceStartResult {
        synchronized(lifecycleLock) {
            val previous = suspensionReasons.idleSuspended
            suspensionReasons.setIdleSuspended(suspended)
            val result = applyDesiredSuspendedLocked()
            if (!result.success) {
                suspensionReasons.setIdleSuspended(previous)
            }
            return result
        }
    }

    private fun applyDesiredSuspendedLocked(): ServiceStartResult {
        return applySuspendedLocked(suspensionReasons.shouldSuspend)
    }

    private fun applySuspendedLocked(suspended: Boolean): ServiceStartResult {
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
        synchronized(lifecycleLock) {
            stopLocked()
        }
    }

    private fun stopLocked() {
        isRunning = false
        isSuspended = false
        suspensionReasons.reset()
        notifySuspendedChanged(false)
        // Uninstall WifiWatch before stopListener so a pending resume cannot
        // call startListener after we tear down.
        loader.cancelAndJoin()
        wifiWatchModule = null
        AndroidCoreActions.stopListener()
        stopSelf()
    }
}
