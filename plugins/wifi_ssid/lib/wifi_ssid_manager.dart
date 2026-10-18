import 'package:flutter/services.dart';

enum WifiSsidPermission { granted, denied, permanentlyDenied }

class WifiConnectionInfo {
  const WifiConnectionInfo({this.ssid, this.rssi});

  final String? ssid;
  final int? rssi;

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

  static const _channel = MethodChannel('wifi_ssid');
  static const _getSsidMethod = 'getSsid';
  static const _getCurrentWifiInfoMethod = 'getCurrentWifiInfo';
  static const _checkPermissionMethod = 'checkPermission';
  static const _requestPermissionMethod = 'requestPermission';
  static const _checkBackgroundPermissionMethod = 'checkBackgroundPermission';
  static const _requestBackgroundPermissionMethod =
      'requestBackgroundPermission';
  static const _validatedWifiSsidChannel = EventChannel(
    'wifi_ssid/validated_wifi_ssid',
  );

  Future<String?> getSsid() {
    return _channel.invokeMethod<String>(_getSsidMethod);
  }

  Future<WifiConnectionInfo> getCurrentWifiInfo() async {
    final result = await _channel.invokeMapMethod<dynamic, dynamic>(
      _getCurrentWifiInfoMethod,
    );
    return WifiConnectionInfo.fromMap(result);
  }

  /// Android only; every other platform gets an empty stream.
  Stream<String?> watchValidatedWifiSsid() {
    return _validatedWifiSsidChannel.receiveBroadcastStream().map(
      (event) => event as String?,
    );
  }

  Future<WifiSsidPermission> checkPermission() async {
    final result = await _channel.invokeMethod<int>(_checkPermissionMethod);
    return _decodePermission(result);
  }

  Future<WifiSsidPermission> requestPermission() async {
    final result = await _channel.invokeMethod<int>(_requestPermissionMethod);
    return _decodePermission(result);
  }

  /// Older Android versions always report granted.
  Future<WifiSsidPermission> checkBackgroundPermission() async {
    final result = await _channel.invokeMethod<int>(
      _checkBackgroundPermissionMethod,
    );
    return _decodePermission(result);
  }

  Future<WifiSsidPermission> requestBackgroundPermission() async {
    final result = await _channel.invokeMethod<int>(
      _requestBackgroundPermissionMethod,
    );
    return _decodePermission(result);
  }

  WifiSsidPermission _decodePermission(int? value) {
    return switch (value) {
      0 => WifiSsidPermission.granted,
      2 => WifiSsidPermission.permanentlyDenied,
      null || 1 => WifiSsidPermission.denied,
      _ => throw PlatformException(
        code: 'INVALID_PERMISSION_STATE',
        message: 'Native wifi_ssid returned an invalid permission state.',
        details: value,
      ),
    };
  }
}

final wifiSsidManager = WifiSsidManager.instance;
