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

  setUp(() async {
    tmpDir = await Directory.systemTemp.createTemp('flclash_store_test_');
    PathProviderPlatform.instance = _FakePathProvider(tmpDir.path);
    localProxyStore.resetForTest();
    await localProxyStore.init();
  });

  tearDown(() async {
    await tmpDir.delete(recursive: true);
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
        const LocalProxyProviderConfig(
          enabled: false,
          targetGroups: ['Proxy'],
        ),
      );

      final didReset = await localProxyStore.resetMixinOnProfileSwitch();

      expect(didReset, isFalse);
      expect(localProxyStore.config.enabled, isFalse);
      expect(localProxyStore.config.targetGroups, ['Proxy']);
    });
  });
}
