package com.hi2shark.flclash_nw.service.modules

import android.app.Service
import android.content.Intent
import android.os.PowerManager
import androidx.core.content.getSystemService
import com.hi2shark.flclash_nw.common.receiveBroadcastFlow
import com.hi2shark.flclash_nw.service.ManagedService
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.merge
import kotlinx.coroutines.flow.onStart
import kotlinx.coroutines.launch

internal class SuspendModule(private val service: Service) : ServiceModule {
    private val scope = CoroutineScope(Dispatchers.Default)

    private fun isScreenOn(): Boolean {
        val pm = service.getSystemService<PowerManager>()
        return when (pm != null) {
            true -> pm.isInteractive
            false -> true
        }
    }

    val isDeviceIdleMode: Boolean
        get() {
            return service.getSystemService<PowerManager>()?.isDeviceIdleMode ?: true
        }

    /**
     * Screen/idle suspension is routed through the service's idle-suspend
     * channel (setIdleSuspended) so it composes with external and WiFi-watch
     * suspensions via the shared ServiceSuspensionReasons arbiter, instead of
     * calling Core.suspended directly. Routing everything through the arbiter
     * guarantees Core state, the isSuspended flag and the
     * SERVICE_SUSPENDED_CHANGED broadcast all stay in sync.
     *
     * When the screen is on the service is never idle-suspended. When off, the
     * service is idle-suspended only if the device has entered Doze
     * (isDeviceIdleMode). WiFi-watch and user suspensions are evaluated
     * independently by the arbiter.
     */
    private fun onUpdate(isScreenOn: Boolean) {
        (service as? ManagedService)?.setIdleSuspended(!isScreenOn && isDeviceIdleMode)
    }

    override fun start() {
        scope.launch {
            val screenFlow = service.receiveBroadcastFlow {
                addAction(Intent.ACTION_SCREEN_ON)
                addAction(Intent.ACTION_SCREEN_OFF)
            }.map { intent ->
                intent.action == Intent.ACTION_SCREEN_ON
            }.onStart {
                emit(isScreenOn())
            }

            // Doze enter/exit can happen while the screen stays off; without
            // this, idleSuspended would stay stale until the next screen event
            // and could block WiFi-watch resume (OR arbiter).
            val idleFlow = service.receiveBroadcastFlow {
                addAction(PowerManager.ACTION_DEVICE_IDLE_MODE_CHANGED)
            }.map {
                isScreenOn()
            }

            merge(screenFlow, idleFlow).collect {
                onUpdate(it)
            }
        }
    }

    override fun stop() {
        scope.cancel()
    }
}
