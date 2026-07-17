import 'dart:convert';
import 'dart:io';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/local_proxy.dart';
import 'package:path/path.dart' as path;
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
    if (type == 'nowhere') {
      _normalizeNowhere(proxy, map);
    } else {
      _normalizeAlpn(map);
    }

    if (type == 'anytls') {
      _normalizeEchOpts(map);
      _removeZeroValues(map, [
        'idle-session-check-interval',
        'idle-session-timeout',
        'min-idle-session',
      ]);
    }

    return map;
  }

  void _normalizeNowhere(LocalProxy proxy, Map<String, dynamic> map) {
    final server = map['server'];
    if (server is! String || server.isEmpty) {
      _invalidNowhere(proxy, 'server must be a non-empty string');
    }

    final port = map['port'];
    if (port is! int || port < 1 || port > 65535) {
      _invalidNowhere(proxy, 'port must be an integer from 1 to 65535');
    }

    final password = _resolveNowherePassword(proxy, map);
    _validateUtf8Length(proxy, 'password/key', password);
    map['password'] = password;
    map.remove('key');

    final carriers = _resolveNowhereCarriers(proxy, map);
    map['up'] = carriers.$1;
    map['down'] = carriers.$2;
    map['network'] = carriers.$1;
    map.remove('net');
    map.remove('spec');

    _normalizeNowhereAlpn(proxy, map);

    final pool = _normalizeNonNegativeInteger(proxy, map, 'pool');
    final tcpTCP = carriers.$1 == 'tcp' && carriers.$2 == 'tcp';
    if (tcpTCP) {
      if (pool != null && pool > 9) {
        commonPrint.log(
          '[Nowhere] Proxy "${proxy.name}" pool $pool exceeds maximum 9; using 9.',
          logLevel: LogLevel.warning,
        );
        map['pool'] = 9;
      }
    } else {
      map.remove('pool');
    }

    _normalizeNonNegativeInteger(proxy, map, 'max-concurrent-dials');
    final backoffInitial = _normalizeNonNegativeInteger(
      proxy,
      map,
      'warm-backoff-initial',
    );
    final backoffMax = _normalizeNonNegativeInteger(
      proxy,
      map,
      'warm-backoff-max',
    );
    _normalizeNonNegativeInteger(proxy, map, 'cwnd');

    final effectiveInitial = backoffInitial == null || backoffInitial == 0
        ? 1
        : backoffInitial;
    final effectiveMax = backoffMax == null || backoffMax == 0
        ? 30
        : backoffMax;
    if (effectiveInitial > effectiveMax) {
      _invalidNowhere(
        proxy,
        'warm-backoff-initial must not exceed warm-backoff-max after defaults',
      );
    }

    map.remove('bbr-profile');
    map.remove('reduce-rtt');
    map.remove('max-udp-relay-packet-size');
    _normalizeEchOpts(map);
  }

  String _resolveNowherePassword(LocalProxy proxy, Map<String, dynamic> map) {
    final password = map['password'];
    if (password != null) {
      if (password is! String) {
        _invalidNowhere(proxy, 'password must be a string');
      }
      if (password.isNotEmpty) return password;
    }

    final key = map['key'];
    if (key != null) {
      if (key is! String) {
        _invalidNowhere(proxy, 'key must be a string');
      }
      if (key.isNotEmpty) return key;
    }

    _invalidNowhere(proxy, 'password/key must be non-empty');
  }

  (String, String) _resolveNowhereCarriers(
    LocalProxy proxy,
    Map<String, dynamic> map,
  ) {
    final up = _optionalString(proxy, map, 'up');
    final down = _optionalString(proxy, map, 'down');
    late final String resolvedUp;
    late final String resolvedDown;

    if (up != null || down != null) {
      if (up == null || down == null) {
        _invalidNowhere(proxy, 'up and down must be set together');
      }
      resolvedUp = up;
      resolvedDown = down;
    } else {
      final network = _optionalString(proxy, map, 'network');
      final net = _optionalString(proxy, map, 'net');
      final symmetric = network ?? net ?? 'udp';
      resolvedUp = symmetric;
      resolvedDown = symmetric;
    }

    if (!_isNowhereCarrier(resolvedUp) || !_isNowhereCarrier(resolvedDown)) {
      _invalidNowhere(proxy, 'carriers must be exactly "tcp" or "udp"');
    }
    return (resolvedUp, resolvedDown);
  }

  bool _isNowhereCarrier(String value) => value == 'tcp' || value == 'udp';

  String? _optionalString(
    LocalProxy proxy,
    Map<String, dynamic> map,
    String field,
  ) {
    final value = map[field];
    if (value == null) return null;
    if (value is! String) {
      _invalidNowhere(proxy, '$field must be a string');
    }
    return value.isEmpty ? null : value;
  }

  void _normalizeNowhereAlpn(LocalProxy proxy, Map<String, dynamic> map) {
    final value = map['alpn'];
    if (value == null) return;

    late final String first;
    if (value is String) {
      first = value.split(',').first;
    } else if (value is List) {
      if (value.isEmpty) {
        map.remove('alpn');
        return;
      }
      final firstValue = value.first;
      if (firstValue is! String) {
        _invalidNowhere(proxy, 'the first ALPN entry must be a string');
      }
      first = firstValue;
    } else {
      _invalidNowhere(proxy, 'ALPN must be a string or list of strings');
    }

    if (first.isEmpty) {
      map.remove('alpn');
      return;
    }
    _validateUtf8Length(proxy, 'ALPN', first);
    map['alpn'] = [first];
  }

  int? _normalizeNonNegativeInteger(
    LocalProxy proxy,
    Map<String, dynamic> map,
    String field,
  ) {
    final value = map[field];
    if (value == null) return null;

    final parsed = value is int
        ? value
        : value is String
        ? int.tryParse(value)
        : null;
    if (parsed == null || parsed < 0) {
      _invalidNowhere(proxy, '$field must be a non-negative integer');
    }
    map[field] = parsed;
    return parsed;
  }

  void _validateUtf8Length(LocalProxy proxy, String field, String value) {
    late final int byteLength;
    try {
      byteLength = utf8.encode(value).length;
    } catch (_) {
      _invalidNowhere(proxy, '$field must be valid UTF-8');
    }
    if (byteLength > 255) {
      _invalidNowhere(proxy, '$field must not exceed 255 UTF-8 bytes');
    }
  }

  Never _invalidNowhere(LocalProxy proxy, String message) {
    throw ArgumentError('Invalid Nowhere proxy "${proxy.name}": $message.');
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
    if (ech is! Map || ech['enable'] != true) {
      map.remove('ech-opts');
      return;
    }

    final normalized = <String, dynamic>{'enable': true};
    final config = ech['config']?.toString() ?? '';
    if (config.isNotEmpty) {
      normalized['config'] = config;
    }
    final queryServerName = ech['query-server-name']?.toString() ?? '';
    if (queryServerName.isNotEmpty) {
      normalized['query-server-name'] = queryServerName;
    }
    map['ech-opts'] = normalized;
  }

  void _removeZeroValues(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value == null || value == 0 || value == '') {
        map.remove(key);
      }
    }
  }

  String _resolveProviderPath(String homePath, String providerPath) {
    if (providerPath.isEmpty) {
      throw ArgumentError.value(
        providerPath,
        'providerPath',
        'Provider path must identify a file inside the application home.',
      );
    }

    final resolved = path.canonicalize(
      path.isAbsolute(providerPath)
          ? providerPath
          : path.join(homePath, providerPath),
    );
    if (!path.isWithin(homePath, resolved)) {
      throw ArgumentError.value(
        providerPath,
        'providerPath',
        'Provider path must resolve inside the application home directory.',
      );
    }
    return resolved;
  }

  Future<void> _validateTargetPath(
    String homePath,
    String targetPath,
    String providerPath, {
    required bool createParent,
  }) async {
    final homeDirectory = Directory(homePath);
    if (!await homeDirectory.exists()) {
      if (!createParent) {
        throw StateError('Application home directory no longer exists.');
      }
      await homeDirectory.create(recursive: true);
    }

    final parentPath = path.dirname(targetPath);
    final relativeParent = path.relative(parentPath, from: homePath);
    var currentPath = homePath;
    for (final component in path.split(relativeParent)) {
      if (component.isEmpty || component == '.') continue;
      currentPath = path.join(currentPath, component);
      final entityType = await FileSystemEntity.type(
        currentPath,
        followLinks: false,
      );
      if (entityType == FileSystemEntityType.notFound) {
        if (!createParent) {
          throw StateError('Provider parent directory no longer exists.');
        }
        await Directory(currentPath).create();
      } else if (entityType != FileSystemEntityType.directory) {
        throw ArgumentError.value(
          providerPath,
          'providerPath',
          'Provider path must not traverse symbolic links or non-directories.',
        );
      }
    }

    final realHome = path.canonicalize(
      await homeDirectory.resolveSymbolicLinks(),
    );
    final realParent = path.canonicalize(
      await Directory(parentPath).resolveSymbolicLinks(),
    );
    if (!path.equals(realHome, realParent) &&
        !path.isWithin(realHome, realParent)) {
      throw ArgumentError.value(
        providerPath,
        'providerPath',
        'Provider path must remain inside the application home directory.',
      );
    }

    final targetType = await FileSystemEntity.type(
      targetPath,
      followLinks: false,
    );
    if (targetType != FileSystemEntityType.notFound &&
        targetType != FileSystemEntityType.file) {
      throw ArgumentError.value(
        providerPath,
        'providerPath',
        'Provider target must be a regular file, not a link or directory.',
      );
    }
  }

  void _validateGeneratedYaml(String content) {
    late final dynamic document;
    try {
      document = yaml_parser.loadYaml(content);
    } catch (error) {
      throw FormatException('Generated provider YAML is invalid: $error');
    }
    if (document is! Map || document['proxies'] is! List) {
      throw const FormatException(
        'Generated provider YAML must contain a proxies list.',
      );
    }
  }

  Future<File?> _backupProviderTarget(
    File targetFile,
    Directory temporaryDirectory,
  ) async {
    final targetType = await FileSystemEntity.type(
      targetFile.path,
      followLinks: false,
    );
    if (targetType == FileSystemEntityType.notFound) return null;
    if (targetType != FileSystemEntityType.file) {
      throw StateError('Provider target changed before replacement.');
    }

    final backupFile = File(
      path.join(
        temporaryDirectory.path,
        '.${path.basename(targetFile.path)}.backup',
      ),
    );
    await targetFile.copy(backupFile.path);
    return backupFile;
  }

  Future<void> _replaceProviderTarget({
    required File temporaryFile,
    required File targetFile,
    required File? backupFile,
  }) async {
    try {
      await temporaryFile.rename(targetFile.path);
    } catch (error, stackTrace) {
      await _restoreProviderTarget(targetFile, backupFile);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> _restoreProviderTarget(File targetFile, File? backupFile) async {
    try {
      await _removeTargetEntry(targetFile.path);
      if (backupFile == null) return;
      if (!await backupFile.exists()) {
        throw StateError('Provider backup is missing.');
      }
      try {
        await backupFile.rename(targetFile.path);
      } catch (_) {
        await backupFile.copy(targetFile.path);
      }
    } catch (error) {
      commonPrint.log(
        'Failed to restore local proxy provider after replacement failure: $error',
        logLevel: LogLevel.warning,
      );
    }
  }

  Future<void> _removeTargetEntry(String targetPath) async {
    final targetType = await FileSystemEntity.type(
      targetPath,
      followLinks: false,
    );
    if (targetType == FileSystemEntityType.notFound) return;
    if (targetType == FileSystemEntityType.file) {
      await File(targetPath).delete();
      return;
    }
    if (targetType == FileSystemEntityType.link) {
      await Link(targetPath).delete();
      return;
    }
    if (targetType == FileSystemEntityType.directory) {
      await Directory(targetPath).delete();
      return;
    }
    throw FileSystemException(
      'Unsupported provider target type during restore',
      targetPath,
    );
  }

  Future<String> get _targetPath async => path.join(
    await appPath.homeDirPath,
    'proxy_providers',
    'flclash-local.yaml',
  );

  Future<String> writeProviderFile(
    List<LocalProxy> proxies, {
    required String providerPath,
  }) async {
    final enabled = proxies.where((p) => p.enabled).toList();
    if (enabled.isEmpty) {
      return '';
    }

    final yamlString = generateYaml(enabled);
    final homePath = path.canonicalize(await appPath.homeDirPath);
    final targetPath = _resolveProviderPath(homePath, providerPath);
    await _validateTargetPath(
      homePath,
      targetPath,
      providerPath,
      createParent: true,
    );

    Directory? temporaryDirectory;
    try {
      final targetFile = File(targetPath);
      final targetDirectory = targetFile.parent;
      temporaryDirectory = await targetDirectory.createTemp(
        '.flclash-provider-',
      );
      final temporaryFile = File(
        path.join(temporaryDirectory.path, '.${path.basename(targetPath)}.tmp'),
      );
      await temporaryFile.writeAsString(
        yamlString,
        encoding: utf8,
        flush: true,
      );
      _validateGeneratedYaml(await temporaryFile.readAsString(encoding: utf8));
      await _validateTargetPath(
        homePath,
        targetPath,
        providerPath,
        createParent: false,
      );
      final backupFile = await _backupProviderTarget(
        targetFile,
        temporaryDirectory,
      );
      await _replaceProviderTarget(
        temporaryFile: temporaryFile,
        targetFile: targetFile,
        backupFile: backupFile,
      );
      return targetPath;
    } finally {
      final directory = temporaryDirectory;
      if (directory != null && await directory.exists()) {
        await directory.delete(recursive: true);
      }
    }
  }

  Future<void> deleteProviderFile() async {
    final file = File(await _targetPath);
    await file.safeDelete();
  }
}

const localProxyProviderGenerator = LocalProxyProviderGenerator();
