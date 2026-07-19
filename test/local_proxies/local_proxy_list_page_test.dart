import 'dart:io';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/common/theme.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/local_proxies/pages/local_proxy_list_page.dart';
import 'package:fl_clash/local_proxies/services/local_proxy_store.dart';
import 'package:fl_clash/models/local_proxy.dart';
import 'package:fl_clash/state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

class _FakePathProvider extends PathProviderPlatform {
  final String root;

  _FakePathProvider(this.root);

  @override
  Future<String?> getApplicationSupportPath() async => root;

  @override
  Future<String?> getTemporaryPath() async => path.join(root, 'temp');

  @override
  Future<String?> getApplicationCachePath() async => path.join(root, 'cache');

  @override
  Future<String?> getDownloadsPath() async => path.join(root, 'downloads');

  @override
  Future<String?> getLibraryPath() async => root;

  @override
  Future<String?> getExternalStoragePath() async => null;

  @override
  Future<List<String>?> getExternalCachePaths() async => null;

  @override
  Future<List<String>?> getExternalStoragePaths({
    StorageDirectory? type,
  }) async => null;
}

LocalProxy _proxy({
  String name = 'Local SOCKS proxy',
  String server = 'proxy.example.com',
}) {
  final now = DateTime.utc(2026);
  return LocalProxy(
    id: 1,
    name: name,
    type: 'socks5',
    config: {'server': server, 'port': 1080},
    createdAt: now,
    updatedAt: now,
  );
}

Widget _testApp(ProviderContainer container) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      navigatorKey: globalState.navigatorKey,
      locale: const Locale('en'),
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
          globalState.measure = Measure.of(context, 1);
          return const LocalProxyListPage();
        },
      ),
    ),
  );
}

Future<void> _pumpFrames(WidgetTester tester, {int count = 10}) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDirectory;
  late File storeFile;
  late ProviderContainer container;

  setUpAll(() async {
    tempDirectory = await Directory.systemTemp.createTemp(
      'flclash_local_proxy_list_page_test_',
    );
    PathProviderPlatform.instance = _FakePathProvider(tempDirectory.path);
    storeFile = File(path.join(tempDirectory.path, 'local_proxies.json'));
  });

  setUp(() async {
    if (await storeFile.exists()) {
      await storeFile.delete();
    }
    localProxyStore.resetForTest();
    await localProxyStore.init().timeout(const Duration(seconds: 5));
    container = ProviderContainer();
    globalState.container = container;
  });

  tearDown(() {
    container.dispose();
  });

  tearDownAll(() async {
    localProxyStore.resetForTest();
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  testWidgets('proxy card smoke test preserves control callbacks', (
    tester,
  ) async {
    final proxy = _proxy();
    localProxyStore.proxiesNotifier.value = [proxy];

    await tester.pumpWidget(_testApp(container));
    await _pumpFrames(tester);

    expect(tester.takeException(), isNull);
    expect(find.text(proxy.name), findsOneWidget);
    expect(find.text('SOCKS5 · proxy.example.com:1080'), findsOneWidget);

    final switchWidget = tester.widget<Switch>(find.byType(Switch));
    expect(switchWidget.onChanged, isNotNull);
    final editButton = tester.widget<IconButton>(
      find.ancestor(
        of: find.byIcon(Icons.edit_outlined),
        matching: find.byType(IconButton),
      ),
    );
    final deleteButton = tester.widget<IconButton>(
      find.ancestor(
        of: find.byIcon(Icons.delete_outlined),
        matching: find.byType(IconButton),
      ),
    );
    expect(editButton.onPressed, isNotNull);
    expect(deleteButton.onPressed, isNotNull);
  });

  testWidgets(
    'narrow proxy card separates details and controls without overflow',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(220, 640);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      final proxy = _proxy(
        name: 'A very long local proxy name that must wrap on a narrow screen',
        server: 'very-long-local-proxy-host-name.example.com',
      );
      localProxyStore.proxiesNotifier.value = [proxy];

      await tester.pumpWidget(_testApp(container));
      await _pumpFrames(tester);

      expect(tester.takeException(), isNull);
      final statusBottom = tester.getRect(find.text('Enabled')).bottom;
      expect(
        tester.getRect(find.byType(Switch)).top,
        greaterThan(statusBottom),
      );
      expect(
        tester.getRect(find.byIcon(Icons.edit_outlined)).top,
        greaterThan(statusBottom),
      );
      expect(
        tester.getRect(find.byIcon(Icons.delete_outlined)).top,
        greaterThan(statusBottom),
      );
    },
  );

  testWidgets('add menu shows every supported protocol label', (tester) async {
    await tester.pumpWidget(_testApp(container));
    await _pumpFrames(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await _pumpFrames(tester);

    for (final label in [
      'Shadowsocks',
      'SOCKS5',
      'SSH',
      'VLESS',
      'Trojan',
      'AnyTLS',
      'Nowhere',
      'Hysteria2',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });
}
