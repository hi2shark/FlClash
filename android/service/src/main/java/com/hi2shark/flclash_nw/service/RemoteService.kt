package com.hi2shark.flclash_nw.service

import android.app.Service
import android.content.Intent
import android.os.IBinder
import com.hi2shark.flclash_nw.common.GlobalState
import com.hi2shark.flclash_nw.common.ServiceDelegate
import com.hi2shark.flclash_nw.common.chunkedForAidl
import com.hi2shark.flclash_nw.common.intent
import com.hi2shark.flclash_nw.common.startForegroundServiceCompat
import com.hi2shark.flclash_nw.core.Core
import com.hi2shark.flclash_nw.service.State.delegate
import com.hi2shark.flclash_nw.service.State.intent
import com.hi2shark.flclash_nw.service.State.runLock
import com.hi2shark.flclash_nw.service.models.NotificationParams
import com.hi2shark.flclash_nw.service.models.VpnOptions
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.sync.withLock
import java.util.UUID
import kotlin.coroutines.resume

class RemoteService : Service(),
    CoroutineScope by CoroutineScope(SupervisorJob() + Dispatchers.Default) {
    private fun sameServiceIntent(left: Intent?, right: Intent): Boolean {
        return left?.component == right.component
    }

    private fun handleStopService(result: IResultInterface) {
        launch {
            runLock.withLock {
                try {
                    val activeDelegate = delegate
                    activeDelegate?.useService { service ->
                        service.stop()
                    }
                    activeDelegate?.unbind()
                    delegate = null
                    intent = null
                    State.runtimeState.markStopped()
                    result.onResult(0)
                } catch (e: Exception) {
                    GlobalState.log("Stop background service exception: $e")
                    State.runtimeState.markStopped()
                    result.onResult(0)
                }
            }
        }
    }

    private fun handleServiceDisconnected(expectedIntent: Intent, message: String) {
        if (!sameServiceIntent(intent, expectedIntent)) {
            return
        }
        GlobalState.log("Background service disconnected: $message")
        State.runtimeState.markDisconnected()
        intent = null
        delegate = null
    }

    private suspend fun bindStartedService(nextIntent: Intent) {
        if (!sameServiceIntent(intent, nextIntent)) {
            delegate?.useService { service ->
                service.stop()
            }
            delegate?.unbind()
            delegate = ServiceDelegate(
                nextIntent,
                { message -> handleServiceDisconnected(nextIntent, message) },
            ) { binder ->
                when (binder) {
                    is VpnService.LocalBinder -> binder.getService()
                    is CommonService.LocalBinder -> binder.getService()
                    else -> throw IllegalArgumentException("Invalid binder type")
                }
            }
            intent = nextIntent
        }
        GlobalState.application.startForegroundServiceCompat(nextIntent)
        delegate?.bind()
    }

    private fun handleStartService(runTime: Long, result: IResultInterface) {
        launch {
            runLock.withLock {
                try {
                    val nextIntent = when (State.options?.enable == true) {
                        true -> VpnService::class.intent
                        false -> CommonService::class.intent
                    }
                    bindStartedService(nextIntent)
                    val startResult = delegate?.useService { service ->
                        service.start()
                    }?.getOrNull()
                    if (startResult?.success == true) {
                        val nextRunTime = State.runtimeState.markStarted(runTime)
                        result.onResult(nextRunTime)
                    } else {
                        GlobalState.log("Start background service failed: ${startResult?.message}")
                        delegate?.useService { service ->
                            service.stop()
                        }
                        delegate?.unbind()
                        delegate = null
                        intent = null
                        State.runtimeState.markStartFailed()
                        result.onResult(0)
                    }
                } catch (e: Exception) {
                    GlobalState.log("Start background service exception: $e")
                    State.runtimeState.markStartFailed()
                    result.onResult(0)
                }
            }
        }
    }

    private fun handleSetSuspended(suspended: Boolean, result: IResultInterface) {
        launch {
            runLock.withLock {
                try {
                    val suspendResult = delegate?.useService { service ->
                        service.setSuspended(suspended)
                    }?.getOrNull()
                    if (suspendResult?.success == true) {
                        result.onResult(State.runTime)
                    } else {
                        GlobalState.log("Set service suspended failed: ${suspendResult?.message}")
                        result.onResult(0)
                    }
                } catch (e: Exception) {
                    GlobalState.log("Set service suspended exception: $e")
                    result.onResult(0)
                }
            }
        }
    }

    private val binder = object : IRemoteInterface.Stub() {
        override fun invokeAction(data: String, callback: ICallbackInterface) {
            Core.invokeAction(data) {
                launch {
                    runCatching {
                        val chunks = it?.chunkedForAidl() ?: listOf()
                        for ((index, chunk) in chunks.withIndex()) {
                            suspendCancellableCoroutine { cont ->
                                callback.onResult(
                                    chunk,
                                    index == chunks.lastIndex,
                                    object : IAckInterface.Stub() {
                                        override fun onAck() {
                                            cont.resume(Unit)
                                        }
                                    },
                                )
                            }
                        }
                    }
                }
            }
        }

        override fun quickSetup(
            initParamsString: String,
            setupParamsString: String,
            callback: ICallbackInterface,
            onStarted: IVoidInterface
        ) {
            Core.quickSetup(initParamsString, setupParamsString) {
                launch {
                    runCatching {
                        val chunks = it?.chunkedForAidl() ?: listOf()
                        for ((index, chunk) in chunks.withIndex()) {
                            suspendCancellableCoroutine { cont ->
                                callback.onResult(
                                    chunk,
                                    index == chunks.lastIndex,
                                    object : IAckInterface.Stub() {
                                        override fun onAck() {
                                            cont.resume(Unit)
                                        }
                                    },
                                )
                            }
                        }
                    }
                }
            }
            onStarted()
        }

        override fun updateNotificationParams(params: NotificationParams?) {
            State.notificationParamsFlow.tryEmit(params)
        }

        override fun updateSuspendOnWifiSsids(ssids: Array<String>?) {
            State.suspendOnWifiSsidsFlow.tryEmit(ssids?.toSet() ?: emptySet())
        }


        override fun startService(
            options: VpnOptions,
            runtime: Long,
            result: IResultInterface,
        ) {
            GlobalState.log("remote startService")
            State.options = options
            handleStartService(runtime, result)
        }

        override fun stopService(result: IResultInterface) {
            handleStopService(result)
        }

        override fun setSuspended(suspended: Boolean, result: IResultInterface) {
            handleSetSuspended(suspended, result)
        }

        override fun setEventListener(eventListener: IEventInterface?) {
            GlobalState.log("RemoveEventListener ${eventListener == null}")
            when (eventListener != null) {
                true -> Core.callSetEventListener {
                    launch {
                        runCatching {
                            val id = UUID.randomUUID().toString()
                            val chunks = it?.chunkedForAidl() ?: listOf()
                            for ((index, chunk) in chunks.withIndex()) {
                                suspendCancellableCoroutine { cont ->
                                    eventListener.onEvent(
                                        id,
                                        chunk,
                                        index == chunks.lastIndex,
                                        object : IAckInterface.Stub() {
                                            override fun onAck() {
                                                cont.resume(Unit)
                                            }
                                        },
                                    )
                                }
                            }
                        }
                    }
                }

                false -> Core.callSetEventListener(null)
            }
        }

        override fun setCrashlytics(enable: Boolean) {
            GlobalState.setCrashlytics(enable)
        }

        override fun getRunTime(): Long {
            if (delegate == null) {
                return 0
            }
            return State.runTime
        }

        override fun getSuspended(): Boolean {
            return State.runtimeState.isSuspended
        }

        override fun getWifiWatchState(): String {
            return runBlocking {
                delegate?.useService { service ->
                    service.getWifiWatchStateJson()
                }?.getOrNull()
            } ?: "{}"
        }
    }

    override fun onBind(intent: Intent?): IBinder {
        return binder
    }

    override fun onDestroy() {
        GlobalState.log("Remote service destroy")
        super.onDestroy()
    }
}
