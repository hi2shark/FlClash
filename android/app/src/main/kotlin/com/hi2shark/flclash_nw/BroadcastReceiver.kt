package com.hi2shark.flclash_nw

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.hi2shark.flclash_nw.common.BroadcastAction
import com.hi2shark.flclash_nw.common.BroadcastExtra
import com.hi2shark.flclash_nw.common.GlobalState
import com.hi2shark.flclash_nw.common.action
import kotlinx.coroutines.launch

class BroadcastReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        when (intent?.action) {
            BroadcastAction.SERVICE_CREATED.action -> {
                GlobalState.log("Receiver service created")
                GlobalState.launch {
                    State.handleStartServiceAction()
                }
            }

            BroadcastAction.SERVICE_DESTROYED.action -> {
                GlobalState.log("Receiver service destroyed")
                State.handleServiceSuspendedChanged(false)
                GlobalState.launch {
                    State.handleStopServiceAction()
                }
            }

            BroadcastAction.SERVICE_SUSPENDED_CHANGED.action -> {
                val suspended = intent.getBooleanExtra(BroadcastExtra.SUSPENDED, false)
                State.handleServiceSuspendedChanged(suspended)
            }

            BroadcastAction.WIFI_WATCH_STATE_CHANGED.action -> {
                val stateJson = intent.getStringExtra(BroadcastExtra.WIFI_WATCH_STATE) ?: "{}"
                State.handleWifiWatchStateChanged(stateJson)
            }
        }
    }
}
