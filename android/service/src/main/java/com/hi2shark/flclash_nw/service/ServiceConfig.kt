package com.hi2shark.flclash_nw.service

import com.hi2shark.flclash_nw.service.models.NotificationParams
import com.hi2shark.flclash_nw.service.models.VpnOptions
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

object ServiceConfig {
    @Volatile
    private var currentVpnOptions: VpnOptions? = null
    private val mutableNotificationParams = MutableStateFlow(NotificationParams())
    private val mutableSuspendOnWifiSsids = MutableStateFlow<Set<String>>(emptySet())

    val vpnOptions: VpnOptions?
        get() = currentVpnOptions

    val notificationParams = mutableNotificationParams.asStateFlow()

    val runtimeState = ServiceRuntimeState()

    val suspendOnWifiSsids: StateFlow<Set<String>> =
        mutableSuspendOnWifiSsids.asStateFlow()

    fun updateVpnOptions(options: VpnOptions) {
        currentVpnOptions = options
    }

    fun updateNotificationParams(params: NotificationParams) {
        mutableNotificationParams.value = params
    }

    fun updateSuspendOnWifiSsids(value: Set<String>) {
        mutableSuspendOnWifiSsids.value = value
    }
}
