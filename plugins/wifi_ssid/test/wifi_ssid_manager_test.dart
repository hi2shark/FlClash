import 'package:flutter_test/flutter_test.dart';
import 'package:wifi_ssid/wifi_ssid.dart';

void main() {
  group('WifiConnectionInfo', () {
    test('parses ssid and rssi from platform map', () {
      final info = WifiConnectionInfo.fromMap({
        'ssid': 'Office',
        'rssi': -64,
      });

      expect(info.ssid, 'Office');
      expect(info.rssi, -64);
    });

    test('parses numeric string rssi and ignores invalid Android sentinel', () {
      final fromString = WifiConnectionInfo.fromMap({
        'ssid': 'Cafe',
        'rssi': '-72',
      });
      final invalid = WifiConnectionInfo.fromMap({
        'ssid': 'Cafe',
        'rssi': -127,
      });

      expect(fromString.rssi, -72);
      expect(invalid.rssi, null);
    });
  });
}
