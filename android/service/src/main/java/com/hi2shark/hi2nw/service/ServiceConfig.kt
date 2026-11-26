package com.hi2shark.hi2nw.service

import com.hi2shark.hi2nw.service.models.NotificationParams
import com.hi2shark.hi2nw.service.models.VpnOptions
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

object ServiceConfig {
    @Volatile
    private var currentVpnOptions: VpnOptions? = null
    private val mutableNotificationParams = MutableStateFlow(NotificationParams())
    private val mutableMitm = MutableStateFlow(false)
    private val mutableSuspendOnWifiSsids = MutableStateFlow<Set<String>>(emptySet())
    private val mutablePackageCacheEpoch = MutableStateFlow(0L)

    val vpnOptions: VpnOptions?
        get() = currentVpnOptions

    val notificationParams = mutableNotificationParams.asStateFlow()

    val mitm = mutableMitm.asStateFlow()

    val runtimeState = ServiceRuntimeState()

    val suspendOnWifiSsids: StateFlow<Set<String>> =
        mutableSuspendOnWifiSsids.asStateFlow()

    val packageCacheEpoch: StateFlow<Long> = mutablePackageCacheEpoch.asStateFlow()

    fun updateVpnOptions(options: VpnOptions) {
        currentVpnOptions = options
    }

    fun updateNotificationParams(params: NotificationParams) {
        mutableNotificationParams.value = params
    }

    fun updateMitm(enabled: Boolean) {
        mutableMitm.value = enabled
    }

    fun updateSuspendOnWifiSsids(value: Set<String>) {
        mutableSuspendOnWifiSsids.value = value
    }

    fun invalidatePackageCache() {
        mutablePackageCacheEpoch.value += 1
    }
}
