import 'dart:io';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/common/theme.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/local_rules/pages/local_rule_list_page.dart';
import 'package:fl_clash/local_rules/services/local_rule_store.dart';
import 'package:fl_clash/models/local_rule.dart';
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
          return const LocalRuleListPage();
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

  testWidgets('shows empty state when there are no local rules', (tester) async {
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
}
