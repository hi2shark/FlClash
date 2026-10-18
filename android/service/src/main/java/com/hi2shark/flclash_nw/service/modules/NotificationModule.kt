package com.hi2shark.flclash_nw.service.modules

import android.app.Notification.FOREGROUND_SERVICE_IMMEDIATE
import android.app.Service
import android.app.Service.STOP_FOREGROUND_REMOVE
import android.content.Intent
import android.os.Build
import android.os.PowerManager
import androidx.core.app.NotificationCompat
import androidx.core.content.getSystemService
import com.hi2shark.flclash_nw.common.Components
import com.hi2shark.flclash_nw.common.GlobalState
import com.hi2shark.flclash_nw.common.QuickAction
import com.hi2shark.flclash_nw.common.ensureNotificationChannel
import com.hi2shark.flclash_nw.common.quickIntent
import com.hi2shark.flclash_nw.common.receiveBroadcastFlow
import com.hi2shark.flclash_nw.common.startForeground
import com.hi2shark.flclash_nw.common.toPendingIntent
import com.hi2shark.flclash_nw.core.Core
import com.hi2shark.flclash_nw.service.R
import com.hi2shark.flclash_nw.service.ServiceConfig
import com.hi2shark.flclash_nw.service.models.NotificationParams
import com.hi2shark.flclash_nw.service.models.getSpeedTrafficText
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.onStart
import kotlinx.coroutines.launch

private data class ExtendedNotificationParams(
    val title: String,
    val stopText: String,
    val showStopAction: Boolean,
    val contentText: String,
    val suspendedText: String,
)

/**
 * A suspended service shows the suspended label instead of the live speed/traffic; the
 * combine re-derives this on every suspend transition and on each 1s ticker tick.
 */
private val NotificationParams.extended: ExtendedNotificationParams
    get() = ExtendedNotificationParams(
        title,
        stopText,
        showStopAction,
        if (ServiceConfig.runtimeState.isSuspended) {
            suspendedText
        } else {
            Core.getSpeedTrafficText(onlyStatisticsProxy)
        },
        suspendedText,
    )

internal class NotificationModule(
    private val service: Service,
    private val scope: CoroutineScope,
) : ServiceModule {
    override fun start() {
        service.ensureNotificationChannel()
        update(ServiceConfig.notificationParams.value.extended)
        scope.launch {
            // Some ROMs, vivo's among them, drop updates posted behind the
            // keyguard, so unlocking restarts the loop to post once more.
            // SystemUI, an app, sends USER_PRESENT, which a receiver that is
            // not exported never gets; all three actions are protected.
            service.receiveBroadcastFlow(exported = true) {
                addAction(Intent.ACTION_SCREEN_ON)
                addAction(Intent.ACTION_SCREEN_OFF)
                addAction(Intent.ACTION_USER_PRESENT)
            }.map { intent ->
                intent.action != Intent.ACTION_SCREEN_OFF
            }.onStart {
                emit(isScreenOn())
            }.collectLatest { screenOn ->
                if (!screenOn) return@collectLatest
                combine(
                    flow {
                        while (true) {
                            delay(1_000)
                            emit(Unit)
                        }
                    },
                    ServiceConfig.notificationParams,
                    // isSuspendedFlow re-emits once runtimeState is up to date.
                    ServiceConfig.runtimeState.isSuspendedFlow,
                ) { _, params, _ ->
                    params.extended
                }.distinctUntilChanged()
                    .collect(::update)
            }
        }
    }

    private fun isScreenOn() =
        service.getSystemService<PowerManager>()?.isInteractive ?: true

    private val notificationBuilder: NotificationCompat.Builder by lazy {
        val intent = Intent().setComponent(Components.mainActivity)

        NotificationCompat.Builder(
            service,
            GlobalState.NOTIFICATION_CHANNEL,
        ).apply {
            setSmallIcon(R.drawable.ic_service)
            setContentTitle("FlClash")
            setContentIntent(intent.toPendingIntent)
            setPriority(NotificationCompat.PRIORITY_LOW)
            setCategory(NotificationCompat.CATEGORY_SERVICE)
            setOngoing(true)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                foregroundServiceBehavior = FOREGROUND_SERVICE_IMMEDIATE
            }
            setShowWhen(true)
            setOnlyAlertOnce(true)
        }
    }

    private val stopIntent by lazy { QuickAction.STOP.quickIntent.toPendingIntent }

    private fun update(params: ExtendedNotificationParams) {
        service.startForeground(
            with(notificationBuilder) {
                setContentTitle(params.title)
                setContentText(params.contentText)
                clearActions()
                if (params.showStopAction) {
                    addAction(0, params.stopText, stopIntent)
                }
                build()
            },
        )
    }

    @Suppress("DEPRECATION")
    override fun stop() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            service.stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            service.stopForeground(true)
        }
    }
}
