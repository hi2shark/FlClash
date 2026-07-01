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

    val runLock = Mutex()
    var runTime: Long = 0L

    var delegate: ServiceDelegate<IBaseService>? = null

    var intent: Intent? = null
}