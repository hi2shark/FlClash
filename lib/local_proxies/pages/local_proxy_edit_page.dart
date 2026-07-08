import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/local_proxies/services/local_proxy_store.dart';
import 'package:fl_clash/models/local_proxy.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';

class LocalProxyEditPage extends StatefulWidget {
  final LocalProxy? proxy;

  const LocalProxyEditPage({super.key, this.proxy});

  @override
  State<LocalProxyEditPage> createState() => _LocalProxyEditPageState();
}

const _manualProxyTypes = {
  'ss',
  'vless',
  'trojan',
  'anytls',
  'nowhere',
  'hysteria2',
};

class _LocalProxyEditPageState extends State<LocalProxyEditPage> {
  late String _type;
  late final TextEditingController _nameController;
  late final TextEditingController _serverController;
  late final TextEditingController _portController;
  late final TextEditingController _passwordController;
  late final TextEditingController _cipherController;
  late final TextEditingController _uuidController;
  late final TextEditingController _sniController;
  late final TextEditingController _keyController;
  late final TextEditingController _specController;
  late final TextEditingController _alpnController;
  late final TextEditingController _clientFingerprintController;
  late final TextEditingController _fingerprintController;
  late final TextEditingController _certificateController;
  late final TextEditingController _privateKeyController;
  late final TextEditingController _echConfigController;
  late final TextEditingController _idleSessionCheckIntervalController;
  late final TextEditingController _idleSessionTimeoutController;
  late final TextEditingController _minIdleSessionController;
  late final TextEditingController _poolController;
  late final TextEditingController _congestionControllerController;
  late final TextEditingController _cwndController;
  late final TextEditingController _bbrProfileController;
  late final TextEditingController _maxUdpRelayPacketSizeController;
  late final TextEditingController _obfsController;
  late final TextEditingController _obfsPasswordController;
  late final TextEditingController _hysteria2UpController;
  late final TextEditingController _hysteria2DownController;

  late bool _tls;
  late bool _udp;
  late bool _skipCertVerify;
  late bool _echEnabled;
  late bool _reduceRtt;
  late String _up;
  late String _down;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final proxy = widget.proxy;
    final config = proxy?.config ?? {};
    _type = proxy?.type ?? 'ss';
    _nameController = TextEditingController(text: proxy?.name ?? '');
    _serverController = TextEditingController(
      text: config['server']?.toString() ?? '',
    );
    _portController = TextEditingController(
      text: config['port']?.toString() ?? '',
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
    _keyController = TextEditingController(
      text: config['key']?.toString() ?? config['password']?.toString() ?? '',
    );
    _specController = TextEditingController(
      text: config['spec']?.toString() ?? '',
    );
    _alpnController = TextEditingController(
      text: _alpnToString(config['alpn']),
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
      text: config['private-key']?.toString() ?? '',
    );
    final echOpts = config['ech-opts'] as Map?;
    _echEnabled = echOpts?['enable'] == true;
    _echConfigController = TextEditingController(
      text: echOpts?['config']?.toString() ?? '',
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
    _congestionControllerController = TextEditingController(
      text: config['congestion-controller']?.toString() ?? '',
    );
    _cwndController = TextEditingController(
      text: config['cwnd']?.toString() ?? '',
    );
    _bbrProfileController = TextEditingController(
      text: config['bbr-profile']?.toString() ?? '',
    );
    _maxUdpRelayPacketSizeController = TextEditingController(
      text: config['max-udp-relay-packet-size']?.toString() ?? '',
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
    _tls = config['tls'] == true;
    _udp = config['udp'] != false;
    _skipCertVerify = config['skip-cert-verify'] == true;
    _reduceRtt = config['reduce-rtt'] == true;
    _up = config['up']?.toString() ?? 'udp';
    _down = config['down']?.toString() ?? 'udp';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _serverController.dispose();
    _portController.dispose();
    _passwordController.dispose();
    _cipherController.dispose();
    _uuidController.dispose();
    _sniController.dispose();
    _keyController.dispose();
    _specController.dispose();
    _alpnController.dispose();
    _clientFingerprintController.dispose();
    _fingerprintController.dispose();
    _certificateController.dispose();
    _privateKeyController.dispose();
    _echConfigController.dispose();
    _idleSessionCheckIntervalController.dispose();
    _idleSessionTimeoutController.dispose();
    _minIdleSessionController.dispose();
    _poolController.dispose();
    _congestionControllerController.dispose();
    _cwndController.dispose();
    _bbrProfileController.dispose();
    _maxUdpRelayPacketSizeController.dispose();
    _obfsController.dispose();
    _obfsPasswordController.dispose();
    _hysteria2UpController.dispose();
    _hysteria2DownController.dispose();
    super.dispose();
  }

  String _alpnToString(dynamic value) {
    if (value == null) return '';
    if (value is List) return value.join(', ');
    return value.toString();
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

  Map<String, dynamic> _buildConfig() {
    final base = <String, dynamic>{
      'name': _nameController.text.trim(),
      'type': _type,
      'server': _serverController.text.trim(),
      'port': _port,
      'udp': _udp,
    };
    switch (_type) {
      case 'ss':
        base['cipher'] = _cipherController.text.trim();
        base['password'] = _passwordController.text;
      case 'vless':
        base['uuid'] = _uuidController.text.trim();
        base['network'] = 'tcp';
        base['tls'] = _tls;
        base['servername'] = _sniController.text.trim().isNotEmpty
            ? _sniController.text.trim()
            : _serverController.text.trim();
      case 'trojan':
        base['password'] = _passwordController.text;
        base['sni'] = _sniController.text.trim().isNotEmpty
            ? _sniController.text.trim()
            : _serverController.text.trim();
        base['skip-cert-verify'] = _skipCertVerify;
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
        base['key'] = _keyController.text.trim();
        _applySni(base);
        _applyAlpn(base);
        _applyTlsOptions(base);
        _applyEch(base);
        if (_specController.text.trim().isNotEmpty) {
          base['spec'] = _specController.text.trim();
        }
        base['up'] = _up;
        base['down'] = _down;
        base['network'] = _up;
        final pool = _intOrNull(_poolController.text);
        if (pool != null) {
          base['pool'] = pool;
        }
        if (_congestionControllerController.text.trim().isNotEmpty) {
          base['congestion-controller'] = _congestionControllerController.text
              .trim();
        }
        final cwnd = _intOrNull(_cwndController.text);
        if (cwnd != null) {
          base['cwnd'] = cwnd;
        }
        if (_bbrProfileController.text.trim().isNotEmpty) {
          base['bbr-profile'] = _bbrProfileController.text.trim();
        }
        base['reduce-rtt'] = _reduceRtt;
        final maxUdp = _intOrNull(_maxUdpRelayPacketSizeController.text);
        if (maxUdp != null) {
          base['max-udp-relay-packet-size'] = maxUdp;
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

  void _applySni(Map<String, dynamic> base) {
    if (_sniController.text.trim().isNotEmpty) {
      base['sni'] = _sniController.text.trim();
    }
  }

  void _applyAlpn(Map<String, dynamic> base) {
    if (_alpnController.text.trim().isNotEmpty) {
      base['alpn'] = _alpnController.text.trim();
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
    if (_echEnabled && _echConfigController.text.trim().isNotEmpty) {
      base['ech-opts'] = {
        'enable': true,
        'config': _echConfigController.text.trim(),
      };
    }
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
        if (_keyController.text.trim().isEmpty) {
          return appLocalizations.localProxyNowhereKeyEmpty;
        }
        if (!['tcp', 'udp'].contains(_up) || !['tcp', 'udp'].contains(_down)) {
          return appLocalizations.localProxyCarrierInvalid;
        }
        final pool = _intOrNull(_poolController.text);
        if (_poolController.text.trim().isNotEmpty &&
            (pool == null || pool < 0 || pool > 9)) {
          return appLocalizations.localProxyPoolInvalid;
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
      maxLines: maxLines,
      minLines: minLines,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
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
          _buildTextField(_cipherController, appLocalizations.cipher),
          const SizedBox(height: 16),
          _buildTextField(_passwordController, appLocalizations.password),
        ],
      ),
      'vless' => _buildTextField(_uuidController, appLocalizations.uuid),
      'trojan' || 'anytls' || 'hysteria2' => _buildTextField(
        _passwordController,
        appLocalizations.password,
      ),
      'nowhere' => _buildTextField(_keyController, appLocalizations.key),
      _ => Container(),
    };
  }

  Widget _buildTransportFields() {
    final appLocalizations = context.appLocalizations;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_type == 'vless')
          ListItem.switchItem(
            title: Text(appLocalizations.tls),
            delegate: SwitchDelegate<bool>(
              value: _tls,
              onChanged: (value) => setState(() => _tls = value),
            ),
          ),
        if (_type != 'ss' && _type != 'nowhere')
          _buildTextField(
            _sniController,
            _type == 'vless'
                ? appLocalizations.servername
                : appLocalizations.sni,
          ),
        if (_type == 'nowhere') ...[
          _buildTextField(_specController, appLocalizations.spec),
          const SizedBox(height: 16),
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
          const SizedBox(height: 16),
          _buildTextField(
            _poolController,
            appLocalizations.pool,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          _buildTextField(_sniController, appLocalizations.sni),
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
      return Container();
    }
    final appLocalizations = context.appLocalizations;
    return Column(
      children: [
        _buildTextField(_alpnController, appLocalizations.alpn),
        const SizedBox(height: 16),
        _buildTextField(
          _clientFingerprintController,
          appLocalizations.clientFingerprint,
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
      return Container();
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
            onChanged: (value) => setState(() => _udp = value),
          ),
        ),
        if (_type == 'trojan' ||
            _type == 'anytls' ||
            _type == 'nowhere' ||
            _type == 'hysteria2')
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
          const SizedBox(height: 16),
          _buildTextField(_bbrProfileController, appLocalizations.bbrProfile),
          const SizedBox(height: 16),
          ListItem.switchItem(
            title: Text(appLocalizations.reduceRtt),
            delegate: SwitchDelegate<bool>(
              value: _reduceRtt,
              onChanged: (value) => setState(() => _reduceRtt = value),
            ),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            _maxUdpRelayPacketSizeController,
            appLocalizations.maxUdpRelayPacketSize,
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      _ => Container(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    final isManualEditable =
        widget.proxy == null || _manualProxyTypes.contains(_type);
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
                  'This protocol (${_type.toUpperCase()}) is currently only editable by re-importing its URI.',
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
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SegmentedButton<String>(
                    segments: [
                      ButtonSegment(
                        value: 'ss',
                        label: Text(appLocalizations.ss),
                      ),
                      ButtonSegment(
                        value: 'vless',
                        label: Text(appLocalizations.vless),
                      ),
                      ButtonSegment(
                        value: 'trojan',
                        label: Text(appLocalizations.trojan),
                      ),
                      ButtonSegment(
                        value: 'anytls',
                        label: Text(appLocalizations.anytls),
                      ),
                      ButtonSegment(
                        value: 'nowhere',
                        label: Text(appLocalizations.nowhere),
                      ),
                      ButtonSegment(
                        value: 'hysteria2',
                        label: Text(appLocalizations.hysteria2),
                      ),
                    ],
                    selected: {_type},
                    onSelectionChanged: (value) {
                      setState(() => _type = value.first);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
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
            if (_type == 'anytls' || _type == 'nowhere') ...[
              const SizedBox(height: 24),
              Text(appLocalizations.tls, style: context.textTheme.titleSmall),
              const SizedBox(height: 12),
              _buildTlsFields(),
              const SizedBox(height: 24),
              Text(appLocalizations.ech, style: context.textTheme.titleSmall),
              const SizedBox(height: 12),
              _buildEchFields(),
            ],
            const SizedBox(height: 24),
            Text(
              appLocalizations.advancedSettings,
              style: context.textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            _buildAdvancedFields(),
          ],
        ),
      ),
    );
  }
}
