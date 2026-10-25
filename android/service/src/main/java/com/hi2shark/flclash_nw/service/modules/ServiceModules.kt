package com.hi2shark.flclash_nw.service.modules

import android.app.Service
import com.hi2shark.flclash_nw.service.ManagedService
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel

internal interface ServiceModule {
    fun start()

    fun stop()
}

internal class ServiceModules(private val service: Service) {
    private var scope: CoroutineScope? = null
    private var modules = emptyList<ServiceModule>()

    var wifiWatchModule: WifiWatchModule? = null
        private set

    @Synchronized
    fun start() {
        if (scope != null) return

        val nextScope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
        // Assign the field before start(): starting registers network callbacks
        // and can fire the first onStateChanged() before the list is built. If
        // the field were assigned afterwards, getWifiWatchStateJson() would
        // read wifiWatchModule == null and drop SSID/RSSI from the first push.
        val wifiWatchModule = WifiWatchModule(service) {
            (service as? ManagedService)?.publishWifiWatchState()
        }
        this.wifiWatchModule = wifiWatchModule
        val nextModules = listOf(
            NotificationModule(service, nextScope),
            SuspendModule(service),
            wifiWatchModule,
        )
        val startedModules = mutableListOf<ServiceModule>()

        try {
            nextModules.forEach { module ->
                module.start()
                startedModules.add(module)
            }
            scope = nextScope
            modules = nextModules
        } catch (error: Throwable) {
            nextScope.cancel()
            this.wifiWatchModule = null
            startedModules.asReversed().forEach { module ->
                runCatching { module.stop() }
            }
            throw error
        }
    }

    @Synchronized
    fun stop() {
        val currentScope = scope ?: return
        val currentModules = modules
        scope = null
        modules = emptyList()
        wifiWatchModule = null

        currentScope.cancel()
        // Reverse order stops WifiWatchModule first, so a pending delayed
        // suspend / force-resume can never fire after the listener or the tun
        // is torn down beneath it.
        currentModules.asReversed().forEach { module ->
            runCatching { module.stop() }
        }
    }
}
