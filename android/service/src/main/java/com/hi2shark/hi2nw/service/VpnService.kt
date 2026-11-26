package com.hi2shark.hi2nw.service

import android.content.Intent
import android.content.pm.PackageManager
import android.net.ConnectivityManager
import android.net.IpPrefix
import android.net.Network
import android.net.ProxyInfo
import android.os.Binder
import android.os.Build
import android.os.IBinder
import androidx.core.content.getSystemService
import com.hi2shark.hi2nw.common.AccessControlMode
import com.hi2shark.hi2nw.common.GlobalState
import com.hi2shark.hi2nw.common.R as CommonR
import com.hi2shark.hi2nw.core.Core
import com.hi2shark.hi2nw.service.models.CIDR
import com.hi2shark.hi2nw.service.models.VpnOptions
import com.hi2shark.hi2nw.service.models.getIpv4RouteAddress
import com.hi2shark.hi2nw.service.models.getIpv4RouteExcludeAddress
import com.hi2shark.hi2nw.service.models.getIpv6RouteAddress
import com.hi2shark.hi2nw.service.models.getIpv6RouteExcludeAddress
import com.hi2shark.hi2nw.service.models.toCIDR
import com.hi2shark.hi2nw.service.models.tunMtu
import com.hi2shark.hi2nw.service.models.tunOptions
import com.hi2shark.hi2nw.service.modules.ServiceModules
import com.hi2shark.hi2nw.service.modules.promoteToInitialForeground
import com.hi2shark.hi2nw.service.modules.stopForegroundCompat
import com.google.gson.Gson
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.drop
import kotlinx.coroutines.launch
import java.net.InetSocketAddress
import java.util.concurrent.ConcurrentHashMap
import android.net.VpnService as SystemVpnService

class VpnService : SystemVpnService(), ManagedService {
    private val modules = ServiceModules(this)
    private val binder = LocalBinder()
    private val tunLock = Any()
    private var tunRunning = false
    private var serviceScope: CoroutineScope? = null
    private var underlyingNetworkJob: Job? = null

    @Volatile
    private var running = false

    private val suspensionController = SuspensionController(
        serviceName = "VPN service",
        isRunning = { running },
        applySuspended = {
            VpnSuspendController(
                currentOptions = { ServiceConfig.vpnOptions },
                stopTun = { stopTunLocked() },
                startTun = { handleStart(it) },
            ).setSuspended(it)
        },
        onSuspendedChanged = { notifySuspendedChanged(it) },
    )

    override val isVpn: Boolean = true

    override val isSuspended: Boolean
        get() = suspensionController.isSuspended

    override fun setSuspended(suspended: Boolean): ServiceStartResult =
        suspensionController.setExternalSuspended(suspended)

    override fun setWifiSuspended(suspended: Boolean): ServiceStartResult =
        suspensionController.setWifiSuspended(suspended)

    override fun getWifiWatchStateJson(): String = Gson().toJson(
        modules.wifiWatchModule?.currentState(isSuspended)
            ?: WifiWatchState(
                ssid = null,
                rssi = null,
                validated = false,
                wifiPresent = false,
                suspended = isSuspended,
                pendingSuspendDeadline = null,
            ),
    )

    override fun onDestroy() {
        try {
            cleanup()
        } finally {
            super.onDestroy()
        }
    }

    private val connectivity by lazy {
        getSystemService<ConnectivityManager>()
    }
    private val uidPackageNameMap = ConcurrentHashMap<Int, String>()

    private fun resolveUid(
        protocol: Int,
        source: InetSocketAddress,
        target: InetSocketAddress,
    ): Int {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            return -1
        }
        return connectivity?.getConnectionOwnerUid(protocol, source, target) ?: -1
    }

    private fun resolvePackage(uid: Int): String {
        val cached = uidPackageNameMap[uid]
        if (cached != null) return cached
        val packageName = packageManager
            .getPackagesForUid(uid)
            ?.firstOrNull()
            ?.takeIf { it.isNotEmpty() }
            .orEmpty()
        if (packageName.isEmpty()) {
            return ""
        }
        return uidPackageNameMap.putIfAbsent(uid, packageName) ?: packageName
    }

    private val VpnOptions.tunAddress
        get(): String = buildString {
            append(IPV4_ADDRESS)
            if (ipv6) {
                append(",")
                append(IPV6_ADDRESS)
            }
        }

    private val VpnOptions.tunDns
        get(): String {
            if (!dnsEnable) {
                return ""
            }
            if (dnsHijacking) {
                return NET_ANY
            }
            return buildString {
                append(DNS)
                if (ipv6) {
                    append(",")
                    append(DNS6)
                }
            }
        }

    override fun onLowMemory() {
        lowCoreMemory()
        super.onLowMemory()
    }

    override fun onTrimMemory(level: Int) {
        trimCoreMemory(level)
        super.onTrimMemory(level)
    }

    inner class LocalBinder : Binder() {
        val service: VpnService
            get() = this@VpnService
    }

    override fun onBind(intent: Intent): IBinder? =
        if (intent.action == SystemVpnService.SERVICE_INTERFACE) {
            super.onBind(intent)
        } else {
            binder
        }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (!running) {
            promoteToInitialForeground()
        }
        if (intent?.action != ACTION_HOST_FOREGROUND_START) {
            notifyVpnStartRequested()
        }
        return START_STICKY
    }

    override fun onRevoke() {
        stop()
        notifyVpnRevoked()
    }

    private fun handleStart(options: VpnOptions) {
        val fd = with(Builder()) {
            addAddressAndRoutes(options)
            addDnsServers(options)
            setMtu(options.tunMtu)
            configureAccessControl(options)
            setSession(getString(CommonR.string.app_name))
            setBlocking(false)
            if (options.allowBypass) {
                allowBypass()
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q && options.systemProxy) {
                GlobalState.log("Enable VPN HTTP proxy")
                setHttpProxy(
                    ProxyInfo.buildDirectProxy(
                        LOCAL_HOST,
                        options.port,
                        options.bypassDomain,
                    ),
                )
            }
            establish()?.detachFd()
                ?: error("VPN establishment was rejected by the system")
        }
        applyUnderlyingNetwork(NetworkObserver.activePhysicalNetwork.value)
        synchronized(tunLock) {
            tunRunning = true
            try {
                // A Core that fails to take the descriptor leaves the system
                // routes pointing at an interface nothing reads, and it no
                // longer keeps its own sockets out of them: every connection
                // then hangs until it times out. Tear the VPN down instead of
                // reporting a start that only looks successful.
                check(
                    Core.startTun(
                        fd = fd,
                        protect = this::protect,
                        resolveUid = this::resolveUid,
                        resolvePackage = this::resolvePackage,
                        stack = options.stack,
                        address = options.tunAddress,
                        dns = options.tunDns,
                        options = options.tunOptions,
                    ),
                ) { "Core rejected the tun file descriptor" }
            } catch (error: Exception) {
                stopTunLocked()
                throw error
            }
        }
    }

    private fun Builder.addAddressAndRoutes(options: VpnOptions) {
        val ipv4Address = IPV4_ADDRESS.toCIDR()
        addAddress(ipv4Address.address, ipv4Address.prefixLength)
        val hasIpv4Route = addRoutes(
            routes = options::getIpv4RouteAddress,
            fallbackAddress = NET_ANY,
            routeAll = options.routeAddress.isEmpty(),
        )
        if (hasIpv4Route) {
            excludeRoutes(options::getIpv4RouteExcludeAddress)
        }

        if (options.ipv6) {
            try {
                val ipv6Address = IPV6_ADDRESS.toCIDR()
                addAddress(ipv6Address.address, ipv6Address.prefixLength)
            } catch (_: Exception) {
                GlobalState.log("IPv6 VPN address is not supported")
            }
            val hasIpv6Route = addRoutes(
                routes = options::getIpv6RouteAddress,
                fallbackAddress = NET_ANY6,
                routeAll = options.routeAddress.isEmpty(),
            )
            if (hasIpv6Route) {
                excludeRoutes(options::getIpv6RouteExcludeAddress)
            }
        }
    }

    // Flutter lists every family it routes, so a family missing from a
    // non-empty list is one whose routes were all excluded.
    private fun Builder.addRoutes(
        routes: () -> List<CIDR>,
        fallbackAddress: String,
        routeAll: Boolean,
    ): Boolean {
        val routeList = runCatching(routes).getOrNull()
        if (routeAll || routeList == null) {
            addRoute(fallbackAddress, 0)
            return true
        }
        if (routeList.isEmpty()) {
            return false
        }
        return try {
            routeList.forEach { route ->
                addRoute(route.address, route.prefixLength)
            }
            true
        } catch (_: Exception) {
            addRoute(fallbackAddress, 0)
            true
        }
    }

    private fun Builder.excludeRoutes(routes: () -> List<CIDR>) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            return
        }
        val routeList = runCatching(routes).getOrNull().orEmpty()
        routeList.forEach { route ->
            runCatching {
                excludeRoute(IpPrefix(route.address, route.prefixLength))
            }.onFailure { error ->
                GlobalState.log(
                    "Unable to exclude route ${route.address.hostAddress}/${route.prefixLength}: $error",
                )
            }
        }
    }

    private fun applyUnderlyingNetwork(network: Network?) {
        runCatching {
            setUnderlyingNetworks(network?.let { arrayOf(it) })
        }.onFailure { error ->
            GlobalState.log("Unable to update underlying networks: $error")
        }
    }

    private fun startObservers() {
        stopObservers()
        val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
        serviceScope = scope
        underlyingNetworkJob = scope.launch {
            NetworkObserver.activePhysicalNetwork.collect { network ->
                if (running && !isSuspended) {
                    applyUnderlyingNetwork(network)
                }
            }
        }
        scope.launch {
            ServiceConfig.packageCacheEpoch.drop(1).collect {
                uidPackageNameMap.clear()
            }
        }
    }

    private fun stopObservers() {
        underlyingNetworkJob?.cancel()
        underlyingNetworkJob = null
        serviceScope?.cancel()
        serviceScope = null
    }

    private fun Builder.addDnsServers(options: VpnOptions) {
        if (!options.dnsEnable) return
        addDnsServer(DNS)
        if (options.ipv6) {
            addDnsServer(DNS6)
        }
    }

    private fun Builder.configureAccessControl(options: VpnOptions) {
        val accessControl = options.accessControlProps
        if (!accessControl.enable) return
        when (accessControl.mode) {
            AccessControlMode.ACCEPT_SELECTED -> {
                (accessControl.acceptList + packageName).forEach { name ->
                    addApplication(name, ::addAllowedApplication)
                }
            }

            AccessControlMode.REJECT_SELECTED -> {
                (accessControl.rejectList - packageName).forEach { name ->
                    addApplication(name, ::addDisallowedApplication)
                }
            }
        }
    }

    // A selected package that was uninstalled since must not veto the whole tunnel.
    private fun addApplication(name: String, add: (String) -> Builder) {
        try {
            add(name)
        } catch (_: PackageManager.NameNotFoundException) {
            GlobalState.log("Access control skipped an uninstalled package: $name")
        }
    }

    override fun start() {
        try {
            modules.start()
            handleStart(requireNotNull(ServiceConfig.vpnOptions) { "VPN options are missing" })
            running = true
            startObservers()
            // runtimeState gates setSuspended on isRunning, so it must lead.
            ServiceConfig.runtimeState.markStarted()
            suspensionController.reset()
            notifySuspendedChanged(false)
        } catch (error: Exception) {
            stop()
            ServiceConfig.runtimeState.markStartFailed()
            throw error
        }
    }

    override fun stop() {
        try {
            running = false
            suspensionController.reset()
            notifySuspendedChanged(false)
            ServiceConfig.runtimeState.markStopped()
            cleanup()
        } finally {
            stopSelf()
        }
    }

    private fun cleanup() {
        stopObservers()
        uidPackageNameMap.clear()
        try {
            modules.stop()
        } finally {
            try {
                stopTun()
            } finally {
                stopForegroundCompat()
            }
        }
    }

    private fun stopTun() = synchronized(tunLock) {
        stopTunLocked()
    }

    private fun stopTunLocked() {
        if (tunRunning) {
            Core.stopTun()
            tunRunning = false
        }
    }

    companion object {
        // mihomo's own TUN default: 198.18.0.0/15 is benchmarking space no LAN
        // uses, and its fake-ip pool starts at .4, past this /30.
        private const val IPV4_ADDRESS = "198.18.0.1/30"
        private const val IPV6_ADDRESS = "fdfe:dcba:9876::1/126"
        private const val DNS = "198.18.0.2"
        private const val DNS6 = "fdfe:dcba:9876::2"
        private const val NET_ANY = "0.0.0.0"
        private const val NET_ANY6 = "::"
        private const val LOCAL_HOST = "127.0.0.1"
    }
}
