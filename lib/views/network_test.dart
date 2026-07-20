import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/core/core.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';

@visibleForTesting
class NetworkTestSpeedPreset {
  final String source;
  final String sizeLabel;
  final String url;
  final int bytes;
  final Duration timeout;

  const NetworkTestSpeedPreset({
    required this.source,
    required this.sizeLabel,
    required this.url,
    required this.bytes,
    required this.timeout,
  });

  String get label => '$source $sizeLabel';
}

const _defaultSpeedTestPreset = NetworkTestSpeedPreset(
  source: 'Cloudflare',
  sizeLabel: '25 MB',
  url: 'https://speed.cloudflare.com/__down?bytes=25000000',
  bytes: 25000000,
  timeout: Duration(seconds: 30),
);
const _speedTestPresets = <NetworkTestSpeedPreset>[
  NetworkTestSpeedPreset(
    source: 'Cloudflare',
    sizeLabel: '10 MB',
    url: 'https://speed.cloudflare.com/__down?bytes=10000000',
    bytes: 10000000,
    timeout: Duration(seconds: 20),
  ),
  _defaultSpeedTestPreset,
  NetworkTestSpeedPreset(
    source: 'Cloudflare',
    sizeLabel: '50 MB',
    url: 'https://speed.cloudflare.com/__down?bytes=50000000',
    bytes: 50000000,
    timeout: Duration(seconds: 60),
  ),
  NetworkTestSpeedPreset(
    source: 'OVH',
    sizeLabel: '10 MiB',
    url: 'https://proof.ovh.net/files/10Mb.dat',
    bytes: 10485760,
    timeout: Duration(seconds: 25),
  ),
  NetworkTestSpeedPreset(
    source: 'OVH',
    sizeLabel: '100 MiB',
    url: 'https://proof.ovh.net/files/100Mb.dat',
    bytes: 104857600,
    timeout: Duration(seconds: 120),
  ),
];
const _quicTestTimeout = Duration(seconds: 10);
const _quicTestTargets = <String>[
  'cloudflare-quic.com:443',
  'www.google.com:443',
  'www.youtube.com:443',
  'nghttp2.org:443',
];
const _customQuicTargetValue = '__custom__';
const _nonTestableProxyTypes = {'reject', 'rejectdrop', 'pass', 'passrule'};

@visibleForTesting
List<NetworkTestSpeedPreset> get networkTestSpeedTestPresets =>
    _speedTestPresets;

@visibleForTesting
NetworkTestSpeedPreset get networkTestDefaultSpeedTestPreset =>
    _defaultSpeedTestPreset;

@visibleForTesting
bool isNetworkTestableProxy(Proxy proxy) =>
    !_nonTestableProxyTypes.contains(proxy.type.trim().toLowerCase());

@visibleForTesting
List<Proxy> filterNetworkTestProxies(Iterable<Proxy> proxies) =>
    proxies.where(isNetworkTestableProxy).toList();

class NetworkTestView extends StatefulWidget {
  final CoreController? controller;

  const NetworkTestView({super.key, this.controller});

  @override
  State<NetworkTestView> createState() => _NetworkTestViewState();
}

class _NetworkTestViewState extends State<NetworkTestView> {
  String _proxyName = 'DIRECT';
  NetworkTestSpeedPreset _speedTestPreset = _defaultSpeedTestPreset;
  bool _isSpeedTesting = false;
  SpeedTestResult? _speedTestResult;
  bool _isQuicTesting = false;
  QuicTestResult? _quicTestResult;
  String _quicTestTarget = _quicTestTargets.first;
  bool _useCustomQuicTarget = false;
  late final TextEditingController _customQuicTargetController;
  late final ExpansibleController _customQuicTargetExpansionController;
  int _speedTestGeneration = 0;
  int _quicTestGeneration = 0;
  int? _activeSpeedTestGeneration;
  int? _activeQuicTestGeneration;

  CoreController get _controller => widget.controller ?? coreController;

  @override
  void initState() {
    super.initState();
    _customQuicTargetController = TextEditingController();
    _customQuicTargetExpansionController = ExpansibleController();
  }

  @override
  void dispose() {
    _customQuicTargetController.dispose();
    _customQuicTargetExpansionController.dispose();
    super.dispose();
  }

  String get _effectiveQuicTarget {
    if (_useCustomQuicTarget) {
      return _customQuicTargetController.text.trim();
    }
    return _quicTestTarget;
  }

  void _clearSpeedTestResult() {
    _speedTestGeneration++;
    _speedTestResult = null;
  }

  void _clearQuicTestResult() {
    _quicTestGeneration++;
    _quicTestResult = null;
  }

  Future<void> _handleSpeedTest() async {
    if (_isSpeedTesting) {
      return;
    }
    final proxyName = _proxyName;
    final preset = _speedTestPreset;
    final generation = ++_speedTestGeneration;
    _activeSpeedTestGeneration = generation;
    setState(() {
      _isSpeedTesting = true;
      _speedTestResult = null;
    });
    try {
      final result = await _controller.getSpeedTest(
        SpeedTestParams(
          proxyName: proxyName,
          testUrl: preset.url,
          timeout: preset.timeout.inMilliseconds,
        ),
      );
      if (!mounted || generation != _speedTestGeneration) {
        return;
      }
      setState(() {
        _speedTestResult = result;
      });
    } catch (e) {
      if (!mounted || generation != _speedTestGeneration) {
        return;
      }
      setState(() {
        _speedTestResult = SpeedTestResult(
          name: proxyName,
          error: e.toString(),
        );
      });
    } finally {
      if (mounted && _activeSpeedTestGeneration == generation) {
        setState(() {
          _isSpeedTesting = false;
          _activeSpeedTestGeneration = null;
        });
      }
    }
  }

  Future<void> _handleQuicTest() async {
    if (_isQuicTesting) {
      return;
    }
    final proxyName = _proxyName;
    final target = _effectiveQuicTarget;
    final generation = ++_quicTestGeneration;
    _activeQuicTestGeneration = generation;
    setState(() {
      _quicTestResult = null;
    });
    if (target.isEmpty) {
      _activeQuicTestGeneration = null;
      setState(() {
        _quicTestResult = QuicTestResult(
          name: proxyName,
          stage: 'target_parse',
          error: context.appLocalizations.quicTestCustomTargetHint,
        );
      });
      return;
    }
    setState(() {
      _isQuicTesting = true;
    });
    try {
      final result = await _controller.getQuicTest(
        QuicTestParams(
          proxyName: proxyName,
          host: target,
          timeout: _quicTestTimeout.inMilliseconds,
        ),
      );
      if (!mounted || generation != _quicTestGeneration) {
        return;
      }
      setState(() {
        _quicTestResult = result;
      });
    } catch (e) {
      if (!mounted || generation != _quicTestGeneration) {
        return;
      }
      setState(() {
        _quicTestResult = QuicTestResult(
          name: proxyName,
          target: target,
          error: e.toString(),
        );
      });
    } finally {
      if (mounted && _activeQuicTestGeneration == generation) {
        setState(() {
          _isQuicTesting = false;
          _activeQuicTestGeneration = null;
        });
      }
    }
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(label, style: context.textTheme.bodyMedium?.toLight),
          ),
          const SizedBox(width: 16),
          Flexible(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: context.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorText(String error) {
    return Text(
      '${context.appLocalizations.testFailed}: $error',
      style: context.textTheme.bodyMedium?.copyWith(
        color: context.colorScheme.error,
      ),
    );
  }

  Widget? _buildSpeedTestResult() {
    final result = _speedTestResult;
    if (result == null) {
      return null;
    }
    final appLocalizations = context.appLocalizations;
    if (result.error.isNotEmpty) {
      return _buildErrorText(result.error);
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildResultRow(appLocalizations.latency, '${result.latency} ms'),
        _buildResultRow(
          appLocalizations.downloadSpeed,
          '${(result.speed * 8 / 1e6).toStringAsFixed(2)} Mbps',
        ),
        _buildResultRow(
          appLocalizations.downloaded,
          '${(result.bytes / 1e6).toStringAsFixed(2)} MB',
        ),
      ],
    );
  }

  Widget? _buildQuicTestResult() {
    final result = _quicTestResult;
    if (result == null) {
      return null;
    }
    final appLocalizations = context.appLocalizations;
    final sent = '${result.sentPackets} (${result.sentBytes} B)';
    final received = '${result.receivedPackets} (${result.receivedBytes} B)';
    if (result.error.isNotEmpty) {
      final isHandshakeTimeout =
          result.stage == 'quic_handshake' &&
          result.error.toLowerCase().contains('deadline exceeded');
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildErrorText(
            isHandshakeTimeout
                ? appLocalizations.quicHandshakeTimedOut
                : result.error,
          ),
          const SizedBox(height: 8),
          if (result.stage.isNotEmpty)
            _buildResultRow(appLocalizations.testStage, result.stage),
          if (result.target.isNotEmpty)
            _buildResultRow(appLocalizations.testTarget, result.target),
          if (result.resolvedIp.isNotEmpty)
            _buildResultRow(
              appLocalizations.resolvedAddress,
              result.resolvedIp,
            ),
          if (result.network.isNotEmpty)
            _buildResultRow(appLocalizations.networkType, result.network),
          _buildResultRow(appLocalizations.sentPackets, sent),
          _buildResultRow(appLocalizations.receivedPackets, received),
          _buildResultRow(appLocalizations.errorDetails, result.error),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildResultRow(appLocalizations.rtt, '${result.rtt} ms'),
        _buildResultRow(appLocalizations.alpn, result.alpn),
        _buildResultRow(appLocalizations.quicVersion, '${result.version}'),
        if (result.target.isNotEmpty)
          _buildResultRow(appLocalizations.testTarget, result.target),
        if (result.resolvedIp.isNotEmpty)
          _buildResultRow(appLocalizations.resolvedAddress, result.resolvedIp),
        if (result.network.isNotEmpty)
          _buildResultRow(appLocalizations.networkType, result.network),
        _buildResultRow(appLocalizations.sentPackets, sent),
        _buildResultRow(appLocalizations.receivedPackets, received),
      ],
    );
  }

  Widget _buildSpeedTestPackageSelector() {
    final appLocalizations = context.appLocalizations;
    return ListItem<NetworkTestSpeedPreset>.options(
      title: Text(appLocalizations.speedTestPackageSize),
      subtitle: Text(_speedTestPreset.label),
      delegate: OptionsDelegate<NetworkTestSpeedPreset>(
        title: appLocalizations.speedTestPackageSize,
        options: _speedTestPresets,
        value: _speedTestPreset,
        textBuilder: (preset) => preset.label,
        onChanged: (preset) {
          if (preset == null || preset == _speedTestPreset) {
            return;
          }
          setState(() {
            _speedTestPreset = preset;
            _clearSpeedTestResult();
          });
        },
      ),
    );
  }

  void _selectQuicPreset(String target) {
    if (_customQuicTargetExpansionController.isExpanded) {
      _customQuicTargetExpansionController.collapse();
    }
    setState(() {
      _useCustomQuicTarget = false;
      _quicTestTarget = target;
      _clearQuicTestResult();
    });
  }

  void _selectCustomQuicTarget() {
    if (!_useCustomQuicTarget) {
      setState(() {
        _useCustomQuicTarget = true;
        _clearQuicTestResult();
      });
    }
    if (!_customQuicTargetExpansionController.isExpanded) {
      _customQuicTargetExpansionController.expand();
    }
  }

  Widget _buildQuicTargetSelector() {
    final appLocalizations = context.appLocalizations;
    final customTarget = _customQuicTargetController.text.trim();
    final groupValue = _useCustomQuicTarget
        ? _customQuicTargetValue
        : _quicTestTarget;
    final targetSubtitle = _useCustomQuicTarget && customTarget.isEmpty
        ? appLocalizations.quicTestCustomTargetHint
        : _effectiveQuicTarget;
    return ExpansionTile(
      initiallyExpanded: false,
      title: Text(appLocalizations.quicTestTarget),
      subtitle: Text(
        targetSubtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      children: [
        RadioGroup<String>(
          groupValue: groupValue,
          onChanged: (value) {
            if (value == null) {
              return;
            }
            if (value == _customQuicTargetValue) {
              _selectCustomQuicTarget();
            } else {
              _selectQuicPreset(value);
            }
          },
          child: Column(
            children: [
              for (final target in _quicTestTargets)
                RadioListTile<String>(
                  value: target,
                  title: Text(target),
                  contentPadding: EdgeInsets.zero,
                ),
              ExpansionTile(
                controller: _customQuicTargetExpansionController,
                initiallyExpanded: false,
                maintainState: true,
                leading: const Radio<String>(value: _customQuicTargetValue),
                title: Text(appLocalizations.quicTestCustomTarget),
                subtitle: Text(
                  customTarget.isEmpty
                      ? appLocalizations.quicTestCustomTargetHint
                      : customTarget,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onExpansionChanged: (expanded) {
                  if (expanded) {
                    _selectCustomQuicTarget();
                  }
                },
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: TextField(
                      controller: _customQuicTargetController,
                      keyboardType: TextInputType.url,
                      textInputAction: TextInputAction.done,
                      autocorrect: false,
                      enableSuggestions: false,
                      maxLines: 1,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: appLocalizations.quicTestCustomTarget,
                        hintText: appLocalizations.quicTestCustomTargetHint,
                      ),
                      onChanged: (_) {
                        if (_useCustomQuicTarget) {
                          setState(_clearQuicTestResult);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTestCard({
    required String description,
    required bool isTesting,
    required VoidCallback onStart,
    required Widget? result,
    Widget? configuration,
  }) {
    final appLocalizations = context.appLocalizations;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: CommonCard(
        radius: 18,
        onPressed: () {},
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: double.infinity,
                child: Text(
                  description,
                  style: context.textTheme.bodyMedium?.toLight,
                ),
              ),
              if (configuration != null) ...[
                const SizedBox(height: 8),
                configuration,
              ],
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: isTesting ? null : onStart,
                icon: isTesting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_arrow),
                label: Text(
                  isTesting
                      ? appLocalizations.testing
                      : appLocalizations.startTest,
                ),
              ),
              if (result != null) ...[const Divider(height: 24), result],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    return CommonScaffold(
      title: appLocalizations.networkTest,
      body: ListView(
        padding: const EdgeInsets.only(bottom: 20),
        children: [
          ...generateSection(
            title: appLocalizations.selectNode,
            items: [
              ListItem<dynamic>.open(
                leading: const Icon(Icons.dns),
                title: Text(appLocalizations.selectNode),
                subtitle: Text(_proxyName),
                delegate: OpenDelegate<dynamic>(
                  widget: _NodeSelectionView(
                    currentName: _proxyName,
                    controller: widget.controller,
                  ),
                  onChanged: (name) {
                    if (name is String && name != _proxyName) {
                      setState(() {
                        _proxyName = name;
                        _clearSpeedTestResult();
                        _clearQuicTestResult();
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          ...generateSection(
            title: appLocalizations.speedTest,
            items: [
              _buildTestCard(
                description: appLocalizations.speedTestDesc,
                isTesting: _isSpeedTesting,
                onStart: _handleSpeedTest,
                configuration: _buildSpeedTestPackageSelector(),
                result: _buildSpeedTestResult(),
              ),
            ],
          ),
          ...generateSection(
            title: appLocalizations.quicTest,
            items: [
              _buildTestCard(
                description: appLocalizations.quicTestDesc,
                isTesting: _isQuicTesting,
                onStart: _handleQuicTest,
                configuration: _buildQuicTargetSelector(),
                result: _buildQuicTestResult(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NodeSelectionView extends StatefulWidget {
  final String currentName;
  final CoreController? controller;

  const _NodeSelectionView({required this.currentName, this.controller});

  @override
  State<_NodeSelectionView> createState() => _NodeSelectionViewState();
}

class _NodeSelectionViewState extends State<_NodeSelectionView> {
  static const _localNodeNames = ['DIRECT', 'COMPATIBLE'];

  late final Future<List<Proxy>> _proxiesFuture =
      (widget.controller ?? coreController).getAllProxies();

  Widget _buildProxyItem(Proxy proxy) {
    return ListItem(
      title: Text(proxy.name),
      subtitle: Text(proxy.type),
      trailing: proxy.name == widget.currentName
          ? const Icon(Icons.check)
          : null,
      onTap: () {
        Navigator.of(context).pop<String>(proxy.name);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    return CommonScaffold(
      title: appLocalizations.selectNode,
      body: FutureBuilder<List<Proxy>>(
        future: _proxiesFuture,
        builder: (_, snapshot) {
          if (snapshot.hasError) {
            return NullStatus(
              label: '${appLocalizations.testFailed}: ${snapshot.error}',
            );
          }
          final proxies = snapshot.data;
          if (proxies == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final testableProxies = filterNetworkTestProxies(proxies);
          if (testableProxies.isEmpty) {
            return NullStatus(label: appLocalizations.noData);
          }
          final localProxies = testableProxies
              .where((proxy) => _localNodeNames.contains(proxy.name))
              .toList();
          final otherProxies =
              testableProxies
                  .where((proxy) => !_localNodeNames.contains(proxy.name))
                  .toList()
                ..sort((a, b) => a.name.compareTo(b.name));
          return ListView(
            padding: const EdgeInsets.only(bottom: 20),
            children: [
              ...generateSection(
                title: appLocalizations.localNodes,
                items: localProxies.map(_buildProxyItem),
              ),
              ...generateSection(
                title: appLocalizations.allNodes,
                items: otherProxies.map(_buildProxyItem),
              ),
            ],
          );
        },
      ),
    );
  }
}
