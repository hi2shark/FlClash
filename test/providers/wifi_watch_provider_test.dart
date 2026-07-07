import 'dart:convert';

import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/app.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:wifi_ssid/wifi_ssid.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('WifiWatchStateJson provider', () {
    test('default is empty string', () {
      expect(container.read(wifiWatchStateJsonProvider), '');
    });

    test('accepts JSON pushed from native side', () {
      const json = '{"ssid":"Home","rssi":-55,"validated":true}';
      container.read(wifiWatchStateJsonProvider.notifier).value = json;
      expect(container.read(wifiWatchStateJsonProvider), json);
    });
  });

  group('WifiWatch provider on non-Android', () {
    // system.isAndroid is false in the test host, so WifiWatch.build()
    // short-circuits to the empty default and never watches the JSON holder.
    test('returns empty state regardless of pushed JSON', () {
      container.read(wifiWatchStateJsonProvider.notifier).value =
          '{"ssid":"Home"}';
      final state = container.read(wifiWatchProvider);
      expect(state.ssid, isNull);
      expect(state.suspended, false);
    });
  });

  group('buildWifiWatchState', () {
    test('empty json string yields default with suspended flag', () {
      final state = buildWifiWatchState('', true);
      expect(state.ssid, isNull);
      expect(state.suspended, true);
    });

    test('parses service JSON and composes android-suspended flag', () {
      const json = '{"ssid":"Home","rssi":-55,"validated":true}';
      final state = buildWifiWatchState(json, true);
      expect(state.ssid, 'Home');
      expect(state.rssi, -55);
      expect(state.validated, true);
      expect(state.suspended, true);
    });

    test('service suspended=false keeps wifiSuspended-driven suspension', () {
      // The native wifi-watch can drive suspended=true via setWifiSuspended;
      // androidServiceSuspended is a separate reason and should OR in, not
      // override. Here service says suspended=true, android says false.
      const json = '{"ssid":"Home","suspended":true}';
      final state = buildWifiWatchState(json, false);
      expect(state.suspended, true);
    });

    test('malformed JSON falls back to default without throwing', () {
      final state = buildWifiWatchState('not json', true);
      expect(state.ssid, isNull);
      expect(state.suspended, true);
    });
  });

  group('mergeServiceAndDeviceWifi', () {
    test('service rssi wins over device rssi (regression: was inverted)', () {
      // Previous bug: rssi was set to null when service had a value, clearing
      // the strong signal. Service value must be kept.
      final serviceJson = jsonEncode(
        const WifiWatchState(
          ssid: 'Home',
          rawSsid: 'Home',
          rssi: -55,
          validated: true,
          wifiPresent: true,
        ).toJson(),
      );
      const deviceInfo = WifiConnectionInfo(ssid: 'Other', rssi: -90);
      final merged = mergeServiceAndDeviceWifi(serviceJson, deviceInfo);
      final state = WifiWatchState.fromJson(jsonDecode(merged));
      expect(state.rssi, -55);
      expect(state.ssid, 'Home');
    });

    test('device rssi fills in when service has none', () {
      final serviceJson = jsonEncode(
        const WifiWatchState(
          ssid: 'Home',
          rawSsid: 'Home',
          validated: true,
          wifiPresent: true,
        ).toJson(),
      );
      const deviceInfo = WifiConnectionInfo(ssid: 'Home', rssi: -70);
      final merged = mergeServiceAndDeviceWifi(serviceJson, deviceInfo);
      final state = WifiWatchState.fromJson(jsonDecode(merged));
      expect(state.rssi, -70);
    });

    test(
      'rawSsid mirrors service ssid, not device ssid (regression: was overwritten)',
      () {
        // Previous bug: rawSsid was always set to the device SSID, which could
        // differ from the service-resolved SSID while a self-VPN tunnel was
        // active and confuse the copy-to-clipboard action.
        final serviceJson = jsonEncode(
          const WifiWatchState(
            ssid: 'ServiceHome',
            rawSsid: 'ServiceHome',
            rssi: -55,
            validated: true,
            wifiPresent: true,
          ).toJson(),
        );
        const deviceInfo = WifiConnectionInfo(ssid: 'DeviceHome', rssi: -55);
        final merged = mergeServiceAndDeviceWifi(serviceJson, deviceInfo);
        final state = WifiWatchState.fromJson(jsonDecode(merged));
        expect(state.rawSsid, 'ServiceHome');
        expect(state.ssid, 'ServiceHome');
      },
    );

    test('null service data falls back to device-only info', () {
      const deviceInfo = WifiConnectionInfo(ssid: 'Home', rssi: -55);
      final merged = mergeServiceAndDeviceWifi(null, deviceInfo);
      final state = WifiWatchState.fromJson(jsonDecode(merged));
      expect(state.ssid, 'Home');
      expect(state.rssi, -55);
      expect(state.wifiPresent, true);
    });

    test('empty service json string falls back to device-only info', () {
      const deviceInfo = WifiConnectionInfo(ssid: 'Home', rssi: -55);
      final merged = mergeServiceAndDeviceWifi('', deviceInfo);
      final state = WifiWatchState.fromJson(jsonDecode(merged));
      expect(state.ssid, 'Home');
    });

    test('malformed service json is passed through, not replaced', () {
      const deviceInfo = WifiConnectionInfo(ssid: 'Home', rssi: -55);
      const badJson = 'not json';
      // We keep the service's raw payload rather than silently substituting
      // device-only info — the parse error will be logged downstream.
      expect(mergeServiceAndDeviceWifi(badJson, deviceInfo), badJson);
    });

    test('wifiPresent is true if either source reports wifi', () {
      final serviceJson = jsonEncode(
        const WifiWatchState(
          ssid: 'Home',
          validated: true,
          // service says no wifi present
          wifiPresent: false,
        ).toJson(),
      );
      const deviceInfo = WifiConnectionInfo(ssid: 'Home', rssi: -55);
      final merged = mergeServiceAndDeviceWifi(serviceJson, deviceInfo);
      final state = WifiWatchState.fromJson(jsonDecode(merged));
      expect(state.wifiPresent, true);
    });
  });
}
