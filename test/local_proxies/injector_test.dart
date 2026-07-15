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

Future<void> _addEnabledNode({int id = 100}) async {
  await localProxyStore.add(
    LocalProxy(
      id: id,
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
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tmpDir;

  setUpAll(() async {
    tmpDir = await Directory.systemTemp.createTemp('flclash_test_');
    PathProviderPlatform.instance = _FakePathProvider(tmpDir.path);
  });

  setUp(() async {
    for (final entity in [
      File(join(tmpDir.path, 'local_proxies.json')),
      Directory(join(tmpDir.path, 'proxy_providers')),
      Directory(join(tmpDir.path, 'custom')),
    ]) {
      if (await entity.exists()) {
        await entity.delete(recursive: true);
      }
    }
    localProxyStore.resetForTest();
    await localProxyStore.init();
  });

  tearDownAll(() async {
    localProxyStore.resetForTest();
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

  test('writes provider to configured providerPath', () async {
    await localProxyStore.add(
      LocalProxy(
        id: 6,
        name: 'Custom Path Node',
        type: 'ss',
        enabled: true,
        config: {
          'name': 'Custom Path Node',
          'type': 'ss',
          'server': '127.0.0.1',
          'port': 8388,
          'cipher': 'aes-256-gcm',
          'password': 'pwd',
        },
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    const providerPath = './custom/providers/local.yaml';
    await localProxyStore.saveConfig(
      const LocalProxyProviderConfig(
        enabled: true,
        targetGroups: ['SELECT'],
        providerPath: providerPath,
      ),
    );
    final rawConfig = <String, dynamic>{
      'proxy-groups': [
        {'name': 'SELECT', 'type': 'select'},
      ],
    };

    await localProxyConfigInjector.inject(rawConfig);

    final provider =
        (rawConfig['proxy-providers'] as Map)['_flclash_local'] as Map;
    expect(provider['path'], providerPath);
    final customFile = File(
      join(tmpDir.path, 'custom', 'providers', 'local.yaml'),
    );
    expect(await customFile.exists(), isTrue);
    final defaultFile = File(
      join(tmpDir.path, 'proxy_providers', 'flclash-local.yaml'),
    );
    expect(await defaultFile.exists(), isFalse);
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

  test('throws when proxy-groups is missing without mutation', () async {
    await _addEnabledNode();
    await localProxyStore.saveConfig(
      const LocalProxyProviderConfig(enabled: true, targetGroups: ['SELECT']),
    );
    final proxies = <dynamic>[];
    final rawConfig = <String, dynamic>{'proxies': proxies};

    await expectLater(
      localProxyConfigInjector.inject(rawConfig),
      throwsA(isA<StateError>()),
    );

    expect(rawConfig, {'proxies': proxies});
    expect(identical(rawConfig['proxies'], proxies), isTrue);
  });

  test('throws for missing target group without partial mutation', () async {
    await _addEnabledNode();
    await localProxyStore.saveConfig(
      const LocalProxyProviderConfig(enabled: true, targetGroups: ['MISSING']),
    );
    final providers = <String, dynamic>{
      'existing': {'type': 'file', 'path': './existing.yaml'},
    };
    final groups = <dynamic>[
      {
        'name': 'SELECT',
        'type': 'select',
        'use': ['existing'],
      },
    ];
    final rawConfig = <String, dynamic>{
      'proxy-providers': providers,
      'proxy-groups': groups,
    };

    await expectLater(
      localProxyConfigInjector.inject(rawConfig),
      throwsA(
        isA<StateError>().having(
          (error) => error.toString(),
          'message',
          contains('MISSING'),
        ),
      ),
    );

    expect(identical(rawConfig['proxy-providers'], providers), isTrue);
    expect(identical(rawConfig['proxy-groups'], groups), isTrue);
    expect(providers.containsKey('_flclash_local'), isFalse);
    expect((groups.first as Map)['use'], ['existing']);
  });

  test('throws when proxy-providers is not a Map without mutation', () async {
    await _addEnabledNode();
    await localProxyStore.saveConfig(
      const LocalProxyProviderConfig(enabled: true, targetGroups: ['SELECT']),
    );
    final groups = <dynamic>[
      {'name': 'SELECT', 'type': 'select'},
    ];
    final rawConfig = <String, dynamic>{
      'proxy-providers': 'invalid',
      'proxy-groups': groups,
    };

    await expectLater(
      localProxyConfigInjector.inject(rawConfig),
      throwsA(isA<StateError>()),
    );

    expect(rawConfig['proxy-providers'], 'invalid');
    expect(identical(rawConfig['proxy-groups'], groups), isTrue);
    expect((groups.first as Map)['use'], isNull);
  });

  test('throws for non-Map provider collision without mutation', () async {
    await _addEnabledNode();
    await localProxyStore.saveConfig(
      const LocalProxyProviderConfig(enabled: true, targetGroups: ['SELECT']),
    );
    final providers = <String, dynamic>{'_flclash_local': 'invalid'};
    final groups = <dynamic>[
      {'name': 'SELECT', 'type': 'select'},
    ];
    final rawConfig = <String, dynamic>{
      'proxy-providers': providers,
      'proxy-groups': groups,
    };

    await expectLater(
      localProxyConfigInjector.inject(rawConfig),
      throwsA(isA<StateError>()),
    );

    expect(identical(rawConfig['proxy-providers'], providers), isTrue);
    expect(identical(rawConfig['proxy-groups'], groups), isTrue);
    expect(providers['_flclash_local'], 'invalid');
    expect((groups.first as Map)['use'], isNull);
  });

  test(
    'throws for same-path Map provider collision without mutation',
    () async {
      await _addEnabledNode();
      await localProxyStore.saveConfig(
        const LocalProxyProviderConfig(enabled: true, targetGroups: ['SELECT']),
      );
      final provider = <String, dynamic>{
        'type': 'file',
        'path': './proxy_providers/flclash-local.yaml',
      };
      final providers = <String, dynamic>{'_flclash_local': provider};
      final groups = <dynamic>[
        {'name': 'SELECT', 'type': 'select'},
      ];
      final rawConfig = <String, dynamic>{
        'proxy-providers': providers,
        'proxy-groups': groups,
      };

      await expectLater(
        localProxyConfigInjector.inject(rawConfig),
        throwsA(
          isA<StateError>().having(
            (error) => error.toString(),
            'message',
            contains('_flclash_local'),
          ),
        ),
      );

      expect(identical(rawConfig['proxy-providers'], providers), isTrue);
      expect(identical(rawConfig['proxy-groups'], groups), isTrue);
      expect(identical(providers['_flclash_local'], provider), isTrue);
      expect((groups.first as Map)['use'], isNull);
      final providerFile = File(
        join(tmpDir.path, 'proxy_providers', 'flclash-local.yaml'),
      );
      expect(await providerFile.exists(), isFalse);
    },
  );

  test('throws for non-String group use without partial mutation', () async {
    await _addEnabledNode();
    await localProxyStore.saveConfig(
      const LocalProxyProviderConfig(enabled: true, targetGroups: ['SELECT']),
    );
    final providers = <String, dynamic>{
      'existing': {'type': 'file', 'path': './existing.yaml'},
    };
    final groups = <dynamic>[
      {
        'name': 'SELECT',
        'type': 'select',
        'use': ['existing', 1],
      },
    ];
    final rawConfig = <String, dynamic>{
      'proxy-providers': providers,
      'proxy-groups': groups,
    };

    await expectLater(
      localProxyConfigInjector.inject(rawConfig),
      throwsA(isA<StateError>()),
    );

    expect(identical(rawConfig['proxy-providers'], providers), isTrue);
    expect(identical(rawConfig['proxy-groups'], groups), isTrue);
    expect(providers.containsKey('_flclash_local'), isFalse);
    expect((groups.first as Map)['use'], ['existing', 1]);
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
