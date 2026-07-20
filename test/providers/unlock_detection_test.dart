import 'dart:convert';

import 'package:fl_clash/core/controller.dart';
import 'package:fl_clash/core/interface.dart';
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
    registerFallbackValue(const UnlockTestParams(proxyName: 'P'));
  });

  ProviderContainer buildContainer(UnlockTestProps props) {
    return ProviderContainer(
      overrides: [unlockTestSettingProvider.overrideWithBuild((_, _) => props)],
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
      final state = container.read(unlockDetectionProvider);
      expect(state.isLoading, false);
      expect(state.results, isEmpty);
      verifyNever(() => mock.unlockTest(any()));
    });

    test('startCheck does nothing when no targets are selected', () async {
      container = buildContainer(
        const UnlockTestProps(enable: true, selectedTargets: []),
      );
      await container
          .read(unlockDetectionProvider.notifier)
          .startCheck(controller: controller);
      final state = container.read(unlockDetectionProvider);
      expect(state.results, isEmpty);
      verifyNever(() => mock.unlockTest(any()));
    });

    test('startCheck tests selected targets through the given proxy', () async {
      container = buildContainer(
        const UnlockTestProps(
          enable: true,
          selectedTargets: ['chatgpt', 'netflix'],
        ),
      );
      when(() => mock.unlockTest(any())).thenAnswer((invocation) async {
        final params = invocation.positionalArguments[0] as UnlockTestParams;
        return json.encode({
          'name': params.proxyName,
          'results': [
            {
              'id': 'chatgpt',
              'status': 200,
              'latency': 100,
              'region': 'US',
              'unlocked': true,
              'error': '',
            },
            {
              'id': 'netflix',
              'status': 403,
              'latency': 80,
              'region': '',
              'unlocked': false,
              'error': '',
            },
          ],
          'error': '',
        });
      });

      await container
          .read(unlockDetectionProvider.notifier)
          .startCheck(proxyName: 'P1', controller: controller);

      final captured =
          verify(() => mock.unlockTest(captureAny())).captured.single
              as UnlockTestParams;
      expect(captured.proxyName, 'P1');
      expect(captured.tests.map((test) => test.id), ['chatgpt', 'netflix']);

      final state = container.read(unlockDetectionProvider);
      expect(state.isLoading, false);
      expect(state.proxyName, 'P1');
      expect(state.error, '');
      expect(state.results.keys, ['chatgpt', 'netflix']);
      expect(state.results['chatgpt']?.unlocked, true);
      expect(state.results['chatgpt']?.region, 'US');
      expect(state.results['netflix']?.unlocked, false);
    });

    test('startCheck uses GLOBAL proxy by default', () async {
      container = buildContainer(
        const UnlockTestProps(enable: true, selectedTargets: ['chatgpt']),
      );
      when(() => mock.unlockTest(any())).thenAnswer(
        (_) async =>
            json.encode({'name': 'GLOBAL', 'results': [], 'error': ''}),
      );

      await container
          .read(unlockDetectionProvider.notifier)
          .startCheck(controller: controller);

      final captured =
          verify(() => mock.unlockTest(captureAny())).captured.single
              as UnlockTestParams;
      expect(captured.proxyName, 'GLOBAL');
      expect(container.read(unlockDetectionProvider).proxyName, 'GLOBAL');
    });

    test('startCheck surfaces top-level core errors', () async {
      container = buildContainer(
        const UnlockTestProps(enable: true, selectedTargets: ['chatgpt']),
      );
      when(() => mock.unlockTest(any())).thenAnswer(
        (_) async => json.encode({
          'name': 'GLOBAL',
          'results': [],
          'error': 'proxy GLOBAL not found',
        }),
      );

      await container
          .read(unlockDetectionProvider.notifier)
          .startCheck(controller: controller);

      final state = container.read(unlockDetectionProvider);
      expect(state.isLoading, false);
      expect(state.error, 'proxy GLOBAL not found');
      expect(state.results, isEmpty);
    });
  });
}
