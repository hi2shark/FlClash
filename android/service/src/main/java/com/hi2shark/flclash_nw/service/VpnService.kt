package com.hi2shark.flclash_nw.service

import android.content.Intent
import android.net.ConnectivityManager
import android.net.ProxyInfo
import android.os.Binder
import android.os.Build
import android.os.IBinder
import android.os.Parcel
import android.os.RemoteException
import android.util.Log
import androidx.core.content.getSystemService
import com.google.gson.Gson
import com.hi2shark.flclash_nw.service.WifiWatchState
import com.hi2shark.flclash_nw.common.AccessControlMode
import com.hi2shark.flclash_nw.common.GlobalState
import com.hi2shark.flclash_nw.core.Core
import com.hi2shark.flclash_nw.service.models.VpnOptions
import com.hi2shark.flclash_nw.service.models.getIpv4RouteAddress
import com.hi2shark.flclash_nw.service.models.getIpv6RouteAddress
import com.hi2shark.flclash_nw.service.models.toCIDR
import com.hi2shark.flclash_nw.service.modules.NetworkObserveModule
import com.hi2shark.flclash_nw.service.modules.NotificationModule
import com.hi2shark.flclash_nw.service.modules.SuspendModule
import com.hi2shark.flclash_nw.service.modules.WifiWatchModule
import com.hi2shark.flclash_nw.service.modules.moduleLoader
import com.hi2shark.flclash_nw.service.modules.startForegroundWithNotification
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import java.net.InetSocketAddress
import android.net.VpnService as SystemVpnService

class VpnService : SystemVpnService(), IBaseService,
    CoroutineScope by CoroutineScope(Dispatchers.Default) {

    private val self: VpnService
        get() = this

    private val loader = moduleLoader {
        install(NetworkObserveModule(self))
        install(NotificationModule(self))
        install(SuspendModule(self))
        // Assign the field before install(): install() runs onInstall()
        // synchronously, which can register the network callback and fire the
        // first onStateChanged() before this block continues. If the field
        // were assigned after install(), getWifiWatchStateJson() would read
        // wifiWatchModule == null and drop SSID/RSSI from the first push.
        val wifiWatchModule = WifiWatchModule(self) {
            notifyWifiWatchStateChanged(getWifiWatchStateJson())
        }
        this@VpnService.wifiWatchModule = wifiWatchModule
        install(wifiWatchModule)
    }

    @Volatile
    private var wifiWatchModule: WifiWatchModule? = null

    override fun getWifiWatchStateJson(): String {
        val state = wifiWatchModule?.currentState(isSuspended) ?: WifiWatchState(
            ssid = null,
            rssi = null,
            validated = false,
            wifiPresent = false,
            suspended = isSuspended,
            pendingSuspendDeadline = null,
        )
        return Gson().toJson(state)
    }

    override var isRunning: Boolean = false
        private set

    override var isSuspended: Boolean = false
        private set

    override val isVpn: Boolean = true

    override val wifiSuspended: Boolean
        get() = suspensionReasons.wifiSuspended

    private val suspensionReasons = ServiceSuspensionReasons()

    // Serializes start / stop / applySuspended so WifiWatch cannot race with
    // user-initiated stop (establish / stopTun overlapping stopSelf).
    private val lifecycleLock = Any()

    private val suspendController = VpnSuspendController(
        currentOptions = { State.options },
        stopTun = Core::stopTun,
        startTun = ::handleStart,
        isSuspended = { isSuspended },
    )

    override fun onCreate() {
        super.onCreate()
        handleCreate()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startForegroundWithNotification()
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        handleDestroy()
        super.onDestroy()
    }

    private val connectivity by lazy {
        getSystemService<ConnectivityManager>()
    }
    private val uidPageNameMap = mutableMapOf<Int, String>()

    private fun resolverProcess(
        protocol: Int,
        source: InetSocketAddress,
        target: InetSocketAddress,
        uid: Int,
    ): String {
        val nextUid = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            connectivity?.getConnectionOwnerUid(protocol, source, target) ?: -1
        } else {
            uid
        }
        if (nextUid == -1) {
            return ""
        }
        if (!uidPageNameMap.containsKey(nextUid)) {
            uidPageNameMap[nextUid] = this.packageManager?.getPackagesForUid(nextUid)?.first() ?: ""
        }
        return uidPageNameMap[nextUid] ?: ""
    }

    val VpnOptions.address
        get(): String = buildString {
            append(IPV4_ADDRESS)
            if (ipv6) {
                append(",")
                append(IPV6_ADDRESS)
            }
        }

    val VpnOptions.dns
        get(): String {
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
        Core.forceGC()
        super.onLowMemory()
    }

    private val binder = LocalBinder()

    inner class LocalBinder : Binder() {
        fun getService(): VpnService = this@VpnService

        override fun onTransact(code: Int, data: Parcel, reply: Parcel?, flags: Int): Boolean {
            try {
                val isSuccess = super.onTransact(code, data, reply, flags)
                if (!isSuccess) {
                    GlobalState.log("VpnService disconnected")
                    handleDestroy()
                }
                return isSuccess
            } catch (e: RemoteException) {
                GlobalState.log("VpnService onTransact $e")
                return false
            }
        }
    }

    override fun onBind(intent: Intent): IBinder {
        return binder
    }

    private fun handleStart(options: VpnOptions) {
        val fd = with(Builder()) {
            val cidr = IPV4_ADDRESS.toCIDR()
            addAddress(cidr.address, cidr.prefixLength)
            Log.d(
                "addAddress", "address: ${cidr.address} prefixLength:${cidr.prefixLength}"
            )
            val routeAddress = options.getIpv4RouteAddress()
            if (routeAddress.isNotEmpty()) {
                try {
                    routeAddress.forEach { i ->
                        Log.d(
                            "addRoute4", "address: ${i.address} prefixLength:${i.prefixLength}"
                        )
                        addRoute(i.address, i.prefixLength)
                    }
                } catch (_: Exception) {
                    addRoute(NET_ANY, 0)
                }
            } else {
                addRoute(NET_ANY, 0)
            }
            if (options.ipv6) {
                try {
                    val cidr = IPV6_ADDRESS.toCIDR()
                    Log.d(
                        "addAddress6", "address: ${cidr.address} prefixLength:${cidr.prefixLength}"
                    )
                    addAddress(cidr.address, cidr.prefixLength)
                } catch (_: Exception) {
                    Log.d(
                        "addAddress6", "IPv6 is not supported."
                    )
                }

                try {
                    val routeAddress = options.getIpv6RouteAddress()
                    if (routeAddress.isNotEmpty()) {
                        try {
                            routeAddress.forEach { i ->
                                Log.d(
                                    "addRoute6",
                                    "address: ${i.address} prefixLength:${i.prefixLength}"
                                )
                                addRoute(i.address, i.prefixLength)
                            }
                        } catch (_: Exception) {
                            addRoute("::", 0)
                        }
                    } else {
                        addRoute(NET_ANY6, 0)
                    }
                } catch (_: Exception) {
                    addRoute(NET_ANY6, 0)
                }
            }
            addDnsServer(DNS)
            if (options.ipv6) {
                addDnsServer(DNS6)
            }
            setMtu(9000)
            options.accessControlProps.let { accessControl ->
                if (accessControl.enable) {
                    when (accessControl.mode) {
                        AccessControlMode.ACCEPT_SELECTED -> {
                            (accessControl.acceptList + packageName).forEach {
                                addAllowedApplication(it)
                            }
                        }

                        AccessControlMode.REJECT_SELECTED -> {
                            (accessControl.rejectList - packageName).forEach {
                                addDisallowedApplication(it)
                            }
                        }
                    }
                }
            }
            setSession("FlClash")
            setBlocking(false)
            if (Build.VERSION.SDK_INT >= 29) {
                setMetered(false)
            }
            if (options.allowBypass) {
                allowBypass()
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q && options.systemProxy) {
                GlobalState.log("Open http proxy")
                setHttpProxy(
                    ProxyInfo.buildDirectProxy(
                        "127.0.0.1", options.port, options.bypassDomain
                    )
                )
            }
            establish()?.detachFd()
                ?: throw NullPointerException("Establish VPN rejected by system")
        }
        Core.startTun(
            fd,
            protect = this::protect,
            resolverProcess = this::resolverProcess,
            options.stack,
            options.address,
            options.dns
        )
    }

    override fun start(): ServiceStartResult {
        synchronized(lifecycleLock) {
            return try {
                startForegroundWithNotification()
                loader.load()
                State.options?.let {
                    handleStart(it)
                } ?: return ServiceStartResult.failure("VPN options empty")
                isRunning = true
                isSuspended = false
                suspensionReasons.reset()
                notifySuspendedChanged(false)
                ServiceStartResult.success()
            } catch (e: Exception) {
                GlobalState.log("VpnService start failed $e")
                stopLocked()
                ServiceStartResult.failure(e.message ?: "VPN service start failed")
            }
        }
    }

    override fun setSuspended(suspended: Boolean): ServiceStartResult {
        synchronized(lifecycleLock) {
            val previous = suspensionReasons.externalSuspended
            suspensionReasons.setExternalSuspended(suspended)
            val result = applyDesiredSuspendedLocked()
            if (!result.success) {
                suspensionReasons.setExternalSuspended(previous)
            }
            return result
        }
    }

    override fun setWifiSuspended(suspended: Boolean): ServiceStartResult {
        synchronized(lifecycleLock) {
            val previous = suspensionReasons.wifiSuspended
            suspensionReasons.setWifiSuspended(suspended)
            val result = applyDesiredSuspendedLocked()
            if (!result.success) {
                suspensionReasons.setWifiSuspended(previous)
            }
            return result
        }
    }

    override fun setIdleSuspended(suspended: Boolean): ServiceStartResult {
        synchronized(lifecycleLock) {
            val previous = suspensionReasons.idleSuspended
            suspensionReasons.setIdleSuspended(suspended)
            val result = applyDesiredSuspendedLocked()
            if (!result.success) {
                suspensionReasons.setIdleSuspended(previous)
            }
            return result
        }
    }

    private fun applyDesiredSuspendedLocked(): ServiceStartResult {
        return applySuspendedLocked(suspensionReasons.shouldSuspend)
    }

    private fun applySuspendedLocked(suspended: Boolean): ServiceStartResult {
        if (!isRunning) {
            return ServiceStartResult.failure("VPN service is not running")
        }
        if (isSuspended == suspended) {
            return ServiceStartResult.success()
        }
        return try {
            val suspendResult = suspendController.setSuspended(suspended)
            if (!suspendResult.success) return suspendResult
            isSuspended = suspended
            notifySuspendedChanged(suspended)
            ServiceStartResult.success()
        } catch (e: Exception) {
            GlobalState.log("VpnService suspend update failed $e")
            ServiceStartResult.failure(e.message ?: "VPN suspend update failed")
        }
    }

    override fun stop() {
        synchronized(lifecycleLock) {
            stopLocked()
        }
    }

    private fun stopLocked() {
        isRunning = false
        isSuspended = false
        suspensionReasons.reset()
        notifySuspendedChanged(false)
        // Uninstall WifiWatch (and other modules) before stopTun so a pending
        // delayed suspend / force-resume cannot call establish after we tear down.
        loader.cancelAndJoin()
        wifiWatchModule = null
        Core.stopTun()
        stopSelf()
    }

    companion object {
        private const val IPV4_ADDRESS = "172.19.0.1/30"
        private const val IPV6_ADDRESS = "fdfe:dcba:9876::1/126"
        private const val DNS = "172.19.0.2"
        private const val DNS6 = "fdfe:dcba:9876::2"
        private const val NET_ANY = "0.0.0.0"
        private const val NET_ANY6 = "::"
    }
}
