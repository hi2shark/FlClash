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
  });
}
