import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/local_proxies/services/local_proxy_parser.dart';
import 'package:fl_clash/local_proxies/services/local_proxy_store.dart';
import 'package:fl_clash/models/local_proxy.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';

class LocalProxyImportPage extends StatefulWidget {
  const LocalProxyImportPage({super.key});

  @override
  State<LocalProxyImportPage> createState() => _LocalProxyImportPageState();
}

class _LocalProxyImportPageState extends State<LocalProxyImportPage> {
  final TextEditingController _controller = TextEditingController();
  List<LocalProxyParseResult> _results = [];
  final Set<int> _selected = {};
  bool _parsed = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _parse() {
    setState(() {
      _results = localProxyParser.parseMany(_controller.text);
      _parsed = true;
      _selected.clear();
      for (var i = 0; i < _results.length; i++) {
        if (_results[i].proxy != null && _results[i].error == null) {
          _selected.add(i);
        }
      }
    });
  }

  Future<void> _import() async {
    final proxies = _results
        .asMap()
        .entries
        .where((e) => _selected.contains(e.key) && e.value.proxy != null)
        .map((e) => e.value.proxy!)
        .toList();
    if (proxies.isEmpty) return;
    await localProxyStore.import(proxies);
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    return CommonScaffold(
      title: appLocalizations.pasteShareLink,
      floatingActionButton: _parsed
          ? FloatingActionButton.extended(
              heroTag: null,
              onPressed: _selected.isEmpty ? null : _import,
              label: Text(appLocalizations.importAvailableNodes),
              icon: const Icon(Icons.download_done),
            )
          : FloatingActionButton.extended(
              heroTag: null,
              onPressed: _parse,
              label: Text(appLocalizations.parse),
              icon: const Icon(Icons.play_arrow),
            ),
      body: Padding(
        padding: const EdgeInsets.all(16).copyWith(bottom: 88),
        child: _parsed ? _buildResultView() : _buildInputView(),
      ),
    );
  }

  Widget _buildInputView() {
    final appLocalizations = context.appLocalizations;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          maxLines: 12,
          minLines: 6,
          decoration: InputDecoration(
            hintText: appLocalizations.pasteNodeLinkHint,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          appLocalizations.supportedProtocols,
          style: context.textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        const Text(
          'ss:// / ssr:// / vmess:// / vless:// / trojan:// /\n'
          'socks5:// / http:// / https:// /\n'
          'hysteria:// / hysteria2:// / hy2:// / tuic:// /\n'
          'anytls:// / nowhere:// / mierus://',
        ),
      ],
    );
  }

  Widget _buildResultView() {
    final appLocalizations = context.appLocalizations;
    final validCount = _results.where((r) => r.proxy != null).length;
    final invalidCount = _results.length - validCount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          appLocalizations.parseResult(validCount, invalidCount),
          style: context.textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.separated(
            itemCount: _results.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (_, index) {
              final result = _results[index];
              final proxy = result.proxy;
              final hasError = result.error != null;
              return CommonCard(
                child: CheckboxListTile(
                  value: _selected.contains(index),
                  onChanged: hasError || proxy == null
                      ? null
                      : (value) {
                          setState(() {
                            if (value == true) {
                              _selected.add(index);
                            } else {
                              _selected.remove(index);
                            }
                          });
                        },
                  title: Text(
                    proxy?.name ?? appLocalizations.parseFailed,
                    style: TextStyle(
                      color: hasError ? context.colorScheme.error : null,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (proxy != null)
                        Text('${proxy.displayType} · ${proxy.serverDesc}'),
                      if (result.error != null)
                        Text(
                          '${appLocalizations.reason}: ${result.error}',
                          style: TextStyle(color: context.colorScheme.error),
                        ),
                      if (result.warnings.isNotEmpty)
                        Text(
                          '${appLocalizations.incompleteSupport}: ${result.warnings.join('; ')}',
                          style: TextStyle(color: context.colorScheme.outline),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
