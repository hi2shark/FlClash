import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/providers/app.dart';
import 'package:fl_clash/state.dart';
import 'package:flutter/material.dart';
import 'package:wifi_ssid/wifi_ssid.dart';

class ConnectivityManager extends StatefulWidget {
  final Function(List<ConnectivityResult> results)? onConnectivityChanged;
  final Widget child;

  const ConnectivityManager({
    super.key,
    this.onConnectivityChanged,
    required this.child,
  });

  @override
  State<ConnectivityManager> createState() => _ConnectivityManagerState();
}

class _ConnectivityManagerState extends State<ConnectivityManager> {
  late StreamSubscription subscription;
  StreamSubscription<String?>? validatedWifiSsidSubscription;

  @override
  void initState() {
    super.initState();
    if (system.isAndroid) {
      validatedWifiSsidSubscription = WifiSsidManager.instance
          .watchValidatedWifiSsid()
          .listen(
            (ssid) {
              globalState.container.read(currentSSIDProvider.notifier).value =
                  ssid;
              commonPrint.log(
                'Validated Wi-fi SSID: $ssid',
                logLevel: LogLevel.info,
              );
            },
            onError: (_) {
              globalState.container.read(currentSSIDProvider.notifier).value =
                  null;
            },
          );
    }
    subscription = Connectivity().onConnectivityChanged.listen((results) {
      if (!system.isAndroid && results.contains(ConnectivityResult.wifi)) {
        WifiSsidManager.instance.getSsid().then((ssid) {
          globalState.container.read(currentSSIDProvider.notifier).value = ssid;
          commonPrint.log('Wi-fi SSID: $ssid ', logLevel: LogLevel.info);
        });
      } else if (!system.isAndroid) {
        globalState.container.read(currentSSIDProvider.notifier).value = null;
      }
      if (widget.onConnectivityChanged != null) {
        widget.onConnectivityChanged!(results);
      }
    });
  }

  @override
  void dispose() {
    subscription.cancel();
    validatedWifiSsidSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
