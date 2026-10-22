import 'dart:io';

import 'package:fl_clash/ui/icons/icons.dart';
import 'package:fl_clash/local_proxies/pages/local_proxy_list_page.dart';
import 'package:fl_clash/local_proxies/services/local_proxy_store.dart';
import 'package:fl_clash/models/local_proxy.dart';
import 'package:fl_clash/state.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import '../helpers/glyph_finders.dart';
import '../helpers/test_app.dart';

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
    child: const TestApp(child: LocalProxyListPage()),
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
      find.widgetWithGlyph(IconButton, AppGlyphs.edit),
    );
    final deleteButton = tester.widget<IconButton>(
      find.widgetWithGlyph(IconButton, AppGlyphs.delete),
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
        tester.getRect(find.byGlyph(AppGlyphs.edit)).top,
        greaterThan(statusBottom),
      );
      expect(
        tester.getRect(find.byGlyph(AppGlyphs.delete)).top,
        greaterThan(statusBottom),
      );
    },
  );

  testWidgets('add menu splits protocols into ordered pairs', (tester) async {
    await tester.pumpWidget(_testApp(container));
    await _pumpFrames(tester);

    await tester.tap(find.widgetWithGlyph(IconButton, AppGlyphs.addCircle));
    await _pumpFrames(tester);

    for (final label in [
      'Nowhere',
      'Sudoku',
      'AnyTLS',
      'Trojan',
      'VLESS',
      'Hysteria2',
      'Shadowsocks',
      'SOCKS5',
      'SSH',
      'EasyTier',
    ]) {
      expect(find.text(label), findsOneWidget);
    }

    double topOf(String label) => tester.getTopLeft(find.text(label)).dy;
    expect(topOf('Nowhere'), topOf('Sudoku'));
    expect(topOf('AnyTLS'), topOf('Trojan'));
    expect(topOf('VLESS'), topOf('Hysteria2'));
    expect(topOf('Shadowsocks'), topOf('SOCKS5'));
    expect(topOf('SSH'), topOf('EasyTier'));
    expect(topOf('Nowhere'), lessThan(topOf('AnyTLS')));
    expect(topOf('AnyTLS'), lessThan(topOf('VLESS')));
    expect(topOf('VLESS'), lessThan(topOf('Shadowsocks')));
    expect(tester.takeException(), isNull);
  });

  testWidgets('add menu protocol tiles fit a narrow sheet', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(220, 640);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(_testApp(container));
    await _pumpFrames(tester);

    await tester.tap(find.widgetWithGlyph(IconButton, AppGlyphs.addCircle));
    await _pumpFrames(tester);

    expect(find.text('Nowhere'), findsOneWidget);
    expect(find.text('EasyTier'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
