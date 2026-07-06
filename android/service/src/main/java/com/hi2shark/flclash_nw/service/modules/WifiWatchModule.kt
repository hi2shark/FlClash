package com.hi2shark.flclash_nw.service.modules

import android.app.Service
import android.content.Context
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import android.net.wifi.WifiInfo
import android.net.wifi.WifiManager
import android.os.Build
import androidx.core.content.getSystemService
import com.hi2shark.flclash_nw.common.GlobalState
import com.hi2shark.flclash_nw.service.IBaseService
import com.hi2shark.flclash_nw.service.State
import com.hi2shark.flclash_nw.service.WifiWatchSuspendController
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

class WifiWatchModule(private val service: Service) : Module() {
    private val scope = CoroutineScope(Dispatchers.Default)
    private val connectivity by lazy {
        service.getSystemService<ConnectivityManager>()
    }
    private val wifiManager by lazy {
        service.applicationContext.getSystemService(Context.WIFI_SERVICE) as? WifiManager
    }

    private val controller = WifiWatchSuspendController(
        scheduler = ::schedule,
        setWifiSuspended = ::setWifiSuspended,
        logger = GlobalState::log,
    )

    private val wifiNetworksLock = Any()
    private val wifiNetworks = linkedMapOf<Network, WifiNetworkStatus>()
    private val callback = createWifiNetworkCallback()
    private var wifiResolutionReconcileJob: Job? = null
    private var lastPublishedStatus: WifiNetworkStatus? = null

    override fun onInstall() {
        scope.launch {
            State.suspendOnWifiSsidsFlow.collect {
                controller.updateSuspendOnWifiSsids(it)
            }
        }

        val manager = connectivity
        if (manager == null) {
            controller.updateWifiNetwork(ssid = null, validated = false, wifiPresent = false)
            return
        }
        runCatching {
            manager.registerNetworkCallback(wifiNetworkRequest, callback)
        }.onSuccess {
            updateKnownWifiNetworks(manager)
        }.onFailure {
            GlobalState.log("WiFi-watch registerNetworkCallback failed: ${it.message}")
            controller.updateWifiNetwork(ssid = null, validated = false, wifiPresent = false)
        }
    }

    private fun schedule(delayMillis: Long, action: () -> Unit): WifiWatchSuspendController.Cancellable {
        val job = scope.launch {
            delay(delayMillis)
            action()
        }
        return WifiWatchSuspendController.Cancellable { job.cancel() }
    }

    private fun setWifiSuspended(suspended: Boolean) {
        val baseService = service as? IBaseService ?: return
        val result = baseService.setWifiSuspended(suspended)
        if (!result.success) {
            GlobalState.log("WiFi-watch setWifiSuspended($suspended) failed: ${result.message}")
        }
    }

    private val wifiNetworkRequest: NetworkRequest
        get() = NetworkRequest.Builder()
            .addTransportType(NetworkCapabilities.TRANSPORT_WIFI)
            .addCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
            .build()

    private fun createWifiNetworkCallback(): ConnectivityManager.NetworkCallback {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            object : ConnectivityManager.NetworkCallback(
                ConnectivityManager.NetworkCallback.FLAG_INCLUDE_LOCATION_INFO
            ) {
                override fun onAvailable(network: Network) {
                    markWifiNetworkAvailable(network)
                }

                override fun onCapabilitiesChanged(
                    network: Network,
                    networkCapabilities: NetworkCapabilities,
                ) {
                    updateWifiNetwork(network, networkCapabilities)
                }

                override fun onLost(network: Network) {
                    removeWifiNetwork(network)
                }

                override fun onUnavailable() {
                    clearWifiNetworks()
                }
            }
        } else {
            object : ConnectivityManager.NetworkCallback() {
                override fun onAvailable(network: Network) {
                    markWifiNetworkAvailable(network)
                }

                override fun onCapabilitiesChanged(
                    network: Network,
                    networkCapabilities: NetworkCapabilities,
                ) {
                    updateWifiNetwork(network, networkCapabilities)
                }

                override fun onLost(network: Network) {
                    removeWifiNetwork(network)
                }

                override fun onUnavailable() {
                    clearWifiNetworks()
                }
            }
        }
    }

    private fun markWifiNetworkAvailable(network: Network) {
        val verdict = wifiVerdict()
        val currentStatus = synchronized(wifiNetworksLock) {
            if (!wifiNetworks.containsKey(network)) {
                wifiNetworks[network] = WifiNetworkStatus(
                    ssid = null,
                    rssi = null,
                    systemValidated = false,
                )
            }
            currentWifiNetworkStatusLocked(verdict)
        }
        publishWifiNetwork(currentStatus, verdict)
    }

    private fun updateKnownWifiNetworks(manager: ConnectivityManager) {
        val verdict = wifiVerdict()
        val status = synchronized(wifiNetworksLock) {
            wifiNetworks.clear()
            manager.allNetworks.forEach { network ->
                val networkStatus = manager.getNetworkCapabilities(network).wifiNetworkStatus()
                if (networkStatus != null) {
                    wifiNetworks[network] = networkStatus
                }
            }
            currentWifiNetworkStatusLocked(verdict)
        }
        publishWifiNetwork(status, verdict)
    }

    private fun updateWifiNetwork(network: Network, capabilities: NetworkCapabilities?) {
        val status = capabilities.wifiNetworkStatus()
        val verdict = wifiVerdict()
        val currentStatus = synchronized(wifiNetworksLock) {
            if (status == null) {
                wifiNetworks.remove(network)
            } else {
                wifiNetworks[network] = status
            }
            currentWifiNetworkStatusLocked(verdict)
        }
        publishWifiNetwork(currentStatus, verdict)
    }

    private fun removeWifiNetwork(network: Network) {
        val verdict = wifiVerdict()
        val status = synchronized(wifiNetworksLock) {
            wifiNetworks.remove(network)
            currentWifiNetworkStatusLocked(verdict)
        }
        publishWifiNetwork(status, verdict)
    }

    private fun clearWifiNetworks() {
        val verdict = wifiVerdict()
        val status = synchronized(wifiNetworksLock) {
            wifiNetworks.clear()
            currentWifiNetworkStatusLocked(verdict)
        }
        publishWifiNetwork(status, verdict)
    }

    private fun publishWifiNetwork(status: WifiNetworkStatus?, verdict: WifiVerdict) {
        val trusted = status?.isTrusted(verdict) == true
        val unresolvedSsid = status != null && status.ssid == null
        synchronized(wifiNetworksLock) {
            lastPublishedStatus = status
        }
        GlobalState.log(
            "WiFi-watch wifi status ssid=${status?.ssid ?: "<none>"} " +
                "rssi=${status?.rssi ?: "<none>"} " +
                "systemValidated=${status?.systemValidated == true} " +
                "verdict=$verdict trusted=$trusted " +
                "(${status?.trustedLabel(verdict) ?: "<none>"})"
        )
        controller.updateWifiNetwork(
            ssid = status?.ssid,
            validated = trusted,
            wifiPresent = status != null,
        )
        when {
            unresolvedSsid -> scheduleWifiResolutionReconcile("SSID unresolved while WiFi present")
            else -> cancelWifiResolutionReconcile("WiFi state resolved")
        }
    }

    private fun scheduleWifiResolutionReconcile(reason: String) {
        if (wifiResolutionReconcileJob != null) {
            return
        }
        GlobalState.log(
            "WiFi-watch start unresolved SSID reconcile reason=$reason " +
                "interval=${SSID_RECONCILE_INTERVAL_MILLIS}ms maxAttempts=$MAX_SSID_RECONCILE_ATTEMPTS"
        )
        wifiResolutionReconcileJob = scope.launch {
            repeat(MAX_SSID_RECONCILE_ATTEMPTS) { attempt ->
                delay(SSID_RECONCILE_INTERVAL_MILLIS)
                val manager = connectivity ?: return@launch
                GlobalState.log(
                    "WiFi-watch unresolved SSID reconcile attempt=${attempt + 1}/" +
                        MAX_SSID_RECONCILE_ATTEMPTS
                )
                updateKnownWifiNetworks(manager)
                if (!shouldRetryWifiResolution()) {
                    GlobalState.log(
                        "WiFi-watch stop unresolved SSID reconcile after attempt=${attempt + 1}"
                    )
                    wifiResolutionReconcileJob = null
                    return@launch
                }
            }
            GlobalState.log(
                "WiFi-watch unresolved SSID reconcile exhausted attempts — " +
                    "controller grace fallback will decide final suspend state"
            )
            wifiResolutionReconcileJob = null
        }
    }

    private fun shouldRetryWifiResolution(): Boolean {
        val verdict = wifiVerdict()
        return synchronized(wifiNetworksLock) {
            val status = currentWifiNetworkStatusLocked(verdict)
            status != null && status.ssid == null
        }
    }

    private fun cancelWifiResolutionReconcile(reason: String) {
        val job = wifiResolutionReconcileJob ?: return
        GlobalState.log("WiFi-watch cancel unresolved SSID reconcile: $reason")
        wifiResolutionReconcileJob = null
        job.cancel()
    }

    private fun currentWifiNetworkStatusLocked(verdict: WifiVerdict): WifiNetworkStatus? {
        // Prefer a network that already reads as trusted under the active
        // verdict (validated when no VPN, or strong RSSI when a VPN is active),
        // otherwise fall back to the first known WiFi network so the controller
        // still observes the SSID change (e.g. switching between access points).
        return wifiNetworks.values.firstOrNull {
            it.isTrusted(verdict) && it.ssid != null
        } ?: wifiNetworks.values.firstOrNull()
    }

    private fun NetworkCapabilities?.wifiNetworkStatus(): WifiNetworkStatus? {
        if (this == null) return null
        if (!hasTransport(NetworkCapabilities.TRANSPORT_WIFI)) return null
        if (!hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)) return null
        val info = readWifiInfo()
        return WifiNetworkStatus(
            ssid = normalizeSsid(info?.ssid),
            rssi = info?.rssi?.takeIf { it != INVALID_RSSI },
            systemValidated = hasCapability(NetworkCapabilities.NET_CAPABILITY_VALIDATED),
        )
    }

    private fun NetworkCapabilities.readWifiInfo(): WifiInfo? {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            transportInfo as? WifiInfo
        } else {
            @Suppress("DEPRECATION")
            wifiManager?.connectionInfo
        }
    }

    /**
     * Resolves how the current WiFi network should be judged as trusted.
     *
     * While a VPN tunnel is the default network, Android stops reporting
     * NET_CAPABILITY_VALIDATED for the underlying WiFi (it validates the VPN
     * instead). In that case fall back to the WiFi signal strength (RSSI):
     * a strong signal implies a usable direct connection, so suspending the
     * proxy is safe; a weak or unknown signal keeps the proxy active.
     */
    private fun wifiVerdict(): WifiVerdict {
        return if (isVpnActive()) WifiVerdict.Rssi else WifiVerdict.SystemValidated
    }

    private fun isVpnActive(): Boolean {
        val manager = connectivity ?: return false
        val capabilities = manager.getNetworkCapabilities(manager.activeNetwork)
        return capabilities?.hasTransport(NetworkCapabilities.TRANSPORT_VPN) == true
    }

    private data class WifiNetworkStatus(
        val ssid: String?,
        val rssi: Int?,
        val systemValidated: Boolean,
    )

    private enum class WifiVerdict { SystemValidated, Rssi }

    private fun WifiNetworkStatus.isTrusted(verdict: WifiVerdict): Boolean {
        return when (verdict) {
            WifiVerdict.SystemValidated -> systemValidated
            WifiVerdict.Rssi -> rssi != null && rssi >= WEAK_RSSI_THRESHOLD_DBM
        }
    }

    private fun WifiNetworkStatus.trustedLabel(verdict: WifiVerdict): String {
        return when (verdict) {
            WifiVerdict.SystemValidated -> systemValidated.toString()
            WifiVerdict.Rssi -> "rssi=${rssi ?: "<none>"} >= $WEAK_RSSI_THRESHOLD_DBM"
        }
    }

    private fun normalizeSsid(ssid: String?): String? {
        return if (ssid == null || ssid == "<unknown ssid>" || ssid == "0x") {
            null
        } else {
            ssid.removeSurrounding("\"")
        }
    }

    fun currentState(serviceSuspended: Boolean): WifiWatchState {
        val controllerStatus = controller.currentStatus()
        val status = synchronized(wifiNetworksLock) { lastPublishedStatus }
        return WifiWatchState(
            ssid = controllerStatus.ssid ?: status?.ssid,
            rssi = status?.rssi,
            validated = controllerStatus.validated,
            wifiPresent = controllerStatus.wifiPresent,
            suspended = serviceSuspended,
            pendingSuspendDeadline = controllerStatus.pendingSuspendDeadline,
        )
    }

    override fun onUninstall() {
        cancelWifiResolutionReconcile("module uninstall")
        runCatching {
            connectivity?.unregisterNetworkCallback(callback)
        }
        synchronized(wifiNetworksLock) {
            wifiNetworks.clear()
        }
        controller.cancel()
        scope.cancel()
    }

    companion object {
        // Sentinel returned by WifiInfo.getRssi() when the value is unknown.
        private const val INVALID_RSSI = -127

        // Minimum RSSI (dBm) treated as a strong-enough WiFi signal to suspend
        // the proxy while a VPN tunnel is active. -80 dBm is the widely cited
        // floor for reliable packet delivery; below it the connection is
        // considered weak and the proxy stays active.
        const val WEAK_RSSI_THRESHOLD_DBM = -80
        private const val SSID_RECONCILE_INTERVAL_MILLIS = 500L
        private const val MAX_SSID_RECONCILE_ATTEMPTS = 4
    }
}
