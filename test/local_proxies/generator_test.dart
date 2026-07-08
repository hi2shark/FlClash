import 'package:fl_clash/local_proxies/services/local_proxy_provider_generator.dart';
import 'package:fl_clash/models/local_proxy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart' as yaml;

LocalProxy _proxy({
  required String type,
  required Map<String, dynamic> config,
}) {
  return LocalProxy(
    id: 1,
    name: 'Test',
    type: type,
    enabled: true,
    config: config,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

void main() {
  const generator = LocalProxyProviderGenerator();

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

    test('emits valid nowhere config and strips pool for udp carriers', () {
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
      final yamlString = generator.generateYaml([proxy]);
      final doc = yaml.loadYaml(yamlString) as Map;
      final map = (doc['proxies'] as List).first as Map;
      expect(map['type'], 'nowhere');
      expect(map['up'], 'udp');
      expect(map['down'], 'udp');
      expect(map['network'], 'udp');
      expect(map.containsKey('pool'), false);
      expect(map['reduce-rtt'], true);
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
}
