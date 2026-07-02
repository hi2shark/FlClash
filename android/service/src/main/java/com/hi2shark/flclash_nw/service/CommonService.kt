package com.hi2shark.flclash_nw.service

import android.app.Service
import android.content.Intent
import android.os.Binder
import android.os.IBinder
import com.hi2shark.flclash_nw.common.GlobalState
import com.hi2shark.flclash_nw.core.Core
import com.hi2shark.flclash_nw.service.modules.NetworkObserveModule
import com.hi2shark.flclash_nw.service.modules.NotificationModule
import com.hi2shark.flclash_nw.service.modules.SuspendModule
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
    }

    override var isRunning: Boolean = false
        private set

    override var isSuspended: Boolean = false
        private set

    override var wifiSuspended: Boolean = false
        private set

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
            wifiSuspended = false
            ServiceStartResult.success()
        } catch (_: Exception) {
            stop()
            ServiceStartResult.failure("Common service start failed")
        }
    }

    override fun setSuspended(suspended: Boolean): ServiceStartResult {
        if (!isRunning) {
            return ServiceStartResult.failure("Common service is not running")
        }
        return try {
            Core.suspended(suspended)
            isSuspended = suspended
            wifiSuspended = suspended
            ServiceStartResult.success()
        } catch (e: Exception) {
            GlobalState.log("Common service suspend update failed $e")
            ServiceStartResult.failure(e.message ?: "Common service suspend update failed")
        }
    }

    override fun stop() {
        isRunning = false
        isSuspended = false
        wifiSuspended = false
        loader.cancel()
        stopSelf()
    }
}
