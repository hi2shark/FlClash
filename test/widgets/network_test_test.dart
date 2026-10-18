import 'dart:async';

import 'package:fl_clash/common/theme.dart';
import 'package:fl_clash/core/controller.dart';
import 'package:fl_clash/core/desktop/model.dart';
import 'package:fl_clash/core/interface.dart';
import 'package:fl_clash/core/method.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/app.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/views/network_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockCoreHandler extends Mock implements CoreHandlerInterface {}

const _lifecycleResult = CoreLifecycleResult(
  revision: 0,
  outcome: CoreLifecycleOutcome.applied,
);

class _RecordingCoreHandler extends CoreHandlerInterface {
  CoreMethod? method;
  Object? arguments;
  Duration? timeout;

  @override
  Future<T?> invokeMethod<T>({
    required CoreMethod method,
    Object? arguments,
    Duration? timeout,
  }) async {
    this.method = method;
    this.arguments = arguments;
    this.timeout = timeout;
    return <String, dynamic>{'name': 'P'} as T?;
  }

  @override
  Future<CoreLifecycleResult> start() async => _lifecycleResult;

  @override
  Future<CoreLifecycleResult> restart() async => _lifecycleResult;

  @override
  Future<CoreLifecycleResult> stop() async => _lifecycleResult;

  @override
  Future<CoreLifecycleResult> close() async => _lifecycleResult;
}

class _UnansweredCoreHandler extends _RecordingCoreHandler {
  @override
  Future<T?> invokeMethod<T>({
    required CoreMethod method,
    Object? arguments,
    Duration? timeout,
  }) async {
    this.method = method;
    this.arguments = arguments;
    this.timeout = timeout;
    return null;
  }
}

Widget _wrap(Widget child) {
  return UncontrolledProviderScope(
    container: globalState.container,
    child: MaterialApp(
      navigatorKey: globalState.navigatorKey,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: AppLocalizations.delegate.supportedLocales,
      home: Builder(
        builder: (context) {
          globalState.theme = CommonTheme.of(context, 1.0);
          return child;
        },
      ),
    ),
  );
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
}

SpeedTestResult _speedResult({int latency = 1}) {
  return SpeedTestResult(
    name: 'DIRECT',
    latency: latency,
    speed: 1000,
    bytes: 1000,
  );
}

QuicTestResult _quicResult({String target = 'cloudflare-quic.com:443'}) {
  return QuicTestResult(
    name: 'DIRECT',
    target: target,
    stage: 'completed',
    rtt: 1,
  );
}

void main() {
  late _MockCoreHandler mock;
  late CoreController controller;

  setUpAll(() {
    globalState.container = ProviderContainer(
      overrides: [
        viewSizeProvider.overrideWithBuild((_, _) => const Size(800, 600)),
      ],
    );
    registerFallbackValue(const SpeedTestParams(proxyName: 'fallback'));
    registerFallbackValue(const QuicTestParams(proxyName: 'fallback'));
  });

  setUp(() {
    mock = _MockCoreHandler();
    controller = CoreController.test(mock);
  });

  test('speed test presets keep source, size, URL, bytes, and timeout', () {
    final presets = networkTestSpeedTestPresets;
    final presetsByLabel = {for (final preset in presets) preset.label: preset};

    expect(presets, hasLength(4));
    expect(
      presetsByLabel.keys,
      containsAll([
        'Cloudflare 10 MB',
        'Cloudflare 25 MB',
        'Cloudflare 50 MB',
        'CacheFly 100 MB',
      ]),
    );
    expect(
      presetsByLabel.keys.where((label) => label.startsWith('OVH')),
      isEmpty,
    );
    expect(presetsByLabel, isNot(contains('Cloudflare 100 MB')));
    expect(
      presets.map((preset) => preset.url),
      isNot(contains('https://speed.cloudflare.com/__down?bytes=100000000')),
    );

    expect(presetsByLabel['Cloudflare 10 MB']?.bytes, 10000000);
    expect(
      presetsByLabel['Cloudflare 10 MB']?.url,
      'https://speed.cloudflare.com/__down?bytes=10000000',
    );
    expect(
      presetsByLabel['Cloudflare 10 MB']?.timeout,
      const Duration(seconds: 20),
    );
    expect(presetsByLabel['Cloudflare 25 MB']?.bytes, 25000000);
    expect(
      presetsByLabel['Cloudflare 25 MB']?.url,
      'https://speed.cloudflare.com/__down?bytes=25000000',
    );
    expect(
      presetsByLabel['Cloudflare 25 MB']?.timeout,
      const Duration(seconds: 30),
    );
    expect(presetsByLabel['Cloudflare 50 MB']?.bytes, 50000000);
    expect(
      presetsByLabel['Cloudflare 50 MB']?.url,
      'https://speed.cloudflare.com/__down?bytes=50000000',
    );
    expect(
      presetsByLabel['Cloudflare 50 MB']?.timeout,
      const Duration(seconds: 60),
    );
    expect(presetsByLabel['CacheFly 100 MB']?.bytes, 104857600);
    expect(
      presetsByLabel['CacheFly 100 MB']?.url,
      'https://cachefly.cachefly.net/100mb.test',
    );
    expect(
      presetsByLabel['CacheFly 100 MB']?.timeout,
      const Duration(seconds: 120),
    );
    expect(networkTestDefaultSpeedTestPreset.label, 'Cloudflare 25 MB');
  });

  test('network candidate filtering is type-based, not name-based', () {
    final proxies = [
      const Proxy(name: 'reject-by-type', type: ' Reject '),
      const Proxy(name: 'rejectdrop-by-type', type: 'RejectDrop'),
      const Proxy(name: 'pass-by-type', type: 'Pass'),
      const Proxy(name: 'passrule-by-type', type: 'PassRule'),
      const Proxy(name: 'REJECT', type: 'HTTP'),
      const Proxy(name: 'PASS', type: 'Shadowsocks'),
      const Proxy(name: 'DIRECT', type: 'Direct'),
      const Proxy(name: 'COMPATIBLE', type: 'Compatible'),
    ];

    final result = filterNetworkTestProxies(proxies);

    expect(result.map((proxy) => proxy.name), [
      'REJECT',
      'PASS',
      'DIRECT',
      'COMPATIBLE',
    ]);
  });

  test('core interface forwards test timeout and payload', () async {
    final handler = _RecordingCoreHandler();

    await handler.speedTest(
      const SpeedTestParams(
        proxyName: 'P',
        testUrl: 'https://offline.invalid/?bytes=10000000',
        timeout: 20000,
      ),
    );
    expect(handler.method, CoreMethod.speedTest);
    expect(handler.timeout, const Duration(seconds: 45));
    expect(handler.arguments, {
      'proxy-name': 'P',
      'test-url': 'https://offline.invalid/?bytes=10000000',
      'timeout': 20000,
    });

    await handler.quicTest(
      const QuicTestParams(
        proxyName: 'P',
        host: 'offline.invalid:8443',
        timeout: 10000,
      ),
    );
    expect(handler.method, CoreMethod.quicTest);
    expect(handler.timeout, const Duration(seconds: 25));
    expect(handler.arguments, {
      'proxy-name': 'P',
      'host': 'offline.invalid:8443',
      'timeout': 10000,
    });
  });

  test('a Core that never answers surfaces the client timeout', () async {
    final handler = _UnansweredCoreHandler();
    final unansweredController = CoreController.test(handler);

    final result = await unansweredController.getQuicTest(
      const QuicTestParams(
        proxyName: 'P',
        host: 'offline.invalid:443',
        timeout: 1,
      ),
    );

    expect(handler.timeout, const Duration(milliseconds: 5002));
    expect(result.name, 'P');
    expect(result.rtt, 0);
    expect(result.alpn, '');
    expect(result.version, 0);
    expect(
      result.error,
      'core QUIC test did not respond before the client timeout',
    );
    expect(result.stage, 'client_timeout');
    expect(result.target, 'offline.invalid:443');
    expect(result.resolvedIp, '');
    expect(result.network, '');
    expect(result.sentPackets, 0);
    expect(result.sentBytes, 0);
    expect(result.receivedPackets, 0);
    expect(result.receivedBytes, 0);
  });

  testWidgets('NetworkTestView starts with speed and QUIC targets collapsed', (
    tester,
  ) async {
    when(() => mock.speedTest(any())).thenAnswer((_) async => _speedResult());
    when(() => mock.quicTest(any())).thenAnswer((_) async => _quicResult());

    await tester.pumpWidget(_wrap(NetworkTestView(controller: controller)));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(NetworkTestView), findsOneWidget);
    expect(find.text('Cloudflare 25 MB'), findsOneWidget);
    expect(find.text('Cloudflare 100 MB'), findsNothing);
    expect(find.text('CacheFly 100 MB'), findsNothing);
    expect(find.text('cloudflare-quic.com:443'), findsOneWidget);
    expect(find.text('www.google.com:443'), findsNothing);
    expect(find.text('nghttp2.org:443'), findsNothing);
    expect(find.text('Custom download URL'), findsNothing);
    expect(find.text('Custom target'), findsNothing);
    expect(find.byType(TextField), findsNothing);

    final speedTargetTile = find.widgetWithText(
      ExpansionTile,
      'Test package size',
    );
    expect(speedTargetTile, findsOneWidget);
    expect(
      tester.widget<ExpansionTile>(speedTargetTile).initiallyExpanded,
      isFalse,
    );

    final quicTargetTile = find.widgetWithText(
      ExpansionTile,
      'QUIC test target',
    );
    expect(quicTargetTile, findsOneWidget);
    expect(
      tester.widget<ExpansionTile>(quicTargetTile).initiallyExpanded,
      isFalse,
    );
    await _tapVisible(tester, quicTargetTile);
    await tester.pumpAndSettle();

    expect(find.text('www.google.com:443'), findsOneWidget);
    expect(find.text('nghttp2.org:443'), findsOneWidget);
    expect(find.text('Custom target'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('speed test sends the selected preset URL and timeout', (
    tester,
  ) async {
    final calls = <SpeedTestParams>[];
    when(() => mock.speedTest(any())).thenAnswer((invocation) {
      calls.add(invocation.positionalArguments.single as SpeedTestParams);
      return Future.value(_speedResult());
    });

    await tester.pumpWidget(_wrap(NetworkTestView(controller: controller)));
    await tester.pumpAndSettle();

    await _tapVisible(
      tester,
      find.widgetWithText(ExpansionTile, 'Test package size'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Cloudflare 100 MB'), findsNothing);
    expect(find.text('Cloudflare 50 MB'), findsOneWidget);
    expect(find.text('CacheFly 100 MB'), findsOneWidget);
    expect(find.text('OVH 10 MiB'), findsNothing);
    expect(find.text('OVH 100 MiB'), findsNothing);
    await tester.tap(find.text('CacheFly 100 MB'));
    await tester.pumpAndSettle();

    final speedButton = find.widgetWithText(FilledButton, 'Start Test').first;
    await _tapVisible(tester, speedButton);
    await tester.pumpAndSettle();

    expect(calls, hasLength(1));
    expect(calls.single.testUrl, 'https://cachefly.cachefly.net/100mb.test');
    expect(calls.single.timeout, 120000);
  });

  testWidgets('speed test sends custom download URL with default timeout', (
    tester,
  ) async {
    final calls = <SpeedTestParams>[];
    when(() => mock.speedTest(any())).thenAnswer((invocation) {
      calls.add(invocation.positionalArguments.single as SpeedTestParams);
      return Future.value(_speedResult());
    });

    await tester.pumpWidget(_wrap(NetworkTestView(controller: controller)));
    await tester.pumpAndSettle();

    await _tapVisible(
      tester,
      find.widgetWithText(ExpansionTile, 'Test package size'),
    );
    await tester.pumpAndSettle();
    await _tapVisible(tester, find.text('Custom download URL'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
    await tester.enterText(
      find.byType(TextField),
      ' https://offline.invalid/custom.bin ',
    );
    await tester.pump();

    final speedButton = find.widgetWithText(FilledButton, 'Start Test').first;
    await _tapVisible(tester, speedButton);
    await tester.pumpAndSettle();

    expect(calls, hasLength(1));
    expect(calls.single.testUrl, 'https://offline.invalid/custom.bin');
    expect(calls.single.timeout, 60000);
  });

  testWidgets('QUIC preset and custom host are sent exclusively', (
    tester,
  ) async {
    final calls = <QuicTestParams>[];
    when(() => mock.quicTest(any())).thenAnswer((invocation) {
      calls.add(invocation.positionalArguments.single as QuicTestParams);
      return Future.value(_quicResult());
    });

    await tester.pumpWidget(_wrap(NetworkTestView(controller: controller)));
    await tester.pumpAndSettle();

    await _tapVisible(
      tester,
      find.widgetWithText(ExpansionTile, 'QUIC test target'),
    );
    await tester.pumpAndSettle();
    await _tapVisible(tester, find.text('nghttp2.org:443'));
    await tester.pumpAndSettle();
    final quicButton = find.widgetWithText(FilledButton, 'Start Test').last;
    await _tapVisible(tester, quicButton);
    await tester.pumpAndSettle();
    expect(calls.single.host, 'nghttp2.org:443');
    expect(calls.single.timeout, 10000);

    await _tapVisible(tester, find.text('Custom target'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
    await tester.enterText(find.byType(TextField), ' custom.invalid:8443 ');
    await tester.pump();
    await _tapVisible(tester, quicButton);
    await tester.pumpAndSettle();

    expect(calls, hasLength(2));
    expect(calls.last.host, 'custom.invalid:8443');
  });

  testWidgets('stale speed result is ignored after package changes', (
    tester,
  ) async {
    final firstResult = Completer<SpeedTestResult>();
    final secondResult = Completer<SpeedTestResult>();
    var callCount = 0;
    when(() => mock.speedTest(any())).thenAnswer((_) {
      callCount++;
      return callCount == 1 ? firstResult.future : secondResult.future;
    });

    await tester.pumpWidget(_wrap(NetworkTestView(controller: controller)));
    await tester.pumpAndSettle();

    await _tapVisible(
      tester,
      find.widgetWithText(ExpansionTile, 'Test package size'),
    );
    await tester.pumpAndSettle();

    final speedButton = find.widgetWithText(FilledButton, 'Start Test').first;
    await _tapVisible(tester, speedButton);
    await tester.pump();
    expect(find.text('Testing...'), findsOneWidget);

    await _tapVisible(tester, find.text('Cloudflare 10 MB'));
    await tester.pump();

    firstResult.complete(_speedResult(latency: 111));
    await tester.pump();
    expect(find.text('111 ms'), findsNothing);
    expect(find.text('Testing...'), findsNothing);

    await _tapVisible(tester, speedButton);
    await tester.pump();
    secondResult.complete(_speedResult(latency: 222));
    await tester.pump();

    expect(find.text('222 ms'), findsOneWidget);
    expect(find.text('111 ms'), findsNothing);
  });

  testWidgets('stale QUIC result is ignored after target changes', (
    tester,
  ) async {
    final firstResult = Completer<QuicTestResult>();
    final secondResult = Completer<QuicTestResult>();
    final calls = <QuicTestParams>[];
    when(() => mock.quicTest(any())).thenAnswer((invocation) {
      calls.add(invocation.positionalArguments.single as QuicTestParams);
      return calls.length == 1 ? firstResult.future : secondResult.future;
    });

    await tester.pumpWidget(_wrap(NetworkTestView(controller: controller)));
    await tester.pumpAndSettle();

    await _tapVisible(
      tester,
      find.widgetWithText(ExpansionTile, 'QUIC test target'),
    );
    await tester.pumpAndSettle();

    final quicButton = find.widgetWithText(FilledButton, 'Start Test').last;
    await _tapVisible(tester, quicButton);
    await tester.pump();
    expect(find.text('Testing...'), findsOneWidget);

    await _tapVisible(tester, find.text('www.google.com:443'));
    await tester.pump();
    firstResult.complete(_quicResult(target: 'stale.invalid:443'));
    await tester.pumpAndSettle();

    expect(calls.first.host, 'cloudflare-quic.com:443');
    expect(find.text('stale.invalid:443'), findsNothing);
    expect(find.text('Testing...'), findsNothing);

    await _tapVisible(tester, quicButton);
    await tester.pump();
    secondResult.complete(_quicResult(target: 'fresh.invalid:443'));
    await tester.pumpAndSettle();

    expect(calls.last.host, 'www.google.com:443');
    expect(find.text('fresh.invalid:443'), findsOneWidget);
    expect(find.text('stale.invalid:443'), findsNothing);
  });
}
