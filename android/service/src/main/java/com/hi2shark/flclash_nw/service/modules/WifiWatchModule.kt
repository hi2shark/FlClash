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
import com.hi2shark.flclash_nw.service.ServiceStartResult
import com.hi2shark.flclash_nw.service.State
import com.hi2shark.flclash_nw.service.WifiWatchResumeRetry
import com.hi2shark.flclash_nw.service.WifiWatchRssi
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

    private val resumeRetry = WifiWatchResumeRetry(
        scheduler = ::schedule,
        applySuspended = ::applyWifiSuspended,
        onAttemptFinished = onStateChanged,
        logger = { GlobalState.log("WiFi-watch $it") },
    )

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
    private var defaultLostReconsider: WifiWatchSuspendController.Cancellable? = null

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

    private fun setWifiSuspended(suspended: Boolean) {
        // Resume failures are retried with backoff so a single establish /
        // startListener failure after long Doze cannot leave the proxy hung.
        // Suspend cancels any pending resume retries. Exhausted resumes keep
        // needsResume so publishWifiNetwork can reconcile later.
        resumeRetry.apply(suspended)
    }

    private fun applyWifiSuspended(suspended: Boolean): ServiceStartResult {
        val baseService = service as? IBaseService
            ?: return ServiceStartResult.failure("service unavailable")
        val result = baseService.setWifiSuspended(suspended)
        if (!result.success) {
            GlobalState.log("WiFi-watch setWifiSuspended($suspended) failed: ${result.message}")
        }
        return result
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
                    handleDefaultNetworkCapabilities(networkCapabilities)
                }

                override fun onLost(network: Network) {
                    // The OS has not nominated a successor yet. Clearing
                    // force-resume immediately would re-enter WiFi suspend
                    // judgment in the gap and could leave the proxy hung if
                    // the next callback is delayed by Doze. Hold state and
                    // re-read the active network after a short delay.
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
        reconsiderForceResumeFromActiveNetwork()
    }

    private fun scheduleDefaultLostReconsider() {
        defaultLostReconsider?.cancel()
        GlobalState.log(
            "WiFi-watch default network lost — reconsider in ${DEFAULT_LOST_RECONSIDER_MILLIS}ms"
        )
        defaultLostReconsider = schedule(DEFAULT_LOST_RECONSIDER_MILLIS) {
            defaultLostReconsider = null
            reconsiderForceResumeFromActiveNetwork(allowEmptyActive = true)
        }
    }

    private fun cancelDefaultLostReconsider(reason: String) {
        val pending = defaultLostReconsider ?: return
        GlobalState.log("WiFi-watch cancel default-lost reconsider: $reason")
        defaultLostReconsider = null
        pending.cancel()
    }

    private fun handleDefaultNetworkCapabilities(caps: NetworkCapabilities) {
        cancelDefaultLostReconsider("default network capabilities arrived")
        val isCellular = caps.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR)
        if (isCellular) {
            controller.forceResume("default network is Cellular")
        } else {
            controller.clearForceResume("default network is no longer Cellular")
        }
    }

    /**
     * Best-effort check of the active default network via the synchronous
     * [ConnectivityManager.getActiveNetwork] + [getNetworkCapabilities] (both
     * available since API 21/23, well within our minSdk = 23). Called on
     * registration and from the WiFi callback path so devices without
     * [registerDefaultNetworkCallback] (API 23) still detect a Cellular
     * default network when the OS switches while WiFi stays associated.
     *
     * When [allowEmptyActive] is true (after a delayed default-network loss),
     * a missing active network or missing capabilities forces resume so the
     * proxy cannot stay suspended in the handover gap. Otherwise we leave the
     * current force-resume state untouched and wait for the next callback.
     */
    private fun reconsiderForceResumeFromActiveNetwork(allowEmptyActive: Boolean = false) {
        val manager = connectivity ?: return
        val active = manager.activeNetwork
        if (active == null) {
            if (allowEmptyActive) {
                controller.forceResume("no active network after default lost")
            }
            return
        }
        val caps = manager.getNetworkCapabilities(active)
        if (caps == null) {
            if (allowEmptyActive) {
                controller.forceResume("active network capabilities unavailable after default lost")
            }
            return
        }
        val isCellular = caps.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR)
        if (isCellular) {
            controller.forceResume("active network is Cellular")
        } else {
            controller.clearForceResume("active network is not Cellular")
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
        val trusted = when {
            status == null -> {
                lastRssiTrusted = false
                false
            }
            verdict == WifiVerdict.SystemValidated -> {
                lastRssiTrusted = false
                status.systemValidated
            }
            else -> {
                val next = WifiWatchRssi.isTrusted(status.rssi, lastRssiTrusted)
                lastRssiTrusted = next
                next
            }
        }
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
        // Best-effort default-network recheck. On API 24+ the dedicated default
        // network callback drives forceResume immediately; this is a cheap
        // secondary signal. On API 23 (no registerDefaultNetworkCallback) this
        // is the primary signal — without it, API 23 users would never
        // force-resume when the OS switches the default to Cellular while WiFi
        // stays associated.
        reconsiderForceResumeFromActiveNetwork()
        // If a previous resume budget was exhausted and no long-delay reconcile
        // is pending yet, kick one from capability updates (quiet networks also
        // get WifiWatchResumeRetry's own 10s reconcile timer).
        if (resumeRetry.needsResume) {
            resumeRetry.reconcileIfNeeded()
        }
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
        // Only use WifiManager fallback while we still track at least one WiFi
        // network from ConnectivityManager. Once the local map is empty
        // (onLost / onUnavailable), a stale connectionInfo SSID must not keep
        // wifiPresent=true and block resume.
        if (wifiNetworks.isNotEmpty() && hasWifiTransport()) {
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

    // Last RSSI-based trust decision, used for hysteresis between enter/exit
    // thresholds so a signal hovering near -80 dBm does not flap suspend/resume.
    private var lastRssiTrusted: Boolean = false

    private fun WifiNetworkStatus.isTrusted(verdict: WifiVerdict): Boolean {
        // Pure read for network selection — does not mutate hysteresis state.
        // publishWifiNetwork owns lastRssiTrusted updates.
        return when (verdict) {
            WifiVerdict.SystemValidated -> systemValidated
            WifiVerdict.Rssi -> WifiWatchRssi.isTrusted(rssi, lastRssiTrusted)
        }
    }

    private fun WifiNetworkStatus.trustedLabel(verdict: WifiVerdict): String {
        return when (verdict) {
            WifiVerdict.SystemValidated -> systemValidated.toString()
            WifiVerdict.Rssi ->
                "rssi=${rssi ?: "<none>"} enter>=${WifiWatchRssi.RSSI_ENTER_TRUSTED_DBM} " +
                    "exit<${WifiWatchRssi.RSSI_EXIT_TRUSTED_DBM} trusted=$lastRssiTrusted"
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
        // present AND we still track a ConnectivityManager WiFi network. Once
        // the map is empty the WiFi is gone — do not resurrect a stale SSID.
        val hasTrackedWifi = synchronized(wifiNetworksLock) { wifiNetworks.isNotEmpty() }
        val fallback = if (status?.rssi == null && hasTrackedWifi && hasWifiTransport()) {
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
        cancelDefaultLostReconsider("module uninstall")
        resumeRetry.cancel("module uninstall")
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

        /** @deprecated Use [WifiWatchRssi.RSSI_ENTER_TRUSTED_DBM]. */
        const val WEAK_RSSI_THRESHOLD_DBM = WifiWatchRssi.RSSI_ENTER_TRUSTED_DBM

        const val RSSI_ENTER_TRUSTED_DBM = WifiWatchRssi.RSSI_ENTER_TRUSTED_DBM
        const val RSSI_EXIT_TRUSTED_DBM = WifiWatchRssi.RSSI_EXIT_TRUSTED_DBM

        fun isRssiTrusted(rssi: Int?, wasTrusted: Boolean): Boolean =
            WifiWatchRssi.isTrusted(rssi, wasTrusted)

        private const val SSID_RECONCILE_INTERVAL_MILLIS = 500L
        private const val MAX_SSID_RECONCILE_ATTEMPTS = 4
        // Delay before re-reading the active network after the default network
        // is lost, giving the OS time to nominate Cellular / the next WiFi.
        const val DEFAULT_LOST_RECONSIDER_MILLIS = 1500L
    }
}
