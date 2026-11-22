import 'package:fl_clash/manager/background_resource_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'pauses Android bulk streams after 5s and resumes on foreground',
    (tester) async {
      final foregroundCalls = <bool>[];
      var pauseLogs = 0;
      var resumeLogs = 0;
      final manager = BackgroundResourceManager.forTest(
        isAndroid: true,
        onForegroundChanged: (foreground) async =>
            foregroundCalls.add(foreground),
        onPauseLog: () => pauseLogs++,
        onResumeLog: () => resumeLogs++,
      );
      addTearDown(manager.leaveBackground);

      manager.enterBackground();
      await tester.pump(const Duration(seconds: 4));
      expect(manager.isBulkStreamsPaused, isFalse);
      expect(foregroundCalls, isEmpty);
      expect(pauseLogs, 0);

      await tester.pump(const Duration(seconds: 1));
      expect(manager.isBulkStreamsPaused, isTrue);
      expect(foregroundCalls, [false]);
      expect(pauseLogs, 1);

      manager.leaveBackground();
      expect(manager.isBulkStreamsPaused, isFalse);
      expect(foregroundCalls, [false, true]);
      expect(resumeLogs, 1);
    },
  );

  testWidgets('returning to foreground within 5s cancels Android bulk pause', (
    tester,
  ) async {
    final foregroundCalls = <bool>[];
    var pauseLogs = 0;
    var resumeLogs = 0;
    final manager = BackgroundResourceManager.forTest(
      isAndroid: true,
      onForegroundChanged: (foreground) async =>
          foregroundCalls.add(foreground),
      onPauseLog: () => pauseLogs++,
      onResumeLog: () => resumeLogs++,
    );
    addTearDown(manager.leaveBackground);

    manager.enterBackground();
    await tester.pump(const Duration(seconds: 3));
    manager.leaveBackground();
    await tester.pump(const Duration(seconds: 5));

    expect(manager.isBulkStreamsPaused, isFalse);
    expect(foregroundCalls, isEmpty);
    expect(pauseLogs, 0);
    expect(resumeLogs, 0);
  });

  testWidgets('desktop background does not pause Android bulk streams', (
    tester,
  ) async {
    final foregroundCalls = <bool>[];
    var pauseLogs = 0;
    final manager = BackgroundResourceManager.forTest(
      isAndroid: false,
      onForegroundChanged: (foreground) async =>
          foregroundCalls.add(foreground),
      onPauseLog: () => pauseLogs++,
    );
    addTearDown(manager.leaveBackground);

    manager.enterBackground();
    await tester.pump(const Duration(seconds: 10));

    expect(manager.isBulkStreamsPaused, isFalse);
    expect(foregroundCalls, isEmpty);
    expect(pauseLogs, 0);
    manager.leaveBackground();
  });

  testWidgets('background cleanup clears package icon cache after 45s', (
    tester,
  ) async {
    var iconClears = 0;
    final manager = BackgroundResourceManager.forTest(
      isAndroid: true,
      onForegroundChanged: (_) async {},
      onPauseLog: () {},
      onResumeLog: () {},
      onClearPackageIcons: () => iconClears++,
    );
    addTearDown(manager.leaveBackground);

    manager.enterBackground();
    await tester.pump(const Duration(seconds: 44));
    expect(iconClears, 0);

    await tester.pump(const Duration(seconds: 1));
    expect(iconClears, 1);

    await tester.pump(const Duration(milliseconds: 600));
    manager.leaveBackground();
  });
}
