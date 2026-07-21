import 'dart:async';
import 'dart:convert';

import 'package:fl_clash/core/controller.dart';
import 'package:fl_clash/core/event.dart';
import 'package:fl_clash/core/interface.dart';
import 'package:fl_clash/database/database.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/app.dart';
import 'package:fl_clash/providers/config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/riverpod.dart';

class MockCoreHandlerInterface extends Mock implements CoreHandlerInterface {}

void main() {
  late MockCoreHandlerInterface mock;
  late CoreController controller;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(
      const UnlockTestRunParams(
        runId: 'fallback',
        routeMode: UnlockTestRouteMode.appRoute,
      ),
    );
  });

  ProviderContainer buildContainer(
    UnlockTestProps props, {
    UnlockTestHistoryWriter? historyWriter,
  }) {
    return ProviderContainer(
      overrides: [
        unlockTestSettingProvider.overrideWithBuild((_, _) => props),
        unlockTestHistoryWriterProvider.overrideWithValue(
          historyWriter ?? (_) async {},
        ),
      ],
    );
  }

  setUp(() {
    mock = MockCoreHandlerInterface();
    CoreController.resetInstance();
    controller = CoreController.test(mock);
  });

  tearDown(() {
    container.dispose();
    CoreController.resetInstance();
  });

  group('UnlockDetection provider', () {
    test('default state is idle and empty', () {
      container = buildContainer(const UnlockTestProps());
      final state = container.read(unlockDetectionProvider);
      expect(state.isLoading, false);
      expect(state.results, isEmpty);
      expect(state.error, '');
    });

    test('startCheck does nothing when feature is disabled', () async {
      container = buildContainer(const UnlockTestProps(enable: false));
      await container
          .read(unlockDetectionProvider.notifier)
          .startCheck(controller: controller);
      expect(container.read(unlockDetectionProvider).results, isEmpty);
      verifyNever(() => mock.unlockTest(any()));
    });

    test('startCheck does nothing when no targets are selected', () async {
      container = buildContainer(
        const UnlockTestProps(enable: true, selectedTargets: []),
      );
      await container
          .read(unlockDetectionProvider.notifier)
          .startCheck(controller: controller);
      expect(container.read(unlockDetectionProvider).results, isEmpty);
      verifyNever(() => mock.unlockTest(any()));
    });

    test('startCheck exposes placeholders before the final result', () async {
      container = buildContainer(
        const UnlockTestProps(
          enable: true,
          selectedTargets: ['chatgpt', 'netflix'],
        ),
      );
      final response = Completer<String>();
      when(() => mock.unlockTest(any())).thenAnswer((_) => response.future);

      final pending = container
          .read(unlockDetectionProvider.notifier)
          .startCheck(controller: controller);
      await Future<void>.delayed(Duration.zero);

      final running = container.read(unlockDetectionProvider);
      expect(running.isLoading, true);
      expect(running.results.keys, ['chatgpt', 'netflix']);
      expect(
        running.results.values.every(
          (item) => item.status == UnlockTestStatus.untested,
        ),
        true,
      );

      final params =
          verify(() => mock.unlockTest(captureAny())).captured.single
              as UnlockTestRunParams;
      expect(params.routeMode, UnlockTestRouteMode.appRoute);
      expect(params.proxyName, isNull);
      expect(params.targetIds, ['chatgpt', 'netflix']);

      response.complete(
        jsonEncode({
          'run-id': params.runId,
          'route-mode': 'appRoute',
          'results': [
            {'id': 'chatgpt', 'status': 'unlocked', 'region': 'US'},
            {'id': 'netflix', 'status': 'partial', 'reason': 'contentLimited'},
          ],
        }),
      );
      await pending;

      final completed = container.read(unlockDetectionProvider);
      expect(completed.isLoading, false);
      expect(completed.results['chatgpt']?.status, UnlockTestStatus.unlocked);
      expect(completed.results['netflix']?.status, UnlockTestStatus.partial);
    });

    test('matching progress event updates one service immediately', () async {
      container = buildContainer(
        const UnlockTestProps(enable: true, selectedTargets: ['chatgpt']),
      );
      final response = Completer<String>();
      when(() => mock.unlockTest(any())).thenAnswer((_) => response.future);
      final pending = container
          .read(unlockDetectionProvider.notifier)
          .startCheck(controller: controller);
      await Future<void>.delayed(Duration.zero);
      final params =
          verify(() => mock.unlockTest(captureAny())).captured.single
              as UnlockTestRunParams;

      coreEventManager.sendEvent(
        CoreEvent(
          type: CoreEventType.unlockTestProgress,
          data: {
            'run-id': params.runId,
            'completed': 1,
            'total': 1,
            'item': {'id': 'chatgpt', 'status': 'unlocked', 'region': 'JP'},
          },
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(
        container.read(unlockDetectionProvider).results['chatgpt']?.region,
        'JP',
      );

      response.complete(
        jsonEncode({
          'run-id': params.runId,
          'route-mode': 'appRoute',
          'results': [
            {'id': 'chatgpt', 'status': 'unlocked', 'region': 'JP'},
          ],
        }),
      );
      await pending;
    });

    test('stale progress run id is ignored', () async {
      container = buildContainer(
        const UnlockTestProps(enable: true, selectedTargets: ['chatgpt']),
      );
      final response = Completer<String>();
      when(() => mock.unlockTest(any())).thenAnswer((_) => response.future);
      final pending = container
          .read(unlockDetectionProvider.notifier)
          .startCheck(controller: controller);
      await Future<void>.delayed(Duration.zero);
      final params =
          verify(() => mock.unlockTest(captureAny())).captured.single
              as UnlockTestRunParams;

      coreEventManager.sendEvent(
        const CoreEvent(
          type: CoreEventType.unlockTestProgress,
          data: {
            'run-id': 'stale-run',
            'completed': 1,
            'total': 1,
            'item': {'id': 'chatgpt', 'status': 'locked', 'region': 'ZZ'},
          },
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(
        container.read(unlockDetectionProvider).results['chatgpt']?.status,
        UnlockTestStatus.untested,
      );

      response.complete(
        jsonEncode({
          'run-id': params.runId,
          'route-mode': 'appRoute',
          'results': [
            {'id': 'chatgpt', 'status': 'unlocked', 'region': 'US'},
          ],
        }),
      );
      await pending;
    });

    test(
      'specified proxy is encoded without changing selected targets',
      () async {
        container = buildContainer(
          const UnlockTestProps(enable: true, selectedTargets: ['chatgpt']),
        );
        when(() => mock.unlockTest(any())).thenAnswer((invocation) async {
          final params =
              invocation.positionalArguments.single as UnlockTestRunParams;
          return jsonEncode({
            'run-id': params.runId,
            'route-mode': 'proxy',
            'proxy-name': 'P1',
            'results': const [],
          });
        });

        await container
            .read(unlockDetectionProvider.notifier)
            .startCheck(
              routeMode: UnlockTestRouteMode.proxy,
              proxyName: 'P1',
              controller: controller,
            );

        final params =
            verify(() => mock.unlockTest(captureAny())).captured.single
                as UnlockTestRunParams;
        expect(params.routeMode, UnlockTestRouteMode.proxy);
        expect(params.proxyName, 'P1');
        expect(params.targetIds, ['chatgpt']);
      },
    );

    test('stopCheck sends cancellation for the active run', () async {
      var historyWrites = 0;
      container = buildContainer(
        const UnlockTestProps(enable: true, selectedTargets: ['chatgpt']),
        historyWriter: (_) async => historyWrites++,
      );
      final response = Completer<String>();
      when(() => mock.unlockTest(any())).thenAnswer((_) => response.future);
      when(() => mock.cancelUnlockTest(any())).thenAnswer((_) async => true);
      final pending = container
          .read(unlockDetectionProvider.notifier)
          .startCheck(controller: controller);
      await Future<void>.delayed(Duration.zero);
      final params =
          verify(() => mock.unlockTest(captureAny())).captured.single
              as UnlockTestRunParams;

      await container
          .read(unlockDetectionProvider.notifier)
          .stopCheck(controller: controller);
      verify(() => mock.cancelUnlockTest(params.runId)).called(1);
      expect(container.read(unlockDetectionProvider).isLoading, false);

      response.complete(
        jsonEncode({
          'run-id': params.runId,
          'route-mode': 'appRoute',
          'cancelled': true,
        }),
      );
      await pending;
      expect(historyWrites, 0);
    });

    test('completed run is persisted exactly once', () async {
      final saved = <UnlockTestRunRecord>[];
      container = buildContainer(
        const UnlockTestProps(enable: true, selectedTargets: ['chatgpt']),
        historyWriter: (record) async => saved.add(record),
      );
      when(() => mock.unlockTest(any())).thenAnswer((invocation) async {
        final params =
            invocation.positionalArguments.single as UnlockTestRunParams;
        return jsonEncode({
          'run-id': params.runId,
          'route-mode': 'appRoute',
          'results': [
            {'id': 'chatgpt', 'status': 'unlocked'},
          ],
        });
      });

      await container
          .read(unlockDetectionProvider.notifier)
          .startCheck(controller: controller);

      expect(saved, hasLength(1));
      expect(saved.single.routeMode, 'appRoute');
      expect(saved.single.resultsJson, contains('"chatgpt"'));
      final state = container.read(unlockDetectionProvider);
      expect(state.testedAt, isNotNull);
      expect(saved.single.createdAt, state.testedAt);
    });
  });
}
