package com.hi2shark.flclash_nw.service.modules

import android.app.Notification
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
import com.hi2shark.flclash_nw.common.quickIntent
import com.hi2shark.flclash_nw.common.receiveBroadcastFlow
import com.hi2shark.flclash_nw.common.startForeground
import com.hi2shark.flclash_nw.common.tickerFlow
import com.hi2shark.flclash_nw.common.toPendingIntent
import com.hi2shark.flclash_nw.core.Core
import com.hi2shark.flclash_nw.service.R
import com.hi2shark.flclash_nw.service.State
import com.hi2shark.flclash_nw.service.models.NotificationParams
import com.hi2shark.flclash_nw.service.models.getSpeedTrafficText
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.filter
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.onStart
import kotlinx.coroutines.launch

data class ExtendedNotificationParams(
    val title: String,
    val stopText: String,
    val onlyStatisticsProxy: Boolean,
    val contentText: String,
    val suspendedText: String,
)

/**
 * Builds the notification-facing params. When the service is suspended (whether
 * by the user, WiFi-watch, or Doze idle), the contentText is replaced with the
 * localized "Suspended..." text instead of the live speed/traffic.
 *
 * [NotificationModule] includes `runtimeState.isSuspendedFlow` in its combine,
 * so this is re-evaluated the moment suspend state changes (no 1s ticker
 * latency), and also once per second by the ticker to refresh the live
 * speed/traffic text while not suspended.
 */
val NotificationParams.extended: ExtendedNotificationParams
    get() {
        val suspended = State.runtimeState.isSuspended
        return ExtendedNotificationParams(
            title = title,
            stopText = stopText,
            onlyStatisticsProxy = onlyStatisticsProxy,
            contentText = if (suspended) suspendedText
                else Core.getSpeedTrafficText(onlyStatisticsProxy),
            suspendedText = suspendedText,
        )
    }

private fun Service.isScreenOn(): Boolean {
    val pm = getSystemService<PowerManager>()
    return when (pm != null) {
        true -> pm.isInteractive
        false -> true
    }
}

private fun Service.buildServiceNotification(
    params: ExtendedNotificationParams,
): Notification {
    val intent = Intent().setComponent(Components.MAIN_ACTIVITY)
    return NotificationCompat.Builder(
        this, GlobalState.NOTIFICATION_CHANNEL
    ).apply {
        setSmallIcon(R.drawable.ic_service)
        setContentTitle("FlClash")
        setContentIntent(intent.toPendingIntent)
        setPriority(NotificationCompat.PRIORITY_HIGH)
        setCategory(NotificationCompat.CATEGORY_SERVICE)
        setOngoing(true)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            foregroundServiceBehavior = FOREGROUND_SERVICE_IMMEDIATE
        }
        setShowWhen(true)
        setOnlyAlertOnce(true)
//            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
//                setRequestPromotedOngoing(true)
//            }
        clearActions()
        addAction(
            0, params.stopText, QuickAction.STOP.quickIntent.toPendingIntent
        )
        setContentTitle(params.title)
        setContentText(params.contentText)
    }.build()
}

fun Service.startForegroundWithNotification(
    params: ExtendedNotificationParams = (State.notificationParamsFlow.value ?: NotificationParams()).extended,
) {
    startForeground(buildServiceNotification(params))
}

class NotificationModule(private val service: Service) : Module() {
    private val scope = CoroutineScope(Dispatchers.Default)

    override fun onInstall() {
        scope.launch {
            val screenFlow = service.receiveBroadcastFlow {
                addAction(Intent.ACTION_SCREEN_ON)
                addAction(Intent.ACTION_SCREEN_OFF)
            }.map { intent ->
                intent.action == Intent.ACTION_SCREEN_ON
            }.onStart {
                emit(service.isScreenOn())
            }

            combine(
                tickerFlow(1000, 0),
                State.notificationParamsFlow,
                screenFlow,
                State.runtimeState.isSuspendedFlow,
            ) { _, params, screenOn, _ ->
                // Re-derive extended on every tick, param change, screen toggle,
                // AND suspend/resume transition. The `extended` getter reads
                // State.runtimeState.isSuspended internally, which is already
                // up to date by the time isSuspendedFlow re-emits, so the
                // resulting ExtendedNotificationParams reflects the new state.
                params?.extended to screenOn
            }.filter { (params, screenOn) -> params != null && screenOn }
                .distinctUntilChanged { old, new -> old.first == new.first && old.second == new.second }
                .collect { (params, _) ->
                    update(params!!)
                }

            State.notificationParamsFlow.value?.let {
                update(it.extended)
            } ?: run {
                update(NotificationParams().extended)
            }
        }
    }

    private fun update(params: ExtendedNotificationParams) {
        service.startForegroundWithNotification(params)
    }

    override fun onUninstall() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            service.stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            service.stopForeground(true)
        }
        scope.cancel()
    }
}
