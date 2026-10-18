package com.hi2shark.flclash_nw.wifi_ssid

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import android.net.wifi.WifiInfo
import android.net.wifi.WifiManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.core.content.edit
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.RequestPermissionsResultListener
import java.util.concurrent.ConcurrentHashMap

class WifiSsidPlugin : FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler, ActivityAware {
    private lateinit var channel: MethodChannel
    private lateinit var validatedWifiSsidChannel: EventChannel
    private var context: Context? = null
    private var activity: Activity? = null
    private var wifiManager: WifiManager? = null
    private var connectivityManager: ConnectivityManager? = null
    private var activityBinding: ActivityPluginBinding? = null
    private var pendingPermissionResult: Result? = null
    private var pendingBackgroundPermissionResult: Result? = null
    private var rationaleBeforeRequest: Map<String, Boolean> = emptyMap()
    private var eventSink: EventChannel.EventSink? = null
    private var wifiNetworkCallback: ConnectivityManager.NetworkCallback? = null
    private val wifiInfoByNetwork = ConcurrentHashMap<Network, WifiInfo>()
    private val pendingSsidResults = mutableListOf<Result>()
    @Volatile
    private var hasPendingSsid = false
    private val mainHandler = Handler(Looper.getMainLooper())
    private var ssidTimeout: Runnable? = null
    // Trust-scoped snapshot published to watchValidatedWifiSsid(); the on-demand
    // getSsid lookup reads wifiInfoByNetwork instead.
    private val wifiNetworksLock = Any()
    private val wifiNetworks = linkedMapOf<Network, WifiNetworkStatus>()
    private var wifiResolutionReconcileRunnable: Runnable? = null
    private var wifiResolutionReconcileAttempts = 0

    private val permissionResultListener = RequestPermissionsResultListener { requestCode, _, _ ->
        if (requestCode != REQUEST_CODE_LOCATION && requestCode != REQUEST_CODE_BACKGROUND_LOCATION) {
            return@RequestPermissionsResultListener false
        }
        val result = pendingPermissionResult
            ?: pendingBackgroundPermissionResult
            ?: return@RequestPermissionsResultListener false
        val currentActivity = activity
        if (currentActivity == null) {
            pendingPermissionResult = null
            pendingBackgroundPermissionResult = null
            result.error(ERROR_UNAVAILABLE, "Activity not available", null)
            return@RequestPermissionsResultListener true
        }
        // R+ dialogs never offer "Allow all the time"; asking for it alone opens Settings.
        if (
            requestCode == REQUEST_CODE_LOCATION &&
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.R &&
            hasForegroundLocation(currentActivity) &&
            !hasBackgroundLocation(currentActivity)
        ) {
            requestBackgroundLocation(currentActivity)
            return@RequestPermissionsResultListener true
        }
        pendingPermissionResult = null
        pendingBackgroundPermissionResult = null
        result.success(settleRequest(currentActivity))
        refreshWifiNetworkWatch()
        true
    }

    companion object {
        private const val CHANNEL_NAME = "wifi_ssid"
        private const val VALIDATED_WIFI_SSID_CHANNEL_NAME = "wifi_ssid/validated_wifi_ssid"
        private const val METHOD_GET_SSID = "getSsid"
        private const val METHOD_GET_CURRENT_WIFI_INFO = "getCurrentWifiInfo"
        private const val METHOD_CHECK_PERMISSION = "checkPermission"
        private const val METHOD_REQUEST_PERMISSION = "requestPermission"
        private const val METHOD_CHECK_BACKGROUND_PERMISSION = "checkBackgroundPermission"
        private const val METHOD_REQUEST_BACKGROUND_PERMISSION = "requestBackgroundPermission"
        private const val ERROR_UNAVAILABLE = "UNAVAILABLE"
        private const val ERROR_IN_PROGRESS = "IN_PROGRESS"
        // Every plugin on the activity sees every result; stay clear of the app's codes.
        private const val REQUEST_CODE_LOCATION = 2101
        private const val REQUEST_CODE_BACKGROUND_LOCATION = 2102
        private const val DENIED_PERMISSIONS_PREFERENCES = "wifi_ssid_denied_permissions"
        private const val SSID_TIMEOUT_MILLIS = 3_000L

        // Values must match WifiSsidPermission enum index in Dart
        private const val PERMISSION_GRANTED = 0
        private const val PERMISSION_DENIED = 1
        private const val PERMISSION_PERMANENTLY_DENIED = 2

        private const val TAG = "WifiSsidPlugin"

        // Sentinel returned by WifiInfo.getRssi() when the value is unknown.
        private const val INVALID_RSSI = -127

        // Minimum RSSI (dBm) treated as a trustworthy WiFi signal while a VPN
        // tunnel is active (see wifiVerdict()). Below it the SSID is reported
        // as untrusted so the UI/service keep the proxy active.
        private const val WEAK_RSSI_THRESHOLD_DBM = -80
        private const val SSID_RECONCILE_INTERVAL_MILLIS = 500L
        private const val MAX_SSID_RECONCILE_ATTEMPTS = 4
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)
        validatedWifiSsidChannel = EventChannel(
            binding.binaryMessenger,
            VALIDATED_WIFI_SSID_CHANNEL_NAME,
        )
        validatedWifiSsidChannel.setStreamHandler(this)
        wifiManager = binding.applicationContext.getSystemService(Context.WIFI_SERVICE) as? WifiManager
        connectivityManager = binding.applicationContext.getSystemService(
            Context.CONNECTIVITY_SERVICE,
        ) as? ConnectivityManager
        if (hasForegroundLocation(binding.applicationContext)) {
            registerWifiNetworkCallback()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        completePendingSsidResults(
            errorMessage = "Plugin detached before SSID lookup completed",
        )
        channel.setMethodCallHandler(null)
        validatedWifiSsidChannel.setStreamHandler(null)
        eventSink = null
        stopWifiNetworkWatch()
        unregisterWifiNetworkCallback()
        detachFromActivity(cancelPermissionRequest = true)
        context = null
        wifiManager = null
        connectivityManager = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityBinding?.removeRequestPermissionsResultListener(permissionResultListener)
        activityBinding = binding
        activity = binding.activity
        binding.addRequestPermissionsResultListener(permissionResultListener)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        detachFromActivity(cancelPermissionRequest = false)
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivity() {
        detachFromActivity(cancelPermissionRequest = true)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            METHOD_GET_SSID -> getSsid(result)
            METHOD_GET_CURRENT_WIFI_INFO -> getCurrentWifiInfo(result)
            METHOD_CHECK_PERMISSION -> checkPermission(result)
            METHOD_REQUEST_PERMISSION -> requestPermission(result)
            METHOD_CHECK_BACKGROUND_PERMISSION -> checkBackgroundPermission(result)
            METHOD_REQUEST_BACKGROUND_PERMISSION -> requestBackgroundPermission(result)
            else -> result.notImplemented()
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        startWifiNetworkWatch()
    }

    override fun onCancel(arguments: Any?) {
        stopWifiNetworkWatch()
        eventSink = null
    }

    private fun checkPermission(result: Result) {
        val ctx = context ?: run {
            result.error(ERROR_UNAVAILABLE, "Context not available", null)
            return
        }
        refreshWifiNetworkCallback()
        forgetGrantedDenials(ctx)
        result.success(
            if (missingPermission(ctx) == null) PERMISSION_GRANTED else PERMISSION_DENIED,
        )
    }

    private fun requestPermission(result: Result) {
        val act = activity ?: run {
            result.error(ERROR_UNAVAILABLE, "Activity not available", null)
            return
        }
        val ctx = context ?: run {
            result.error(ERROR_UNAVAILABLE, "Context not available", null)
            return
        }
        if (missingPermission(ctx) == null) {
            refreshWifiNetworkCallback()
            forgetGrantedDenials(ctx)
            result.success(PERMISSION_GRANTED)
            return
        }
        if (pendingPermissionResult != null || pendingBackgroundPermissionResult != null) {
            result.error(ERROR_IN_PROGRESS, "A permission request is already active", null)
            return
        }
        pendingPermissionResult = result
        if (hasForegroundLocation(ctx)) {
            requestBackgroundLocation(act)
        } else {
            requestForegroundLocation(act)
        }
    }

    private fun checkBackgroundPermission(result: Result) {
        val ctx = context ?: run {
            result.error(ERROR_UNAVAILABLE, "Context not available", null)
            return
        }
        forgetGrantedDenials(ctx)
        result.success(
            if (hasBackgroundLocation(ctx)) PERMISSION_GRANTED else PERMISSION_DENIED,
        )
    }

    private fun requestBackgroundPermission(result: Result) {
        val act = activity ?: run {
            result.error(ERROR_UNAVAILABLE, "Activity not available", null)
            return
        }
        val ctx = context ?: run {
            result.error(ERROR_UNAVAILABLE, "Context not available", null)
            return
        }
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            result.success(PERMISSION_GRANTED)
            return
        }
        if (hasBackgroundLocation(ctx)) {
            refreshWifiNetworkCallback()
            forgetGrantedDenials(ctx)
            result.success(PERMISSION_GRANTED)
            return
        }
        if (pendingPermissionResult != null || pendingBackgroundPermissionResult != null) {
            result.error(ERROR_IN_PROGRESS, "A permission request is already active", null)
            return
        }
        pendingBackgroundPermissionResult = result
        if (hasForegroundLocation(ctx)) {
            requestBackgroundLocation(act)
        } else {
            requestForegroundLocation(act)
        }
    }

    private fun requestForegroundLocation(activity: Activity) {
        // Q accepts the background permission in the same dialog; R+ rejects the
        // combined request and needs it asked separately once foreground is granted.
        val permissions = if (Build.VERSION.SDK_INT == Build.VERSION_CODES.Q) {
            arrayOf(
                Manifest.permission.ACCESS_FINE_LOCATION,
                Manifest.permission.ACCESS_COARSE_LOCATION,
                Manifest.permission.ACCESS_BACKGROUND_LOCATION,
            )
        } else {
            arrayOf(
                Manifest.permission.ACCESS_FINE_LOCATION,
                Manifest.permission.ACCESS_COARSE_LOCATION,
            )
        }
        launchPermissionRequest(activity, permissions, REQUEST_CODE_LOCATION)
    }

    private fun requestBackgroundLocation(activity: Activity) {
        launchPermissionRequest(
            activity,
            arrayOf(Manifest.permission.ACCESS_BACKGROUND_LOCATION),
            REQUEST_CODE_BACKGROUND_LOCATION,
        )
    }

    private fun launchPermissionRequest(
        activity: Activity,
        permissions: Array<String>,
        requestCode: Int,
    ) {
        rationaleBeforeRequest = permissions.associateWith {
            ActivityCompat.shouldShowRequestPermissionRationale(activity, it)
        }
        ActivityCompat.requestPermissions(activity, permissions, requestCode)
    }

    private fun settleRequest(activity: Activity): Int {
        val rationaleBefore = rationaleBeforeRequest
        rationaleBeforeRequest = emptyMap()
        refreshWifiNetworkCallback()
        forgetGrantedDenials(activity)
        val missing = missingPermission(activity) ?: return PERMISSION_GRANTED
        return resolveDenial(activity, missing, rationaleBefore[missing] == true)
    }

    // Rationale is false both before the first prompt and after a permanent denial;
    // how it moved across the request and a persisted earlier denial tell them apart.
    private fun resolveDenial(
        activity: Activity,
        permission: String,
        rationaleBefore: Boolean,
    ): Int {
        val preferences = deniedPermissions(activity)
        val deniedBefore = preferences.getBoolean(permission, false)
        if (ActivityCompat.shouldShowRequestPermissionRationale(activity, permission)) {
            preferences.edit { putBoolean(permission, true) }
            return PERMISSION_DENIED
        }
        if (rationaleBefore) {
            preferences.edit { putBoolean(permission, true) }
            return PERMISSION_PERMANENTLY_DENIED
        }
        return if (deniedBefore) PERMISSION_PERMANENTLY_DENIED else PERMISSION_DENIED
    }

    private fun forgetGrantedDenials(context: Context) {
        val preferences = deniedPermissions(context)
        val granted = preferences.all.keys.filter { isGranted(context, it) }
        if (granted.isNotEmpty()) {
            preferences.edit { granted.forEach(::remove) }
        }
    }

    private fun deniedPermissions(context: Context) =
        context.getSharedPreferences(DENIED_PERMISSIONS_PREFERENCES, Context.MODE_PRIVATE)

    private fun isGranted(context: Context, permission: String): Boolean =
        ContextCompat.checkSelfPermission(context, permission) == PackageManager.PERMISSION_GRANTED

    private fun hasForegroundLocation(context: Context): Boolean =
        isGranted(context, Manifest.permission.ACCESS_FINE_LOCATION)

    // Since Q the SSID reads as UNKNOWN_SSID from the background without this
    // permission, which is where the on-demand check spends most of its time.
    private fun hasBackgroundLocation(context: Context): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.Q ||
            isGranted(context, Manifest.permission.ACCESS_BACKGROUND_LOCATION)

    private fun missingPermission(context: Context): String? = when {
        !hasForegroundLocation(context) -> Manifest.permission.ACCESS_FINE_LOCATION
        !hasBackgroundLocation(context) -> Manifest.permission.ACCESS_BACKGROUND_LOCATION
        else -> null
    }

    private fun getSsid(result: Result) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val ctx = context ?: run {
                result.error(ERROR_UNAVAILABLE, "Context not available", null)
                return
            }
            if (!hasForegroundLocation(ctx)) {
                result.success(null)
                return
            }
            if (connectivityManager == null) {
                result.error(ERROR_UNAVAILABLE, "ConnectivityManager not available", null)
                return
            }
            val ssid = currentSsid()
            if (ssid != null) {
                result.success(ssid)
                return
            }
            pendingSsidResults.add(result)
            hasPendingSsid = true
            if (!registerWifiNetworkCallback()) {
                completePendingSsidResults(ssid = null)
                return
            }
            scheduleSsidTimeout()
            return
        }

        val wm = wifiManager ?: run {
            result.error(ERROR_UNAVAILABLE, "WifiManager not available", null)
            return
        }
        @Suppress("DEPRECATION")
        result.success(normalizeSsid(wm.connectionInfo?.ssid))
    }

    private fun currentSsid(): String? {
        val activeNetwork = connectivityManager?.activeNetwork
        val info = activeNetwork?.let(wifiInfoByNetwork::get)
            ?: wifiInfoByNetwork.values.firstOrNull()
        return normalizeSsid(info?.ssid)
    }

    private fun normalizeSsid(ssid: String?): String? {
        val normalized = ssid?.removeSurrounding("\"")
        return normalized?.takeIf {
            it.isNotEmpty() && it != WifiManager.UNKNOWN_SSID && it != "0x"
        }
    }

    private fun getCurrentWifiInfo(result: Result) {
        val status = currentWifiInfo()
        if (status == null) {
            result.success(null)
            return
        }
        result.success(
            mapOf(
                "ssid" to status.ssid,
                "rssi" to status.rssi,
            ),
        )
    }

    private fun currentWifiInfo(): WifiNetworkStatus? {
        val status = readCurrentNetworkStatus()
        val fallback = if (status?.ssid == null || status?.rssi == null) {
            readWifiManagerStatus()
        } else {
            null
        }
        val rssi = status?.rssi
            ?: fallback?.rssi
            ?: readSignalStrengthFromAllNetworks()
            ?: readScanResultRssi()
        val ssid = status?.ssid ?: fallback?.ssid
        if (ssid == null && rssi == null) {
            return null
        }
        return WifiNetworkStatus(
            ssid = ssid,
            rssi = rssi,
            systemValidated = status?.systemValidated
                ?: fallback?.systemValidated
                ?: false,
        )
    }

    private fun readCurrentNetworkStatus(): WifiNetworkStatus? {
        val cm = connectivityManager ?: return null
        var firstStatus: WifiNetworkStatus? = null
        for (network in cm.allNetworks) {
            val status = cm.getNetworkCapabilities(network).wifiNetworkStatus() ?: continue
            if (firstStatus == null) {
                firstStatus = status
            }
            if (status.ssid != null) {
                return status
            }
        }
        return firstStatus
    }

    @Suppress("DEPRECATION")
    private fun readWifiManagerStatus(): WifiNetworkStatus? {
        val info = runCatching { wifiManager?.connectionInfo }.getOrNull()
            ?: return null
        val ssid = normalizeSsid(info.ssid)
        val rssi = resolveRssi(info)
        if (ssid == null && rssi == null) {
            return null
        }
        return WifiNetworkStatus(
            ssid = ssid,
            rssi = rssi,
            systemValidated = false,
        )
    }

    private fun readSignalStrengthFromAllNetworks(): Int? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            return null
        }
        val cm = connectivityManager ?: return null
        for (network in cm.allNetworks) {
            val rssi = cm.getNetworkCapabilities(network)
                ?.takeIf { it.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) }
                ?.signalStrength
                ?.takeIf { it != NetworkCapabilities.SIGNAL_STRENGTH_UNSPECIFIED }
            if (rssi != null) {
                return rssi
            }
        }
        return null
    }

    @Suppress("DEPRECATION")
    private fun readScanResultRssi(): Int? {
        val wm = wifiManager ?: return null
        val info = runCatching { wm.connectionInfo }.getOrNull() ?: return null
        val connectedSsid = normalizeSsid(info.ssid) ?: return null
        val connectedBssid = info.bssid?.takeIf { it != "02:00:00:00:00:00" }
        runCatching { wm.startScan() }
        val results = runCatching { wm.scanResults }.getOrNull() ?: return null
        return results.firstOrNull { result ->
            if (connectedBssid != null && result.BSSID != null) {
                result.BSSID == connectedBssid
            } else {
                normalizeSsid(result.SSID) == connectedSsid
            }
        }?.level
    }

    private fun refreshWifiNetworkCallback() {
        unregisterWifiNetworkCallback()
        registerWifiNetworkCallback()
    }

    private fun registerWifiNetworkCallback(): Boolean {
        val ctx = context ?: return false
        if (!hasForegroundLocation(ctx)) {
            unregisterWifiNetworkCallback()
            return false
        }
        if (wifiNetworkCallback != null) {
            return true
        }
        val cm = connectivityManager ?: return false
        val callback = createWifiNetworkCallback()
        val request = NetworkRequest.Builder()
            .addTransportType(NetworkCapabilities.TRANSPORT_WIFI)
            .build()
        return runCatching { cm.registerNetworkCallback(request, callback) }
            .onSuccess { wifiNetworkCallback = callback }
            .isSuccess
    }

    private fun createWifiNetworkCallback(): ConnectivityManager.NetworkCallback {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            object : ConnectivityManager.NetworkCallback(FLAG_INCLUDE_LOCATION_INFO) {
                override fun onAvailable(network: Network) {
                    if (eventSink != null) {
                        markWifiNetworkAvailable(network)
                    }
                }

                override fun onCapabilitiesChanged(
                    network: Network,
                    capabilities: NetworkCapabilities,
                ) {
                    handleCapabilitiesChanged(network, capabilities)
                }

                override fun onLost(network: Network) {
                    handleNetworkLost(network)
                }

                override fun onUnavailable() {
                    if (eventSink != null) {
                        clearWifiNetworks()
                    }
                }
            }
        } else {
            object : ConnectivityManager.NetworkCallback() {
                override fun onAvailable(network: Network) {
                    if (eventSink != null) {
                        markWifiNetworkAvailable(network)
                    }
                }

                override fun onCapabilitiesChanged(
                    network: Network,
                    capabilities: NetworkCapabilities,
                ) {
                    handleCapabilitiesChanged(network, capabilities)
                }

                override fun onLost(network: Network) {
                    handleNetworkLost(network)
                }

                override fun onUnavailable() {
                    if (eventSink != null) {
                        clearWifiNetworks()
                    }
                }
            }
        }
    }

    private fun handleCapabilitiesChanged(network: Network, capabilities: NetworkCapabilities) {
        val wifiInfo = capabilities.transportInfo as? WifiInfo
        if (wifiInfo == null) {
            wifiInfoByNetwork.remove(network)
        } else {
            wifiInfoByNetwork[network] = wifiInfo
        }
        if (eventSink != null) {
            updateWifiNetwork(network, capabilities)
        }
        if (!hasPendingSsid) {
            return
        }
        currentSsid()?.let { ssid ->
            mainHandler.post {
                completePendingSsidResults(ssid = ssid)
            }
        }
    }

    private fun handleNetworkLost(network: Network) {
        wifiInfoByNetwork.remove(network)
        if (eventSink != null) {
            removeWifiNetwork(network)
        }
    }

    private fun scheduleSsidTimeout() {
        if (ssidTimeout != null) {
            return
        }
        val timeout = Runnable {
            ssidTimeout = null
            completePendingSsidResults(ssid = currentSsid())
        }
        ssidTimeout = timeout
        mainHandler.postDelayed(timeout, SSID_TIMEOUT_MILLIS)
    }

    private fun completePendingSsidResults(
        ssid: String? = null,
        errorMessage: String? = null,
    ) {
        val timeout = ssidTimeout
        ssidTimeout = null
        if (timeout != null) {
            mainHandler.removeCallbacks(timeout)
        }
        val results = pendingSsidResults.toList()
        pendingSsidResults.clear()
        hasPendingSsid = false
        results.forEach { result ->
            if (errorMessage == null) {
                result.success(ssid)
            } else {
                result.error(ERROR_UNAVAILABLE, errorMessage, null)
            }
        }
    }

    private fun unregisterWifiNetworkCallback() {
        val callback = wifiNetworkCallback
        wifiNetworkCallback = null
        if (callback != null) {
            connectivityManager?.let { manager ->
                runCatching { manager.unregisterNetworkCallback(callback) }
            }
        }
        wifiInfoByNetwork.clear()
    }

    private fun startWifiNetworkWatch() {
        val cm = connectivityManager ?: run {
            emitValidatedWifiSsid(null)
            return
        }
        stopWifiNetworkWatch()
        registerWifiNetworkCallback()
        updateKnownWifiNetworks(cm)
    }

    private fun stopWifiNetworkWatch() {
        stopWifiResolutionReconcile("stop watch")
        synchronized(wifiNetworksLock) {
            wifiNetworks.clear()
        }
    }

    private fun refreshWifiNetworkWatch() {
        if (eventSink == null) {
            return
        }
        connectivityManager?.let(::updateKnownWifiNetworks)
    }

    private fun markWifiNetworkAvailable(network: Network) {
        val verdict = wifiVerdict()
        val status = synchronized(wifiNetworksLock) {
            if (!wifiNetworks.containsKey(network)) {
                wifiNetworks[network] = WifiNetworkStatus(
                    ssid = null,
                    rssi = null,
                    systemValidated = false,
                )
            }
            currentWifiNetworkStatusLocked(verdict)
        }
        emitValidatedWifiSsid(status?.takeIf { it.isTrusted(verdict) }?.ssid)
        when {
            status != null && status.ssid == null ->
                scheduleWifiResolutionReconcile("SSID unresolved while WiFi present")

            else -> stopWifiResolutionReconcile("WiFi state resolved")
        }
    }

    private fun updateKnownWifiNetworks(cm: ConnectivityManager) {
        val verdict = wifiVerdict()
        val status = synchronized(wifiNetworksLock) {
            wifiNetworks.clear()
            cm.allNetworks.forEach { network ->
                val status = cm.getNetworkCapabilities(network).wifiNetworkStatus()
                if (status != null) {
                    wifiNetworks[network] = status
                }
            }
            currentWifiNetworkStatusLocked(verdict)
        }
        emitValidatedWifiSsid(status?.takeIf { it.isTrusted(verdict) }?.ssid)
        when {
            status != null && status.ssid == null ->
                scheduleWifiResolutionReconcile("SSID unresolved while WiFi present")

            else -> stopWifiResolutionReconcile("WiFi state resolved")
        }
    }

    private fun updateWifiNetwork(network: Network, caps: NetworkCapabilities?) {
        val status = caps.wifiNetworkStatus()
        val verdict = wifiVerdict()
        val currentStatus = synchronized(wifiNetworksLock) {
            if (status == null) {
                wifiNetworks.remove(network)
            } else {
                wifiNetworks[network] = status
            }
            currentWifiNetworkStatusLocked(verdict)
        }
        emitValidatedWifiSsid(currentStatus?.takeIf { it.isTrusted(verdict) }?.ssid)
        when {
            currentStatus != null && currentStatus.ssid == null ->
                scheduleWifiResolutionReconcile("SSID unresolved while WiFi present")

            else -> stopWifiResolutionReconcile("WiFi state resolved")
        }
    }

    private fun removeWifiNetwork(network: Network) {
        val verdict = wifiVerdict()
        val status = synchronized(wifiNetworksLock) {
            wifiNetworks.remove(network)
            currentWifiNetworkStatusLocked(verdict)
        }
        emitValidatedWifiSsid(status?.takeIf { it.isTrusted(verdict) }?.ssid)
        when {
            status != null && status.ssid == null ->
                scheduleWifiResolutionReconcile("SSID unresolved while WiFi present")

            else -> stopWifiResolutionReconcile("WiFi state resolved")
        }
    }

    private fun clearWifiNetworks() {
        val verdict = wifiVerdict()
        val status = synchronized(wifiNetworksLock) {
            wifiNetworks.clear()
            currentWifiNetworkStatusLocked(verdict)
        }
        emitValidatedWifiSsid(status?.takeIf { it.isTrusted(verdict) }?.ssid)
        stopWifiResolutionReconcile("WiFi unavailable")
    }

    private fun emitValidatedWifiSsid(ssid: String?) {
        mainHandler.post {
            eventSink?.success(ssid)
        }
    }

    private fun shouldRetryWifiResolution(): Boolean {
        val verdict = wifiVerdict()
        return synchronized(wifiNetworksLock) {
            val status = currentWifiNetworkStatusLocked(verdict)
            status != null && status.ssid == null
        }
    }

    private fun scheduleWifiResolutionReconcile(reason: String) {
        if (wifiResolutionReconcileRunnable != null) {
            return
        }
        log(
            "start unresolved SSID reconcile reason=$reason interval=" +
                "${SSID_RECONCILE_INTERVAL_MILLIS}ms maxAttempts=$MAX_SSID_RECONCILE_ATTEMPTS",
        )
        wifiResolutionReconcileAttempts = 0
        val runnable = object : Runnable {
            override fun run() {
                val cm = connectivityManager ?: run {
                    stopWifiResolutionReconcile("ConnectivityManager unavailable")
                    return
                }
                wifiResolutionReconcileAttempts += 1
                log(
                    "unresolved SSID reconcile attempt=$wifiResolutionReconcileAttempts/" +
                        MAX_SSID_RECONCILE_ATTEMPTS,
                )
                updateKnownWifiNetworks(cm)
                if (!shouldRetryWifiResolution()) {
                    stopWifiResolutionReconcile(
                        "WiFi state resolved after attempt=$wifiResolutionReconcileAttempts",
                    )
                    return
                }
                if (wifiResolutionReconcileAttempts >= MAX_SSID_RECONCILE_ATTEMPTS) {
                    log("unresolved SSID reconcile exhausted attempts")
                    wifiResolutionReconcileRunnable = null
                    wifiResolutionReconcileAttempts = 0
                    return
                }
                if (wifiResolutionReconcileRunnable === this) {
                    mainHandler.postDelayed(this, SSID_RECONCILE_INTERVAL_MILLIS)
                }
            }
        }
        wifiResolutionReconcileRunnable = runnable
        mainHandler.postDelayed(runnable, SSID_RECONCILE_INTERVAL_MILLIS)
    }

    private fun stopWifiResolutionReconcile(reason: String) {
        val runnable = wifiResolutionReconcileRunnable ?: return
        log("cancel unresolved SSID reconcile: $reason")
        mainHandler.removeCallbacks(runnable)
        wifiResolutionReconcileRunnable = null
        wifiResolutionReconcileAttempts = 0
    }

    private fun wifiVerdict(): WifiVerdict {
        return if (isVpnActive()) WifiVerdict.Rssi else WifiVerdict.SystemValidated
    }

    private fun isVpnActive(): Boolean {
        val cm = connectivityManager ?: return false
        val capabilities = cm.getNetworkCapabilities(cm.activeNetwork)
        return capabilities?.hasTransport(NetworkCapabilities.TRANSPORT_VPN) == true
    }

    private fun currentWifiNetworkStatusLocked(verdict: WifiVerdict): WifiNetworkStatus? {
        return wifiNetworks.values.firstOrNull {
            it.isTrusted(verdict) && it.ssid != null
        } ?: wifiNetworks.values.firstOrNull()
    }

    private fun resolveRssi(info: WifiInfo?): Int? {
        return info?.rssi?.takeIf { it != INVALID_RSSI }
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

    private fun NetworkCapabilities?.wifiNetworkStatus(): WifiNetworkStatus? {
        if (this == null) {
            return null
        }
        if (!hasTransport(NetworkCapabilities.TRANSPORT_WIFI)) {
            return null
        }
        if (!hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)) {
            return null
        }
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

    private fun NetworkCapabilities.readWifiInfo(): WifiInfo? {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            transportInfo as? WifiInfo
        } else {
            @Suppress("DEPRECATION")
            wifiManager?.connectionInfo
        }
    }

    private fun log(message: String) {
        Log.d(TAG, message)
    }

    private fun detachFromActivity(cancelPermissionRequest: Boolean) {
        activityBinding?.removeRequestPermissionsResultListener(permissionResultListener)
        activityBinding = null
        activity = null
        if (cancelPermissionRequest) {
            rationaleBeforeRequest = emptyMap()
            completePendingPermissionRequest(
                "Activity detached before permission request completed",
            )
        }
    }

    private fun completePendingPermissionRequest(message: String) {
        pendingPermissionResult?.error(ERROR_UNAVAILABLE, message, null)
        pendingPermissionResult = null
        pendingBackgroundPermissionResult?.error(ERROR_UNAVAILABLE, message, null)
        pendingBackgroundPermissionResult = null
    }
}
