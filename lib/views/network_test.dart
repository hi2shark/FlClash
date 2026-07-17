import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/core/core.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';

class NetworkTestView extends StatefulWidget {
  const NetworkTestView({super.key});

  @override
  State<NetworkTestView> createState() => _NetworkTestViewState();
}

class _NetworkTestViewState extends State<NetworkTestView> {
  String _proxyName = 'DIRECT';
  bool _isSpeedTesting = false;
  SpeedTestResult? _speedTestResult;
  bool _isQuicTesting = false;
  QuicTestResult? _quicTestResult;

  Future<void> _handleSpeedTest() async {
    if (_isSpeedTesting) {
      return;
    }
    setState(() {
      _isSpeedTesting = true;
    });
    try {
      final result = await coreController.getSpeedTest(
        SpeedTestParams(proxyName: _proxyName),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _speedTestResult = result;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _speedTestResult = SpeedTestResult(
          name: _proxyName,
          error: e.toString(),
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSpeedTesting = false;
        });
      }
    }
  }

  Future<void> _handleQuicTest() async {
    if (_isQuicTesting) {
      return;
    }
    setState(() {
      _isQuicTesting = true;
    });
    try {
      final result = await coreController.getQuicTest(
        QuicTestParams(proxyName: _proxyName),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _quicTestResult = result;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _quicTestResult = QuicTestResult(name: _proxyName, error: e.toString());
      });
    } finally {
      if (mounted) {
        setState(() {
          _isQuicTesting = false;
        });
      }
    }
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: context.textTheme.bodyMedium?.toLight),
          Text(value, style: context.textTheme.bodyMedium),
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
    if (result.error.isNotEmpty) {
      return _buildErrorText(result.error);
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildResultRow(appLocalizations.rtt, '${result.rtt} ms'),
        _buildResultRow(appLocalizations.alpn, result.alpn),
        _buildResultRow(appLocalizations.quicVersion, '${result.version}'),
      ],
    );
  }

  Widget _buildTestCard({
    required String description,
    required bool isTesting,
    required VoidCallback onStart,
    required Widget? result,
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
              ListItem<String>.open(
                leading: const Icon(Icons.dns),
                title: Text(appLocalizations.selectNode),
                subtitle: Text(_proxyName),
                delegate: OpenDelegate(
                  widget: _NodeSelectionView(currentName: _proxyName),
                  onChanged: (name) {
                    if (name is String && name != _proxyName) {
                      setState(() {
                        _proxyName = name;
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

  const _NodeSelectionView({required this.currentName});

  @override
  State<_NodeSelectionView> createState() => _NodeSelectionViewState();
}

class _NodeSelectionViewState extends State<_NodeSelectionView> {
  static const _localNodeNames = ['DIRECT', 'REJECT'];

  late final Future<List<Proxy>> _proxiesFuture = coreController
      .getAllProxies();

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
          if (proxies.isEmpty) {
            return NullStatus(label: appLocalizations.noData);
          }
          final localProxies = proxies
              .where((proxy) => _localNodeNames.contains(proxy.name))
              .toList();
          final otherProxies =
              proxies
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
