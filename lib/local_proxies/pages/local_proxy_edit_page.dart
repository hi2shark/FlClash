import 'dart:convert';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/local_proxies/services/local_proxy_store.dart';
import 'package:fl_clash/models/local_proxy.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';

const manualProxyTypes = [
  'ss',
  'socks5',
  'ssh',
  'vless',
  'trojan',
  'anytls',
  'nowhere',
  'hysteria2',
];

const _manualProxyTypeSet = {
  'ss',
  'socks5',
  'ssh',
  'vless',
  'trojan',
  'anytls',
  'nowhere',
  'hysteria2',
};

const _ssCiphers = [
  'aes-128-gcm',
  'aes-192-gcm',
  'aes-256-gcm',
  'chacha20-ietf-poly1305',
  'xchacha20-ietf-poly1305',
  '2022-blake3-aes-128-gcm',
  '2022-blake3-aes-256-gcm',
  '2022-blake3-chacha20-poly1305',
  'none',
];

const _networks = ['tcp', 'ws', 'httpupgrade', 'http', 'h2', 'grpc', 'xhttp'];

const _clientFingerprints = [
  '',
  'chrome',
  'firefox',
  'safari',
  'ios',
  'android',
  'edge',
  'random',
];

const _vlessFlows = ['', 'xtls-rprx-vision'];

const _packetEncodings = ['', 'packet', 'xudp'];

const _xhttpModes = ['', 'auto', 'packet-up', 'stream-up', 'stream-one'];

const _httpMethods = ['GET', 'POST', 'PUT', 'HEAD'];

const _nowhereControlledFields = {
  'name',
  'type',
  'server',
  'port',
  'udp',
  'password',
  'key',
  'spec',
  'up',
  'down',
  'network',
  'net',
  'pool',
  'prewarm-on-start',
  'max-concurrent-dials',
  'warm-backoff-initial',
  'warm-backoff-max',
  'dialer-proxy',
  'sni',
  'alpn',
  'skip-cert-verify',
  'client-fingerprint',
  'fingerprint',
  'certificate',
  'private-key',
  'ech-opts',
  'congestion-controller',
  'cwnd',
  'bbr-profile',
  'reduce-rtt',
  'max-udp-relay-packet-size',
};

const _commonControlledFields = {'name', 'type', 'server', 'port', 'udp'};

const _transportControlledFields = {
  'network',
  'net',
  'servername',
  'sni',
  'tls',
  'skip-cert-verify',
  'alpn',
  'client-fingerprint',
  'fingerprint',
  'certificate',
  'private-key',
  'reality-opts',
  'ws-opts',
  'grpc-opts',
  'http-opts',
  'h2-opts',
  'xhttp-opts',
};

const _packetControlledFields = {'packet-encoding', 'xudp', 'packet-addr'};

const _ssControlledFields = {'cipher', 'password'};

const _socks5ControlledFields = {
  'username',
  'password',
  'tls',
  'skip-cert-verify',
  'fingerprint',
  'certificate',
  'private-key',
};

const _sshControlledFields = {
  'username',
  'password',
  'private-key',
  'private-key-passphrase',
  'host-key',
  'host-key-algorithms',
  'privateKey',
  'privateKeyPassphrase',
  'hostKey',
  'hostKeyAlgorithms',
};

const _vlessControlledFields = {
  ..._transportControlledFields,
  ..._packetControlledFields,
  'uuid',
  'flow',
  'encryption',
};

const _trojanControlledFields = {..._transportControlledFields, 'password'};

const _anyTlsControlledFields = {
  'password',
  'sni',
  'alpn',
  'client-fingerprint',
  'fingerprint',
  'certificate',
  'private-key',
  'skip-cert-verify',
  'ech-opts',
  'idle-session-check-interval',
  'idle-session-timeout',
  'min-idle-session',
};

const _hysteria2ControlledFields = {
  'password',
  'sni',
  'obfs',
  'obfs-password',
  'alpn',
  'fingerprint',
  'up',
  'down',
  'skip-cert-verify',
};

const _controlledFieldsByType = <String, Set<String>>{
  'ss': _ssControlledFields,
  'socks5': _socks5ControlledFields,
  'ssh': _sshControlledFields,
  'vless': _vlessControlledFields,
  'trojan': _trojanControlledFields,
  'anytls': _anyTlsControlledFields,
  'nowhere': _nowhereControlledFields,
  'hysteria2': _hysteria2ControlledFields,
};

class LocalProxyEditPage extends StatefulWidget {
  final LocalProxy? proxy;
  final String? initialType;

  const LocalProxyEditPage({super.key, this.proxy, this.initialType});

  @override
  State<LocalProxyEditPage> createState() => _LocalProxyEditPageState();
}

class _LocalProxyEditPageState extends State<LocalProxyEditPage> {
  late String _type;
  late final TextEditingController _nameController;
  late final TextEditingController _serverController;
  late final TextEditingController _portController;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  late final TextEditingController _cipherController;
  late final TextEditingController _uuidController;
  late final TextEditingController _sniController;
  late final TextEditingController _keyController;
  late final TextEditingController _alpnController;
  late final TextEditingController _clientFingerprintController;
  late final TextEditingController _fingerprintController;
  late final TextEditingController _certificateController;
  late final TextEditingController _privateKeyController;
  late final TextEditingController _privateKeyPassphraseController;
  late final TextEditingController _hostKeyController;
  late final TextEditingController _hostKeyAlgorithmsController;
  late final TextEditingController _echConfigController;
  late final TextEditingController _echQueryServerNameController;
  late final TextEditingController _idleSessionCheckIntervalController;
  late final TextEditingController _idleSessionTimeoutController;
  late final TextEditingController _minIdleSessionController;
  late final TextEditingController _poolController;
  late final TextEditingController _maxConcurrentDialsController;
  late final TextEditingController _warmBackoffInitialController;
  late final TextEditingController _warmBackoffMaxController;
  late final TextEditingController _dialerProxyController;
  late final TextEditingController _congestionControllerController;
  late final TextEditingController _cwndController;
  late final TextEditingController _obfsController;
  late final TextEditingController _obfsPasswordController;
  late final TextEditingController _hysteria2UpController;
  late final TextEditingController _hysteria2DownController;
  late final TextEditingController _encryptionController;
  late final TextEditingController _realityPublicKeyController;
  late final TextEditingController _realityShortIdController;
  late final TextEditingController _wsPathController;
  late final TextEditingController _wsHostController;
  late final TextEditingController _maxEarlyDataController;
  late final TextEditingController _earlyDataHeaderNameController;
  late final TextEditingController _grpcServiceNameController;
  late final TextEditingController _grpcUserAgentController;
  late final TextEditingController _httpPathController;
  late final TextEditingController _httpHostController;
  late final TextEditingController _h2PathController;
  late final TextEditingController _h2HostController;
  late final TextEditingController _xhttpPathController;
  late final TextEditingController _xhttpHostController;
  late final TextEditingController _xhttpHeadersController;

  late bool _tls;
  late bool _udp;
  late bool _udpWasSpecified;
  bool _udpTouched = false;
  late bool _skipCertVerify;
  late bool _echEnabled;
  late bool _prewarmOnStart;
  late bool _supportX25519Mlkem768;
  late bool _v2rayHttpUpgrade;
  late bool _v2rayHttpUpgradeFastOpen;
  late bool _xhttpAdvancedExpanded;
  late String _up;
  late String _down;
  late String _network;
  late String _security;
  late String _flow;
  late String _packetEncoding;
  late String _httpMethod;
  late String _xhttpMode;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final proxy = widget.proxy;
    final config = proxy?.config ?? {};
    _type = proxy?.type ?? widget.initialType ?? 'ss';
    _nameController = TextEditingController(text: proxy?.name ?? '');
    _serverController = TextEditingController(
      text: config['server']?.toString() ?? '',
    );
    _portController = TextEditingController(
      text: config['port']?.toString() ?? '',
    );
    _usernameController = TextEditingController(
      text: config['username']?.toString() ?? '',
    );
    _passwordController = TextEditingController(
      text: config['password']?.toString() ?? '',
    );
    _cipherController = TextEditingController(
      text: config['cipher']?.toString() ?? 'aes-256-gcm',
    );
    _uuidController = TextEditingController(
      text: config['uuid']?.toString() ?? '',
    );
    _sniController = TextEditingController(
      text: (config['servername'] ?? config['sni'])?.toString() ?? '',
    );
    final nowherePassword = config['password']?.toString() ?? '';
    _keyController = TextEditingController(
      text: nowherePassword.isNotEmpty
          ? nowherePassword
          : config['key']?.toString() ?? '',
    );
    _alpnController = TextEditingController(
      text: _type == 'nowhere'
          ? _firstAlpnToString(config['alpn'])
          : _alpnToString(config['alpn']),
    );
    _clientFingerprintController = TextEditingController(
      text: config['client-fingerprint']?.toString() ?? '',
    );
    _fingerprintController = TextEditingController(
      text: config['fingerprint']?.toString() ?? '',
    );
    _certificateController = TextEditingController(
      text: config['certificate']?.toString() ?? '',
    );
    _privateKeyController = TextEditingController(
      text:
          _sshConfigValue(config, 'private-key', 'privateKey')?.toString() ??
          '',
    );
    _privateKeyPassphraseController = TextEditingController(
      text:
          _sshConfigValue(
            config,
            'private-key-passphrase',
            'privateKeyPassphrase',
          )?.toString() ??
          '',
    );
    _hostKeyController = TextEditingController(
      text: _listToLines(_sshConfigValue(config, 'host-key', 'hostKey')),
    );
    _hostKeyAlgorithmsController = TextEditingController(
      text: _listToLines(
        _sshConfigValue(config, 'host-key-algorithms', 'hostKeyAlgorithms'),
      ),
    );
    final echOpts = config['ech-opts'] as Map?;
    _echEnabled = echOpts?['enable'] == true;
    _echConfigController = TextEditingController(
      text: echOpts?['config']?.toString() ?? '',
    );
    _echQueryServerNameController = TextEditingController(
      text: echOpts?['query-server-name']?.toString() ?? '',
    );
    _idleSessionCheckIntervalController = TextEditingController(
      text: config['idle-session-check-interval']?.toString() ?? '',
    );
    _idleSessionTimeoutController = TextEditingController(
      text: config['idle-session-timeout']?.toString() ?? '',
    );
    _minIdleSessionController = TextEditingController(
      text: config['min-idle-session']?.toString() ?? '',
    );
    _poolController = TextEditingController(
      text: config['pool']?.toString() ?? '',
    );
    _maxConcurrentDialsController = TextEditingController(
      text: config['max-concurrent-dials']?.toString() ?? '',
    );
    _warmBackoffInitialController = TextEditingController(
      text: config['warm-backoff-initial']?.toString() ?? '',
    );
    _warmBackoffMaxController = TextEditingController(
      text: config['warm-backoff-max']?.toString() ?? '',
    );
    _dialerProxyController = TextEditingController(
      text: config['dialer-proxy']?.toString() ?? '',
    );
    _congestionControllerController = TextEditingController(
      text: config['congestion-controller']?.toString() ?? '',
    );
    _cwndController = TextEditingController(
      text: config['cwnd']?.toString() ?? '',
    );
    _obfsController = TextEditingController(
      text: config['obfs']?.toString() ?? '',
    );
    _obfsPasswordController = TextEditingController(
      text: config['obfs-password']?.toString() ?? '',
    );
    _hysteria2UpController = TextEditingController(
      text: config['up']?.toString() ?? '',
    );
    _hysteria2DownController = TextEditingController(
      text: config['down']?.toString() ?? '',
    );
    _encryptionController = TextEditingController(
      text: config['encryption']?.toString() ?? '',
    );

    final realityOpts = config['reality-opts'] as Map? ?? {};
    _realityPublicKeyController = TextEditingController(
      text: realityOpts['public-key']?.toString() ?? '',
    );
    _realityShortIdController = TextEditingController(
      text: realityOpts['short-id']?.toString() ?? '',
    );
    _supportX25519Mlkem768 = realityOpts['support-x25519mlkem768'] == true;

    final wsOpts = config['ws-opts'] as Map? ?? {};
    final wsHeaders = wsOpts['headers'] as Map? ?? {};
    _wsPathController = TextEditingController(
      text: wsOpts['path']?.toString() ?? '',
    );
    _wsHostController = TextEditingController(
      text: (wsHeaders['Host'] ?? wsHeaders['host'])?.toString() ?? '',
    );
    _maxEarlyDataController = TextEditingController(
      text: wsOpts['max-early-data']?.toString() ?? '',
    );
    _earlyDataHeaderNameController = TextEditingController(
      text: wsOpts['early-data-header-name']?.toString() ?? '',
    );
    _v2rayHttpUpgrade = wsOpts['v2ray-http-upgrade'] == true;
    _v2rayHttpUpgradeFastOpen = wsOpts['v2ray-http-upgrade-fast-open'] == true;

    final grpcOpts = config['grpc-opts'] as Map? ?? {};
    _grpcServiceNameController = TextEditingController(
      text: grpcOpts['grpc-service-name']?.toString() ?? '',
    );
    _grpcUserAgentController = TextEditingController(
      text: grpcOpts['grpc-user-agent']?.toString() ?? '',
    );

    final httpOpts = config['http-opts'] as Map? ?? {};
    final httpHeaders = httpOpts['headers'] as Map? ?? {};
    final httpHost = httpHeaders['Host'] ?? httpHeaders['host'];
    _httpMethod = httpOpts['method']?.toString() ?? 'GET';
    if (!_httpMethods.contains(_httpMethod)) {
      _httpMethod = 'GET';
    }
    _httpPathController = TextEditingController(
      text: _listOrString(httpOpts['path']),
    );
    _httpHostController = TextEditingController(text: _listOrString(httpHost));

    final h2Opts = config['h2-opts'] as Map? ?? {};
    _h2PathController = TextEditingController(
      text: h2Opts['path']?.toString() ?? '',
    );
    _h2HostController = TextEditingController(
      text: _listOrString(h2Opts['host']),
    );

    final xhttpOpts = config['xhttp-opts'] as Map? ?? {};
    _xhttpPathController = TextEditingController(
      text: xhttpOpts['path']?.toString() ?? '',
    );
    _xhttpHostController = TextEditingController(
      text: xhttpOpts['host']?.toString() ?? '',
    );
    _xhttpMode = xhttpOpts['mode']?.toString() ?? '';
    if (!_xhttpModes.contains(_xhttpMode)) {
      _xhttpMode = '';
    }
    final xhttpHeaders = xhttpOpts['headers'] as Map?;
    _xhttpHeadersController = TextEditingController(
      text: xhttpHeaders == null
          ? ''
          : xhttpHeaders.entries.map((e) => '${e.key}: ${e.value}').join('\n'),
    );
    _xhttpAdvancedExpanded = false;

    _tls = config['tls'] == true;
    _udpWasSpecified = config.containsKey('udp');
    _udp = _udpWasSpecified ? config['udp'] == true : _type != 'socks5';
    _skipCertVerify = config['skip-cert-verify'] == true;
    _prewarmOnStart = config['prewarm-on-start'] == true;
    final legacyCarrier = (config['network'] ?? config['net'])?.toString();
    _up = config['up']?.toString() ?? legacyCarrier ?? 'udp';
    _down = config['down']?.toString() ?? legacyCarrier ?? 'udp';
    _network = config['network']?.toString() ?? 'tcp';
    if (!_networks.contains(_network)) {
      _network = 'tcp';
    }
    if (realityOpts.isNotEmpty ||
        (config['reality-opts'] is Map &&
            (config['reality-opts'] as Map).isNotEmpty)) {
      _security = 'reality';
      _tls = true;
    } else if (_tls) {
      _security = 'tls';
    } else {
      _security = 'none';
    }
    _flow = config['flow']?.toString() ?? '';
    if (!_vlessFlows.contains(_flow)) {
      _flow = '';
    }
    _packetEncoding = config['packet-encoding']?.toString() ?? '';
    if (config['xudp'] == true) {
      _packetEncoding = 'xudp';
    } else if (config['packet-addr'] == true) {
      _packetEncoding = 'packet';
    }
    if (!_packetEncodings.contains(_packetEncoding)) {
      _packetEncoding = '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _serverController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _cipherController.dispose();
    _uuidController.dispose();
    _sniController.dispose();
    _keyController.dispose();
    _alpnController.dispose();
    _clientFingerprintController.dispose();
    _fingerprintController.dispose();
    _certificateController.dispose();
    _privateKeyController.dispose();
    _privateKeyPassphraseController.dispose();
    _hostKeyController.dispose();
    _hostKeyAlgorithmsController.dispose();
    _echConfigController.dispose();
    _echQueryServerNameController.dispose();
    _idleSessionCheckIntervalController.dispose();
    _idleSessionTimeoutController.dispose();
    _minIdleSessionController.dispose();
    _poolController.dispose();
    _maxConcurrentDialsController.dispose();
    _warmBackoffInitialController.dispose();
    _warmBackoffMaxController.dispose();
    _dialerProxyController.dispose();
    _congestionControllerController.dispose();
    _cwndController.dispose();
    _obfsController.dispose();
    _obfsPasswordController.dispose();
    _hysteria2UpController.dispose();
    _hysteria2DownController.dispose();
    _encryptionController.dispose();
    _realityPublicKeyController.dispose();
    _realityShortIdController.dispose();
    _wsPathController.dispose();
    _wsHostController.dispose();
    _maxEarlyDataController.dispose();
    _earlyDataHeaderNameController.dispose();
    _grpcServiceNameController.dispose();
    _grpcUserAgentController.dispose();
    _httpPathController.dispose();
    _httpHostController.dispose();
    _h2PathController.dispose();
    _h2HostController.dispose();
    _xhttpPathController.dispose();
    _xhttpHostController.dispose();
    _xhttpHeadersController.dispose();
    super.dispose();
  }

  String _alpnToString(dynamic value) {
    if (value == null) return '';
    if (value is List) return value.join(', ');
    return value.toString();
  }

  String _firstAlpnToString(dynamic value) {
    if (value is List) {
      return value.isEmpty ? '' : value.first.toString();
    }
    return (value?.toString() ?? '').split(',').first;
  }

  String _listOrString(dynamic value) {
    if (value == null) return '';
    if (value is List) {
      return value.map((e) => e.toString()).join(', ');
    }
    return value.toString();
  }

  String _listToLines(dynamic value) {
    if (value == null) return '';
    if (value is List) {
      return value.map((e) => e.toString()).join('\n');
    }
    return value.toString();
  }

  dynamic _sshConfigValue(
    Map<String, dynamic> config,
    String canonicalKey,
    String legacyKey,
  ) {
    if (_type != 'ssh' || config.containsKey(canonicalKey)) {
      return config[canonicalKey];
    }
    return config[legacyKey];
  }

  List<String> _splitLines(String text, {bool preserveSpaces = false}) {
    return const LineSplitter()
        .convert(text)
        .map((line) => preserveSpaces ? line : line.trim())
        .where((line) => line.trim().isNotEmpty)
        .toList();
  }

  List<String> _splitCsv(String text) {
    return text
        .split(RegExp(r'[,，\s]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Map<String, String> _parseHeaders(String text) {
    final headers = <String, String>{};
    for (final line in text.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      final idx = trimmed.indexOf(':');
      if (idx <= 0) continue;
      headers[trimmed.substring(0, idx).trim()] = trimmed
          .substring(idx + 1)
          .trim();
    }
    return headers;
  }

  int? get _port {
    final value = int.tryParse(_portController.text);
    if (value == null || value < 1 || value > 65535) return null;
    return value;
  }

  int? _intOrNull(String text) {
    if (text.trim().isEmpty) return null;
    return int.tryParse(text.trim());
  }

  String? get _firstNowhereAlpn {
    final alpn = _alpnController.text;
    if (alpn.isEmpty) return null;
    return alpn.split(',').first;
  }

  bool _isValidNonNegativeInteger(TextEditingController controller) {
    final text = controller.text.trim();
    if (text.isEmpty) return true;
    final value = int.tryParse(text);
    return value != null && value >= 0;
  }

  bool _fitsNowhereField(String value) {
    try {
      return utf8.encode(value).length <= 255;
    } catch (_) {
      return false;
    }
  }

  bool get _isTransportProtocol => _type == 'vless' || _type == 'trojan';

  Set<String> _controlledFieldsForType(String type) {
    return _controlledFieldsByType[type] ?? const <String>{};
  }

  Map<String, dynamic> _buildConfig() {
    final base = widget.proxy == null
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(widget.proxy!.config);
    final fieldsToClear = <String>{
      ..._commonControlledFields,
      ..._controlledFieldsForType(_type),
    };
    final previousType = widget.proxy?.type;
    if (previousType != null && previousType != _type) {
      fieldsToClear.addAll(_controlledFieldsForType(previousType));
    }
    for (final field in fieldsToClear) {
      base.remove(field);
    }
    base.addAll({
      'name': _nameController.text.trim(),
      'type': _type,
      'server': _serverController.text.trim(),
      'port': _port,
    });
    final preserveMissingUdp =
        widget.proxy != null &&
        !_udpWasSpecified &&
        !_udpTouched &&
        previousType == _type;
    if (_type != 'ssh' && !preserveMissingUdp) {
      base['udp'] = _udp;
    }
    switch (_type) {
      case 'ss':
        base['cipher'] = _cipherController.text.trim();
        base['password'] = _passwordController.text;
      case 'socks5':
        if (_usernameController.text.trim().isNotEmpty) {
          base['username'] = _usernameController.text.trim();
        }
        if (_passwordController.text.isNotEmpty) {
          base['password'] = _passwordController.text;
        }
        base['tls'] = _tls;
        if (_tls) {
          base['skip-cert-verify'] = _skipCertVerify;
          if (_fingerprintController.text.trim().isNotEmpty) {
            base['fingerprint'] = _fingerprintController.text.trim();
          }
          if (_certificateController.text.trim().isNotEmpty) {
            base['certificate'] = _certificateController.text.trim();
          }
          if (_privateKeyController.text.trim().isNotEmpty) {
            base['private-key'] = _privateKeyController.text.trim();
          }
        }
      case 'ssh':
        base['username'] = _usernameController.text.trim();
        if (_passwordController.text.isNotEmpty) {
          base['password'] = _passwordController.text;
        }
        if (_privateKeyController.text.trim().isNotEmpty) {
          base['private-key'] = _privateKeyController.text.trim();
        }
        if (_privateKeyPassphraseController.text.isNotEmpty) {
          base['private-key-passphrase'] = _privateKeyPassphraseController.text;
        }
        final hostKeys = _splitLines(
          _hostKeyController.text,
          preserveSpaces: true,
        );
        if (hostKeys.isNotEmpty) {
          base['host-key'] = hostKeys;
        }
        final hostKeyAlgorithms = _splitCsv(_hostKeyAlgorithmsController.text);
        if (hostKeyAlgorithms.isNotEmpty) {
          base['host-key-algorithms'] = hostKeyAlgorithms;
        }
      case 'vless':
        base['uuid'] = _uuidController.text.trim();
        if (_flow.isNotEmpty) {
          base['flow'] = _flow;
        }
        if (_encryptionController.text.trim().isNotEmpty) {
          base['encryption'] = _encryptionController.text.trim();
        }
        _applyTransportAndTls(base, servernameKey: 'servername');
        _applyPacketEncoding(base);
      case 'trojan':
        base['password'] = _passwordController.text;
        _applyTransportAndTls(base, servernameKey: 'sni');
      case 'anytls':
        base['password'] = _passwordController.text;
        _applySni(base);
        _applyAlpn(base);
        _applyTlsOptions(base);
        _applyEch(base);
        final idleSessionCheckInterval = _intOrNull(
          _idleSessionCheckIntervalController.text,
        );
        if (idleSessionCheckInterval != null) {
          base['idle-session-check-interval'] = idleSessionCheckInterval;
        }
        final idleSessionTimeout = _intOrNull(
          _idleSessionTimeoutController.text,
        );
        if (idleSessionTimeout != null) {
          base['idle-session-timeout'] = idleSessionTimeout;
        }
        final minIdleSession = _intOrNull(_minIdleSessionController.text);
        if (minIdleSession != null) {
          base['min-idle-session'] = minIdleSession;
        }
      case 'nowhere':
        base['password'] = _keyController.text;
        _applySni(base);
        _applyNowhereAlpn(base);
        _applyTlsOptions(base);
        _applyEch(base);
        base['up'] = _up;
        base['down'] = _down;
        if (_up == 'tcp' && _down == 'tcp') {
          final pool = _intOrNull(_poolController.text);
          if (pool != null) {
            base['pool'] = pool;
          }
        }
        base['prewarm-on-start'] = _prewarmOnStart;
        final maxConcurrentDials = _intOrNull(
          _maxConcurrentDialsController.text,
        );
        if (maxConcurrentDials != null) {
          base['max-concurrent-dials'] = maxConcurrentDials;
        }
        final warmBackoffInitial = _intOrNull(
          _warmBackoffInitialController.text,
        );
        if (warmBackoffInitial != null) {
          base['warm-backoff-initial'] = warmBackoffInitial;
        }
        final warmBackoffMax = _intOrNull(_warmBackoffMaxController.text);
        if (warmBackoffMax != null) {
          base['warm-backoff-max'] = warmBackoffMax;
        }
        if (_dialerProxyController.text.trim().isNotEmpty) {
          base['dialer-proxy'] = _dialerProxyController.text.trim();
        }
        if (_congestionControllerController.text.trim().isNotEmpty) {
          base['congestion-controller'] = _congestionControllerController.text
              .trim();
        }
        final cwnd = _intOrNull(_cwndController.text);
        if (cwnd != null) {
          base['cwnd'] = cwnd;
        }
      case 'hysteria2':
        base['password'] = _passwordController.text;
        if (_sniController.text.trim().isNotEmpty) {
          base['sni'] = _sniController.text.trim();
        }
        if (_obfsController.text.trim().isNotEmpty) {
          base['obfs'] = _obfsController.text.trim();
        }
        if (_obfsPasswordController.text.isNotEmpty) {
          base['obfs-password'] = _obfsPasswordController.text;
        }
        _applyAlpn(base);
        if (_fingerprintController.text.trim().isNotEmpty) {
          base['fingerprint'] = _fingerprintController.text.trim();
        }
        if (_hysteria2UpController.text.trim().isNotEmpty) {
          base['up'] = _hysteria2UpController.text.trim();
        }
        if (_hysteria2DownController.text.trim().isNotEmpty) {
          base['down'] = _hysteria2DownController.text.trim();
        }
        base['skip-cert-verify'] = _skipCertVerify;
    }
    return base;
  }

  void _applyTransportAndTls(
    Map<String, dynamic> base, {
    required String servernameKey,
  }) {
    base['network'] = _network;
    final sni = _sniController.text.trim().isNotEmpty
        ? _sniController.text.trim()
        : _serverController.text.trim();
    base[servernameKey] = sni;

    final useTls = _security == 'tls' || _security == 'reality';
    base['tls'] = useTls;
    base['skip-cert-verify'] = _skipCertVerify;
    _applyAlpn(base);
    if (_clientFingerprintController.text.trim().isNotEmpty) {
      base['client-fingerprint'] = _clientFingerprintController.text.trim();
    }
    if (_fingerprintController.text.trim().isNotEmpty) {
      base['fingerprint'] = _fingerprintController.text.trim();
    }

    if (_security == 'reality') {
      final realityOpts = <String, dynamic>{};
      if (_realityPublicKeyController.text.trim().isNotEmpty) {
        realityOpts['public-key'] = _realityPublicKeyController.text.trim();
      }
      if (_realityShortIdController.text.trim().isNotEmpty) {
        realityOpts['short-id'] = _realityShortIdController.text.trim();
      }
      if (_supportX25519Mlkem768) {
        realityOpts['support-x25519mlkem768'] = true;
      }
      if (realityOpts.isNotEmpty) {
        base['reality-opts'] = realityOpts;
      }
    }

    switch (_network) {
      case 'ws':
      case 'httpupgrade':
        final wsOpts = <String, dynamic>{
          'path': _wsPathController.text.trim().isNotEmpty
              ? _wsPathController.text.trim()
              : '/',
        };
        if (_wsHostController.text.trim().isNotEmpty) {
          wsOpts['headers'] = {'Host': _wsHostController.text.trim()};
        }
        final maxEarly = _intOrNull(_maxEarlyDataController.text);
        if (maxEarly != null) {
          wsOpts['max-early-data'] = maxEarly;
        }
        if (_earlyDataHeaderNameController.text.trim().isNotEmpty) {
          wsOpts['early-data-header-name'] = _earlyDataHeaderNameController.text
              .trim();
        }
        if (_network == 'httpupgrade' || _v2rayHttpUpgrade) {
          wsOpts['v2ray-http-upgrade'] = true;
        }
        if (_v2rayHttpUpgradeFastOpen) {
          wsOpts['v2ray-http-upgrade-fast-open'] = true;
        }
        base['ws-opts'] = wsOpts;
      case 'grpc':
        final grpcOpts = <String, dynamic>{};
        if (_grpcServiceNameController.text.trim().isNotEmpty) {
          grpcOpts['grpc-service-name'] = _grpcServiceNameController.text
              .trim();
        }
        if (_grpcUserAgentController.text.trim().isNotEmpty) {
          grpcOpts['grpc-user-agent'] = _grpcUserAgentController.text.trim();
        }
        if (grpcOpts.isNotEmpty) {
          base['grpc-opts'] = grpcOpts;
        }
      case 'http':
        final httpOpts = <String, dynamic>{
          'method': _httpMethod,
          'path': _httpPathController.text.trim().isNotEmpty
              ? [_httpPathController.text.trim()]
              : ['/'],
        };
        if (_httpHostController.text.trim().isNotEmpty) {
          httpOpts['headers'] = {
            'Host': [_httpHostController.text.trim()],
          };
        }
        base['http-opts'] = httpOpts;
      case 'h2':
        final h2Opts = <String, dynamic>{
          'path': _h2PathController.text.trim().isNotEmpty
              ? _h2PathController.text.trim()
              : '/',
        };
        final hosts = _splitCsv(_h2HostController.text);
        if (hosts.isNotEmpty) {
          h2Opts['host'] = hosts;
        }
        base['h2-opts'] = h2Opts;
      case 'xhttp':
        final xhttpOpts = <String, dynamic>{};
        if (_xhttpPathController.text.trim().isNotEmpty) {
          xhttpOpts['path'] = _xhttpPathController.text.trim();
        }
        if (_xhttpHostController.text.trim().isNotEmpty) {
          xhttpOpts['host'] = _xhttpHostController.text.trim();
        }
        if (_xhttpMode.isNotEmpty) {
          xhttpOpts['mode'] = _xhttpMode;
        }
        final headers = _parseHeaders(_xhttpHeadersController.text);
        if (headers.isNotEmpty) {
          xhttpOpts['headers'] = headers;
        }
        if (xhttpOpts.isNotEmpty) {
          base['xhttp-opts'] = xhttpOpts;
        }
    }
  }

  void _applyPacketEncoding(Map<String, dynamic> base) {
    if (_packetEncoding.isEmpty) return;
    base['packet-encoding'] = _packetEncoding;
    if (_packetEncoding == 'xudp') {
      base['xudp'] = true;
    } else if (_packetEncoding == 'packet') {
      base['packet-addr'] = true;
    }
  }

  void _applySni(Map<String, dynamic> base) {
    if (_sniController.text.trim().isNotEmpty) {
      base['sni'] = _sniController.text.trim();
    }
  }

  void _applyAlpn(Map<String, dynamic> base) {
    final alpn = _splitCsv(_alpnController.text);
    if (alpn.isNotEmpty) {
      base['alpn'] = alpn;
    } else if (_alpnController.text.trim().isNotEmpty) {
      base['alpn'] = _alpnController.text.trim();
    }
  }

  void _applyNowhereAlpn(Map<String, dynamic> base) {
    final alpn = _firstNowhereAlpn;
    if (alpn != null) {
      base['alpn'] = [alpn];
    }
  }

  void _applyTlsOptions(Map<String, dynamic> base) {
    if (_clientFingerprintController.text.trim().isNotEmpty) {
      base['client-fingerprint'] = _clientFingerprintController.text.trim();
    }
    if (_fingerprintController.text.trim().isNotEmpty) {
      base['fingerprint'] = _fingerprintController.text.trim();
    }
    if (_certificateController.text.trim().isNotEmpty) {
      base['certificate'] = _certificateController.text.trim();
    }
    if (_privateKeyController.text.trim().isNotEmpty) {
      base['private-key'] = _privateKeyController.text.trim();
    }
    base['skip-cert-verify'] = _skipCertVerify;
  }

  void _applyEch(Map<String, dynamic> base) {
    if (!_echEnabled) return;
    final echOpts = <String, dynamic>{'enable': true};
    if (_echConfigController.text.trim().isNotEmpty) {
      echOpts['config'] = _echConfigController.text.trim();
    }
    if (_echQueryServerNameController.text.trim().isNotEmpty) {
      echOpts['query-server-name'] = _echQueryServerNameController.text.trim();
    }
    base['ech-opts'] = echOpts;
  }

  String? _validateCommon() {
    final appLocalizations = context.appLocalizations;
    if (_nameController.text.trim().isEmpty) {
      return appLocalizations.localProxyNameEmpty;
    }
    if (_serverController.text.trim().isEmpty) {
      return appLocalizations.localProxyServerEmpty;
    }
    if (_port == null) {
      return appLocalizations.localProxyPortInvalid;
    }
    switch (_type) {
      case 'ss':
        if (_cipherController.text.trim().isEmpty ||
            _passwordController.text.isEmpty) {
          return appLocalizations.localProxySsAuthEmpty;
        }
      case 'socks5':
        if (_passwordController.text.isNotEmpty &&
            _usernameController.text.trim().isEmpty) {
          return appLocalizations.localProxyUsernameEmpty;
        }
        if (_tls) {
          final hasCertificate = _certificateController.text.trim().isNotEmpty;
          final hasPrivateKey = _privateKeyController.text.trim().isNotEmpty;
          if (hasCertificate != hasPrivateKey) {
            return appLocalizations.localProxyTlsKeyPairRequired;
          }
        }
      case 'ssh':
        if (_usernameController.text.trim().isEmpty) {
          return appLocalizations.localProxyUsernameEmpty;
        }
        final hasPrivateKey = _privateKeyController.text.trim().isNotEmpty;
        if (_privateKeyPassphraseController.text.isNotEmpty && !hasPrivateKey) {
          return appLocalizations.localProxySshPassphraseWithoutKey;
        }
        if (_passwordController.text.isEmpty && !hasPrivateKey) {
          return appLocalizations.localProxySshAuthEmpty;
        }
      case 'vless':
        if (_uuidController.text.trim().isEmpty) {
          return appLocalizations.localProxyUuidEmpty;
        }
      case 'trojan':
        if (_passwordController.text.isEmpty) {
          return appLocalizations.localProxyPasswordEmpty;
        }
      case 'anytls':
        if (_passwordController.text.isEmpty) {
          return appLocalizations.localProxyAnyTlsPasswordEmpty;
        }
      case 'nowhere':
        final sharedKey = _keyController.text;
        if (sharedKey.isEmpty) {
          return appLocalizations.localProxyNowhereKeyEmpty;
        }
        final firstAlpn = _firstNowhereAlpn;
        if (!_fitsNowhereField(sharedKey) ||
            (firstAlpn != null && !_fitsNowhereField(firstAlpn))) {
          return appLocalizations.localProxyNowhereInputTooLong;
        }
        if (!['tcp', 'udp'].contains(_up) || !['tcp', 'udp'].contains(_down)) {
          return appLocalizations.localProxyCarrierInvalid;
        }
        if (_up == 'tcp' && _down == 'tcp') {
          final pool = _intOrNull(_poolController.text);
          if (_poolController.text.trim().isNotEmpty &&
              (pool == null || pool < 0 || pool > 9)) {
            return appLocalizations.localProxyPoolInvalid;
          }
        }
        if (!_isValidNonNegativeInteger(_maxConcurrentDialsController) ||
            !_isValidNonNegativeInteger(_warmBackoffInitialController) ||
            !_isValidNonNegativeInteger(_warmBackoffMaxController) ||
            !_isValidNonNegativeInteger(_cwndController)) {
          return appLocalizations.localProxyNowhereAdvancedInvalid;
        }
        final warmBackoffInitial = _intOrNull(
          _warmBackoffInitialController.text,
        );
        final warmBackoffMax = _intOrNull(_warmBackoffMaxController.text);
        final effectiveWarmBackoffInitial =
            warmBackoffInitial == null || warmBackoffInitial == 0
            ? 1
            : warmBackoffInitial;
        final effectiveWarmBackoffMax =
            warmBackoffMax == null || warmBackoffMax == 0 ? 30 : warmBackoffMax;
        if (effectiveWarmBackoffInitial > effectiveWarmBackoffMax) {
          return appLocalizations.localProxyNowhereAdvancedInvalid;
        }
      case 'hysteria2':
        if (_passwordController.text.isEmpty) {
          return appLocalizations.localProxyPasswordEmpty;
        }
    }
    return null;
  }

  Future<void> _handleSave() async {
    final error = _validateCommon();
    if (error != null) {
      globalState.showNotifier(error);
      return;
    }
    final name = _nameController.text.trim();
    final finalName = widget.proxy == null
        ? localProxyStore.uniqueName(name.isEmpty ? 'Local Proxy' : name)
        : name;
    final config = _buildConfig();
    config['name'] = finalName;
    final now = DateTime.now();
    final proxy = LocalProxy(
      id: widget.proxy?.id ?? snowflake.id,
      name: finalName,
      type: _type,
      enabled: widget.proxy?.enabled ?? true,
      config: config,
      tags: widget.proxy?.tags ?? const [],
      sortIndex: widget.proxy?.sortIndex,
      createdAt: widget.proxy?.createdAt ?? now,
      updatedAt: now,
    );
    if (widget.proxy == null) {
      await localProxyStore.add(proxy);
    } else {
      await localProxyStore.update(proxy);
    }
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  String _protocolLabel() {
    final l10n = context.appLocalizations;
    return switch (_type) {
      'ss' => l10n.ss,
      'socks5' => l10n.socks5,
      'ssh' => l10n.ssh,
      'vless' => l10n.vless,
      'trojan' => l10n.trojan,
      'anytls' => l10n.anytls,
      'nowhere' => l10n.nowhere,
      'hysteria2' => l10n.hysteria2,
      _ => _type.toUpperCase(),
    };
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
    int? maxLines,
    int? minLines,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines ?? 1,
      minLines: minLines,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    final effective = items.any((e) => e.value == value)
        ? value
        : (items.first.value ?? '');
    return DropdownButtonFormField<String>(
      initialValue: effective,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: items,
      onChanged: onChanged,
    );
  }

  Widget _buildCommonFields() {
    final appLocalizations = context.appLocalizations;
    return Column(
      children: [
        _buildTextField(_nameController, appLocalizations.name),
        const SizedBox(height: 16),
        _buildTextField(_serverController, appLocalizations.server),
        const SizedBox(height: 16),
        _buildTextField(
          _portController,
          appLocalizations.port,
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  Widget _buildAuthFields() {
    final appLocalizations = context.appLocalizations;
    return switch (_type) {
      'ss' => Column(
        children: [
          _buildDropdown(
            label: appLocalizations.cipher,
            value: _cipherController.text,
            items: [
              for (final cipher in _ssCiphers)
                DropdownMenuItem(value: cipher, child: Text(cipher)),
              if (!_ssCiphers.contains(_cipherController.text) &&
                  _cipherController.text.isNotEmpty)
                DropdownMenuItem(
                  value: _cipherController.text,
                  child: Text(_cipherController.text),
                ),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() => _cipherController.text = value);
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(_passwordController, appLocalizations.password),
        ],
      ),
      'socks5' => Column(
        children: [
          _buildTextField(_usernameController, appLocalizations.username),
          const SizedBox(height: 16),
          _buildTextField(_passwordController, appLocalizations.password),
        ],
      ),
      'ssh' => Column(
        children: [
          _buildTextField(_usernameController, appLocalizations.username),
          const SizedBox(height: 16),
          _buildTextField(_passwordController, appLocalizations.password),
          const SizedBox(height: 16),
          _buildTextField(
            _privateKeyController,
            appLocalizations.privateKey,
            minLines: 3,
            maxLines: 8,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            _privateKeyPassphraseController,
            appLocalizations.privateKeyPassphrase,
          ),
        ],
      ),
      'vless' => Column(
        children: [
          _buildTextField(_uuidController, appLocalizations.uuid),
          const SizedBox(height: 16),
          _buildDropdown(
            label: appLocalizations.flow,
            value: _flow,
            items: [
              DropdownMenuItem(
                value: '',
                child: Text(appLocalizations.noneOption),
              ),
              const DropdownMenuItem(
                value: 'xtls-rprx-vision',
                child: Text('xtls-rprx-vision'),
              ),
            ],
            onChanged: (value) => setState(() => _flow = value ?? ''),
          ),
          const SizedBox(height: 16),
          _buildTextField(_encryptionController, appLocalizations.encryption),
        ],
      ),
      'trojan' || 'anytls' || 'hysteria2' => _buildTextField(
        _passwordController,
        appLocalizations.password,
      ),
      'nowhere' => _buildTextField(
        _keyController,
        appLocalizations.nowhereShareKey,
      ),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _buildTransportFields() {
    final appLocalizations = context.appLocalizations;
    if (_type == 'socks5') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListItem.switchItem(
            title: Text(appLocalizations.tls),
            delegate: SwitchDelegate<bool>(
              value: _tls,
              onChanged: (value) => setState(() => _tls = value),
            ),
          ),
          if (_tls) ...[
            ListItem.switchItem(
              title: Text(appLocalizations.skipCertVerify),
              delegate: SwitchDelegate<bool>(
                value: _skipCertVerify,
                onChanged: (value) => setState(() => _skipCertVerify = value),
              ),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              _fingerprintController,
              appLocalizations.fingerprint,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              _certificateController,
              appLocalizations.certificate,
              minLines: 3,
              maxLines: 6,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              _privateKeyController,
              appLocalizations.privateKey,
              minLines: 3,
              maxLines: 8,
            ),
          ],
        ],
      );
    }
    if (_type == 'ssh') {
      return Column(
        children: [
          _buildTextField(
            _hostKeyController,
            appLocalizations.hostKey,
            minLines: 3,
            maxLines: 8,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            _hostKeyAlgorithmsController,
            appLocalizations.hostKeyAlgorithms,
            minLines: 2,
            maxLines: 6,
          ),
        ],
      );
    }
    if (_isTransportProtocol) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDropdown(
            label: appLocalizations.network,
            value: _network,
            items: [
              for (final n in _networks)
                DropdownMenuItem(value: n, child: Text(n)),
            ],
            onChanged: (value) => setState(() => _network = value ?? 'tcp'),
          ),
          const SizedBox(height: 16),
          _buildDropdown(
            label: appLocalizations.security,
            value: _security,
            items: [
              DropdownMenuItem(
                value: 'none',
                child: Text(appLocalizations.noneOption),
              ),
              DropdownMenuItem(value: 'tls', child: Text(appLocalizations.tls)),
              DropdownMenuItem(
                value: 'reality',
                child: Text(appLocalizations.reality),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _security = value ?? 'none';
                _tls = _security != 'none';
              });
            },
          ),
          if (_security != 'none') ...[
            const SizedBox(height: 16),
            _buildTextField(
              _sniController,
              _type == 'vless'
                  ? appLocalizations.servername
                  : appLocalizations.sni,
            ),
            const SizedBox(height: 16),
            _buildTextField(_alpnController, appLocalizations.alpn),
            const SizedBox(height: 16),
            _buildDropdown(
              label: appLocalizations.clientFingerprint,
              value: _clientFingerprintController.text,
              items: [
                for (final fp in _clientFingerprints)
                  DropdownMenuItem(
                    value: fp,
                    child: Text(fp.isEmpty ? appLocalizations.noneOption : fp),
                  ),
                if (!_clientFingerprints.contains(
                      _clientFingerprintController.text,
                    ) &&
                    _clientFingerprintController.text.isNotEmpty)
                  DropdownMenuItem(
                    value: _clientFingerprintController.text,
                    child: Text(_clientFingerprintController.text),
                  ),
              ],
              onChanged: (value) {
                setState(() => _clientFingerprintController.text = value ?? '');
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              _fingerprintController,
              appLocalizations.fingerprint,
            ),
            ListItem.switchItem(
              title: Text(appLocalizations.skipCertVerify),
              delegate: SwitchDelegate<bool>(
                value: _skipCertVerify,
                onChanged: (value) => setState(() => _skipCertVerify = value),
              ),
            ),
          ],
          if (_security == 'reality') ...[
            const SizedBox(height: 8),
            Text(appLocalizations.reality, style: context.textTheme.titleSmall),
            const SizedBox(height: 12),
            _buildTextField(
              _realityPublicKeyController,
              appLocalizations.realityPublicKey,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              _realityShortIdController,
              appLocalizations.realityShortId,
            ),
            ListItem.switchItem(
              title: Text(appLocalizations.supportX25519Mlkem768),
              delegate: SwitchDelegate<bool>(
                value: _supportX25519Mlkem768,
                onChanged: (value) =>
                    setState(() => _supportX25519Mlkem768 = value),
              ),
            ),
          ],
          if (_network == 'ws' || _network == 'httpupgrade') ...[
            const SizedBox(height: 8),
            _buildTextField(_wsPathController, appLocalizations.wsPath),
            const SizedBox(height: 16),
            _buildTextField(_wsHostController, appLocalizations.wsHost),
            const SizedBox(height: 16),
            _buildTextField(
              _maxEarlyDataController,
              appLocalizations.maxEarlyData,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              _earlyDataHeaderNameController,
              appLocalizations.earlyDataHeaderName,
            ),
            if (_network == 'ws')
              ListItem.switchItem(
                title: const Text('v2ray-http-upgrade'),
                delegate: SwitchDelegate<bool>(
                  value: _v2rayHttpUpgrade,
                  onChanged: (value) =>
                      setState(() => _v2rayHttpUpgrade = value),
                ),
              ),
            ListItem.switchItem(
              title: const Text('v2ray-http-upgrade-fast-open'),
              delegate: SwitchDelegate<bool>(
                value: _v2rayHttpUpgradeFastOpen,
                onChanged: (value) =>
                    setState(() => _v2rayHttpUpgradeFastOpen = value),
              ),
            ),
          ],
          if (_network == 'grpc') ...[
            const SizedBox(height: 8),
            _buildTextField(
              _grpcServiceNameController,
              appLocalizations.grpcServiceName,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              _grpcUserAgentController,
              appLocalizations.grpcUserAgent,
            ),
          ],
          if (_network == 'http') ...[
            const SizedBox(height: 8),
            _buildDropdown(
              label: appLocalizations.httpMethod,
              value: _httpMethod,
              items: [
                for (final m in _httpMethods)
                  DropdownMenuItem(value: m, child: Text(m)),
              ],
              onChanged: (value) =>
                  setState(() => _httpMethod = value ?? 'GET'),
            ),
            const SizedBox(height: 16),
            _buildTextField(_httpPathController, appLocalizations.wsPath),
            const SizedBox(height: 16),
            _buildTextField(_httpHostController, appLocalizations.wsHost),
          ],
          if (_network == 'h2') ...[
            const SizedBox(height: 8),
            _buildTextField(_h2PathController, appLocalizations.wsPath),
            const SizedBox(height: 16),
            _buildTextField(_h2HostController, appLocalizations.wsHost),
          ],
          if (_network == 'xhttp') ...[
            const SizedBox(height: 8),
            _buildTextField(_xhttpPathController, appLocalizations.wsPath),
            const SizedBox(height: 16),
            _buildTextField(_xhttpHostController, appLocalizations.wsHost),
            const SizedBox(height: 16),
            _buildDropdown(
              label: appLocalizations.xhttpMode,
              value: _xhttpMode,
              items: [
                for (final m in _xhttpModes)
                  DropdownMenuItem(
                    value: m,
                    child: Text(m.isEmpty ? appLocalizations.noneOption : m),
                  ),
              ],
              onChanged: (value) => setState(() => _xhttpMode = value ?? ''),
            ),
            const SizedBox(height: 8),
            ExpansionTile(
              title: Text(appLocalizations.xhttpAdvanced),
              initiallyExpanded: _xhttpAdvancedExpanded,
              onExpansionChanged: (v) =>
                  setState(() => _xhttpAdvancedExpanded = v),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildTextField(
                    _xhttpHeadersController,
                    'Headers (Key: Value)',
                    minLines: 3,
                    maxLines: 6,
                  ),
                ),
              ],
            ),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_type == 'anytls')
          _buildTextField(_sniController, appLocalizations.sni),
        if (_type == 'nowhere') ...[
          Row(
            children: [
              Expanded(
                child: _buildCarrierDropdown(
                  label: appLocalizations.up,
                  value: _up,
                  onChanged: (value) => setState(() => _up = value ?? 'udp'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildCarrierDropdown(
                  label: appLocalizations.down,
                  value: _down,
                  onChanged: (value) => setState(() => _down = value ?? 'udp'),
                ),
              ),
            ],
          ),
          if (_up == 'tcp' && _down == 'tcp') ...[
            const SizedBox(height: 16),
            _buildTextField(
              _poolController,
              appLocalizations.pool,
              keyboardType: TextInputType.number,
            ),
          ],
          const SizedBox(height: 16),
          _buildTextField(_sniController, appLocalizations.sni),
          ListItem.switchItem(
            title: Text(appLocalizations.skipCertVerify),
            delegate: SwitchDelegate<bool>(
              value: _skipCertVerify,
              onChanged: (value) => setState(() => _skipCertVerify = value),
            ),
          ),
        ],
        if (_type == 'hysteria2') ...[
          _buildTextField(_sniController, appLocalizations.sni),
          const SizedBox(height: 16),
          _buildTextField(_obfsController, appLocalizations.obfs),
          const SizedBox(height: 16),
          _buildTextField(
            _obfsPasswordController,
            appLocalizations.obfsPassword,
          ),
          const SizedBox(height: 16),
          _buildTextField(_alpnController, appLocalizations.alpn),
          const SizedBox(height: 16),
          _buildTextField(_fingerprintController, appLocalizations.fingerprint),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  _hysteria2UpController,
                  appLocalizations.up,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  _hysteria2DownController,
                  appLocalizations.down,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildCarrierDropdown({
    required String label,
    required String value,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(value: 'tcp', child: Text('TCP')),
        DropdownMenuItem(value: 'udp', child: Text('UDP')),
      ],
      onChanged: onChanged,
    );
  }

  Widget _buildTlsFields() {
    if (_type != 'anytls' && _type != 'nowhere') {
      return const SizedBox.shrink();
    }
    final appLocalizations = context.appLocalizations;
    return Column(
      children: [
        _buildTextField(_alpnController, appLocalizations.alpn),
        const SizedBox(height: 16),
        _buildDropdown(
          label: appLocalizations.clientFingerprint,
          value: _clientFingerprintController.text,
          items: [
            for (final fp in _clientFingerprints)
              DropdownMenuItem(
                value: fp,
                child: Text(fp.isEmpty ? appLocalizations.noneOption : fp),
              ),
            if (!_clientFingerprints.contains(
                  _clientFingerprintController.text,
                ) &&
                _clientFingerprintController.text.isNotEmpty)
              DropdownMenuItem(
                value: _clientFingerprintController.text,
                child: Text(_clientFingerprintController.text),
              ),
          ],
          onChanged: (value) {
            setState(() => _clientFingerprintController.text = value ?? '');
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(_fingerprintController, appLocalizations.fingerprint),
        const SizedBox(height: 16),
        _buildTextField(
          _certificateController,
          appLocalizations.certificate,
          minLines: 3,
          maxLines: 6,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          _privateKeyController,
          appLocalizations.privateKey,
          minLines: 3,
          maxLines: 6,
        ),
      ],
    );
  }

  Widget _buildEchFields() {
    if (_type != 'anytls' && _type != 'nowhere') {
      return const SizedBox.shrink();
    }
    final appLocalizations = context.appLocalizations;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListItem.switchItem(
          title: Text(appLocalizations.ech),
          delegate: SwitchDelegate<bool>(
            value: _echEnabled,
            onChanged: (value) => setState(() => _echEnabled = value),
          ),
        ),
        if (_echEnabled) ...[
          const SizedBox(height: 12),
          _buildTextField(
            _echConfigController,
            appLocalizations.echConfig,
            minLines: 3,
            maxLines: 6,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            _echQueryServerNameController,
            appLocalizations.echQueryServerName,
          ),
        ],
      ],
    );
  }

  Widget _buildAdvancedFields() {
    final appLocalizations = context.appLocalizations;
    return Column(
      children: [
        ListItem.switchItem(
          title: Text(appLocalizations.udp),
          delegate: SwitchDelegate<bool>(
            value: _udp,
            onChanged: (value) => setState(() {
              _udp = value;
              _udpTouched = true;
            }),
          ),
        ),
        if (_type == 'vless') ...[
          const SizedBox(height: 8),
          _buildDropdown(
            label: appLocalizations.packetEncoding,
            value: _packetEncoding,
            items: [
              DropdownMenuItem(
                value: '',
                child: Text(appLocalizations.noneOption),
              ),
              const DropdownMenuItem(value: 'packet', child: Text('packet')),
              const DropdownMenuItem(value: 'xudp', child: Text('xudp')),
            ],
            onChanged: (value) => setState(() => _packetEncoding = value ?? ''),
          ),
        ],
        if (_type == 'trojan' || _type == 'anytls' || _type == 'hysteria2')
          ListItem.switchItem(
            title: Text(appLocalizations.skipCertVerify),
            delegate: SwitchDelegate<bool>(
              value: _skipCertVerify,
              onChanged: (value) => setState(() => _skipCertVerify = value),
            ),
          ),
        if (_type == 'anytls' || _type == 'nowhere') ...[
          const SizedBox(height: 16),
          _buildProtocolSpecificAdvancedFields(),
        ],
      ],
    );
  }

  Widget _buildProtocolSpecificAdvancedFields() {
    final appLocalizations = context.appLocalizations;
    return switch (_type) {
      'anytls' => Column(
        children: [
          _buildTextField(
            _idleSessionCheckIntervalController,
            appLocalizations.idleSessionCheckInterval,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            _idleSessionTimeoutController,
            appLocalizations.idleSessionTimeout,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            _minIdleSessionController,
            appLocalizations.minIdleSession,
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      'nowhere' => Column(
        children: [
          ListItem.switchItem(
            title: Text(appLocalizations.prewarmOnStart),
            delegate: SwitchDelegate<bool>(
              value: _prewarmOnStart,
              onChanged: (value) => setState(() => _prewarmOnStart = value),
            ),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            _maxConcurrentDialsController,
            appLocalizations.maxConcurrentDials,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            _warmBackoffInitialController,
            appLocalizations.warmBackoffInitial,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            _warmBackoffMaxController,
            appLocalizations.warmBackoffMax,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          _buildTextField(_dialerProxyController, appLocalizations.dialerProxy),
          const SizedBox(height: 16),
          _buildTextField(
            _congestionControllerController,
            appLocalizations.congestionController,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            _cwndController,
            appLocalizations.cwnd,
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      _ => const SizedBox.shrink(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    final isManualEditable =
        widget.proxy == null || _manualProxyTypeSet.contains(_type);
    if (!isManualEditable) {
      return CommonScaffold(
        title: appLocalizations.editLocalProxy,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.info_outline, size: 48),
                const SizedBox(height: 16),
                Text(
                  '${_type.toUpperCase()}: '
                  '${appLocalizations.localProxyProtocolReimportOnly}',
                  textAlign: TextAlign.center,
                  style: context.textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ),
      );
    }
    return CommonScaffold(
      title: widget.proxy == null
          ? appLocalizations.addLocalProxy
          : appLocalizations.editLocalProxy,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: _handleSave,
        label: Text(appLocalizations.save),
        icon: const Icon(Icons.save),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16).copyWith(bottom: 88),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Chip(
                avatar: const Icon(Icons.shield_outlined, size: 18),
                label: Text(_protocolLabel()),
              ),
            ),
            const SizedBox(height: 16),
            _buildCommonFields(),
            const SizedBox(height: 24),
            Text(
              appLocalizations.protocolAuth,
              style: context.textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            _buildAuthFields(),
            const SizedBox(height: 24),
            Text(
              appLocalizations.transportSettings,
              style: context.textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            _buildTransportFields(),
            if (_type == 'anytls') ...[
              const SizedBox(height: 24),
              Text(appLocalizations.tls, style: context.textTheme.titleSmall),
              const SizedBox(height: 12),
              _buildTlsFields(),
              const SizedBox(height: 8),
              ExpansionTile(
                initiallyExpanded: false,
                tilePadding: EdgeInsets.zero,
                title: Text(
                  appLocalizations.ech,
                  style: context.textTheme.titleSmall,
                ),
                children: [_buildEchFields(), const SizedBox(height: 8)],
              ),
            ],
            if (_type == 'nowhere') ...[
              const SizedBox(height: 24),
              ExpansionTile(
                initiallyExpanded: false,
                tilePadding: EdgeInsets.zero,
                title: Text(
                  appLocalizations.tls,
                  style: context.textTheme.titleSmall,
                ),
                children: [
                  const SizedBox(height: 12),
                  _buildTlsFields(),
                  const SizedBox(height: 8),
                  ExpansionTile(
                    initiallyExpanded: false,
                    tilePadding: EdgeInsets.zero,
                    title: Text(
                      appLocalizations.ech,
                      style: context.textTheme.titleSmall,
                    ),
                    children: [_buildEchFields(), const SizedBox(height: 8)],
                  ),
                ],
              ),
            ],
            if (_type != 'ssh') ...[
              const SizedBox(height: 8),
              ExpansionTile(
                initiallyExpanded: false,
                tilePadding: EdgeInsets.zero,
                title: Text(
                  appLocalizations.advancedSettings,
                  style: context.textTheme.titleSmall,
                ),
                children: [_buildAdvancedFields(), const SizedBox(height: 8)],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
