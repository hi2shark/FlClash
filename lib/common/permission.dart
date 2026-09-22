import 'dart:async';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/plugins/app.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wifi_ssid/wifi_ssid_manager.dart';

class Permissions {
  static Permissions? _instance;

  Permissions._internal();

  factory Permissions() {
    _instance ??= Permissions._internal();
    return _instance!;
  }

  bool _isRequestingLocation = false;
  bool _locationAutoRequestAttempted = false;
  bool needWaitingBatteryOptimizationSettings = false;

  void check() {
    checkLocationPermissions();
    checkBackgroundLocationPermissions();
    checkBatteryOptimizationDisable();
  }

  Future<void> checkBatteryOptimizationDisable() async {
    await _checkBatteryOptimizationDisable();
  }

  Future<void> _checkBatteryOptimizationDisable() async {
    const tag = LoadingTag.batteryOptimization;
    try {
      if (needWaitingBatteryOptimizationSettings) {
        globalState.container.read(loadingProvider(tag).notifier).value = true;
      }
      globalState.container
          .read(batteryOptimizationDisableProvider.notifier)
          .value = await retry<bool>(
        task: () async {
          return await app?.isBatteryOptimizationDisabled() ?? false;
        },
        retryIf: (res) => res == false,
        delay: const Duration(milliseconds: 500),
        maxAttempts: needWaitingBatteryOptimizationSettings ? 5 : 1,
      );
    } finally {
      globalState.container.read(loadingProvider(tag).notifier).value = false;
      needWaitingBatteryOptimizationSettings = false;
    }
  }

  Future<void> checkLocationPermissions() async {
    if (!(system.isAndroid || system.isMacOS)) {
      return;
    }
    final res = await WifiSsidManager.instance.checkPermission();
    if (res == WifiSsidPermission.granted) {
      _locationAutoRequestAttempted = false;
    }
    final current = globalState.container.read(locationPermissionsProvider);
    if (res == WifiSsidPermission.granted ||
        current != WifiSsidPermission.permanentlyDenied) {
      globalState.container.read(locationPermissionsProvider.notifier).value =
          res;
    }
    final needRequestPermission = globalState.container.read(
      excludeSSIDsProvider.select((state) => state.isNotEmpty),
    );
    // checkPermission on Android never reports permanentlyDenied, so a denied
    // state would otherwise re-prompt on every resume: the dialog flips the
    // app inactive/resumed and each resume requests again, looping at full
    // speed. Auto-request at most once per session; the on-demand settings
    // page still offers an explicit request button.
    if (res == WifiSsidPermission.denied &&
        needRequestPermission &&
        !_isRequestingLocation &&
        !_locationAutoRequestAttempted) {
      try {
        _isRequestingLocation = true;
        _locationAutoRequestAttempted = true;
        final res = await WifiSsidManager.instance.requestPermission();
        globalState.container.read(locationPermissionsProvider.notifier).value =
            res;
        if (res != WifiSsidPermission.granted) {
          final ssid = await WifiSsidManager.instance.getSsid();
          globalState.container.read(currentSSIDProvider.notifier).value = ssid;
        }
      } finally {
        _isRequestingLocation = false;
      }
    }
  }

  Future<void> checkBackgroundLocationPermissions() async {
    if (!system.isAndroid) {
      return;
    }
    final res = await WifiSsidManager.instance.checkBackgroundPermission();
    globalState.container
        .read(backgroundLocationPermissionsProvider.notifier)
        .value = res;
  }
}

final permissions = Permissions();
