import 'dart:io';

import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/ui/icons/icons.dart';

import 'package:fl_clash/local_rules/pages/local_rule_list_page.dart';
import 'package:fl_clash/local_rules/services/local_rule_store.dart';
import 'package:fl_clash/models/local_rule.dart';
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

Widget _testApp(ProviderContainer container) {
  return UncontrolledProviderScope(
    container: container,
    child: const TestApp(child: LocalRuleListPage()),
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
      'flclash_local_rule_list_page_test_',
    );
    PathProviderPlatform.instance = _FakePathProvider(tempDirectory.path);
    storeFile = File(path.join(tempDirectory.path, 'local_rules.json'));
  });

  setUp(() async {
    if (await storeFile.exists()) {
      await storeFile.delete();
    }
    localRuleStore.resetForTest();
    await localRuleStore.init().timeout(const Duration(seconds: 5));
    container = ProviderContainer();
    globalState.container = container;
  });

  tearDown(() {
    container.dispose();
  });

  tearDownAll(() async {
    localRuleStore.resetForTest();
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  testWidgets('shows empty state when there are no local rules', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(container));
    await _pumpFrames(tester);

    expect(find.text('No local rules'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rule card smoke test preserves control callbacks', (
    tester,
  ) async {
    localRuleStore.rulesNotifier.value = [
      const LocalRule(
        id: 1,
        ruleAction: RuleAction.DOMAIN,
        content: 'example.com',
        ruleTarget: 'DIRECT',
      ),
    ];

    await tester.pumpWidget(_testApp(container));
    await _pumpFrames(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('DOMAIN'), findsOneWidget);
    expect(find.text('example.com'), findsOneWidget);
    expect(find.text('DIRECT'), findsOneWidget);

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
}
