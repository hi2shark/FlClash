package com.hi2shark.flclash_nw.service.modules

import android.app.Service
import android.content.Context
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import android.net.wifi.ScanResult
import android.net.wifi.WifiInfo
import android.net.wifi.WifiManager
import android.os.Build
import android.os.PowerManager
import androidx.core.content.getSystemService
import com.hi2shark.flclash_nw.common.GlobalState
import com.hi2shark.flclash_nw.service.IBaseService
import com.hi2shark.flclash_nw.service.State
import com.hi2shark.flclash_nw.service.WifiWatchState
import com.hi2shark.flclash_nw.service.WifiWatchSuspendController
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

class WifiWatchModule(
    private val service: Service,
    private val onStateChanged: () -> Unit = {},
) : Module() {
    private val scope = CoroutineScope(Dispatchers.Default)
    private val connectivity by lazy {
        service.getSystemService<ConnectivityManager>()
    }
    private val wifiManager by lazy {
        service.applicationContext.getSystemService(Context.WIFI_SERVICE) as? WifiManager
    }

    /**
     * Whether this service drives a system VPN tunnel. Cached at construction
     * (the service type never changes). Only when this is true AND a VPN
     * transport is the active network do we fall back to RSSI-based trust,
     * because our own tunnel obscures the underlying WiFi's validated state.
     * Third-party VPNs or the proxy-only CommonService must not trigger the
     * RSSI fallback.
     */
    private val isOwnVpnService: Boolean =
        (service as? IBaseService)?.isVpn == true

    private val wakeLock by lazy {
        (service.applicationContext.getSystemService(Context.POWER_SERVICE) as? PowerManager)
            ?.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "FlClash:WifiWatch")
            ?.apply { setReferenceCounted(false) }
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
    // Default-network callback for immediate Cellular detection. Only
    // registered on API 24+; null on older devices, where Cellular detection
    // falls back to reconsiderForceResumeFromActiveNetwork() called from the
    // WiFi callback path.
    private var defaultNetworkCallback: ConnectivityManager.NetworkCallback? = null
    // Cached transport of the current default network. Only transitions are
    // logged and pushed to the controller, so a stable network does not
    // generate per-callback chatter.
    @Volatile
    private var lastDefaultTransport: DefaultTransport? = null
    // Human-readable reason for the current force-resume (null when not forced).
    // Surfaced to the UI via WifiWatchState.reason for diagnostics.
    @Volatile
    private var forceResumeReason: String? = null
    // Pending deferred re-evaluation scheduled on default-network loss. The OS
    // may take a moment to nominate a new default; we hold the current
    // force-resume state through that gap instead of flipping immediately.
    private var defaultLostReconsiderJob: Job? = null

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
        registerDefaultNetworkWatch(manager)
    }

    private fun schedule(delayMillis: Long, action: () -> Unit): WifiWatchSuspendController.Cancellable {
        val job = scope.launch {
            // Keep the CPU awake while waiting for the delayed suspend so that
            // Doze / app-standby does not defer the timer.
            val lock = wakeLock
            runCatching {
                lock?.acquire(delayMillis + 1000)
            }
            delay(delayMillis)
            action()
            runCatching {
                if (lock?.isHeld == true) lock.release()
            }
        }
        return WifiWatchSuspendController.Cancellable {
            job.cancel()
            runCatching {
                if (wakeLock?.isHeld == true) wakeLock?.release()
            }
        }
    }

    private fun setWifiSuspended(suspended: Boolean): Boolean {
        val baseService = service as? IBaseService ?: return false
        val result = baseService.setWifiSuspended(suspended)
        if (!result.success) {
            GlobalState.log("WiFi-watch setWifiSuspended($suspended) failed: ${result.message}")
        }
        // The actual suspend decision changed (or was attempted); push state so
        // the UI reflects the new suspended/pendingDeadline immediately rather
        // than waiting for the next poll.
        onStateChanged()
        return result.success
    }

    private val wifiNetworkRequest: NetworkRequest
        get() = NetworkRequest.Builder()
            .addTransportType(NetworkCapabilities.TRANSPORT_WIFI)
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

    /**
     * Watches the system default network. When the OS routes traffic through a
     * Cellular network (e.g. WiFi still associated but the system prefers
     * mobile data, or WiFi lost internet validation and the OS fell back to
     * mobile), the proxy is forced back on regardless of WiFi SSID trust — the
     * user clearly needs proxying on the metered/active path. The force hold is
     * lifted once the default network is no longer Cellular.
     *
     * Two paths feed the cellular check:
     *  - API 24+ ([registerDefaultNetworkCallback]): immediate, event-driven.
     *  - All versions (including API 23 where the default callback is absent):
     *    a best-effort poll on every WiFi capability update via
     *    [reconsiderForceResumeFromActiveNetwork], which catches the common
     *    case where the WiFi callback fires around the same time the OS
     *    switches the default network.
     *
     * Per Android guidance, [ConnectivityManager.NetworkCallback.onAvailable]
     * only marks a network as candidate; its capabilities may not be populated
     * yet. We therefore defer the transport check to [onCapabilitiesChanged]
     * and only seed the initial state from the active network synchronously
     * (where capabilities are already known).
     */
    private fun registerDefaultNetworkWatch(manager: ConnectivityManager) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            val cb = object : ConnectivityManager.NetworkCallback() {
                override fun onAvailable(network: Network) {
                    // Intentionally no capability read here: onAvailable may
                    // arrive before the network's capabilities are populated.
                    // Wait for onCapabilitiesChanged.
                }

                override fun onCapabilitiesChanged(
                    network: Network,
                    networkCapabilities: NetworkCapabilities,
                ) {
                    // A new default network is confirmed; cancel any pending
                    // post-loss re-evaluation and apply the fresh transport.
                    cancelDefaultLostReconsider()
                    applyDefaultTransport(DefaultTransport.from(networkCapabilities))
                }

                override fun onLost(network: Network) {
                    // The OS has not nominated a successor yet. Clearing
                    // force-resume immediately would re-enter WiFi suspend
                    // judgment in the gap and could cause a suspend/resume
                    // flap. Instead, hold the current state and re-read the
                    // active network after a short delay — by then the OS has
                    // usually picked a new default, whose capabilities drive
                    // the final decision (and cancel this job).
                    scheduleDefaultLostReconsider()
                }
            }
            runCatching {
                manager.registerDefaultNetworkCallback(cb)
            }.onSuccess {
                defaultNetworkCallback = cb
            }.onFailure {
                GlobalState.log("WiFi-watch registerDefaultNetworkCallback failed: ${it.message}")
            }
        }
        // Seed the initial state on all versions. On API 24+ this covers the
        // case where the default network is already stable and no callback
        // fires right after registration; on API 23 this is the primary signal.
        applyDefaultTransport(currentDefaultTransport())
    }

    /**
     * Snapshots the current default-network transport from the synchronous
     * [ConnectivityManager.getActiveNetwork] + [getNetworkCapabilities] (both
     * available since API 21/23, within minSdk = 23). Returns null when there
     * is no active network or capabilities are not yet ready — callers treat
     * null as "no change" so the next callback retries.
     */
    private fun currentDefaultTransport(): DefaultTransport? {
        val manager = connectivity ?: return null
        val active = manager.activeNetwork ?: return null
        return DefaultTransport.from(manager.getNetworkCapabilities(active))
    }

    /**
     * Applies the default-network transport to the controller and the cached
     * [lastDefaultTransport]. Idempotent: a repeated identical transport is a
     * no-op (no log, no controller call), so a stable network does not
     * generate per-callback chatter. Also feeds [forceResumeReason] for UI.
     */
    private fun applyDefaultTransport(transport: DefaultTransport?) {
        if (transport == null) return
        if (transport == lastDefaultTransport) return
        val previous = lastDefaultTransport
        lastDefaultTransport = transport
        forceResumeReason = if (transport == DefaultTransport.CELLULAR) {
            "default network is Cellular"
        } else {
            null
        }
        GlobalState.log(
            "WiFi-watch default transport $previous -> $transport" +
                (forceResumeReason?.let { " ($it)" } ?: "")
        )
        if (transport == DefaultTransport.CELLULAR) {
            controller.forceResume(forceResumeReason!!)
        } else {
            controller.clearForceResume("default transport is $transport")
        }
        onStateChanged()
    }

    /**
     * Best-effort re-evaluation of the active default network, called from
     * the WiFi callback path so devices without registerDefaultNetworkCallback
     * (API 23) still detect a Cellular default network when the OS switches
     * while WiFi stays associated. Routes through [applyDefaultTransport] so
     * the transport cache and dedup logic are shared.
     */
    private fun reconsiderForceResumeFromActiveNetwork() {
        applyDefaultTransport(currentDefaultTransport())
    }

    private fun scheduleDefaultLostReconsider() {
        cancelDefaultLostReconsider()
        defaultLostReconsiderJob = scope.launch {
            delay(DEFAULT_LOST_RECONSIDER_MILLIS)
            // By now the OS has usually nominated a new default network; read
            // it and let applyDefaultTransport decide. If there is still no
            // active network, leave the current state as-is rather than
            // optimistically clearing force-resume.
            reconsiderForceResumeFromActiveNetwork()
        }
    }

    private fun cancelDefaultLostReconsider() {
        defaultLostReconsiderJob?.cancel()
        defaultLostReconsiderJob = null
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
            // RSSI verdict means trust is inferred from signal strength, not
            // from the system's NET_CAPABILITY_VALIDATED. The controller uses
            // this to forbid RSSI from initiating a new suspend.
            rssiBasedTrust = verdict == WifiVerdict.Rssi,
        )
        when {
            unresolvedSsid -> scheduleWifiResolutionReconcile("SSID unresolved while WiFi present")
            else -> cancelWifiResolutionReconcile("WiFi state resolved")
        }
        // Best-effort default-network recheck. On API 24+ the dedicated default
        // network callback drives forceResume immediately; this is a cheap
        // secondary signal. On API 23 (no registerDefaultNetworkCallback) this
        // is the primary signal — without it, API 23 users would never
        // force-resume when the OS switches the default to Cellular while WiFi
        // stays associated.
        reconsiderForceResumeFromActiveNetwork()
        onStateChanged()
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
        val status = wifiNetworks.values.firstOrNull {
            it.isTrusted(verdict) && it.ssid != null
        } ?: wifiNetworks.values.firstOrNull()
        if (status?.ssid != null) return status
        // If ConnectivityManager cannot see the underlying WiFi (common when a
        // VPN tunnel is the default network) but a WiFi transport is still
        // reported, fall back to WifiManager. Avoid the fallback when the
        // system no longer reports any WiFi transport (real WiFi loss).
        if (hasWifiTransport()) {
            readWifiManagerFallback()?.let { return it }
        }
        return status
    }

    private fun hasWifiTransport(): Boolean {
        val manager = connectivity ?: return false
        return manager.allNetworks.any {
            manager.getNetworkCapabilities(it)
                ?.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) == true
        }
    }

    private fun NetworkCapabilities?.wifiNetworkStatus(): WifiNetworkStatus? {
        if (this == null) return null
        if (!hasTransport(NetworkCapabilities.TRANSPORT_WIFI)) return null
        val info = readWifiInfo()
        return WifiNetworkStatus(
            ssid = normalizeSsid(info?.ssid),
            rssi = resolveRssi(info) ?: signalStrengthOrNull(),
            systemValidated = hasCapability(NetworkCapabilities.NET_CAPABILITY_VALIDATED),
        )
    }

    private fun NetworkCapabilities.signalStrengthOrNull(): Int? {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            signalStrength.takeIf { it != NetworkCapabilities.SIGNAL_STRENGTH_UNSPECIFIED }
        } else {
            null
        }
    }

    /**
     * Fallback to the legacy WiFi connection info when the ConnectivityManager
     * view is restricted (for example while our own VPN tunnel is the default
     * network). This keeps the suspend-on-WiFi logic working as long as the
     * system still exposes the current SSID/RSSI.
     */
    @Suppress("DEPRECATION")
    private fun readWifiManagerFallback(): WifiNetworkStatus? {
        val info = runCatching { wifiManager?.connectionInfo }.getOrNull() ?: return null
        val ssid = normalizeSsid(info.ssid) ?: return null
        val rssi = resolveRssi(info)
        GlobalState.log(
            "WiFi-watch WifiManager fallback ssid=$ssid rssi=${rssi ?: "<none>"}"
        )
        return WifiNetworkStatus(
            ssid = ssid,
            rssi = rssi,
            systemValidated = false,
        )
    }

    private fun resolveRssi(info: WifiInfo?): Int? {
        val fromWifiInfo = info?.rssi?.takeIf { it != INVALID_RSSI }
        if (fromWifiInfo != null) return fromWifiInfo
        return null
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
     * While our own VPN tunnel is the default network, Android stops reporting
     * NET_CAPABILITY_VALIDATED for the underlying WiFi (it validates the VPN
     * instead). In that case fall back to the WiFi signal strength (RSSI):
     * a strong signal implies a usable direct connection, so suspending the
     * proxy is safe; a weak or unknown signal keeps the proxy active.
     *
     * The fallback applies only when this module runs inside the VpnService
     * ([isOwnVpnService]) AND a VPN transport is the active network. A
     * third-party VPN running alongside the proxy-only CommonService does not
     * obscure our view of WiFi validation, so we keep using SystemValidated
     * and avoid a false-positive suspend.
     */
    private fun wifiVerdict(): WifiVerdict {
        return if (isOwnVpnService && isVpnActive()) WifiVerdict.Rssi
        else WifiVerdict.SystemValidated
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

    /**
     * Coarse classification of the system default network's transport, used to
     * (a) decide Cellular force-resume and (b) surface the reason to the UI.
     * Only the dominant transport is recorded.
     */
    private enum class DefaultTransport {
        WIFI, CELLULAR, VPN, ETHERNET, OTHER;

        companion object {
            fun from(caps: NetworkCapabilities?): DefaultTransport? {
                if (caps == null) return null
                return when {
                    caps.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) -> CELLULAR
                    caps.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) -> WIFI
                    caps.hasTransport(NetworkCapabilities.TRANSPORT_VPN) -> VPN
                    caps.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) -> ETHERNET
                    else -> OTHER
                }
            }
        }
    }

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
        // Some devices do not expose RSSI through NetworkCapabilities; use the
        // legacy WifiManager fallback for the UI if a WiFi transport is still
        // present.
        val fallback = if (status?.rssi == null && hasWifiTransport()) {
            readWifiManagerFallback()
        } else {
            null
        }
        val signalStrengthRssi = readSignalStrengthFromAllNetworks()
        val scanRssi = readScanResultRssi()
        val rssi = status?.rssi
            ?: fallback?.rssi
            ?: signalStrengthRssi
            ?: scanRssi
        GlobalState.log(
            "WiFi-watch currentState ssid=${controllerStatus.ssid ?: status?.ssid ?: fallback?.ssid ?: "<none>"} " +
                "rssi=${rssi ?: "<none>"} " +
                "sources=(status=${status?.rssi ?: "x"}, fallback=${fallback?.rssi ?: "x"}, " +
                "signalStrength=${signalStrengthRssi ?: "x"}, scan=${scanRssi ?: "x"})"
        )
        return WifiWatchState(
            ssid = controllerStatus.ssid ?: status?.ssid ?: fallback?.ssid,
            rssi = rssi,
            validated = controllerStatus.validated,
            wifiPresent = controllerStatus.wifiPresent,
            suspended = serviceSuspended,
            pendingSuspendDeadline = controllerStatus.pendingSuspendDeadline,
            forceResumed = controllerStatus.forceResumed,
            reason = forceResumeReason,
        )
    }

    private fun readSignalStrengthFromAllNetworks(): Int? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return null
        val manager = connectivity ?: return null
        return manager.allNetworks.firstNotNullOfOrNull { network ->
            manager.getNetworkCapabilities(network)?.takeIf {
                it.hasTransport(NetworkCapabilities.TRANSPORT_WIFI)
            }?.signalStrength?.takeIf {
                it != NetworkCapabilities.SIGNAL_STRENGTH_UNSPECIFIED
            }
        }
    }

    /**
     * Last-resort RSSI source: the most recent WiFi scan results. This matches
     * what apps like Cellular-Z use to display signal strength when the
     * simplified APIs above return invalid values.
     */
    @Suppress("DEPRECATION")
    private fun readScanResultRssi(): Int? {
        val wm = wifiManager ?: return null
        val info = runCatching { wm.connectionInfo }.getOrNull() ?: return null
        val connectedSsid = normalizeSsid(info.ssid) ?: return null
        val connectedBssid = info.bssid?.takeIf { it != "02:00:00:00:00:00" }
        // Best-effort refresh. Scanning is throttled by the system; if it fails
        // we still fall back to the last cached results.
        runCatching { wm.startScan() }
        val results = runCatching { wm.scanResults }.getOrNull()
        val rssi = results?.firstOrNull { result ->
            if (connectedBssid != null && result.BSSID != null) {
                result.BSSID == connectedBssid
            } else {
                normalizeSsid(result.SSID) == connectedSsid
            }
        }?.level
        GlobalState.log(
            "WiFi-watch scan result count=${results?.size ?: 0} rssi=${rssi ?: "<none>"}"
        )
        return rssi
    }

    override fun onUninstall() {
        cancelWifiResolutionReconcile("module uninstall")
        cancelDefaultLostReconsider()
        runCatching {
            connectivity?.unregisterNetworkCallback(callback)
        }
        defaultNetworkCallback?.let { cb ->
            runCatching {
                connectivity?.unregisterNetworkCallback(cb)
            }
        }
        defaultNetworkCallback = null
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

        // Grace period after the default network is lost before re-reading the
        // active network. The OS usually nominates a successor within this
        // window; holding the current force-resume state through it avoids a
        // suspend/resume flap during the handoff.
        private const val DEFAULT_LOST_RECONSIDER_MILLIS = 1500L
    }
}
