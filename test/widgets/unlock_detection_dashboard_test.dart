import 'package:fl_clash/common/theme.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/app.dart';
import 'package:fl_clash/providers/config.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/views/dashboard/widgets/unlock_detection.dart'
    as dashboard;
import 'package:fl_clash/widgets/grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('unlock dashboard widget is full width and double height', () {
    final GridItem widget = DashboardWidget.unlockDetection.widget;
    expect(widget.crossAxisCellCount, 8);
    expect(widget.mainAxisCellCount, 2);
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
        child: MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xff8f9cff),
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.delegate.supportedLocales,
          home: Builder(
            builder: (context) {
              globalState.theme = CommonTheme.of(context, 1);
              return dashboard.UnlockDetection(historyLoader: () async => null);
            },
          ),
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
        child: MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xff6750a4),
            ),
            useMaterial3: true,
          ),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.delegate.supportedLocales,
          home: Builder(
            builder: (context) {
              globalState.theme = CommonTheme.of(context, 1);
              return dashboard.UnlockDetection(
                historyLoader: () async => history,
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Netflix'), findsOneWidget);
    expect(find.text('ChatGPT'), findsNothing);
  });
}
