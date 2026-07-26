import 'dart:io';

import 'package:fl_clash/common/task.dart';
import 'package:fl_clash/local_proxies/services/local_proxy_store.dart';
import 'package:fl_clash/models/models.dart';
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

MakeRealProfileState _buildState(
  Map<String, dynamic> rawConfig,
  String profilesPath,
) {
  return MakeRealProfileState(
    profilesPath: profilesPath,
    profileId: 1,
    rawConfig: rawConfig,
    realPatchConfig: const PatchClashConfig(),
    overrideDns: false,
    appendSystemDns: false,
    proxyGroups: const [],
    rules: const [],
    addedRules: const [],
    defaultUA: 'clash.meta',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tmpDir;

  setUpAll(() async {
    tmpDir = await Directory.systemTemp.createTemp('flclash_task_test_');
    PathProviderPlatform.instance = _FakePathProvider(tmpDir.path);
  });

  setUp(() {
    localProxyStore.resetForTest();
  });

  tearDownAll(() async {
    localProxyStore.resetForTest();
    await tmpDir.delete(recursive: true);
  });

  group('makeRealProfileTask', () {
    test('replaces malformed scalar or list nodes with empty maps', () async {
      final rawConfig = <String, dynamic>{
        'tun': 'invalid',
        'profile': ['invalid'],
        'hosts': 'invalid',
        'dns': 'invalid',
        'sniffer': {
          'sniff': {
            'HTTP': <String, dynamic>{'ports': [443, 8080]},
            'TLS': 'invalid',
          },
        },
        'proxy-providers': {
          'broken': 'invalid',
          'remote': {'type': 'http', 'url': 'https://example.com/sub'},
        },
        'rule-providers': {
          'broken': 123,
          'remote': {'type': 'http', 'url': 'https://example.com/rules'},
        },
        'proxies': [
          {'name': 'proxy-a', 'type': 'ss', 'server': '1.1.1.1', 'port': 443},
        ],
        'rules': ['MATCH,DIRECT'],
      };

      final result = await makeRealProfileTask(
        _buildState(rawConfig, tmpDir.path),
      );
      final doc = yaml.loadYaml(result.a) as yaml.YamlMap;

      final tun = doc['tun'] as yaml.YamlMap;
      expect(tun.containsKey('enable'), isTrue);
      expect(tun.containsKey('stack'), isTrue);

      final profile = doc['profile'] as yaml.YamlMap;
      expect(profile['store-selected'], isFalse);

      expect(doc['hosts'], isA<yaml.YamlMap>());

      final dns = doc['dns'] as yaml.YamlMap;
      expect(dns['nameserver'], contains('system://'));

      final sniff = doc['sniffer']['sniff'] as yaml.YamlMap;
      expect(sniff['HTTP']['ports'], ['443', '8080']);
      expect(sniff['TLS'], 'invalid');

      final proxyProviders = doc['proxy-providers'] as yaml.YamlMap;
      expect(proxyProviders['broken'], 'invalid');
      expect(
        proxyProviders['remote']['path'],
        startsWith(join(tmpDir.path, 'providers', '1', 'proxies')),
      );

      final ruleProviders = doc['rule-providers'] as yaml.YamlMap;
      expect(ruleProviders['broken'], 123);
      expect(
        ruleProviders['remote']['path'],
        startsWith(join(tmpDir.path, 'providers', '1', 'rules')),
      );
    });

    test('keeps well-formed sections intact', () async {
      final rawConfig = <String, dynamic>{
        'tun': {'enable': true, 'custom-key': 'keep'},
        'profile': {'store-fake-ip': true},
        'hosts': {'example.com': '1.2.3.4'},
        'dns': {'enable': true, 'nameserver': ['223.5.5.5']},
        'sniffer': {
          'enable': true,
          'sniff': {
            'HTTP': <String, dynamic>{
              'ports': [80, 8080],
              'override-destination': true,
            },
          },
        },
        'proxy-providers': {
          'remote': {'type': 'http', 'url': 'https://example.com/sub'},
        },
        'rules': ['MATCH,DIRECT'],
      };

      final result = await makeRealProfileTask(
        _buildState(rawConfig, tmpDir.path),
      );
      final doc = yaml.loadYaml(result.a) as yaml.YamlMap;

      final tun = doc['tun'] as yaml.YamlMap;
      expect(tun['custom-key'], 'keep');

      final profile = doc['profile'] as yaml.YamlMap;
      expect(profile['store-fake-ip'], isTrue);
      expect(profile['store-selected'], isFalse);

      final hosts = doc['hosts'] as yaml.YamlMap;
      expect(hosts['example.com'], '1.2.3.4');

      final dns = doc['dns'] as yaml.YamlMap;
      expect(dns['enable'], isTrue);
      expect(dns['nameserver'], ['223.5.5.5']);

      final sniff = doc['sniffer']['sniff'] as yaml.YamlMap;
      expect(sniff['HTTP']['ports'], ['80', '8080']);
      expect(sniff['HTTP']['override-destination'], isTrue);

      final providers = doc['proxy-providers'] as yaml.YamlMap;
      expect(providers['remote']['url'], 'https://example.com/sub');
      expect(providers['remote']['path'], isNotNull);
    });
  });
}
