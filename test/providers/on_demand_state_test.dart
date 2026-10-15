import 'package:fl_clash/providers/state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('enabled on-demand syncs configured SSIDs', () {
    expect(effectiveSuspendOnWifiSsids(true, const ['Home', 'Office']), [
      'Home',
      'Office',
    ]);
  });

  test('disabled on-demand syncs an empty list without changing config', () {
    const configured = ['Home', 'Office'];

    expect(effectiveSuspendOnWifiSsids(false, configured), isEmpty);
    expect(configured, ['Home', 'Office']);
  });
}
