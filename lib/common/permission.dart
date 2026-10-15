import 'dart:async';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:wifi_ssid/wifi_ssid_manager.dart';

class Permissions {
  static Permissions? _instance;

  Permissions._internal();

  factory Permissions() {
    _instance ??= Permissions._internal();
    return _instance!;
  }

  void check() {
    checkBackgroundLocationPermissions();
  }

  Future<void> checkBackgroundLocationPermissions() async {
    if (!system.isAndroid) {
      return;
    }
    try {
      final res = await WifiSsidManager.instance.checkBackgroundPermission();
      globalState.container
              .read(backgroundLocationPermissionsProvider.notifier)
              .value =
          res;
    } catch (error) {
      commonPrint.log('checkBackgroundPermission error $error');
    }
  }
}

final permissions = Permissions();
