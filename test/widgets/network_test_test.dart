import 'dart:async';
import 'dart:convert';

import 'package:fl_clash/common/theme.dart';
import 'package:fl_clash/core/controller.dart';
import 'package:fl_clash/core/interface.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/app.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/views/network_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockCoreHandler extends Mock implements CoreHandlerInterface {}

class _RecordingCoreHandler extends CoreHandlerInterface {
  final Completer<void> _ready = Completer<void>()..complete();
  ActionMethod? method;
  dynamic data;
  Duration? timeout;

  @override
  Completer get completer => _ready;

  @override
  FutureOr<bool> destroy() async => true;

  @override
  Future<String> preload() async => '';

  @override
  Future<bool> shutdown(bool isUser) async => true;

  @override
  Future<T?> invoke<T>({
    required ActionMethod method,
    dynamic data,
    Duration? timeout,
  }) async {
    this.method = method;
    this.data = data;
    this.timeout = timeout;
    return jsonEncode({'name': 'P'}) as T?;
  }
}

class _PendingCoreHandler extends _RecordingCoreHandler {
  @override
  Future<T?> invoke<T>({
    required ActionMethod method,
    dynamic data,
    Duration? timeout,
  }) {
    this.method = method;
    this.data = data;
    this.timeout = timeout;
    return Completer<T?>().future;
  }
}

Widget _wrap(Widget child) {
  return UncontrolledProviderScope(
    container: globalState.container,
    child: MaterialApp(
      navigatorKey: globalState.navigatorKey,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
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

String _speedResult({int latency = 1}) {
  return jsonEncode(
    SpeedTestResult(
      name: 'DIRECT',
      latency: latency,
      speed: 1000,
      bytes: 1000,
    ).toJson(),
  );
}

String _quicResult({String target = 'cloudflare-quic.com:443'}) {
  return jsonEncode(
    QuicTestResult(
      name: 'DIRECT',
      target: target,
      stage: 'completed',
      rtt: 1,
    ).toJson(),
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

  test('speed test sizes and URL use decimal megabytes', () {
    expect(networkTestPackageSizes, [10, 25, 100]);
    expect(networkTestDefaultPackageSize, 25);
    expect(
      networkTestSpeedTestUrl(10),
      'https://speed.cloudflare.com/__down?bytes=10000000',
    );
    expect(
      networkTestSpeedTestUrl(25),
      'https://speed.cloudflare.com/__down?bytes=25000000',
    );
    expect(
      networkTestSpeedTestUrl(100),
      'https://speed.cloudflare.com/__down?bytes=100000000',
    );
    expect(networkTestSpeedTestTimeout(10), const Duration(seconds: 20));
    expect(networkTestSpeedTestTimeout(25), const Duration(seconds: 30));
    expect(networkTestSpeedTestTimeout(100), const Duration(seconds: 90));
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
    expect(handler.method, ActionMethod.speedTest);
    expect(handler.timeout, const Duration(seconds: 25));
    expect(jsonDecode(handler.data as String), {
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
    expect(handler.method, ActionMethod.quicTest);
    expect(handler.timeout, const Duration(seconds: 12));
    expect(jsonDecode(handler.data as String), {
      'proxy-name': 'P',
      'host': 'offline.invalid:8443',
      'timeout': 10000,
    });
  });

  testWidgets('core interface enforces timeout for a pending invoke', (
    tester,
  ) async {
    final handler = _PendingCoreHandler();
    final resultFuture = handler.quicTest(
      const QuicTestParams(
        proxyName: 'P',
        host: 'offline.invalid:443',
        timeout: 1,
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(seconds: 3));

    expect(handler.timeout, const Duration(milliseconds: 2001));
    expect(jsonDecode(await resultFuture), {
      'name': 'P',
      'rtt': 0,
      'alpn': '',
      'version': 0,
      'error': 'core QUIC test did not respond before the client timeout',
      'stage': 'client_timeout',
      'target': 'offline.invalid:443',
      'resolved-ip': '',
      'network': '',
      'sent-packets': 0,
      'sent-bytes': 0,
      'received-packets': 0,
      'received-bytes': 0,
    });
  });

  testWidgets('NetworkTestView builds with single-select presets', (
    tester,
  ) async {
    when(() => mock.speedTest(any())).thenAnswer((_) async => _speedResult());
    when(() => mock.quicTest(any())).thenAnswer((_) async => _quicResult());

    await tester.pumpWidget(_wrap(NetworkTestView(controller: controller)));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(NetworkTestView), findsOneWidget);
    expect(find.text('25 MB'), findsOneWidget);
    expect(find.text('cloudflare-quic.com:443'), findsAtLeastNWidgets(1));
    expect(find.text('nghttp2.org:443'), findsAtLeastNWidgets(1));
    expect(find.text('quic.rocks:443'), findsNothing);
    expect(find.text('Custom target'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('speed test sends selected decimal URL and timeout', (
    tester,
  ) async {
    final calls = <SpeedTestParams>[];
    when(() => mock.speedTest(any())).thenAnswer((invocation) {
      calls.add(invocation.positionalArguments.single as SpeedTestParams);
      return Future.value(_speedResult());
    });

    await tester.pumpWidget(_wrap(NetworkTestView(controller: controller)));
    await tester.pumpAndSettle();

    await _tapVisible(tester, find.text('25 MB'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('100 MB'));
    await tester.pumpAndSettle();

    final speedButton = find.widgetWithText(FilledButton, 'Start Test').first;
    await _tapVisible(tester, speedButton);
    await tester.pumpAndSettle();

    expect(calls, hasLength(1));
    expect(calls.single.testUrl, networkTestSpeedTestUrl(100));
    expect(calls.single.timeout, 90000);
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
    final firstResult = Completer<String>();
    final secondResult = Completer<String>();
    var callCount = 0;
    when(() => mock.speedTest(any())).thenAnswer((_) {
      callCount++;
      return callCount == 1 ? firstResult.future : secondResult.future;
    });

    await tester.pumpWidget(_wrap(NetworkTestView(controller: controller)));
    await tester.pumpAndSettle();

    final speedButton = find.widgetWithText(FilledButton, 'Start Test').first;
    await _tapVisible(tester, speedButton);
    await tester.pump();
    expect(find.text('Testing...'), findsOneWidget);

    await _tapVisible(tester, find.text('25 MB'));
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('100 MB'));
    await tester.pump(const Duration(seconds: 1));

    firstResult.complete(_speedResult(latency: 111));
    await tester.pumpAndSettle();
    expect(find.text('111 ms'), findsNothing);
    expect(find.text('Testing...'), findsNothing);

    await _tapVisible(tester, speedButton);
    await tester.pump();
    secondResult.complete(_speedResult(latency: 222));
    await tester.pumpAndSettle();

    expect(find.text('222 ms'), findsOneWidget);
    expect(find.text('111 ms'), findsNothing);
  });

  testWidgets('stale QUIC result is ignored after target changes', (
    tester,
  ) async {
    final firstResult = Completer<String>();
    final secondResult = Completer<String>();
    final calls = <QuicTestParams>[];
    when(() => mock.quicTest(any())).thenAnswer((invocation) {
      calls.add(invocation.positionalArguments.single as QuicTestParams);
      return calls.length == 1 ? firstResult.future : secondResult.future;
    });

    await tester.pumpWidget(_wrap(NetworkTestView(controller: controller)));
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
