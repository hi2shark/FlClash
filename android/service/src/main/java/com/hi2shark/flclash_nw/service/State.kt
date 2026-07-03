package com.hi2shark.flclash_nw.service

import android.content.Intent
import com.hi2shark.flclash_nw.common.ServiceDelegate
import com.hi2shark.flclash_nw.service.models.NotificationParams
import com.hi2shark.flclash_nw.service.models.VpnOptions
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.sync.Mutex

object State {
    var options: VpnOptions? = null
    var notificationParamsFlow: MutableStateFlow<NotificationParams?> = MutableStateFlow(
        NotificationParams()
    )
    var suspendOnWifiSsidsFlow: MutableStateFlow<Set<String>> = MutableStateFlow(emptySet())

    val runLock = Mutex()
    val runtimeState = ServiceRuntimeState()

    var runTime: Long
        get() = runtimeState.runTime
        set(value) {
            if (value == 0L) {
                runtimeState.markStopped()
            } else {
                runtimeState.markStarted(value)
            }
        }

    var delegate: ServiceDelegate<IBaseService>? = null

    var intent: Intent? = null
}
