import 'dart:io';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/models/local_proxy.dart';
import 'package:path/path.dart';
import 'package:yaml/yaml.dart' as yaml_parser;

class LocalProxyProviderGenerator {
  const LocalProxyProviderGenerator();

  String generateYaml(List<LocalProxy> proxies) {
    final enabled = proxies.where((p) => p.enabled).toList();
    final proxyMaps = enabled.map(_buildProxyMap).toList();
    return yaml.encode({'proxies': proxyMaps});
  }

  Map<String, dynamic> _buildProxyMap(LocalProxy proxy) {
    final map = Map<String, dynamic>.from(proxy.config);
    map['port'] = _toPort(map['port']);

    // Clean empty/null values regardless of protocol.
    map.removeWhere(
      (key, value) =>
          value == null ||
          value == '' ||
          (value is List && value.isEmpty) ||
          (value is Map && value.isEmpty),
    );

    final type = proxy.type;

    if (type == 'anytls') {
      _normalizeAlpn(map);
      _normalizeEchOpts(map);
      _removeZeroValues(map, [
        'idle-session-check-interval',
        'idle-session-timeout',
        'min-idle-session',
      ]);
    }

    if (type == 'hysteria2') {
      _normalizeAlpn(map);
    }

    if (type == 'nowhere') {
      _normalizeAlpn(map);
      _normalizeEchOpts(map);
      final up = map['up']?.toString() ?? 'udp';
      final down = map['down']?.toString() ?? 'udp';
      if (!['tcp', 'udp'].contains(up) || !['tcp', 'udp'].contains(down)) {
        map['up'] = 'udp';
        map['down'] = 'udp';
      }
      map['network'] = map['up'];
      if (map['up'] != 'tcp' || map['down'] != 'tcp') {
        map.remove('pool');
      } else {
        final poolValue = map['pool'];
        if (poolValue == null || poolValue == '') {
          map.remove('pool');
        }
      }
      _removeZeroValues(map, ['cwnd', 'max-udp-relay-packet-size']);
    }

    return map;
  }

  int _toPort(dynamic value) {
    if (value is int) return value;
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
    }
    return 0;
  }

  void _normalizeAlpn(Map<String, dynamic> map) {
    final alpn = map['alpn'];
    if (alpn is String && alpn.isNotEmpty) {
      map['alpn'] = alpn
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    } else if (alpn is! List) {
      map.remove('alpn');
    }
  }

  void _normalizeEchOpts(Map<String, dynamic> map) {
    final ech = map['ech-opts'];
    if (ech is Map) {
      final enabled = ech['enable'] == true;
      final config = ech['config']?.toString() ?? '';
      if (!enabled || config.isEmpty) {
        map.remove('ech-opts');
      } else {
        map['ech-opts'] = {'enable': true, 'config': config};
      }
    } else {
      map.remove('ech-opts');
    }
  }

  void _removeZeroValues(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value == null || value == 0 || value == '') {
        map.remove(key);
      }
    }
  }

  Future<String> get _targetPath async =>
      join(await appPath.homeDirPath, 'proxy_providers', 'flclash-local.yaml');

  Future<String> get _tempPath async =>
      join(await appPath.tempPath, 'flclash-local.yaml.tmp');

  Future<String> writeProviderFile(List<LocalProxy> proxies) async {
    final yamlString = generateYaml(proxies);
    final tempFile = File(await _tempPath);
    final targetFile = File(await _targetPath);

    await tempFile.safeWriteAsString(yamlString);
    try {
      yaml_parser.loadYaml(await tempFile.readAsString());
    } catch (e) {
      await tempFile.safeDelete();
      throw Exception('Generated provider YAML is invalid: $e');
    }

    if (!await targetFile.parent.exists()) {
      await targetFile.parent.create(recursive: true);
    }
    await tempFile.rename(targetFile.path);
    return targetFile.path;
  }

  Future<void> deleteProviderFile() async {
    final file = File(await _targetPath);
    await file.safeDelete();
  }
}

const localProxyProviderGenerator = LocalProxyProviderGenerator();
