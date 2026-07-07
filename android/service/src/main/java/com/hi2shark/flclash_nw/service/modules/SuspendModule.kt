package com.hi2shark.flclash_nw.service.modules

import android.app.Service
import android.content.Intent
import android.os.PowerManager
import androidx.core.content.getSystemService
import com.hi2shark.flclash_nw.common.receiveBroadcastFlow
import com.hi2shark.flclash_nw.service.IBaseService
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.onStart
import kotlinx.coroutines.launch


class SuspendModule(private val service: Service) : Module() {
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
     * Screen/idle suspension is now routed through the service's idle-suspend
     * channel (setIdleSuspended) so it composes with external and WiFi-watch
     * suspensions via the shared ServiceSuspensionReasons arbiter, instead of
     * calling Core.suspended directly. Routing everything through
     * applyDesiredSuspended guarantees Core state, the isSuspended flag and the
     * SERVICE_SUSPENDED_CHANGED broadcast all stay in sync.
     *
     * When the screen is on the service is never idle-suspended. When off, the
     * service is idle-suspended only if the device has entered Doze
     * (isDeviceIdleMode). WiFi-watch and user suspensions are evaluated
     * independently by the arbiter.
     */
    private fun onUpdate(isScreenOn: Boolean) {
        val baseService = service as? IBaseService ?: return
        val idleSuspended = !isScreenOn && isDeviceIdleMode
        baseService.setIdleSuspended(idleSuspended)
    }

    override fun onInstall() {
        scope.launch {
            val screenFlow = service.receiveBroadcastFlow {
                addAction(Intent.ACTION_SCREEN_ON)
                addAction(Intent.ACTION_SCREEN_OFF)
            }.map { intent ->
                intent.action == Intent.ACTION_SCREEN_ON
            }.onStart {
                emit(isScreenOn())
            }

            screenFlow.collect {
                    onUpdate(it)
                }
        }
    }

    override fun onUninstall() {
        scope.cancel()
    }
}