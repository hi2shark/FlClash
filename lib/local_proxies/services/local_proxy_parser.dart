import 'dart:convert';

import 'package:fl_clash/models/local_proxy.dart';

class LocalProxyParseResult {
  final LocalProxy? proxy;
  final String raw;
  final String? error;
  final List<String> warnings;

  const LocalProxyParseResult({
    this.proxy,
    required this.raw,
    this.error,
    this.warnings = const [],
  });
}

class LocalProxyParser {
  const LocalProxyParser();

  List<LocalProxyParseResult> parseMany(String text) {
    final lines = const LineSplitter()
        .convert(text)
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    return lines.map(_parseUri).toList();
  }

  LocalProxyParseResult _parseUri(String raw) {
    try {
      final uri = Uri.parse(raw);
      final scheme = uri.scheme.toLowerCase();
      return switch (scheme) {
        'ss' => _parseSs(uri, raw),
        'vless' => _parseVless(uri, raw),
        'trojan' => _parseTrojan(uri, raw),
        'anytls' => _parseAnyTLS(uri, raw),
        'nowhere' => _parseNowhere(uri, raw),
        'vmess' => _parseVmess(uri, raw),
        'ssr' => _parseSsr(raw),
        'hysteria' => _parseHysteria(uri, raw),
        'hysteria2' || 'hy2' => _parseHysteria2(uri, raw, scheme),
        'tuic' => _parseTUIC(uri, raw),
        'socks' ||
        'socks5' ||
        'socks5h' ||
        'http' ||
        'https' => _parseSocksOrHttp(uri, raw, scheme),
        'mierus' => _parseMierus(uri, raw),
        _ => LocalProxyParseResult(
          raw: raw,
          error: 'Unsupported protocol: ${uri.scheme}',
        ),
      };
    } catch (e) {
      return LocalProxyParseResult(raw: raw, error: e.toString());
    }
  }

  String _decodeBase64(String input) {
    final normalized = input.padRight(
      input.length + (4 - input.length % 4) % 4,
      '=',
    );
    try {
      return utf8.decode(base64Url.decode(normalized));
    } on FormatException {
      return utf8.decode(base64.decode(normalized));
    }
  }

  String? _tryDecodeBase64(String input) {
    try {
      return _decodeBase64(input);
    } catch (_) {
      return null;
    }
  }

  String _decodeUrlSafeBase64(String input) {
    final normalized = input
        .replaceAll('-', '+')
        .replaceAll('_', '/')
        .padRight(input.length + (4 - input.length % 4) % 4, '=');
    try {
      return utf8.decode(base64Url.decode(normalized));
    } on FormatException {
      return utf8.decode(base64.decode(normalized));
    }
  }

  String? _decodeFragment(String fragment) {
    if (fragment.isEmpty) return null;
    try {
      return Uri.decodeComponent(fragment);
    } catch (_) {
      return fragment;
    }
  }

  String _buildName(String? fragment, String type, String server) {
    if (fragment != null && fragment.isNotEmpty) return fragment;
    return 'Local | ${type.toUpperCase()} | $server';
  }

  int _parsePort(String value) {
    final port = int.tryParse(value);
    if (port == null || port < 1 || port > 65535) {
      throw Exception('Invalid port: $value');
    }
    return port;
  }

  int _parsePortOrDefault(String? value, int defaultPort) {
    if (value == null || value.isEmpty) return defaultPort;
    return _parsePort(value);
  }

  bool _parseBoolQuery(String? value) {
    return value == '1' || value?.toLowerCase() == 'true';
  }

  List<String> _parseAlpn(String? value) {
    if (value == null || value.isEmpty) return [];
    return value
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  Map<String, dynamic>? _parseEch(String? value) {
    if (value == null || value.isEmpty) return null;
    return {'enable': true, 'config': value};
  }

  LocalProxyParseResult _parseSs(Uri uri, String raw) {
    late final String server;
    late final int port;
    late final String method;
    late final String password;
    final fragment = _decodeFragment(uri.fragment);

    if (uri.host.isNotEmpty && uri.userInfo.isNotEmpty) {
      server = uri.host;
      port = _parsePort(uri.port.toString());
      final decoded = _decodeBase64(uri.userInfo);
      final splitIndex = decoded.indexOf(':');
      if (splitIndex == -1) {
        return LocalProxyParseResult(raw: raw, error: 'Invalid SS user info');
      }
      method = decoded.substring(0, splitIndex);
      password = decoded.substring(splitIndex + 1);
    } else {
      final body = raw.substring('ss://'.length);
      final hashIndex = body.indexOf('#');
      final b64Part = hashIndex == -1 ? body : body.substring(0, hashIndex);
      final decoded = _decodeBase64(b64Part);
      final atIndex = decoded.lastIndexOf('@');
      if (atIndex == -1) {
        return LocalProxyParseResult(raw: raw, error: 'Invalid SS URI');
      }
      final userInfo = decoded.substring(0, atIndex);
      final hostPort = decoded.substring(atIndex + 1);
      final colonIndex = hostPort.lastIndexOf(':');
      if (colonIndex == -1) {
        return LocalProxyParseResult(raw: raw, error: 'Invalid SS host:port');
      }
      server = hostPort.substring(0, colonIndex);
      port = _parsePort(hostPort.substring(colonIndex + 1));
      final splitIndex = userInfo.indexOf(':');
      if (splitIndex == -1) {
        return LocalProxyParseResult(raw: raw, error: 'Invalid SS user info');
      }
      method = userInfo.substring(0, splitIndex);
      password = userInfo.substring(splitIndex + 1);
    }

    if (method.isEmpty || password.isEmpty) {
      return LocalProxyParseResult(
        raw: raw,
        error: 'SS method or password is empty',
      );
    }

    final warnings = <String>[];
    if (uri.queryParameters.isNotEmpty) {
      warnings.add('Plugin/extended SS options are not fully supported');
    }

    return LocalProxyParseResult(
      raw: raw,
      proxy: LocalProxy(
        id: -1,
        name: _buildName(fragment, 'ss', server),
        type: 'ss',
        config: {
          'name': _buildName(fragment, 'ss', server),
          'type': 'ss',
          'server': server,
          'port': port,
          'cipher': method,
          'password': password,
          'udp': true,
        },
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      warnings: warnings,
    );
  }

  LocalProxyParseResult _parseVless(Uri uri, String raw) {
    if (uri.userInfo.isEmpty) {
      return LocalProxyParseResult(raw: raw, error: 'VLESS UUID is empty');
    }
    final uuid = uri.userInfo;
    final server = uri.host;
    if (server.isEmpty) {
      return LocalProxyParseResult(raw: raw, error: 'VLESS server is empty');
    }
    final port = _parsePort(uri.port.toString());
    final query = uri.queryParameters;
    final fragment = _decodeFragment(uri.fragment);

    final network = query['type'] ?? 'tcp';
    final security = query['security'];
    final tls = security == 'tls' || security == 'reality';
    final servername = query['sni'] ?? query['host'] ?? server;
    final warnings = <String>[];

    final config = <String, dynamic>{
      'name': _buildName(fragment, 'vless', server),
      'type': 'vless',
      'server': server,
      'port': port,
      'uuid': uuid,
      'network': network,
      'tls': tls,
      'servername': servername,
      'udp': true,
    };

    if (query['flow'] != null) {
      config['flow'] = query['flow'];
    }
    if (security == 'reality') {
      warnings.add('REALITY is not fully supported in this version');
      final realityOpts = <String, dynamic>{};
      if (query['pbk'] != null) realityOpts['public-key'] = query['pbk'];
      if (query['sid'] != null) realityOpts['short-id'] = query['sid'];
      if (query['spx'] != null) realityOpts['spiderX'] = query['spx'];
      if (realityOpts.isNotEmpty) {
        config['reality-opts'] = realityOpts;
      }
    }
    if (network != 'tcp') {
      warnings.add('Only TCP transport is fully supported in this version');
    }

    return LocalProxyParseResult(
      raw: raw,
      proxy: LocalProxy(
        id: -1,
        name: _buildName(fragment, 'vless', server),
        type: 'vless',
        config: config,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      warnings: warnings,
    );
  }

  LocalProxyParseResult _parseTrojan(Uri uri, String raw) {
    if (uri.userInfo.isEmpty) {
      return LocalProxyParseResult(raw: raw, error: 'Trojan password is empty');
    }
    final password = uri.userInfo;
    final server = uri.host;
    if (server.isEmpty) {
      return LocalProxyParseResult(raw: raw, error: 'Trojan server is empty');
    }
    final port = _parsePort(uri.port.toString());
    final query = uri.queryParameters;
    final fragment = _decodeFragment(uri.fragment);

    final sni = query['sni'] ?? query['host'] ?? server;
    final skipCertVerify =
        query['allowInsecure'] == '1' || query['allow_insecure'] == '1';
    final warnings = <String>[];
    if (query['type'] != null && query['type'] != 'tcp') {
      warnings.add('Only TCP transport is fully supported in this version');
    }

    return LocalProxyParseResult(
      raw: raw,
      proxy: LocalProxy(
        id: -1,
        name: _buildName(fragment, 'trojan', server),
        type: 'trojan',
        config: {
          'name': _buildName(fragment, 'trojan', server),
          'type': 'trojan',
          'server': server,
          'port': port,
          'password': password,
          'sni': sni,
          'udp': true,
          'skip-cert-verify': skipCertVerify,
        },
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      warnings: warnings,
    );
  }

  LocalProxyParseResult _parseAnyTLS(Uri uri, String raw) {
    final userInfo = uri.userInfo;
    if (userInfo.isEmpty) {
      return LocalProxyParseResult(raw: raw, error: 'AnyTLS password is empty');
    }
    final server = uri.host;
    if (server.isEmpty) {
      return LocalProxyParseResult(raw: raw, error: 'AnyTLS server is empty');
    }
    final port = _parsePortOrDefault(
      uri.port == 0 ? null : uri.port.toString(),
      443,
    );
    final query = uri.queryParameters;
    final fragment = _decodeFragment(uri.fragment);

    final colonIndex = userInfo.indexOf(':');
    final password = colonIndex != -1
        ? userInfo.substring(colonIndex + 1)
        : userInfo;

    final config = <String, dynamic>{
      'name': _buildName(fragment, 'anytls', server),
      'type': 'anytls',
      'server': server,
      'port': port,
      'password': password,
      'udp': true,
    };

    if (query['sni'] != null && query['sni']!.isNotEmpty) {
      config['sni'] = query['sni'];
    }
    final alpn = _parseAlpn(query['alpn']);
    if (alpn.isNotEmpty) {
      config['alpn'] = alpn;
    }
    final fingerprint = query['hpkp'] ?? query['fp'];
    if (fingerprint != null && fingerprint.isNotEmpty) {
      config['fingerprint'] = fingerprint;
    }
    if (query['client-fingerprint'] != null &&
        query['client-fingerprint']!.isNotEmpty) {
      config['client-fingerprint'] = query['client-fingerprint'];
    }
    if (_parseBoolQuery(query['insecure'])) {
      config['skip-cert-verify'] = true;
    }
    final ech = _parseEch(query['ech']);
    if (ech != null) {
      config['ech-opts'] = ech;
    }

    return LocalProxyParseResult(
      raw: raw,
      proxy: LocalProxy(
        id: -1,
        name: _buildName(fragment, 'anytls', server),
        type: 'anytls',
        config: config,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  LocalProxyParseResult _parseNowhere(Uri uri, String raw) {
    final key = uri.userInfo;
    if (key.isEmpty) {
      return LocalProxyParseResult(raw: raw, error: 'Nowhere key is empty');
    }
    if (uri.userInfo.contains(':')) {
      return LocalProxyParseResult(
        raw: raw,
        error: 'Nowhere URI must not contain a password component',
      );
    }
    final server = uri.host;
    if (server.isEmpty) {
      return LocalProxyParseResult(raw: raw, error: 'Nowhere server is empty');
    }
    final port = _parsePortOrDefault(
      uri.port == 0 ? null : uri.port.toString(),
      443,
    );
    final query = uri.queryParameters;
    final fragment = _decodeFragment(uri.fragment);

    var up = query['up']?.toLowerCase();
    var down = query['down']?.toLowerCase();
    if ((up == null || up.isEmpty) && (down == null || down.isEmpty)) {
      final net =
          query['net']?.toLowerCase() ?? query['network']?.toLowerCase();
      if (net != null && net.isNotEmpty) {
        up = net;
        down = net;
      }
    }
    up ??= 'udp';
    down ??= 'udp';
    if (!['tcp', 'udp'].contains(up) || !['tcp', 'udp'].contains(down)) {
      return LocalProxyParseResult(
        raw: raw,
        error: 'Nowhere carrier must be tcp or udp',
      );
    }
    final tcpTCP = up == 'tcp' && down == 'tcp';

    final config = <String, dynamic>{
      'name': _buildName(fragment, 'nowhere', server),
      'type': 'nowhere',
      'server': server,
      'port': port,
      'key': key,
      'udp': true,
      'up': up,
      'down': down,
      'network': up,
    };

    if (query['spec'] != null && query['spec']!.isNotEmpty) {
      config['spec'] = query['spec'];
    }
    if (query['sni'] != null && query['sni']!.isNotEmpty) {
      config['sni'] = query['sni'];
    }
    final alpn = _parseAlpn(query['alpn']);
    if (alpn.isNotEmpty) {
      config['alpn'] = alpn;
    }
    if (tcpTCP && query['pool'] != null && query['pool']!.isNotEmpty) {
      final pool = int.tryParse(query['pool']!);
      if (pool != null && pool >= 0 && pool <= 9) {
        config['pool'] = pool;
      }
    }
    if (_parseBoolQuery(query['insecure'])) {
      config['skip-cert-verify'] = true;
    }
    final fingerprint = query['fp'];
    if (fingerprint != null && fingerprint.isNotEmpty) {
      config['fingerprint'] = fingerprint;
    }
    final ech = _parseEch(query['ech']);
    if (ech != null) {
      config['ech-opts'] = ech;
    }

    return LocalProxyParseResult(
      raw: raw,
      proxy: LocalProxy(
        id: -1,
        name: _buildName(fragment, 'nowhere', server),
        type: 'nowhere',
        config: config,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  LocalProxyParseResult _parseVmess(Uri uri, String raw) {
    final body = raw.substring('vmess://'.length);
    final decoded = _tryDecodeBase64(body);
    if (decoded != null) {
      try {
        final json = jsonDecode(decoded) as Map<String, dynamic>;
        return _parseVmessJson(json, raw);
      } catch (_) {}
    }
    return _parseVmessXray(uri, raw);
  }

  LocalProxyParseResult _parseVmessJson(Map<String, dynamic> json, String raw) {
    final server = json['add']?.toString() ?? '';
    if (server.isEmpty) {
      return LocalProxyParseResult(raw: raw, error: 'VMess server is empty');
    }
    final uuid = json['id']?.toString() ?? '';
    if (uuid.isEmpty) {
      return LocalProxyParseResult(raw: raw, error: 'VMess UUID is empty');
    }
    final name = _buildName(json['ps']?.toString(), 'vmess', server);
    final portRaw = json['port'];
    final port = portRaw is int
        ? portRaw
        : int.tryParse(portRaw?.toString() ?? '') ?? 0;
    if (port < 1 || port > 65535) {
      return LocalProxyParseResult(raw: raw, error: 'VMess port is invalid');
    }

    var network = (json['net']?.toString() ?? 'tcp').toLowerCase();
    if (json['type']?.toString() == 'http') {
      network = 'http';
    } else if (network == 'http') {
      network = 'h2';
    }

    final cipher = (json['scy']?.toString() ?? '').isNotEmpty
        ? json['scy'].toString()
        : 'auto';
    final alterId = json['aid'] is int
        ? json['aid'] as int
        : int.tryParse(json['aid']?.toString() ?? '') ?? 0;

    final config = <String, dynamic>{
      'name': name,
      'type': 'vmess',
      'server': server,
      'port': port,
      'uuid': uuid,
      'alterId': alterId,
      'cipher': cipher,
      'udp': true,
      'xudp': true,
      'tls': false,
      'skip-cert-verify': false,
      'network': network,
    };

    final sni = json['sni']?.toString() ?? '';
    final tlsRaw = json['tls']?.toString().toLowerCase() ?? '';
    if (tlsRaw.endsWith('tls')) {
      config['tls'] = true;
      final alpn = _parseAlpn(json['alpn']?.toString());
      if (alpn.isNotEmpty) {
        config['alpn'] = alpn;
      }
    }
    if (sni.isNotEmpty) {
      config['servername'] = sni;
    }

    final host = json['host']?.toString() ?? '';
    final path = json['path']?.toString() ?? '';
    _applyVmessNetworkOpts(config, network, host, path);

    return LocalProxyParseResult(
      raw: raw,
      proxy: LocalProxy(
        id: -1,
        name: name,
        type: 'vmess',
        config: config,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  LocalProxyParseResult _parseVmessXray(Uri uri, String raw) {
    final server = uri.host;
    if (server.isEmpty || uri.port == 0) {
      return LocalProxyParseResult(raw: raw, error: 'Invalid VMess URI');
    }
    final uuid = uri.userInfo;
    if (uuid.isEmpty) {
      return LocalProxyParseResult(raw: raw, error: 'VMess UUID is empty');
    }
    final query = uri.queryParameters;
    final name = _buildName(_decodeFragment(uri.fragment), 'vmess', server);

    var network = (query['type'] ?? 'tcp').toLowerCase();
    final fakeType = (query['headerType'] ?? '').toLowerCase();
    if (network == 'tcp' && fakeType == 'http') {
      network = 'http';
    } else if (network == 'http') {
      network = 'h2';
    }

    final config = <String, dynamic>{
      'name': name,
      'type': 'vmess',
      'server': server,
      'port': uri.port,
      'uuid': uuid,
      'alterId': 0,
      'cipher': 'auto',
      'udp': true,
      'xudp': true,
      'tls': false,
      'skip-cert-verify': false,
      'network': network,
    };

    final security = (query['security'] ?? '').toLowerCase();
    if (security.endsWith('tls') || security == 'reality') {
      config['tls'] = true;
      config['client-fingerprint'] = query['fp']?.isNotEmpty == true
          ? query['fp']
          : 'chrome';
      final alpn = _parseAlpn(query['alpn']);
      if (alpn.isNotEmpty) {
        config['alpn'] = alpn;
      }
      if (query['pcs']?.isNotEmpty == true) {
        config['fingerprint'] = query['pcs'];
      }
    }
    if (query['sni']?.isNotEmpty == true) {
      config['servername'] = query['sni'];
    }
    if (query['pbk']?.isNotEmpty == true) {
      config['reality-opts'] = {
        'public-key': query['pbk'],
        'short-id': query['sid'] ?? '',
      };
    }

    final packetEncoding = query['packetEncoding']?.toLowerCase() ?? '';
    switch (packetEncoding) {
      case 'none':
        break;
      case 'packet':
        config['packet-addr'] = true;
      default:
        config['xudp'] = true;
    }

    _applyVmessNetworkOpts(
      config,
      network,
      query['host'] ?? '',
      query['path'] ?? '',
      serviceName: query['serviceName'] ?? '',
      mode: query['mode'] ?? '',
      extra: query['extra'] ?? '',
    );

    return LocalProxyParseResult(
      raw: raw,
      proxy: LocalProxy(
        id: -1,
        name: name,
        type: 'vmess',
        config: config,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  void _applyVmessNetworkOpts(
    Map<String, dynamic> config,
    String network,
    String host,
    String path, {
    String serviceName = '',
    String mode = '',
    String extra = '',
  }) {
    switch (network) {
      case 'http':
        final headers = <String, dynamic>{};
        if (host.isNotEmpty) {
          headers['Host'] = [host];
        }
        config['http-opts'] = {
          'path': path.isNotEmpty ? [path] : ['/'],
          'headers': headers,
        };
      case 'h2':
        config['h2-opts'] = {
          'path': path.isNotEmpty ? path : '/',
          if (host.isNotEmpty) 'host': [host],
        };
      case 'ws':
      case 'httpupgrade':
        final wsOpts = <String, dynamic>{
          'path': path.isNotEmpty ? path : '/',
          'headers': <String, dynamic>{if (host.isNotEmpty) 'Host': host},
        };
        if (path.isNotEmpty) {
          final pathUrl = Uri.tryParse(path);
          if (pathUrl != null) {
            final ed = pathUrl.queryParameters['ed'];
            if (ed != null && int.tryParse(ed) != null) {
              if (network == 'ws') {
                wsOpts['max-early-data'] = int.parse(ed);
                wsOpts['early-data-header-name'] = 'Sec-WebSocket-Protocol';
              } else {
                wsOpts['v2ray-http-upgrade-fast-open'] = true;
              }
            }
            final eh = pathUrl.queryParameters['eh'];
            if (eh != null && eh.isNotEmpty) {
              wsOpts['early-data-header-name'] = eh;
            }
          }
        }
        config['ws-opts'] = wsOpts;
      case 'grpc':
        config['grpc-opts'] = {
          'grpc-service-name': serviceName.isNotEmpty ? serviceName : path,
        };
      case 'xhttp':
        final xhttpOpts = <String, dynamic>{
          if (path.isNotEmpty) 'path': path,
          if (host.isNotEmpty) 'host': host,
          if (mode.isNotEmpty) 'mode': mode,
        };
        if (extra.isNotEmpty) {
          try {
            final extraMap = jsonDecode(extra) as Map<String, dynamic>;
            xhttpOpts.addAll(extraMap);
          } catch (_) {}
        }
        config['xhttp-opts'] = xhttpOpts;
    }
  }

  LocalProxyParseResult _parseSsr(String raw) {
    final body = raw.substring('ssr://'.length);
    final decoded = _tryDecodeBase64(body);
    if (decoded == null) {
      return LocalProxyParseResult(raw: raw, error: 'Invalid SSR base64');
    }
    final sepIndex = decoded.indexOf('/?');
    if (sepIndex == -1) {
      return LocalProxyParseResult(raw: raw, error: 'Invalid SSR URI');
    }
    final before = decoded.substring(0, sepIndex);
    final after = decoded.substring(sepIndex + 2);
    final parts = before.split(':');
    if (parts.length != 6) {
      return LocalProxyParseResult(raw: raw, error: 'Invalid SSR URI');
    }

    final server = parts[0];
    final port = parts[1];
    final protocol = parts[2];
    final method = parts[3];
    final obfs = parts[4];
    final password = _decodeUrlSafeBase64(parts[5]);

    final query = Uri.splitQueryString(after);
    final remarks = _decodeUrlSafeBase64(query['remarks'] ?? '');
    final obfsParam = _decodeUrlSafeBase64(query['obfsparam'] ?? '');
    final protocolParam = _decodeUrlSafeBase64(query['protoparam'] ?? '');
    final name = _buildName(remarks.isNotEmpty ? remarks : null, 'ssr', server);

    final config = <String, dynamic>{
      'name': name,
      'type': 'ssr',
      'server': server,
      'port': port,
      'cipher': method,
      'password': password,
      'protocol': protocol,
      'obfs': obfs,
      'udp': true,
    };
    if (obfsParam.isNotEmpty) {
      config['obfs-param'] = obfsParam;
    }
    if (protocolParam.isNotEmpty) {
      config['protocol-param'] = protocolParam;
    }

    return LocalProxyParseResult(
      raw: raw,
      proxy: LocalProxy(
        id: -1,
        name: name,
        type: 'ssr',
        config: config,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  LocalProxyParseResult _parseHysteria(Uri uri, String raw) {
    final server = uri.host;
    if (server.isEmpty) {
      return LocalProxyParseResult(raw: raw, error: 'Hysteria server is empty');
    }
    final port = _parsePortOrDefault(
      uri.port == 0 ? null : uri.port.toString(),
      443,
    );
    final query = uri.queryParameters;
    final fragment = _decodeFragment(uri.fragment);
    final name = _buildName(fragment, 'hysteria', server);

    var up = query['up'] ?? '';
    var down = query['down'] ?? '';
    if (up.isEmpty) up = query['upmbps'] ?? '';
    if (down.isEmpty) down = query['downmbps'] ?? '';

    final config = <String, dynamic>{
      'name': name,
      'type': 'hysteria',
      'server': server,
      'port': port,
      'sni': query['peer'] ?? '',
      'obfs': query['obfs'] ?? '',
      'auth_str': query['auth'] ?? '',
      'protocol': query['protocol'] ?? '',
      'up': up,
      'down': down,
      'skip-cert-verify': _parseBoolQuery(query['insecure']),
    };
    final alpn = _parseAlpn(query['alpn']);
    if (alpn.isNotEmpty) {
      config['alpn'] = alpn;
    }

    return LocalProxyParseResult(
      raw: raw,
      proxy: LocalProxy(
        id: -1,
        name: name,
        type: 'hysteria',
        config: config,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  LocalProxyParseResult _parseHysteria2(Uri uri, String raw, String scheme) {
    final server = uri.host;
    if (server.isEmpty) {
      return LocalProxyParseResult(
        raw: raw,
        error: 'Hysteria2 server is empty',
      );
    }
    final port = _parsePortOrDefault(
      uri.port == 0 ? null : uri.port.toString(),
      443,
    );
    final query = uri.queryParameters;
    final fragment = _decodeFragment(uri.fragment);
    final name = _buildName(fragment, 'hysteria2', server);

    var password = uri.userInfo;
    final colonIndex = password.indexOf(':');
    if (colonIndex != -1) {
      password = password.substring(colonIndex + 1);
    }

    final config = <String, dynamic>{
      'name': name,
      'type': 'hysteria2',
      'server': server,
      'port': port,
      'password': password,
      'sni': query['sni'] ?? '',
      'obfs': query['obfs'] ?? '',
      'obfs-password': query['obfs-password'] ?? '',
      'fingerprint': query['pinSHA256'] ?? '',
      'down': query['down'] ?? '',
      'up': query['up'] ?? '',
      'skip-cert-verify': _parseBoolQuery(query['insecure']),
    };
    final alpn = _parseAlpn(query['alpn']);
    if (alpn.isNotEmpty) {
      config['alpn'] = alpn;
    }

    return LocalProxyParseResult(
      raw: raw,
      proxy: LocalProxy(
        id: -1,
        name: name,
        type: 'hysteria2',
        config: config,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  LocalProxyParseResult _parseTUIC(Uri uri, String raw) {
    final server = uri.host;
    if (server.isEmpty) {
      return LocalProxyParseResult(raw: raw, error: 'TUIC server is empty');
    }
    if (uri.port == 0) {
      return LocalProxyParseResult(raw: raw, error: 'TUIC port is empty');
    }
    final query = uri.queryParameters;
    final fragment = _decodeFragment(uri.fragment);
    final name = _buildName(fragment, 'tuic', server);

    final config = <String, dynamic>{
      'name': name,
      'type': 'tuic',
      'server': server,
      'port': uri.port,
      'udp': true,
    };

    final userInfo = uri.userInfo;
    final colonIndex = userInfo.indexOf(':');
    if (colonIndex != -1) {
      config['uuid'] = userInfo.substring(0, colonIndex);
      config['password'] = userInfo.substring(colonIndex + 1);
    } else {
      config['token'] = userInfo;
    }

    if (query['congestion_control']?.isNotEmpty == true) {
      config['congestion-controller'] = query['congestion_control'];
    }
    final alpn = _parseAlpn(query['alpn']);
    if (alpn.isNotEmpty) {
      config['alpn'] = alpn;
    }
    if (query['sni']?.isNotEmpty == true) {
      config['sni'] = query['sni'];
    }
    if (query['disable_sni'] == '1') {
      config['disable-sni'] = true;
    }
    if (query['udp_relay_mode']?.isNotEmpty == true) {
      config['udp-relay-mode'] = query['udp_relay_mode'];
    }

    return LocalProxyParseResult(
      raw: raw,
      proxy: LocalProxy(
        id: -1,
        name: name,
        type: 'tuic',
        config: config,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  LocalProxyParseResult _parseSocksOrHttp(Uri uri, String raw, String scheme) {
    final server = uri.host;
    if (server.isEmpty) {
      return LocalProxyParseResult(raw: raw, error: 'Server is empty');
    }
    if (uri.port == 0) {
      return LocalProxyParseResult(raw: raw, error: 'Port is empty');
    }
    final fragment = _decodeFragment(uri.fragment);
    final name = _buildName(fragment, scheme, server);

    final type = ['socks', 'socks5', 'socks5h'].contains(scheme)
        ? 'socks5'
        : 'http';
    var username = '';
    var password = '';
    if (uri.userInfo.isNotEmpty) {
      final decoded = _tryDecodeBase64(uri.userInfo);
      if (decoded != null && decoded.contains(':')) {
        final idx = decoded.indexOf(':');
        username = decoded.substring(0, idx);
        password = decoded.substring(idx + 1);
      } else if (uri.userInfo.contains(':')) {
        final idx = uri.userInfo.indexOf(':');
        username = uri.userInfo.substring(0, idx);
        password = uri.userInfo.substring(idx + 1);
      } else {
        username = uri.userInfo;
      }
    }

    final config = <String, dynamic>{
      'name': name,
      'type': type,
      'server': server,
      'port': uri.port,
      'username': username,
      'password': password,
      'skip-cert-verify': true,
    };
    if (scheme == 'https') {
      config['tls'] = true;
    }

    return LocalProxyParseResult(
      raw: raw,
      proxy: LocalProxy(
        id: -1,
        name: name,
        type: type,
        config: config,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  LocalProxyParseResult _parseMierus(Uri uri, String raw) {
    final server = uri.host;
    if (server.isEmpty) {
      return LocalProxyParseResult(raw: raw, error: 'Mieru server is empty');
    }
    final query = uri.queryParametersAll;
    final fragment = _decodeFragment(uri.fragment);

    var baseName = fragment ?? '';
    if (baseName.isEmpty) baseName = query['profile']?.firstOrNull ?? '';
    if (baseName.isEmpty) baseName = server;

    final portList = query['port'];
    final protocolList = query['protocol'];
    if (portList == null ||
        protocolList == null ||
        portList.isEmpty ||
        portList.length != protocolList.length) {
      return LocalProxyParseResult(
        raw: raw,
        error: 'Invalid mierus port/protocol',
      );
    }

    String username = uri.userInfo;
    String password = '';
    final colonIndex = username.indexOf(':');
    if (colonIndex != -1) {
      password = username.substring(colonIndex + 1);
      username = username.substring(0, colonIndex);
    }
    final multiplexing = query['multiplexing']?.firstOrNull ?? '';
    final handshakeMode = query['handshake-mode']?.firstOrNull ?? '';
    final trafficPattern = query['traffic-pattern']?.firstOrNull ?? '';

    final port = portList.first;
    final protocol = protocolList.first;
    final name = '$baseName:$port/$protocol';

    final config = <String, dynamic>{
      'name': name,
      'type': 'mieru',
      'server': server,
      'transport': protocol,
      'udp': true,
      'username': username,
      'password': password,
    };
    if (port.contains('-')) {
      config['port-range'] = port;
    } else {
      final portNum = int.tryParse(port);
      if (portNum == null) {
        return LocalProxyParseResult(raw: raw, error: 'Invalid mierus port');
      }
      config['port'] = portNum;
    }
    if (multiplexing.isNotEmpty) config['multiplexing'] = multiplexing;
    if (handshakeMode.isNotEmpty) config['handshake-mode'] = handshakeMode;
    if (trafficPattern.isNotEmpty) config['traffic-pattern'] = trafficPattern;

    final warnings = <String>[];
    if (portList.length > 1) {
      warnings.add('Only the first port/protocol pair is imported');
    }

    return LocalProxyParseResult(
      raw: raw,
      proxy: LocalProxy(
        id: -1,
        name: name,
        type: 'mieru',
        config: config,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      warnings: warnings,
    );
  }
}

const localProxyParser = LocalProxyParser();
