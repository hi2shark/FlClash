import 'dart:io';

import 'package:fl_clash/local_rules/pages/local_rule_edit_page.dart';
import 'package:fl_clash/local_rules/services/local_rule_store.dart';
import 'package:fl_clash/local_rules/services/local_rule_targets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

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

Widget _wrap(Widget child) {
  return TestApp(
    wrapInProviderScope: true,
    locale: const Locale('en'),
    child: child,
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

  setUpAll(() async {
    tempDirectory = await Directory.systemTemp.createTemp(
      'flclash_local_rule_edit_page_test_',
    );
    PathProviderPlatform.instance = _FakePathProvider(tempDirectory.path);
  });

  setUp(() async {
    localRuleStore.resetForTest();
    await localRuleStore.init();
  });

  tearDownAll(() async {
    localRuleStore.resetForTest();
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  testWidgets('target page groups basic policies, groups, and local nodes', (
    tester,
  ) async {
    const catalog = LocalRuleTargetCatalog(
      groups: ['Proxy'],
      localNodes: ['Home'],
      localProxyMixinActive: true,
    );

    tester.view.physicalSize = const Size(1400, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _wrap(const LocalRuleTargetPage(catalog: catalog, selected: 'DIRECT')),
    );
    await _pumpFrames(tester);

    expect(find.text('Basic strategies'), findsOneWidget);
    expect(find.text('DIRECT'), findsOneWidget);
    expect(find.text('REJECT'), findsOneWidget);
    expect(find.text('Proxy group'), findsOneWidget);
    expect(find.text('Proxy'), findsOneWidget);
    expect(find.text('Local Nodes'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('target page explains missing groups and disabled node mixin', (
    tester,
  ) async {
    const catalog = LocalRuleTargetCatalog();

    tester.view.physicalSize = const Size(1400, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrap(const LocalRuleTargetPage(catalog: catalog)));
    await _pumpFrames(tester);

    expect(
      find.text('No proxy groups in the current subscription'),
      findsOneWidget,
    );
    expect(
      find.text(
        'Rules can target local nodes only after local proxy mix-in is enabled.',
      ),
      findsOneWidget,
    );
    expect(find.text('No local proxies'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
