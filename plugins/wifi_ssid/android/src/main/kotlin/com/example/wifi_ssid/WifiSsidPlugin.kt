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

    companion object {
        private const val REQUEST_CODE_LOCATION = 1001
        // Values must match WifiSsidPermission enum index in Dart
        private const val PERMISSION_GRANTED = 0
        private const val PERMISSION_DENIED = 1
        private const val PERMISSION_PERMANENTLY_DENIED = 2
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
            wifiNetworkCallback = null
            synchronized(wifiNetworksLock) {
                wifiNetworks.clear()
            }
            emitValidatedWifiSsid(null)
        }
    }

    private fun stopWifiNetworkWatch() {
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

    private fun updateKnownWifiNetworks(cm: ConnectivityManager) {
        val ssid = synchronized(wifiNetworksLock) {
            wifiNetworks.clear()
            cm.allNetworks.forEach { network ->
                val status = cm.getNetworkCapabilities(network).wifiNetworkStatus()
                if (status != null) {
                    wifiNetworks[network] = status
                }
            }
            currentValidatedWifiSsidLocked()
        }
        emitValidatedWifiSsid(ssid)
    }

    private fun updateWifiNetwork(network: Network) {
        val caps = connectivityManager?.getNetworkCapabilities(network)
        updateWifiNetwork(network, caps)
    }

    private fun updateWifiNetwork(network: Network, caps: NetworkCapabilities?) {
        val status = caps.wifiNetworkStatus()
        val ssid = synchronized(wifiNetworksLock) {
            if (status == null) {
                wifiNetworks.remove(network)
            } else {
                wifiNetworks[network] = status
            }
            currentValidatedWifiSsidLocked()
        }
        emitValidatedWifiSsid(ssid)
    }

    private fun removeWifiNetwork(network: Network) {
        val ssid = synchronized(wifiNetworksLock) {
            wifiNetworks.remove(network)
            currentValidatedWifiSsidLocked()
        }
        emitValidatedWifiSsid(ssid)
    }

    private fun clearWifiNetworks() {
        val ssid = synchronized(wifiNetworksLock) {
            wifiNetworks.clear()
            currentValidatedWifiSsidLocked()
        }
        emitValidatedWifiSsid(ssid)
    }

    private fun emitValidatedWifiSsid(ssid: String?) {
        mainHandler.post {
            eventSink?.success(ssid)
        }
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

    private fun currentValidatedWifiSsidLocked(): String? {
        return wifiNetworks.values.firstOrNull {
            it.validated && it.ssid != null
        }?.ssid
    }

    private fun NetworkCapabilities.readWifiSsid(): String? {
        if (!hasCapability(NetworkCapabilities.NET_CAPABILITY_VALIDATED)) return null
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
}
