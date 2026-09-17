import 'dart:io';

import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/local_proxies/services/local_proxy_store.dart';
import 'package:fl_clash/local_rules/services/local_rule_config_injector.dart';
import 'package:fl_clash/local_rules/services/local_rule_store.dart';
import 'package:fl_clash/models/local_proxy.dart';
import 'package:fl_clash/models/local_proxy_provider_config.dart';
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
  RuleAction action = RuleAction.DOMAIN,
}) {
  return LocalRule(
    id: id,
    enabled: enabled,
    ruleAction: action,
    content: content,
    ruleTarget: target,
  );
}

Future<void> _addLocalNode({String name = 'Home'}) async {
  final now = DateTime.utc(2026);
  await localProxyStore.add(
    LocalProxy(
      id: 100,
      name: name,
      type: 'ss',
      enabled: true,
      config: {
        'name': name,
        'type': 'ss',
        'server': '1.1.1.1',
        'port': 443,
        'cipher': 'aes-256-gcm',
        'password': 'pwd',
      },
      createdAt: now,
      updatedAt: now,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tmpDir;

  setUpAll(() async {
    tmpDir = await Directory.systemTemp.createTemp(
      'flclash_local_rule_injector_',
    );
    PathProviderPlatform.instance = _FakePathProvider(tmpDir.path);
  });

  setUp(() async {
    for (final entity in [
      File(join(tmpDir.path, 'local_rules.json')),
      File(join(tmpDir.path, 'local_proxies.json')),
    ]) {
      if (await entity.exists()) {
        await entity.delete();
      }
    }
    localRuleStore.resetForTest();
    localProxyStore.resetForTest();
    await localRuleStore.init();
    await localProxyStore.init();
  });

  tearDownAll(() async {
    localRuleStore.resetForTest();
    localProxyStore.resetForTest();
    await tmpDir.delete(recursive: true);
  });

  test('does not change config when mixin is disabled', () async {
    await localRuleStore.saveConfig(const LocalRuleMixinConfig(enabled: false));
    await localRuleStore.add(_rule(id: 1, content: 'example.com'));
    final rawConfig = <String, dynamic>{
      'rules': ['MATCH,DIRECT'],
    };

    await localRuleConfigInjector.inject(rawConfig);

    expect(rawConfig['rules'], ['MATCH,DIRECT']);
  });

  test('prepends valid enabled rules and keeps existing rules', () async {
    await localRuleStore.saveConfig(const LocalRuleMixinConfig(enabled: true));
    await localRuleStore.add(_rule(id: 1, content: 'example.com'));
    await localRuleStore.add(
      _rule(id: 2, content: 'ads.com', target: 'REJECT'),
    );
    final rawConfig = <String, dynamic>{
      'proxy-groups': [
        {'name': 'Proxy', 'type': 'select'},
      ],
      'rules': ['MATCH,DIRECT'],
    };

    await localRuleConfigInjector.inject(rawConfig);

    expect(rawConfig['rules'], [
      'DOMAIN,example.com,DIRECT',
      'DOMAIN,ads.com,REJECT',
      'MATCH,DIRECT',
    ]);
  });

  test('skips missing groups and nodes without throwing', () async {
    await localRuleStore.saveConfig(const LocalRuleMixinConfig(enabled: true));
    await localRuleStore.add(
      _rule(id: 1, content: 'ok.com', target: 'DIRECT'),
    );
    await localRuleStore.add(
      _rule(id: 2, content: 'missing.com', target: 'Gone'),
    );
    await localRuleStore.add(_rule(id: 3, content: 'home.com', target: 'Home'));
    final rawConfig = <String, dynamic>{
      'proxy-groups': [
        {'name': 'Proxy', 'type': 'select'},
      ],
      'rules': ['GEOIP,CN,DIRECT'],
    };

    await localRuleConfigInjector.inject(rawConfig);

    expect(rawConfig['rules'], ['DOMAIN,ok.com,DIRECT', 'GEOIP,CN,DIRECT']);
  });

  test('injects rules targeting local nodes when mixin is active', () async {
    await _addLocalNode();
    await localProxyStore.saveConfig(
      const LocalProxyProviderConfig(enabled: true, targetGroups: ['Proxy']),
    );
    await localRuleStore.saveConfig(const LocalRuleMixinConfig(enabled: true));
    await localRuleStore.add(_rule(id: 1, content: 'home.com', target: 'Home'));
    final rawConfig = <String, dynamic>{
      'proxy-groups': [
        {'name': 'Proxy', 'type': 'select'},
      ],
      'rules': ['MATCH,DIRECT'],
    };

    await localRuleConfigInjector.inject(rawConfig);

    expect(rawConfig['rules'], ['DOMAIN,home.com,Home', 'MATCH,DIRECT']);
  });

  test('skips local node targets when proxy mixin is off', () async {
    await _addLocalNode();
    await localProxyStore.saveConfig(
      const LocalProxyProviderConfig(enabled: false, targetGroups: ['Proxy']),
    );
    await localRuleStore.saveConfig(const LocalRuleMixinConfig(enabled: true));
    await localRuleStore.add(_rule(id: 1, content: 'home.com', target: 'Home'));
    final rawConfig = <String, dynamic>{
      'proxy-groups': [
        {'name': 'Proxy', 'type': 'select'},
      ],
      'rules': ['MATCH,DIRECT'],
    };

    await localRuleConfigInjector.inject(rawConfig);

    expect(rawConfig['rules'], ['MATCH,DIRECT']);
  });

  test('treats non-list rules as empty', () async {
    await localRuleStore.saveConfig(const LocalRuleMixinConfig(enabled: true));
    await localRuleStore.add(_rule(id: 1, content: 'example.com'));
    final rawConfig = <String, dynamic>{'rules': 'MATCH,DIRECT'};

    await localRuleConfigInjector.inject(rawConfig);

    expect(rawConfig['rules'], ['DOMAIN,example.com,DIRECT']);
  });

  test('skips disabled rules', () async {
    await localRuleStore.saveConfig(const LocalRuleMixinConfig(enabled: true));
    await localRuleStore.add(
      _rule(id: 1, content: 'off.com', enabled: false),
    );
    await localRuleStore.add(_rule(id: 2, content: 'on.com'));
    final rawConfig = <String, dynamic>{'rules': <String>[]};

    await localRuleConfigInjector.inject(rawConfig);

    expect(rawConfig['rules'], ['DOMAIN,on.com,DIRECT']);
  });
}
