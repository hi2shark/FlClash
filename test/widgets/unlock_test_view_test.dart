import 'package:fl_clash/common/theme.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/app.dart';
import 'package:fl_clash/providers/config.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/views/unlock_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap({
  required UnlockTestProps props,
  required UnlockDetectionState detection,
  Brightness brightness = Brightness.light,
  List<UnlockTestHistoryEntry> history = const [],
}) {
  return ProviderScope(
    overrides: [
      unlockTestSettingProvider.overrideWithBuild((_, _) => props),
      unlockDetectionProvider.overrideWithValue(detection),
    ],
    child: MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff6750a4),
          brightness: brightness,
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
          return UnlockTestView(historyLoader: () async => history);
        },
      ),
    ),
  );
}

void main() {
  testWidgets('disabled page remains readable and does not expose raw URLs', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _wrap(
        props: const UnlockTestProps(enable: false),
        detection: const UnlockDetectionState(
          isLoading: false,
          proxyName: '',
          results: {},
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Unlock Detection'), findsWidgets);
    expect(find.text('Enable unlock detection'), findsOneWidget);
    expect(find.textContaining('https://'), findsNothing);
  });

  testWidgets(
    'mixed results show service names and textual five-state labels',
    (tester) async {
      tester.view.physicalSize = const Size(1024, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _wrap(
          props: const UnlockTestProps(
            enable: true,
            selectedTargets: ['chatgpt', 'netflix'],
          ),
          detection: const UnlockDetectionState(
            isLoading: false,
            proxyName: '',
            results: {
              'chatgpt': UnlockTestRunItem(
                id: 'chatgpt',
                status: UnlockTestStatus.unlocked,
                region: 'US',
              ),
              'netflix': UnlockTestRunItem(
                id: 'netflix',
                status: UnlockTestStatus.partial,
                reason: UnlockTestReason.contentLimited,
              ),
            },
          ),
          brightness: Brightness.dark,
        ),
      );
      await tester.pump();

      expect(find.text('ChatGPT'), findsWidgets);
      expect(find.text('Netflix'), findsWidgets);
      expect(find.text('Unlocked'), findsWidgets);
      expect(find.text('Partial'), findsWidgets);
    },
  );

  testWidgets(
    'service selector exposes all regional groups and the last item',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _wrap(
          props: const UnlockTestProps(enable: true),
          detection: const UnlockDetectionState(
            isLoading: false,
            proxyName: '',
            results: {},
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.textContaining('Select services').first);
      await tester.pumpAndSettle();

      expect(find.text('AI Services'), findsWidgets);
      expect(find.text('Global media'), findsWidgets);
      expect(find.text('ChatGPT'), findsWidgets);

      await tester.drag(
        find.byType(ListView).last,
        const Offset(0, -4000),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      expect(find.text('Korea'), findsWidgets);
      expect(find.text('Watcha'), findsOneWidget);
      expect(find.textContaining('https://'), findsNothing);
    },
  );

  testWidgets('history selection is visibly read-only and replaces the grid', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _wrap(
        props: const UnlockTestProps(
          enable: true,
          selectedTargets: ['chatgpt'],
        ),
        detection: const UnlockDetectionState(
          isLoading: false,
          proxyName: '',
          results: {
            'chatgpt': UnlockTestRunItem(
              id: 'chatgpt',
              status: UnlockTestStatus.unlocked,
            ),
          },
        ),
        history: [
          UnlockTestHistoryEntry(
            createdAt: DateTime(2026, 7, 21, 12, 30),
            durationMs: 1000,
            catalogVersion: 2,
            result: const UnlockTestRunResult(
              runId: 'history-run',
              routeMode: UnlockTestRouteMode.appRoute,
              results: [
                UnlockTestRunItem(
                  id: 'netflix',
                  status: UnlockTestStatus.locked,
                  reason: UnlockTestReason.geoBlocked,
                ),
              ],
            ),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Current results').first);
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Follow current routing').last);
    await tester.pumpAndSettle();

    expect(find.textContaining('History result'), findsOneWidget);
    expect(find.text('Netflix'), findsOneWidget);
    expect(find.text('Blocked'), findsWidgets);
    expect(find.text('ChatGPT'), findsNothing);
  });
}
