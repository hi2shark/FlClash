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

    override fun onInstall() {
        scope.launch {
            State.suspendOnWifiSsidsFlow.collect {
                controller.updateSuspendOnWifiSsids(it)
            }
        }

        val manager = connectivity
        if (manager == null) {
            controller.updateWifiNetwork(ssid = null, validated = false)
            return
        }
        runCatching {
            manager.registerNetworkCallback(wifiNetworkRequest, callback)
        }.onSuccess {
            updateKnownWifiNetworks(manager)
        }.onFailure {
            GlobalState.log("WiFi-watch registerNetworkCallback failed: ${it.message}")
            controller.updateWifiNetwork(ssid = null, validated = false)
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
                    updateWifiNetwork(network)
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
                    updateWifiNetwork(network)
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

    private fun updateKnownWifiNetworks(manager: ConnectivityManager) {
        val status = synchronized(wifiNetworksLock) {
            wifiNetworks.clear()
            manager.allNetworks.forEach { network ->
                val networkStatus = manager.getNetworkCapabilities(network).wifiNetworkStatus()
                if (networkStatus != null) {
                    wifiNetworks[network] = networkStatus
                }
            }
            currentWifiNetworkStatusLocked()
        }
        publishWifiNetwork(status)
    }

    private fun updateWifiNetwork(network: Network) {
        val capabilities = connectivity?.getNetworkCapabilities(network)
        updateWifiNetwork(network, capabilities)
    }

    private fun updateWifiNetwork(network: Network, capabilities: NetworkCapabilities?) {
        val status = capabilities.wifiNetworkStatus()
        val currentStatus = synchronized(wifiNetworksLock) {
            if (status == null) {
                wifiNetworks.remove(network)
            } else {
                wifiNetworks[network] = status
            }
            currentWifiNetworkStatusLocked()
        }
        publishWifiNetwork(currentStatus)
    }

    private fun removeWifiNetwork(network: Network) {
        val status = synchronized(wifiNetworksLock) {
            wifiNetworks.remove(network)
            currentWifiNetworkStatusLocked()
        }
        publishWifiNetwork(status)
    }

    private fun clearWifiNetworks() {
        val status = synchronized(wifiNetworksLock) {
            wifiNetworks.clear()
            currentWifiNetworkStatusLocked()
        }
        publishWifiNetwork(status)
    }

    private fun publishWifiNetwork(status: WifiNetworkStatus?) {
        GlobalState.log(
            "WiFi-watch wifi status ssid=${status?.ssid ?: "<none>"} " +
                "validated=${status?.validated == true}"
        )
        controller.updateWifiNetwork(
            ssid = status?.ssid,
            validated = status?.validated == true,
        )
    }

    private fun currentWifiNetworkStatusLocked(): WifiNetworkStatus? {
        return wifiNetworks.values.firstOrNull {
            it.validated && it.ssid != null
        } ?: wifiNetworks.values.firstOrNull()
    }

    private fun NetworkCapabilities?.wifiNetworkStatus(): WifiNetworkStatus? {
        if (this == null) return null
        if (!hasTransport(NetworkCapabilities.TRANSPORT_WIFI)) return null
        if (!hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)) return null
        return WifiNetworkStatus(
            ssid = readWifiSsid(),
            validated = hasCapability(NetworkCapabilities.NET_CAPABILITY_VALIDATED),
        )
    }

    private fun NetworkCapabilities.readWifiSsid(): String? {
        val ssid = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            (transportInfo as? WifiInfo)?.ssid
        } else {
            @Suppress("DEPRECATION")
            wifiManager?.connectionInfo?.ssid
        }
        return normalizeSsid(ssid)
    }

    private data class WifiNetworkStatus(
        val ssid: String?,
        val validated: Boolean,
    )

    private fun normalizeSsid(ssid: String?): String? {
        return if (ssid == null || ssid == "<unknown ssid>" || ssid == "0x") {
            null
        } else {
            ssid.removeSurrounding("\"")
        }
    }

    override fun onUninstall() {
        runCatching {
            connectivity?.unregisterNetworkCallback(callback)
        }
        synchronized(wifiNetworksLock) {
            wifiNetworks.clear()
        }
        controller.cancel()
        scope.cancel()
    }
}
