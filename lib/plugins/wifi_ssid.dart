import 'dart:async';

import 'package:fl_clash/common/common.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:rust_api/rust_api.dart' as rust;

export 'package:rust_api/rust_api.dart' show WifiSsidPermission;

class WifiConnectionInfo {
  final String? ssid;
  final int? rssi;

  const WifiConnectionInfo({this.ssid, this.rssi});

  factory WifiConnectionInfo.fromMap(Map<Object?, Object?>? map) {
    if (map == null) {
      return const WifiConnectionInfo();
    }
    return WifiConnectionInfo(
      ssid: map['ssid'] as String?,
      rssi: (map['rssi'] as num?)?.toInt(),
    );
  }
}

abstract interface class WifiSsidHost {
  Future<String?> getSsid();

  Future<WifiConnectionInfo> getCurrentWifiInfo();

  Future<rust.WifiSsidPermission> checkPermission();

  Future<rust.WifiSsidPermission> requestPermission();

  Future<rust.WifiSsidPermission> checkBackgroundPermission();

  Future<rust.WifiSsidPermission> requestBackgroundPermission();

  Stream<String?> get wifiStream;
}

class AndroidWifiSsidHost implements WifiSsidHost {
  final MethodChannel _channel;
  final EventChannel _eventChannel;

  const AndroidWifiSsidHost([
    this._channel = const MethodChannel('$packageName/wifi_ssid'),
    this._eventChannel = const EventChannel(
      '$packageName/wifi_ssid/validated_wifi_ssid',
    ),
  ]);

  @override
  Future<String?> getSsid() => _channel.invokeMethod<String>('getSsid');

  @override
  Future<WifiConnectionInfo> getCurrentWifiInfo() async {
    final raw = await _channel.invokeMapMethod<Object?, Object?>(
      'getCurrentWifiInfo',
    );
    return WifiConnectionInfo.fromMap(raw);
  }

  @override
  Future<rust.WifiSsidPermission> checkPermission() async {
    return _decode(await _channel.invokeMethod<int>('checkPermission'));
  }

  @override
  Future<rust.WifiSsidPermission> requestPermission() async {
    return _decode(await _channel.invokeMethod<int>('requestPermission'));
  }

  @override
  Future<rust.WifiSsidPermission> checkBackgroundPermission() async {
    return _decode(
      await _channel.invokeMethod<int>('checkBackgroundPermission'),
    );
  }

  @override
  Future<rust.WifiSsidPermission> requestBackgroundPermission() async {
    return _decode(
      await _channel.invokeMethod<int>('requestBackgroundPermission'),
    );
  }

  @override
  Stream<String?> get wifiStream =>
      _eventChannel.receiveBroadcastStream().map((event) => event as String?);

  rust.WifiSsidPermission _decode(int? value) {
    return switch (value) {
      0 => rust.WifiSsidPermission.granted,
      2 => rust.WifiSsidPermission.permanentlyDenied,
      null || 1 => rust.WifiSsidPermission.denied,
      _ => throw PlatformException(
        code: 'INVALID_PERMISSION_STATE',
        message: 'WifiSsidPlugin returned an invalid permission state.',
        details: value,
      ),
    };
  }
}

class _RustWifiSsidHost implements WifiSsidHost {
  const _RustWifiSsidHost();

  @override
  Future<String?> getSsid() => rust.currentWifiSsid();

  @override
  Future<WifiConnectionInfo> getCurrentWifiInfo() async =>
      WifiConnectionInfo(ssid: await getSsid());

  @override
  Future<rust.WifiSsidPermission> checkPermission() {
    return rust.checkWifiSsidPermission();
  }

  @override
  Future<rust.WifiSsidPermission> requestPermission() {
    return rust.requestWifiSsidPermission();
  }

  @override
  Future<rust.WifiSsidPermission> checkBackgroundPermission() async =>
      rust.WifiSsidPermission.granted;

  @override
  Future<rust.WifiSsidPermission> requestBackgroundPermission() async =>
      rust.WifiSsidPermission.granted;

  @override
  Stream<String?> get wifiStream => const Stream.empty();
}

/// Android answers from the app's `WifiSsidPlugin`, the desktop from
/// rust_api's `wifi` module.
class WifiSsidManager {
  WifiSsidManager._();

  static final instance = WifiSsidManager._();

  WifiSsidHost _host = system.isAndroid
      ? const AndroidWifiSsidHost()
      : const _RustWifiSsidHost();

  @visibleForTesting
  void resetForTesting(WifiSsidHost host) {
    _host = host;
  }

  /// Null when the device is not on Wi-Fi or the SSID is withheld.
  Future<String?> getSsid() => _host.getSsid();

  Future<WifiConnectionInfo> getCurrentWifiInfo() => _host.getCurrentWifiInfo();

  Future<rust.WifiSsidPermission> checkPermission() => _host.checkPermission();

  Future<rust.WifiSsidPermission> requestPermission() {
    return _host.requestPermission();
  }

  Future<rust.WifiSsidPermission> checkBackgroundPermission() =>
      _host.checkBackgroundPermission();

  Future<rust.WifiSsidPermission> requestBackgroundPermission() =>
      _host.requestBackgroundPermission();

  Stream<String?> get wifiStream => _host.wifiStream;
}

final wifiSsidManager = WifiSsidManager.instance;
