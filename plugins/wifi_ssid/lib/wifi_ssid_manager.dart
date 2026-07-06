import 'package:flutter/services.dart';

enum WifiSsidPermission {
  granted,
  denied,
  permanentlyDenied,
}

class WifiConnectionInfo {
  final String? ssid;
  final int? rssi;

  const WifiConnectionInfo({
    this.ssid,
    this.rssi,
  });

  factory WifiConnectionInfo.fromMap(Map<dynamic, dynamic>? map) {
    if (map == null) {
      return const WifiConnectionInfo();
    }
    return WifiConnectionInfo(
      ssid: map['ssid']?.toString(),
      rssi: _toRssi(map['rssi']),
    );
  }

  static int? _toRssi(dynamic value) {
    final int? rssi;
    if (value is int) {
      rssi = value;
    } else if (value is double) {
      rssi = value.toInt();
    } else if (value is String) {
      rssi = int.tryParse(value);
    } else {
      rssi = null;
    }
    return rssi == -127 ? null : rssi;
  }
}

class WifiSsidManager {
  WifiSsidManager._();

  static final WifiSsidManager instance = WifiSsidManager._();

  final MethodChannel _channel = const MethodChannel('wifi_ssid');
  final EventChannel _validatedWifiSsidChannel = const EventChannel(
    'wifi_ssid/validated_wifi_ssid',
  );

  /// Returns the current WiFi SSID, or null if not connected to WiFi.
  Future<String?> getSsid() async {
    return await _channel.invokeMethod<String>('getSsid');
  }

  /// Returns the current WiFi SSID and RSSI when the platform exposes them.
  Future<WifiConnectionInfo> getCurrentWifiInfo() async {
    final result = await _channel.invokeMapMethod<dynamic, dynamic>(
      'getCurrentWifiInfo',
    );
    return WifiConnectionInfo.fromMap(result);
  }

  /// Emits the SSID only when Android reports a validated WiFi network.
  ///
  /// Other platforms use the plugin's regular SSID lookup paths and do not
  /// currently provide a validated-WiFi stream.
  Stream<String?> watchValidatedWifiSsid() {
    return _validatedWifiSsidChannel
        .receiveBroadcastStream()
        .map((event) => event as String?);
  }

  /// Checks whether location permission has been granted.
  Future<WifiSsidPermission> checkPermission() async {
    final result = await _channel.invokeMethod<int>('checkPermission');
    return WifiSsidPermission.values[result ?? 1];
  }

  /// Requests location permission from the user.
  Future<WifiSsidPermission> requestPermission() async {
    final result = await _channel.invokeMethod<int>('requestPermission');
    return WifiSsidPermission.values[result ?? 1];
  }

  /// Checks whether background location permission has been granted
  /// (Android 10+). On older Android versions this always returns [granted].
  Future<WifiSsidPermission> checkBackgroundPermission() async {
    final result = await _channel.invokeMethod<int>('checkBackgroundPermission');
    return WifiSsidPermission.values[result ?? 1];
  }

  /// Requests background location permission from the user (Android 10+).
  Future<WifiSsidPermission> requestBackgroundPermission() async {
    final result = await _channel.invokeMethod<int>('requestBackgroundPermission');
    return WifiSsidPermission.values[result ?? 1];
  }
}

final wifiSsidManager = WifiSsidManager.instance;
