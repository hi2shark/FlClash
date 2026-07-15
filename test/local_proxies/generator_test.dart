import 'dart:io';

import 'package:fl_clash/local_proxies/services/local_proxy_provider_generator.dart';
import 'package:fl_clash/models/local_proxy.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:yaml/yaml.dart' as yaml;

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

LocalProxy _proxy({
  required String type,
  required Map<String, dynamic> config,
  String name = 'Test',
}) {
  return LocalProxy(
    id: 1,
    name: name,
    type: type,
    enabled: true,
    config: config,
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );
}

Map<String, dynamic> _validNowhereConfig() {
  return {
    'name': 'Nowhere',
    'type': 'nowhere',
    'server': 'example.com',
    'port': 2077,
    'password': 'secret',
    'udp': true,
  };
}

Map _firstProxy(String yamlString) {
  final document = yaml.loadYaml(yamlString) as Map;
  return (document['proxies'] as List).first as Map;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const generator = LocalProxyProviderGenerator();
  late Directory sandbox;
  late Directory homeDirectory;
  late Directory outsideDirectory;

  setUpAll(() async {
    sandbox = await Directory.systemTemp.createTemp('flclash_generator_test_');
    homeDirectory = Directory(path.join(sandbox.path, 'home'));
    outsideDirectory = Directory(path.join(sandbox.path, 'outside'));
    await homeDirectory.create(recursive: true);
    await outsideDirectory.create(recursive: true);
    PathProviderPlatform.instance = _FakePathProvider(homeDirectory.path);
  });

  setUp(() async {
    if (await homeDirectory.exists()) {
      await homeDirectory.delete(recursive: true);
    }
    if (await outsideDirectory.exists()) {
      await outsideDirectory.delete(recursive: true);
    }
    await homeDirectory.create(recursive: true);
    await outsideDirectory.create(recursive: true);
  });

  tearDownAll(() async {
    if (await sandbox.exists()) {
      await sandbox.delete(recursive: true);
    }
  });

  group('LocalProxyProviderGenerator', () {
    test('cleans empty values and converts string port', () {
      final proxy = _proxy(
        type: 'ss',
        config: {
          'name': 'Test',
          'type': 'ss',
          'server': '127.0.0.1',
          'port': '8388',
          'cipher': 'aes-256-gcm',
          'password': 'pwd',
          'udp': true,
          'unused': '',
        },
      );
      final yamlString = generator.generateYaml([proxy]);
      final doc = yaml.loadYaml(yamlString) as Map;
      final proxies = doc['proxies'] as List;
      expect(proxies.length, 1);
      final map = proxies.first as Map;
      expect(map['port'], 8388);
      expect(map.containsKey('unused'), false);
    });

    test('emits valid anytls config', () {
      final proxy = _proxy(
        type: 'anytls',
        config: {
          'name': 'AnyTLS',
          'type': 'anytls',
          'server': 'example.com',
          'port': 443,
          'password': 'secret',
          'sni': 'cdn.example.com',
          'alpn': 'h2,h3',
          'client-fingerprint': 'chrome',
          'skip-cert-verify': true,
          'ech-opts': {'enable': true, 'config': 'echconfig'},
          'idle-session-timeout': 300,
          'udp': true,
        },
      );
      final yamlString = generator.generateYaml([proxy]);
      final doc = yaml.loadYaml(yamlString) as Map;
      final map = (doc['proxies'] as List).first as Map;
      expect(map['type'], 'anytls');
      expect(map['alpn'], ['h2', 'h3']);
      expect(map['ech-opts'], {'enable': true, 'config': 'echconfig'});
      expect(map['idle-session-timeout'], 300);
    });

    test('drops disabled ech-opts for anytls', () {
      final proxy = _proxy(
        type: 'anytls',
        config: {
          'name': 'AnyTLS',
          'type': 'anytls',
          'server': 'example.com',
          'port': 443,
          'password': 'secret',
          'ech-opts': {'enable': false, 'config': ''},
          'udp': true,
        },
      );
      final yamlString = generator.generateYaml([proxy]);
      final doc = yaml.loadYaml(yamlString) as Map;
      final map = (doc['proxies'] as List).first as Map;
      expect(map.containsKey('ech-opts'), false);
    });

    test('migrates nowhere key and strips pool for udp carriers', () {
      final proxy = _proxy(
        type: 'nowhere',
        config: {
          'name': 'Nowhere',
          'type': 'nowhere',
          'server': 'example.com',
          'port': 2077,
          'key': 'secret',
          'up': 'udp',
          'down': 'udp',
          'spec': 'auto',
          'pool': 5,
          'reduce-rtt': true,
          'udp': true,
        },
      );
      final map = _firstProxy(generator.generateYaml([proxy]));
      expect(map['type'], 'nowhere');
      expect(map['password'], 'secret');
      expect(map.containsKey('key'), isFalse);
      expect(map['up'], 'udp');
      expect(map['down'], 'udp');
      expect(map['network'], 'udp');
      expect(map.containsKey('pool'), isFalse);
      expect(map.containsKey('reduce-rtt'), isFalse);
    });

    test('keeps pool for nowhere tcp/tcp carriers', () {
      final proxy = _proxy(
        type: 'nowhere',
        config: {
          'name': 'Nowhere',
          'type': 'nowhere',
          'server': 'example.com',
          'port': 2077,
          'key': 'secret',
          'up': 'tcp',
          'down': 'tcp',
          'pool': 7,
          'udp': true,
        },
      );
      final yamlString = generator.generateYaml([proxy]);
      final doc = yaml.loadYaml(yamlString) as Map;
      final map = (doc['proxies'] as List).first as Map;
      expect(map['pool'], 7);
    });

    test('clamps tcp/tcp pool above 9 and logs a safe warning', () {
      final messages = <String>[];
      final originalDebugPrint = debugPrint;
      debugPrint = (message, {wrapWidth}) {
        if (message != null) messages.add(message);
      };
      late final Map map;
      try {
        final proxy = _proxy(
          type: 'nowhere',
          config: {
            'name': 'Nowhere',
            'type': 'nowhere',
            'server': 'example.com',
            'port': 2077,
            'password': 'do-not-log-secret',
            'up': 'tcp',
            'down': 'tcp',
            'pool': 12,
            'udp': true,
          },
        );
        map = _firstProxy(generator.generateYaml([proxy]));
      } finally {
        debugPrint = originalDebugPrint;
      }

      expect(map['pool'], 9);
      expect(
        messages.any(
          (message) =>
              message.contains('pool 12') && message.contains('using 9'),
        ),
        isTrue,
      );
      expect(messages.join('\n'), isNot(contains('do-not-log-secret')));
    });

    test('preserves explicit pool 0 for nowhere tcp/tcp carriers', () {
      final proxy = _proxy(
        type: 'nowhere',
        config: {
          'name': 'Nowhere',
          'type': 'nowhere',
          'server': 'example.com',
          'port': 2077,
          'key': 'secret',
          'up': 'tcp',
          'down': 'tcp',
          'pool': 0,
          'udp': true,
        },
      );
      final yamlString = generator.generateYaml([proxy]);
      final doc = yaml.loadYaml(yamlString) as Map;
      final map = (doc['proxies'] as List).first as Map;
      expect(map['pool'], 0);
    });

    test('emits valid hysteria2 config and normalizes alpn', () {
      final proxy = _proxy(
        type: 'hysteria2',
        config: {
          'name': 'HY2',
          'type': 'hysteria2',
          'server': 'example.com',
          'port': 443,
          'password': 'secret',
          'sni': 'cdn.example.com',
          'obfs': 'salamander',
          'obfs-password': 'obfspass',
          'alpn': 'h3',
          'fingerprint': 'sha256',
          'up': '100 Mbps',
          'down': '200 Mbps',
          'skip-cert-verify': true,
        },
      );
      final yamlString = generator.generateYaml([proxy]);
      final doc = yaml.loadYaml(yamlString) as Map;
      final map = (doc['proxies'] as List).first as Map;
      expect(map['type'], 'hysteria2');
      expect(map['port'], 443);
      expect(map['alpn'], ['h3']);
      expect(map['obfs'], 'salamander');
      expect(map['up'], '100 Mbps');
      expect(map['down'], '200 Mbps');
      expect(map.containsKey('unused'), false);
    });

    test('filters disabled proxies', () {
      final enabled = _proxy(
        type: 'ss',
        config: {
          'name': 'Enabled',
          'type': 'ss',
          'server': '1.1.1.1',
          'port': 443,
          'cipher': 'aes-256-gcm',
          'password': 'pwd',
          'udp': true,
        },
      );
      final disabled = enabled.copyWith(enabled: false);
      final yamlString = generator.generateYaml([enabled, disabled]);
      final doc = yaml.loadYaml(yamlString) as Map;
      expect((doc['proxies'] as List).length, 1);
    });
  });

  group('Nowhere normalization and validation', () {
    test('preserves supported fields and removes obsolete fields', () {
      final config = _validNowhereConfig()
        ..addAll({
          'password': 'canonical',
          'key': 'legacy',
          'network': 'tcp',
          'net': 'udp',
          'pool': '0',
          'alpn': ['h2', 'h3'],
          'prewarm-on-start': true,
          'max-concurrent-dials': '16',
          'warm-backoff-initial': '2',
          'warm-backoff-max': '20',
          'congestion-controller': 'bbr',
          'cwnd': 0,
          'certificate': 'certificate',
          'private-key': 'private-key',
          'client-fingerprint': 'chrome',
          'ech-opts': {'enable': true, 'query-server-name': 'ech.example.com'},
          'dialer-proxy': 'CHAIN',
          'tfo': true,
          'mptcp': true,
          'interface-name': 'eth0',
          'routing-mark': 123,
          'ip-version': 'ipv4',
          'smux': {'enabled': true},
          'bbr-profile': 'legacy',
          'reduce-rtt': true,
          'max-udp-relay-packet-size': 1200,
        });

      final map = _firstProxy(
        generator.generateYaml([_proxy(type: 'nowhere', config: config)]),
      );

      expect(map['password'], 'canonical');
      expect(map.containsKey('key'), isFalse);
      expect(map['up'], 'tcp');
      expect(map['down'], 'tcp');
      expect(map['network'], 'tcp');
      expect(map.containsKey('net'), isFalse);
      expect(map['pool'], 0);
      expect(map['alpn'], ['h2']);
      expect(map['prewarm-on-start'], isTrue);
      expect(map['max-concurrent-dials'], 16);
      expect(map['warm-backoff-initial'], 2);
      expect(map['warm-backoff-max'], 20);
      expect(map['congestion-controller'], 'bbr');
      expect(map['cwnd'], 0);
      expect(map['certificate'], 'certificate');
      expect(map['private-key'], 'private-key');
      expect(map['client-fingerprint'], 'chrome');
      expect(map['ech-opts'], {
        'enable': true,
        'query-server-name': 'ech.example.com',
      });
      expect(map['dialer-proxy'], 'CHAIN');
      expect(map['tfo'], isTrue);
      expect(map['mptcp'], isTrue);
      expect(map['interface-name'], 'eth0');
      expect(map['routing-mark'], 123);
      expect(map['ip-version'], 'ipv4');
      expect(map['smux'], {'enabled': true});
      expect(map.containsKey('bbr-profile'), isFalse);
      expect(map.containsKey('reduce-rtt'), isFalse);
      expect(map.containsKey('max-udp-relay-packet-size'), isFalse);
    });

    test('resolves carriers in strict priority order', () {
      final networkConfig = _validNowhereConfig()
        ..addAll({'network': 'tcp', 'net': 'udp'});
      final networkMap = _firstProxy(
        generator.generateYaml([
          _proxy(type: 'nowhere', config: networkConfig),
        ]),
      );
      expect(networkMap['up'], 'tcp');
      expect(networkMap['down'], 'tcp');

      final netConfig = _validNowhereConfig()..['net'] = 'tcp';
      final netMap = _firstProxy(
        generator.generateYaml([_proxy(type: 'nowhere', config: netConfig)]),
      );
      expect(netMap['up'], 'tcp');
      expect(netMap['down'], 'tcp');

      final defaultMap = _firstProxy(
        generator.generateYaml([
          _proxy(type: 'nowhere', config: _validNowhereConfig()),
        ]),
      );
      expect(defaultMap['up'], 'udp');
      expect(defaultMap['down'], 'udp');
      expect(defaultMap['network'], 'udp');
    });

    test('keeps only the effective first ALPN value', () {
      final listConfig = _validNowhereConfig()..['alpn'] = ['h2', 'h3'];
      final listMap = _firstProxy(
        generator.generateYaml([_proxy(type: 'nowhere', config: listConfig)]),
      );
      expect(listMap['alpn'], ['h2']);

      final stringConfig = _validNowhereConfig()..['alpn'] = 'h3,h2';
      final stringMap = _firstProxy(
        generator.generateYaml([_proxy(type: 'nowhere', config: stringConfig)]),
      );
      expect(stringMap['alpn'], ['h3']);

      final defaultAlpnConfig = _validNowhereConfig()
        ..['alpn'] = ['', List.filled(256, 'x').join()];
      final defaultAlpnMap = _firstProxy(
        generator.generateYaml([
          _proxy(type: 'nowhere', config: defaultAlpnConfig),
        ]),
      );
      expect(defaultAlpnMap.containsKey('alpn'), isFalse);
    });

    test('drops pool for every matrix containing UDP', () {
      for (final carriers in [('udp', 'udp'), ('tcp', 'udp'), ('udp', 'tcp')]) {
        final config = _validNowhereConfig()
          ..addAll({'up': carriers.$1, 'down': carriers.$2, 'pool': 5});
        final map = _firstProxy(
          generator.generateYaml([_proxy(type: 'nowhere', config: config)]),
        );
        expect(map.containsKey('pool'), isFalse, reason: '$carriers');
      }
    });

    test('enforces decoded UTF-8 byte limits', () {
      final key255 = List.filled(255, 'k').join();
      final spec255 = List.filled(85, '界').join();
      final alpn255 = List.filled(255, 'a').join();
      final validConfig = _validNowhereConfig()
        ..addAll({
          'password': key255,
          'spec': spec255,
          'alpn': [alpn255, List.filled(256, 'z').join()],
        });
      final map = _firstProxy(
        generator.generateYaml([_proxy(type: 'nowhere', config: validConfig)]),
      );
      expect(map['password'], key255);
      expect(map['spec'], spec255);
      expect(map['alpn'], [alpn255]);

      final tooLongValues = <(String, Map<String, dynamic>)>[
        (
          'password/key',
          _validNowhereConfig()..['password'] = List.filled(256, 'k').join(),
        ),
        (
          'spec',
          _validNowhereConfig()..['spec'] = List.filled(256, 's').join(),
        ),
        (
          'ALPN',
          _validNowhereConfig()..['alpn'] = [List.filled(256, 'a').join()],
        ),
      ];
      for (final (field, config) in tooLongValues) {
        expect(
          () =>
              generator.generateYaml([_proxy(type: 'nowhere', config: config)]),
          throwsA(
            isA<ArgumentError>().having(
              (error) => error.toString(),
              'message',
              allOf(contains(field), contains('255 UTF-8 bytes')),
            ),
          ),
        );
      }
    });

    test('rejects invalid required and numeric fields clearly', () {
      final missingCredential = _validNowhereConfig()..remove('password');
      final invalidCases = <(String, Map<String, dynamic>)>[
        ('server', _validNowhereConfig()..['server'] = ''),
        ('port', _validNowhereConfig()..['port'] = 0),
        ('port', _validNowhereConfig()..['port'] = 65536),
        ('port', _validNowhereConfig()..['port'] = 'invalid'),
        ('password/key', missingCredential),
        ('up and down', _validNowhereConfig()..['up'] = 'tcp'),
        (
          'carriers',
          _validNowhereConfig()..addAll({'network': 'TCP', 'net': 'tcp'}),
        ),
        ('pool', _validNowhereConfig()..['pool'] = -1),
        ('pool', _validNowhereConfig()..['pool'] = 'invalid'),
        (
          'max-concurrent-dials',
          _validNowhereConfig()..['max-concurrent-dials'] = -1,
        ),
        (
          'warm-backoff-initial',
          _validNowhereConfig()..['warm-backoff-initial'] = -1,
        ),
        ('warm-backoff-max', _validNowhereConfig()..['warm-backoff-max'] = -1),
        ('cwnd', _validNowhereConfig()..['cwnd'] = -1),
        (
          'warm-backoff-initial',
          _validNowhereConfig()..['warm-backoff-initial'] = 31,
        ),
        (
          'warm-backoff-initial',
          _validNowhereConfig()
            ..addAll({'warm-backoff-initial': 2, 'warm-backoff-max': 1}),
        ),
      ];

      for (final (field, config) in invalidCases) {
        expect(
          () =>
              generator.generateYaml([_proxy(type: 'nowhere', config: config)]),
          throwsA(
            isA<ArgumentError>().having(
              (error) => error.toString(),
              'message',
              contains(field),
            ),
          ),
          reason: field,
        );
      }
    });
  });

  group('provider file writing', () {
    LocalProxy providerProxy(String name) {
      return _proxy(
        type: 'ss',
        name: name,
        config: {
          'name': name,
          'type': 'ss',
          'server': '127.0.0.1',
          'port': 8388,
          'cipher': 'aes-256-gcm',
          'password': 'pwd',
          'udp': true,
        },
      );
    }

    test(
      'resolves relative paths, replaces existing target and cleans temp data',
      () async {
        const providerPath = './custom/providers/local.yaml';
        final expectedPath = path.canonicalize(
          path.join(homeDirectory.path, providerPath),
        );

        final firstPath = await generator.writeProviderFile([
          providerProxy('First'),
        ], providerPath: providerPath);
        expect(firstPath, expectedPath);
        final firstContent = await File(firstPath).readAsString();
        final firstDocument = yaml.loadYaml(firstContent) as Map;
        expect(
          ((firstDocument['proxies'] as List).single as Map)['name'],
          'First',
        );

        final secondPath = await generator.writeProviderFile([
          providerProxy('Second'),
        ], providerPath: providerPath);
        expect(secondPath, expectedPath);
        final secondContent = await File(secondPath).readAsString();
        expect(secondContent, isNot(firstContent));
        final secondDocument = yaml.loadYaml(secondContent) as Map;
        expect(
          ((secondDocument['proxies'] as List).single as Map)['name'],
          'Second',
        );

        final leftovers = await File(secondPath).parent
            .list()
            .where(
              (entity) =>
                  path.basename(entity.path).startsWith('.flclash-provider-'),
            )
            .toList();
        expect(leftovers, isEmpty);
      },
    );

    test('accepts absolute paths inside the application home', () async {
      final targetPath = path.join(homeDirectory.path, 'absolute.yaml');
      final result = await generator.writeProviderFile([
        providerProxy('Absolute'),
      ], providerPath: targetPath);
      expect(result, path.canonicalize(targetPath));
      expect(await File(targetPath).exists(), isTrue);
    });

    test('rejects paths that escape or do not identify a home file', () async {
      final unsafePaths = [
        '',
        '.',
        '../outside.yaml',
        path.join(outsideDirectory.path, 'outside.yaml'),
      ];
      for (final providerPath in unsafePaths) {
        await expectLater(
          generator.writeProviderFile([
            providerProxy('Unsafe'),
          ], providerPath: providerPath),
          throwsA(
            isA<ArgumentError>().having(
              (error) => error.toString(),
              'message',
              contains('providerPath'),
            ),
          ),
          reason: providerPath,
        );
      }
      expect(
        await File(path.join(outsideDirectory.path, 'outside.yaml')).exists(),
        isFalse,
      );
    });

    test('rejects parent and target symbolic links', () async {
      if (Platform.isWindows) return;

      final linkedDirectory = Link(path.join(homeDirectory.path, 'linked'));
      await linkedDirectory.create(outsideDirectory.path);
      await expectLater(
        generator.writeProviderFile([
          providerProxy('Linked parent'),
        ], providerPath: 'linked/provider.yaml'),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        await File(path.join(outsideDirectory.path, 'provider.yaml')).exists(),
        isFalse,
      );

      final outsideFile = File(path.join(outsideDirectory.path, 'target.yaml'));
      await outsideFile.writeAsString('outside');
      final targetLink = Link(path.join(homeDirectory.path, 'target.yaml'));
      await targetLink.create(outsideFile.path);
      await expectLater(
        generator.writeProviderFile([
          providerProxy('Linked target'),
        ], providerPath: 'target.yaml'),
        throwsA(isA<ArgumentError>()),
      );
      expect(await outsideFile.readAsString(), 'outside');
    });
  });
}
