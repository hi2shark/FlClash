import 'dart:convert';

import 'package:fl_clash/models/models.dart';
import 'package:test/test.dart';

void main() {
  group('WifiWatchState', () {
    test('merges Android service suspended state into fallback snapshots', () {
      final state = const WifiWatchState(
        ssid: 'Home',
        rawSsid: 'Home',
        validated: false,
        wifiPresent: true,
      ).withAndroidServiceSuspended(true);

      expect(state.suspended, true);
      expect(state.ssid, 'Home');
      expect(state.rawSsid, 'Home');
      expect(state.wifiPresent, true);
    });

    test('marks pending suspend snapshots as action-priority', () {
      final deadline = DateTime.fromMillisecondsSinceEpoch(2000);

      expect(
        WifiWatchState(pendingSuspendDeadline: deadline).prioritizeActionStatus,
        true,
      );
      expect(
        const WifiWatchState(suspended: true).prioritizeActionStatus,
        true,
      );
      expect(
        const WifiWatchState(ssid: 'Home', wifiPresent: true)
            .prioritizeActionStatus,
        false,
      );
    });

    test('round-trips forceResumed and reason through JSON', () {
      const state = WifiWatchState(
        ssid: 'Home',
        forceResumed: true,
        reason: 'default network is Cellular',
      );
      final encoded = jsonEncode(state.toJson());
      final decoded = WifiWatchState.fromJson(
        jsonDecode(encoded) as Map<String, dynamic>,
      );
      expect(decoded.forceResumed, true);
      expect(decoded.reason, 'default network is Cellular');
    });

    test('forceResumed defaults to false and reason to null', () {
      const state = WifiWatchState();
      expect(state.forceResumed, false);
      expect(state.reason, isNull);
    });
  });
}
