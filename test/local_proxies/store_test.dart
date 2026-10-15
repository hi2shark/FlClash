import 'dart:convert';
import 'dart:io';

import 'package:fl_clash/local_proxies/services/local_proxy_store.dart';
import 'package:fl_clash/models/local_proxy.dart';
import 'package:fl_clash/models/local_proxy_provider_config.dart';
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tmpDir;
  late File storeFile;

  setUpAll(() async {
    tmpDir = await Directory.systemTemp.createTemp('flclash_store_test_');
    PathProviderPlatform.instance = _FakePathProvider(tmpDir.path);
    storeFile = File(join(tmpDir.path, 'local_proxies.json'));
  });

  setUp(() async {
    if (await storeFile.exists()) {
      await storeFile.delete();
    }
    localProxyStore.resetForTest();
    await localProxyStore.init();
  });

  tearDownAll(() async {
    localProxyStore.resetForTest();
    if (await tmpDir.exists()) {
      await tmpDir.delete(recursive: true);
    }
  });

  group('resetMixinOnProfileSwitch', () {
    test('disables mixin and clears target groups, keeps nodes', () async {
      final now = DateTime.now();
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
          },
          createdAt: now,
          updatedAt: now,
        ),
      );
      await localProxyStore.saveConfig(
        const LocalProxyProviderConfig(
          enabled: true,
          targetGroups: ['手动选择', 'GFW'],
          healthCheckInterval: 600,
        ),
      );

      final didReset = await localProxyStore.resetMixinOnProfileSwitch();

      expect(didReset, isTrue);
      expect(localProxyStore.config.enabled, isFalse);
      expect(localProxyStore.config.targetGroups, isEmpty);
      expect(localProxyStore.config.healthCheckInterval, 600);
      expect(localProxyStore.proxies, hasLength(1));
      expect(localProxyStore.proxies.first.name, 'Local Node');
    });

    test('is no-op when mixin is already disabled', () async {
      await localProxyStore.saveConfig(
        const LocalProxyProviderConfig(enabled: false, targetGroups: ['Proxy']),
      );

      final didReset = await localProxyStore.resetMixinOnProfileSwitch();

      expect(didReset, isFalse);
      expect(localProxyStore.config.enabled, isFalse);
      expect(localProxyStore.config.targetGroups, ['Proxy']);
    });
  });

  group('proxy ids', () {
    test('import assigns unique ids and delete removes one proxy', () async {
      await localProxyStore.import([
        _proxy(id: -1, name: 'Imported A'),
        _proxy(id: -1, name: 'Imported B'),
      ]);

      final imported = localProxyStore.proxies;
      final ids = imported.map((proxy) => proxy.id).toList();
      expect(ids, everyElement(greaterThan(0)));
      expect(ids.toSet(), hasLength(2));

      await localProxyStore.delete(imported.first.id);

      expect(localProxyStore.proxies, hasLength(1));
      expect(localProxyStore.proxies.single.name, 'Imported B');
    });

    test('delete removes only one proxy when ids are duplicated', () async {
      await localProxyStore.add(_proxy(id: 7, name: 'Duplicate A'));
      await localProxyStore.add(_proxy(id: 7, name: 'Duplicate B'));

      await localProxyStore.delete(7);

      expect(localProxyStore.proxies, hasLength(1));
      expect(localProxyStore.proxies.single.name, 'Duplicate B');
    });

    test('load migrates and persists invalid and duplicate ids', () async {
      final legacyProxies = [
        _proxy(id: -1, name: 'Invalid A'),
        _proxy(id: -1, name: 'Invalid B'),
        _proxy(id: 42, name: 'Duplicate A'),
        _proxy(id: 42, name: 'Duplicate B'),
      ];
      await storeFile.writeAsString(
        jsonEncode({
          'providerConfig': const LocalProxyProviderConfig().toJson(),
          'proxies': legacyProxies.map((proxy) => proxy.toJson()).toList(),
        }),
      );
      localProxyStore.resetForTest();

      await localProxyStore.init();

      final ids = localProxyStore.proxies.map((proxy) => proxy.id).toList();
      expect(ids, everyElement(greaterThan(0)));
      expect(ids.toSet(), hasLength(legacyProxies.length));
      expect(ids.where((id) => id == 42), hasLength(1));
      expect(localProxyStore.proxies[2].id, 42);

      final persisted =
          jsonDecode(await storeFile.readAsString()) as Map<String, dynamic>;
      final persistedIds = (persisted['proxies'] as List<dynamic>)
          .map((proxy) => (proxy as Map<String, dynamic>)['id'] as int)
          .toList();
      expect(persistedIds, ids);
    });
  });
}

LocalProxy _proxy({required int id, required String name}) {
  final now = DateTime.utc(2026);
  return LocalProxy(
    id: id,
    name: name,
    type: 'ss',
    config: {
      'name': name,
      'type': 'ss',
      'server': '127.0.0.1',
      'port': 8388,
      'cipher': 'aes-256-gcm',
      'password': 'pwd',
    },
    createdAt: now,
    updatedAt: now,
  );
}
