import 'dart:io';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
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

const _profileNtp = <String, dynamic>{
  'enable': true,
  'server': 'ntp.aliyun.com',
  'port': 123,
  'write-to-system': true,
};

const _overrides = ProfileOverrides(
  ntp: Ntp(server: 'time.cloudflare.com', interval: 60),
  ntpOverrideKeys: {NtpOverrideKey.server, NtpOverrideKey.interval},
);

Future<YamlMap?> _ntpOf({
  required Map<String, dynamic> rawConfig,
  ProfileOverrides overrides = _overrides,
}) async {
  final result = await makeRealProfileTask(
    MakeRealProfileState(
      profilesPath: '/profiles',
      profileId: 1,
      rawConfig: rawConfig,
      realPatchConfig: const PatchClashConfig(),
      overrides: overrides,
      appendSystemDns: false,
      proxyGroups: const [],
      rules: const [],
      addedRules: const [],
      defaultUA: 'FlClash-Test',
    ),
  );
  final config = loadYaml(result.yaml) as YamlMap;
  return config['ntp'] as YamlMap?;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tmpDir;

  setUpAll(() async {
    tmpDir = await Directory.systemTemp.createTemp('flclash_task_test_');
    PathProviderPlatform.instance = _FakePathProvider(tmpDir.path);
    await useAppPaths(tmpDir);
  });

  tearDownAll(() async {
    await tmpDir.delete(recursive: true);
  });

  test('overrides only the selected NTP keys of a profile', () async {
    final ntp = await _ntpOf(rawConfig: {'ntp': _profileNtp});

    expect(ntp!['server'], 'time.cloudflare.com');
    expect(ntp['interval'], 60);
    expect(ntp['enable'], true);
    expect(ntp['port'], 123);
    expect(ntp['write-to-system'], true);
  });

  test('leaves the profile alone without picked keys', () async {
    final ntp = await _ntpOf(
      rawConfig: {'ntp': _profileNtp},
      overrides: const ProfileOverrides(),
    );

    expect(ntp!['server'], 'ntp.aliyun.com');
    expect(ntp.containsKey('interval'), isFalse);
  });

  test('writes nothing for a profile without NTP', () async {
    expect(
      await _ntpOf(rawConfig: {}, overrides: const ProfileOverrides()),
      isNull,
    );
  });

  test('a profile without NTP gets only the selected keys', () async {
    final ntp = await _ntpOf(rawConfig: {});

    expect(ntp, {'server': 'time.cloudflare.com', 'interval': 60});
  });
}
