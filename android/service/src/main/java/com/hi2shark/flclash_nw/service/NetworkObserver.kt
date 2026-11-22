package com.hi2shark.flclash_nw.service

import android.net.ConnectivityManager
import android.net.LinkProperties
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkCapabilities.TRANSPORT_SATELLITE
import android.net.NetworkCapabilities.TRANSPORT_USB
import android.net.NetworkRequest
import android.os.Build
import android.os.Handler
import android.os.HandlerThread
import androidx.core.content.getSystemService
import com.hi2shark.flclash_nw.common.GlobalState
import com.hi2shark.flclash_nw.core.Core
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import java.net.Inet4Address
import java.net.Inet6Address
import java.net.InetAddress
import java.util.concurrent.ConcurrentHashMap

private data class NetworkInfo(
    @Volatile var losingUntilMillis: Long = 0,
    @Volatile var dnsList: List<InetAddress> = emptyList(),
    @Volatile var validated: Boolean = false,
    @Volatile var transportPriority: Int = UNKNOWN_TRANSPORT_PRIORITY,
)

// Outlives every service run: the Core also tests delays and updates providers
// while stopped, and a `system` nameserver has no upstream until DNS arrives here.
object NetworkObserver {

    private val networkInfos = ConcurrentHashMap<Network, NetworkInfo>()
    private val mutableActivePhysicalNetwork = MutableStateFlow<Network?>(null)
    val activePhysicalNetwork: StateFlow<Network?> = mutableActivePhysicalNetwork.asStateFlow()

    private val connectivity by lazy {
        GlobalState.application.getSystemService<ConnectivityManager>()
    }
    private val handler by lazy {
        Handler(HandlerThread("NetworkObserve").apply { start() }.looper)
    }
    private var currentDnsList = listOf<String>()
    private var currentNetwork: Network? = null
    @Volatile
    private var bestMatchingNetwork: Network? = null
    private var started = false

    private val request = NetworkRequest.Builder().apply {
        addCapability(NetworkCapabilities.NET_CAPABILITY_NOT_VPN)
        addCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            addCapability(NetworkCapabilities.NET_CAPABILITY_FOREGROUND)
        }
        addCapability(NetworkCapabilities.NET_CAPABILITY_NOT_RESTRICTED)
    }.build()

    private val callback = object : ConnectivityManager.NetworkCallback() {
        override fun onAvailable(network: Network) {
            if (usesBestMatchingCallback()) {
                // registerBestMatchingNetworkCallback replaces the previous best network
                // without delivering onLost for it.
                bestMatchingNetwork = network
                networkInfos.keys.retainAll(setOf(network))
            }
            val caps = connectivity?.getNetworkCapabilities(network)
            val info = networkInfos.computeIfAbsent(network) { NetworkInfo() }
            info.losingUntilMillis = 0
            info.validated = caps?.hasCapability(NetworkCapabilities.NET_CAPABILITY_VALIDATED) == true
            info.transportPriority = transportPriorityOf(caps)
            scheduleUpdateDns()
        }

        override fun onCapabilitiesChanged(
            network: Network,
            networkCapabilities: NetworkCapabilities,
        ) {
            val info = networkInfos.computeIfAbsent(network) { NetworkInfo() }
            info.validated = networkCapabilities.hasCapability(
                NetworkCapabilities.NET_CAPABILITY_VALIDATED,
            )
            info.transportPriority = transportPriorityOf(networkCapabilities)
            scheduleUpdateDns()
        }

        override fun onLosing(network: Network, maxMsToLive: Int) {
            val info = networkInfos[network] ?: return
            info.losingUntilMillis = System.currentTimeMillis() + maxMsToLive
            scheduleUpdateDns()
            if (maxMsToLive > 0) {
                handler.postDelayed({
                    if (networkInfos.containsKey(network)) {
                        updateDns()
                    }
                }, maxMsToLive.toLong() + 50)
            }
        }

        override fun onLost(network: Network) {
            if (bestMatchingNetwork == network) {
                bestMatchingNetwork = null
            }
            networkInfos.remove(network)
            scheduleUpdateDns()
        }

        override fun onLinkPropertiesChanged(network: Network, linkProperties: LinkProperties) {
            val info = networkInfos.computeIfAbsent(network) { NetworkInfo() }
            info.dnsList = linkProperties.dnsServers
            scheduleUpdateDns()
        }
    }

    private val updateDnsTask = Runnable(::updateDns)

    // A switch arrives as a burst, and a network that just came up has no DNS
    // until its link properties follow; the Core flushes its cache per list.
    private fun scheduleUpdateDns() {
        handler.removeCallbacks(updateDnsTask)
        handler.postDelayed(updateDnsTask, DNS_UPDATE_DELAY_MILLIS)
    }

    private fun usesBestMatchingCallback(): Boolean =
        Build.VERSION.SDK_INT >= Build.VERSION_CODES.S

    @Synchronized
    fun start() {
        if (started) return
        runCatching {
            val manager = requireNotNull(connectivity)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                manager.registerBestMatchingNetworkCallback(request, callback, handler)
            } else {
                manager.registerNetworkCallback(request, callback)
            }
        }
            .onSuccess { started = true }
            .onFailure { error -> GlobalState.log("Unable to observe networks: $error") }
    }

    private fun transportPriorityOf(capabilities: NetworkCapabilities?): Int = when {
        capabilities == null -> UNKNOWN_TRANSPORT_PRIORITY
        capabilities.hasTransport(NetworkCapabilities.TRANSPORT_VPN) -> 90
        capabilities.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) -> 0
        capabilities.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) -> 1
        Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
            capabilities.hasTransport(TRANSPORT_USB) -> 2

        capabilities.hasTransport(NetworkCapabilities.TRANSPORT_BLUETOOTH) -> 3
        capabilities.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) -> 4
        Build.VERSION.SDK_INT >= Build.VERSION_CODES.VANILLA_ICE_CREAM &&
            capabilities.hasTransport(TRANSPORT_SATELLITE) -> 5

        else -> 20
    }

    private fun resolvePreferredNetwork(): Network? {
        if (usesBestMatchingCallback()) {
            return bestMatchingNetwork
        }
        val now = System.currentTimeMillis()
        val candidates = networkInfos.entries.map { (network, info) ->
            PhysicalNetworkCandidate(
                key = network,
                transportPriority = info.transportPriority,
                validated = info.validated,
                losing = info.losingUntilMillis > now,
            )
        }
        return selectPreferredPhysicalNetwork(candidates)
    }

    @Synchronized
    private fun updateDns() {
        val preferred = resolvePreferredNetwork()
        mutableActivePhysicalNetwork.value = preferred
        val dnsList = preferred
            ?.let { networkInfos[it]?.dnsList }
            .orEmpty()
            .map { address -> address.asSocketAddressText(DNS_PORT) }
            .distinct()
        if (dnsList != currentDnsList) {
            currentDnsList = dnsList
            Core.updateDNS(dnsList.joinToString(","))
        }
        val network = preferred ?: return
        // Sockets protected onto the network we left stay bound to it; closing
        // them makes apps reconnect now instead of after a TCP timeout.
        if (currentNetwork != null && currentNetwork != network) {
            Core.resetNetwork()
        }
        currentNetwork = network
    }
}

private const val DNS_PORT = 53
private const val DNS_UPDATE_DELAY_MILLIS = 200L
private const val UNKNOWN_TRANSPORT_PRIORITY = 100

private fun InetAddress.asSocketAddressText(port: Int): String = when (this) {
    is Inet6Address -> "[$hostAddress]:$port"
    is Inet4Address -> "$hostAddress:$port"
    else -> error("Unsupported address type: ${javaClass.name}")
}
