import 'dart:io';

import 'package:fl_clash/local_proxies/services/local_proxy_config_injector.dart';
import 'package:fl_clash/local_proxies/services/local_proxy_store.dart';
import 'package:fl_clash/models/local_proxy.dart';
import 'package:fl_clash/models/local_proxy_provider_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:yaml/yaml.dart' as yaml;

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tmpDir;

  setUp(() async {
    tmpDir = await Directory.systemTemp.createTemp('flclash_test_');
    PathProviderPlatform.instance = _FakePathProvider(tmpDir.path);
    localProxyStore.resetForTest();
    await localProxyStore.init();
    final file = File(
      join(tmpDir.path, 'proxy_providers', 'flclash-local.yaml'),
    );
    if (await file.exists()) {
      await file.delete(recursive: true);
    }
  });

  tearDown(() async {
    await tmpDir.delete(recursive: true);
  });

  test('injects provider and use into target group', () async {
    await localProxyStore.add(
      LocalProxy(
        id: 1,
        name: 'Local Node',
        type: 'ss',
        enabled: true,
        config: {
          'name': 'Local Node',
          'type': 'ss',
          'server': '127.0.0.1',
          'port': 8388,
          'cipher': 'aes-256-gcm',
          'password': 'pwd',
          'udp': true,
        },
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    await localProxyStore.saveConfig(
      const LocalProxyProviderConfig(enabled: true, targetGroups: ['🚀 节点选择']),
    );

    final rawConfig = <String, dynamic>{
      'proxy-groups': [
        {
          'name': '🚀 节点选择',
          'type': 'select',
          'proxies': ['DIRECT'],
        },
      ],
    };

    await localProxyConfigInjector.inject(rawConfig);

    final providers = rawConfig['proxy-providers'] as Map?;
    expect(providers, isNotNull);
    expect(providers!['_flclash_local'], isNotNull);
    expect(providers['_flclash_local']['type'], 'file');

    final groups = rawConfig['proxy-groups'] as List;
    final group = groups.first as Map;
    expect(group['use'], contains('_flclash_local'));

    final providerFile = File(
      join(tmpDir.path, 'proxy_providers', 'flclash-local.yaml'),
    );
    expect(await providerFile.exists(), true);
    final content = await providerFile.readAsString();
    final doc = yaml.loadYaml(content) as Map;
    expect((doc['proxies'] as List).length, 1);
  });

  test('does nothing when disabled', () async {
    await localProxyStore.saveConfig(
      const LocalProxyProviderConfig(enabled: false),
    );
    final rawConfig = <String, dynamic>{
      'proxy-groups': [
        {'name': '🚀 节点选择', 'type': 'select'},
      ],
    };
    await localProxyConfigInjector.inject(rawConfig);
    expect(rawConfig['proxy-providers'], isNull);
  });

  test('injects when proxy-groups entries are Map<dynamic, dynamic>', () async {
    await localProxyStore.add(
      LocalProxy(
        id: 2,
        name: 'Dyn Node',
        type: 'ss',
        enabled: true,
        config: {
          'name': 'Dyn Node',
          'type': 'ss',
          'server': '1.1.1.1',
          'port': 443,
          'cipher': 'aes-256-gcm',
          'password': 'pwd',
          'udp': true,
        },
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    await localProxyStore.saveConfig(
      const LocalProxyProviderConfig(enabled: true, targetGroups: ['SELECT']),
    );

    final rawConfig = <String, dynamic>{
      'proxy-groups': <dynamic>[
        <dynamic, dynamic>{
          'name': 'SELECT',
          'type': 'select',
          'proxies': <dynamic>['DIRECT'],
        },
      ],
    };

    await localProxyConfigInjector.inject(rawConfig);
    final group = (rawConfig['proxy-groups'] as List).first as Map;
    expect(group['use'], contains('_flclash_local'));
    expect(rawConfig['proxy-providers'], isA<Map>());
  });

  test('skips without throwing when proxy-groups missing', () async {
    await localProxyStore.add(
      LocalProxy(
        id: 3,
        name: 'Node',
        type: 'ss',
        enabled: true,
        config: {
          'name': 'Node',
          'type': 'ss',
          'server': '1.1.1.1',
          'port': 443,
          'cipher': 'aes-256-gcm',
          'password': 'pwd',
        },
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    await localProxyStore.saveConfig(
      const LocalProxyProviderConfig(enabled: true, targetGroups: ['SELECT']),
    );

    final rawConfig = <String, dynamic>{'proxies': <dynamic>[]};
    await expectLater(localProxyConfigInjector.inject(rawConfig), completes);
    expect(rawConfig.containsKey('proxy-providers'), isFalse);
  });

  test('skips without throwing when proxy-providers is not a map', () async {
    await localProxyStore.add(
      LocalProxy(
        id: 4,
        name: 'Node',
        type: 'ss',
        enabled: true,
        config: {
          'name': 'Node',
          'type': 'ss',
          'server': '1.1.1.1',
          'port': 443,
          'cipher': 'aes-256-gcm',
          'password': 'pwd',
        },
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    await localProxyStore.saveConfig(
      const LocalProxyProviderConfig(enabled: true, targetGroups: ['SELECT']),
    );

    final rawConfig = <String, dynamic>{
      'proxy-providers': 'invalid',
      'proxy-groups': [
        {'name': 'SELECT', 'type': 'select'},
      ],
    };
    await expectLater(localProxyConfigInjector.inject(rawConfig), completes);
    expect(rawConfig['proxy-providers'], 'invalid');
    final group = (rawConfig['proxy-groups'] as List).first as Map;
    expect(group['use'], isNull);
  });

  test('skips inject when enabled with empty targetGroups', () async {
    await localProxyStore.add(
      LocalProxy(
        id: 5,
        name: 'Node',
        type: 'ss',
        enabled: true,
        config: {
          'name': 'Node',
          'type': 'ss',
          'server': '1.1.1.1',
          'port': 443,
          'cipher': 'aes-256-gcm',
          'password': 'pwd',
        },
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    await localProxyStore.saveConfig(
      const LocalProxyProviderConfig(enabled: true, targetGroups: []),
    );

    final rawConfig = <String, dynamic>{
      'proxy-groups': [
        {'name': 'SELECT', 'type': 'select'},
      ],
    };
    await localProxyConfigInjector.inject(rawConfig);
    expect(rawConfig['proxy-providers'], isNull);
    final group = (rawConfig['proxy-groups'] as List).first as Map;
    expect(group['use'], isNull);
  });
}
