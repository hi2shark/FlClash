import 'dart:convert';
import 'dart:io';

import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/local_rules/services/local_rule_store.dart';
import 'package:fl_clash/models/local_rule.dart';
import 'package:fl_clash/models/local_rule_mixin_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

class _FakePathProvider extends PathProviderPlatform {
  final String root;

  _FakePathProvider(this.root);

  @override
  Future<String?> getApplicationSupportPath() async => root;

  @override
  Future<String?> getTemporaryPath() async => join(root, 'temp');

  @override
  Future<String?> getApplicationCachePath() async => join(root, 'cache');

  @override
  Future<String?> getDownloadsPath() async => join(root, 'downloads');

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

LocalRule _rule({
  required int id,
  required String content,
  String target = 'DIRECT',
  bool enabled = true,
  int? sortIndex,
}) {
  return LocalRule(
    id: id,
    enabled: enabled,
    ruleAction: RuleAction.DOMAIN,
    content: content,
    ruleTarget: target,
    sortIndex: sortIndex,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tmpDir;
  late File storeFile;

  setUpAll(() async {
    tmpDir = await Directory.systemTemp.createTemp('flclash_local_rule_store_');
    PathProviderPlatform.instance = _FakePathProvider(tmpDir.path);
    storeFile = File(join(tmpDir.path, 'local_rules.json'));
  });

  setUp(() async {
    if (await storeFile.exists()) {
      await storeFile.delete();
    }
    localRuleStore.resetForTest();
    await localRuleStore.init();
  });

  tearDownAll(() async {
    localRuleStore.resetForTest();
    if (await tmpDir.exists()) {
      await tmpDir.delete(recursive: true);
    }
  });

  test('add toggle and persist mixin config', () async {
    await localRuleStore.add(_rule(id: 1, content: 'example.com'));
    await localRuleStore.add(
      _rule(id: 2, content: 'ads.example', target: 'REJECT'),
    );
    expect(localRuleStore.rules, hasLength(2));
    expect(localRuleStore.enabledCount, 2);

    await localRuleStore.toggle(2);
    expect(localRuleStore.rules.last.enabled, isFalse);
    expect(localRuleStore.enabledCount, 1);

    await localRuleStore.saveConfig(const LocalRuleMixinConfig(enabled: true));
    expect(localRuleStore.config.enabled, isTrue);

    localRuleStore.resetForTest();
    await localRuleStore.init();
    expect(localRuleStore.config.enabled, isTrue);
    expect(localRuleStore.rules, hasLength(2));
    expect(localRuleStore.rules.last.enabled, isFalse);
  });

  test('reorder updates sort order', () async {
    await localRuleStore.add(_rule(id: 1, content: 'first.com'));
    await localRuleStore.add(_rule(id: 2, content: 'second.com'));
    await localRuleStore.add(_rule(id: 3, content: 'third.com'));

    await localRuleStore.reorder(0, 2);

    expect(
      localRuleStore.rules.map((rule) => rule.content).toList(),
      ['second.com', 'third.com', 'first.com'],
    );
  });

  test('load migrates invalid and duplicate ids', () async {
    final legacyRules = [
      _rule(id: -1, content: 'a.com'),
      _rule(id: -1, content: 'b.com'),
      _rule(id: 42, content: 'c.com'),
      _rule(id: 42, content: 'd.com'),
    ];
    await storeFile.writeAsString(
      jsonEncode({
        'mixinConfig': const LocalRuleMixinConfig().toJson(),
        'rules': legacyRules.map((rule) => rule.toJson()).toList(),
      }),
    );
    localRuleStore.resetForTest();

    await localRuleStore.init();

    final ids = localRuleStore.rules.map((rule) => rule.id).toList();
    expect(ids, everyElement(greaterThan(0)));
    expect(ids.toSet(), hasLength(legacyRules.length));
    expect(ids.where((id) => id == 42), hasLength(1));
  });
}
