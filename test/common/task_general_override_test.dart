import 'dart:io';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/local_proxies/services/local_proxy_store.dart';
import 'package:fl_clash/local_rules/services/local_rule_store.dart';
import 'package:fl_clash/models/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:yaml/yaml.dart';
import '../helpers/app_paths.dart';

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

const _profile = <String, dynamic>{
  'unified-delay': false,
  'tcp-concurrent': false,
  'ipv6': true,
  'geodata-loader': 'standard',
};

Future<YamlMap> _configOf(PatchClashConfig patchConfig) async {
  final result = await makeRealProfileTask(
    MakeRealProfileState(
      profilesPath: '/profiles',
      profileId: 1,
      rawConfig: _profile,
      realPatchConfig: patchConfig,
      overrides: const ProfileOverrides(),
      appendSystemDns: false,
      proxyGroups: const [],
      rules: const [],
      addedRules: const [],
      defaultUA: 'FlClash-Test',
    ),
  );
  return loadYaml(result.yaml) as YamlMap;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tmpDir;

  setUpAll(() async {
    tmpDir = await Directory.systemTemp.createTemp('flclash_task_test_');
    PathProviderPlatform.instance = _FakePathProvider(tmpDir.path);
    await useAppPaths(tmpDir);
  });

  setUp(() {
    localProxyStore.resetForTest();
    localRuleStore.resetForTest();
  });

  tearDownAll(() async {
    localProxyStore.resetForTest();
    localRuleStore.resetForTest();
    await tmpDir.delete(recursive: true);
  });

  test('leaves the profile alone without picked keys', () async {
    final config = await _configOf(const PatchClashConfig());

    for (final MapEntry(:key, :value) in _profile.entries) {
      expect(config[key], value, reason: key);
    }
  });

  test('replaces only the picked keys', () async {
    final config = await _configOf(
      const PatchClashConfig(
        tcpConcurrent: true,
        geodataLoader: GeodataLoader.memconservative,
        generalOverrideKeys: {
          GeneralOverrideKey.tcpConcurrent,
          GeneralOverrideKey.geodataLoader,
        },
      ),
    );

    expect(config['tcp-concurrent'], true);
    expect(config['geodata-loader'], 'memconservative');
    expect(config['unified-delay'], false);
    expect(config['ipv6'], true);
  });

  test('keeps the test URL out of the profile', () async {
    final config = await _configOf(
      const PatchClashConfig(
        testUrl: 'https://probe.test/204',
        generalOverrideKeys: {GeneralOverrideKey.testUrl},
      ),
    );

    expect(config.containsKey('test-url'), isFalse);
  });
}
