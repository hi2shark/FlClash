package com.hi2shark.flclash_nw.service.modules

import android.app.Notification
import android.app.Notification.FOREGROUND_SERVICE_IMMEDIATE
import android.app.NotificationManager
import android.app.Service
import android.app.Service.STOP_FOREGROUND_REMOVE
import android.content.Intent
import android.os.Build
import android.os.PowerManager
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
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

internal fun Service.promoteToInitialForeground() {
    ensureNotificationChannel()
    startForeground(buildServiceNotification(this, ServiceConfig.notificationParams.value.extended))
}

@Suppress("DEPRECATION")
internal fun Service.stopForegroundCompat() {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
        stopForeground(STOP_FOREGROUND_REMOVE)
    } else {
        stopForeground(true)
    }
}

private fun buildServiceNotification(
    service: Service,
    params: ExtendedNotificationParams,
    builder: NotificationCompat.Builder = createNotificationBuilder(service),
    stopPendingIntent: android.app.PendingIntent = QuickAction.STOP.quickIntent.toPendingIntent,
    updateActions: Boolean = true,
): Notification = with(builder) {
    setContentTitle(params.title)
    setContentText(params.contentText)
    if (updateActions) {
        clearActions()
        if (params.showStopAction) {
            addAction(0, params.stopText, stopPendingIntent)
        }
    }
    build()
}

private fun createNotificationBuilder(service: Service): NotificationCompat.Builder {
    val intent = Intent().setComponent(Components.mainActivity)
    return NotificationCompat.Builder(
        service,
        GlobalState.NOTIFICATION_CHANNEL,
    ).apply {
        setSmallIcon(R.drawable.ic_service)
        setContentTitle("HI2NW")
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

internal class NotificationModule(
    private val service: Service,
    private val scope: CoroutineScope,
) : ServiceModule {
    private var lastActionState: Pair<Boolean, String>? = null

    override fun start() {
        service.ensureNotificationChannel()
        val initial = ServiceConfig.notificationParams.value.extended
        lastActionState = initial.showStopAction to initial.stopText
        service.startForeground(
            buildServiceNotification(
                service = service,
                params = initial,
                builder = notificationBuilder,
                stopPendingIntent = stopIntent,
            ),
        )
        scope.launch {
            // Some ROMs, vivo's among them, drop updates posted behind the
            // keyguard, so unlocking restarts the loop to post once more.
            // SystemUI, an app, sends USER_PRESENT, which a receiver that is
            // not exported never gets; all three actions are protected.
            service.receiveBroadcastFlow(exported = true) {
                addAction(Intent.ACTION_SCREEN_ON)
                addAction(Intent.ACTION_SCREEN_OFF)
                addAction(Intent.ACTION_USER_PRESENT)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                    addAction(NotificationManager.ACTION_APP_BLOCK_STATE_CHANGED)
                }
            }.map { intent ->
                val screenOn = intent.action == Intent.ACTION_SCREEN_ON ||
                    (intent.action != Intent.ACTION_SCREEN_OFF && isScreenOn())
                screenOn && areNotificationsEnabled()
            }.onStart {
                emit(isScreenOn() && areNotificationsEnabled())
            }.collectLatest { active ->
                if (!active) return@collectLatest
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

    private fun areNotificationsEnabled() =
        NotificationManagerCompat.from(service).areNotificationsEnabled()

    private val notificationBuilder: NotificationCompat.Builder by lazy {
        createNotificationBuilder(service)
    }

    private val stopIntent by lazy { QuickAction.STOP.quickIntent.toPendingIntent }

    private fun update(params: ExtendedNotificationParams) {
        val actionState = params.showStopAction to params.stopText
        val actionsChanged = actionState != lastActionState
        lastActionState = actionState
        service.getSystemService<NotificationManager>()?.notify(
            GlobalState.NOTIFICATION_ID,
            buildServiceNotification(
                service = service,
                params = params,
                builder = notificationBuilder,
                stopPendingIntent = stopIntent,
                updateActions = actionsChanged,
            ),
        )
    }

    override fun stop() {
        service.stopForegroundCompat()
    }
}
