import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/app.dart';
import 'package:fl_clash/providers/config.dart';
import 'package:fl_clash/views/dashboard/widget_registry.dart';
import 'package:fl_clash/views/dashboard/widgets/unlock_detection.dart'
    as dashboard;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/test_app.dart';

void main() {
  test('unlock dashboard widget builds the unlock detection card', () {
    expect(
      DashboardWidget.unlockDetection.card,
      isA<dashboard.UnlockDetection>(),
    );
  });

  testWidgets('dark dashboard exposes eight service states without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 300);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const statuses = [
      UnlockTestStatus.error,
      UnlockTestStatus.locked,
      UnlockTestStatus.partial,
      UnlockTestStatus.unlocked,
      UnlockTestStatus.unlocked,
      UnlockTestStatus.unlocked,
      UnlockTestStatus.unlocked,
      UnlockTestStatus.unlocked,
    ];
    const ids = [
      'chatgpt',
      'claude',
      'gemini',
      'copilot',
      'netflix',
      'disney-plus',
      'youtube-premium',
      'spotify',
    ];
    final results = {
      for (var index = 0; index < ids.length; index++)
        ids[index]: UnlockTestRunItem(id: ids[index], status: statuses[index]),
    };

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          unlockTestSettingProvider.overrideWithBuild(
            (_, _) => const UnlockTestProps(enable: true),
          ),
          unlockDetectionProvider.overrideWithValue(
            UnlockDetectionState(
              isLoading: false,
              proxyName: '',
              results: results,
              testedAt: DateTime(2026, 7, 21, 12, 34),
            ),
          ),
        ],
        child: TestApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xff8f9cff),
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          child: dashboard.UnlockDetection(historyLoader: () async => null),
        ),
      ),
    );
    await tester.pump();

    for (final name in const [
      'ChatGPT',
      'Claude',
      'Gemini',
      'Microsoft Copilot',
      'Netflix',
      'Disney+',
      'YouTube Premium',
      'Spotify',
    ]) {
      expect(find.text(name), findsOneWidget);
    }
    expect(find.text('12:34'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('named proxy results never replace latest app route history', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 300);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final history = UnlockTestHistoryEntry(
      createdAt: DateTime(2026, 7, 21, 12),
      durationMs: 1000,
      catalogVersion: 2,
      result: const UnlockTestRunResult(
        runId: 'app-route',
        routeMode: UnlockTestRouteMode.appRoute,
        results: [
          UnlockTestRunItem(id: 'netflix', status: UnlockTestStatus.unlocked),
        ],
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          unlockTestSettingProvider.overrideWithBuild(
            (_, _) => const UnlockTestProps(enable: true),
          ),
          unlockDetectionProvider.overrideWithValue(
            const UnlockDetectionState(
              isLoading: false,
              proxyName: 'Named Proxy',
              results: {
                'chatgpt': UnlockTestRunItem(
                  id: 'chatgpt',
                  status: UnlockTestStatus.locked,
                ),
              },
            ),
          ),
        ],
        child: TestApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xff6750a4),
            ),
            useMaterial3: true,
          ),
          child: dashboard.UnlockDetection(historyLoader: () async => history),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Netflix'), findsOneWidget);
    expect(find.text('ChatGPT'), findsNothing);
  });
}
