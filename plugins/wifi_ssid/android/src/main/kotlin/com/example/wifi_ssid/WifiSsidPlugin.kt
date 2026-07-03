package com.example.wifi_ssid

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
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.EventChannel

class WifiSsidPlugin : FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler, ActivityAware {

    private lateinit var channel: MethodChannel
    private lateinit var validatedWifiSsidChannel: EventChannel
    private var context: Context? = null
    private var activity: Activity? = null
    private var wifiManager: WifiManager? = null
    private var connectivityManager: ConnectivityManager? = null
    private var pendingPermissionResult: Result? = null
    private var eventSink: EventChannel.EventSink? = null
    private var wifiNetworkCallback: ConnectivityManager.NetworkCallback? = null
    private val wifiNetworksLock = Any()
    private val wifiNetworks = linkedMapOf<Network, WifiNetworkStatus>()
    private val mainHandler = Handler(Looper.getMainLooper())
    private var wifiResolutionReconcileRunnable: Runnable? = null
    private var wifiResolutionReconcileAttempts = 0

    companion object {
        private const val TAG = "WifiSsidPlugin"
        private const val REQUEST_CODE_LOCATION = 1001
        // Values must match WifiSsidPermission enum index in Dart
        private const val PERMISSION_GRANTED = 0
        private const val PERMISSION_DENIED = 1
        private const val PERMISSION_PERMANENTLY_DENIED = 2

        // Sentinel returned by WifiInfo.getRssi() when the value is unknown.
        private const val INVALID_RSSI = -127

        // Minimum RSSI (dBm) treated as a trustworthy WiFi signal while a VPN
        // tunnel is active (see wifiVerdict()). Below it the SSID is reported
        // as untrusted so the UI/service keep the proxy active.
        private const val WEAK_RSSI_THRESHOLD_DBM = -80
        private const val SSID_RECONCILE_INTERVAL_MILLIS = 500L
        private const val MAX_SSID_RECONCILE_ATTEMPTS = 4
    }

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "wifi_ssid")
        channel.setMethodCallHandler(this)
        validatedWifiSsidChannel = EventChannel(
            flutterPluginBinding.binaryMessenger,
            "wifi_ssid/validated_wifi_ssid"
        )
        validatedWifiSsidChannel.setStreamHandler(this)
        wifiManager = context?.applicationContext?.getSystemService(Context.WIFI_SERVICE) as? WifiManager
        connectivityManager = context?.applicationContext?.getSystemService(Context.CONNECTIVITY_SERVICE) as? ConnectivityManager
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        stopWifiNetworkWatch()
        validatedWifiSsidChannel.setStreamHandler(null)
        channel.setMethodCallHandler(null)
        context = null
        wifiManager = null
        connectivityManager = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addRequestPermissionsResultListener { requestCode, _, grantResults ->
            if (requestCode == REQUEST_CODE_LOCATION) {
                val result = pendingPermissionResult ?: return@addRequestPermissionsResultListener false
                pendingPermissionResult = null
                if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                    result.success(PERMISSION_GRANTED)
                } else {
                    if (!ActivityCompat.shouldShowRequestPermissionRationale(binding.activity, Manifest.permission.ACCESS_FINE_LOCATION)) {
                        result.success(PERMISSION_PERMANENTLY_DENIED)
                    } else {
                        result.success(PERMISSION_DENIED)
                    }
                }
                true
            } else {
                false
            }
        }
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "getSsid" -> getSsid(result)
            "checkPermission" -> checkPermission(result)
            "requestPermission" -> requestPermission(result)
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

    // MARK: - Permission

    private fun checkPermission(result: Result) {
        val ctx = context ?: run {
            result.error("UNAVAILABLE", "Context not available", null)
            return
        }
        val granted = ContextCompat.checkSelfPermission(ctx, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
        result.success(if (granted) PERMISSION_GRANTED else PERMISSION_DENIED)
    }

    private fun requestPermission(result: Result) {
        val act = activity ?: run {
            result.error("UNAVAILABLE", "Activity not available", null)
            return
        }
        val ctx = context ?: run {
            result.error("UNAVAILABLE", "Context not available", null)
            return
        }
        if (ContextCompat.checkSelfPermission(ctx, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED) {
            result.success(PERMISSION_GRANTED)
            return
        }
        pendingPermissionResult = result
        ActivityCompat.requestPermissions(act, arrayOf(Manifest.permission.ACCESS_FINE_LOCATION), REQUEST_CODE_LOCATION)
    }

    // MARK: - SSID

    private fun getSsid(result: Result) {
        val wm = wifiManager ?: run {
            result.error("UNAVAILABLE", "WifiManager not available", null)
            return
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val cm = connectivityManager ?: run {
                result.error("UNAVAILABLE", "ConnectivityManager not available", null)
                return
            }
            val hasWifiNetwork = cm.allNetworks.any {
                cm.getNetworkCapabilities(it)?.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) == true
            }
            if (!hasWifiNetwork) {
                result.success(null)
                return
            }
        }

        @Suppress("DEPRECATION")
        val info = wm.connectionInfo
        result.success(normalizeSsid(info.ssid))
    }

    private fun startWifiNetworkWatch() {
        val cm = connectivityManager ?: run {
            emitValidatedWifiSsid(null)
            return
        }
        stopWifiNetworkWatch()
        val callback = createWifiNetworkCallback()
        runCatching {
            cm.registerNetworkCallback(wifiNetworkRequest, callback)
        }.onSuccess {
            wifiNetworkCallback = callback
            updateKnownWifiNetworks(cm)
        }.onFailure {
            stopWifiResolutionReconcile("register callback failed")
            wifiNetworkCallback = null
            synchronized(wifiNetworksLock) {
                wifiNetworks.clear()
            }
            emitValidatedWifiSsid(null)
        }
    }

    private fun stopWifiNetworkWatch() {
        stopWifiResolutionReconcile("stop watch")
        val callback = wifiNetworkCallback ?: return
        runCatching {
            connectivityManager?.unregisterNetworkCallback(callback)
        }
        synchronized(wifiNetworksLock) {
            wifiNetworks.clear()
        }
        wifiNetworkCallback = null
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
                "${SSID_RECONCILE_INTERVAL_MILLIS}ms maxAttempts=$MAX_SSID_RECONCILE_ATTEMPTS"
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
                        MAX_SSID_RECONCILE_ATTEMPTS
                )
                updateKnownWifiNetworks(cm)
                if (!shouldRetryWifiResolution()) {
                    stopWifiResolutionReconcile(
                        "WiFi state resolved after attempt=$wifiResolutionReconcileAttempts"
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

    private fun log(message: String) {
        Log.d(TAG, message)
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

    private fun currentWifiNetworkStatusLocked(verdict: WifiVerdict): WifiNetworkStatus? {
        return wifiNetworks.values.firstOrNull {
            it.isTrusted(verdict) && it.ssid != null
        } ?: wifiNetworks.values.firstOrNull()
    }

    private fun NetworkCapabilities.readWifiInfo(): WifiInfo? {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            transportInfo as? WifiInfo
        } else {
            @Suppress("DEPRECATION")
            wifiManager?.connectionInfo
        }
    }

    private fun wifiVerdict(): WifiVerdict {
        return if (isVpnActive()) WifiVerdict.Rssi else WifiVerdict.SystemValidated
    }

    private fun isVpnActive(): Boolean {
        val cm = connectivityManager ?: return false
        val capabilities = cm.getNetworkCapabilities(cm.activeNetwork)
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

    private fun normalizeSsid(ssid: String?): String? {
        return if (ssid == null || ssid == "<unknown ssid>" || ssid == "0x") {
            null
        } else {
            ssid.removeSurrounding("\"")
        }
    }
}
