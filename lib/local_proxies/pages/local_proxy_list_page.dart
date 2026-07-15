import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/local_proxies/pages/local_proxy_edit_page.dart';
import 'package:fl_clash/local_proxies/pages/local_proxy_import_page.dart';
import 'package:fl_clash/local_proxies/services/local_proxy_store.dart';
import 'package:fl_clash/models/local_proxy.dart';
import 'package:fl_clash/pages/scan.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';

class LocalProxyListPage extends StatefulWidget {
  const LocalProxyListPage({super.key});

  @override
  State<LocalProxyListPage> createState() => _LocalProxyListPageState();
}

class _LocalProxyListPageState extends State<LocalProxyListPage> {
  late final TextEditingController _searchController;
  Future<void> _toggleQueue = Future<void>.value();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    localProxyStore.init();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<LocalProxy> _filter(List<LocalProxy> proxies) {
    if (_query.isEmpty) return proxies;
    final lower = _query.toLowerCase();
    return proxies.where((p) {
      return p.name.toLowerCase().contains(lower) ||
          p.type.toLowerCase().contains(lower) ||
          p.server.toLowerCase().contains(lower);
    }).toList();
  }

  Future<bool> _reloadIfEnabled() async {
    final config = localProxyStore.config;
    if (!config.enabled || config.targetGroups.isEmpty) return true;
    return globalState.container
        .read(setupActionProvider.notifier)
        .applyProfile(force: true);
  }

  LocalProxy? _findProxy(int id) {
    for (final proxy in localProxyStore.proxies) {
      if (proxy.id == id) return proxy;
    }
    return null;
  }

  void _handleToggle(LocalProxy proxy) {
    final previous = _toggleQueue;
    _toggleQueue = _runQueuedToggle(previous, proxy.id);
  }

  Future<void> _runQueuedToggle(Future<void> previous, int id) async {
    try {
      await previous;
    } catch (error, stackTrace) {
      commonPrint.log(
        'Previous local proxy toggle failed: $error\n$stackTrace',
      );
    }

    try {
      await _toggleAndReload(id);
    } catch (error, stackTrace) {
      commonPrint.log(
        'Unexpected local proxy toggle failure: $error\n$stackTrace',
      );
    }
  }

  Future<void> _toggleAndReload(int id) async {
    final original = _findProxy(id);
    if (original == null) return;

    var success = false;
    try {
      await localProxyStore.toggle(id);
      success = await _reloadIfEnabled();
    } catch (error, stackTrace) {
      commonPrint.log(
        'Failed to reload after local proxy toggle: $error\n$stackTrace',
      );
    }
    if (success) return;

    await _restoreToggle(id, original.enabled);
    await _reapplyPreviousConfig();
    if (mounted) {
      globalState.showNotifier(context.appLocalizations.localProxyReloadFailed);
    }
  }

  Future<void> _restoreToggle(int id, bool enabled) async {
    try {
      final current = _findProxy(id);
      if (current != null && current.enabled != enabled) {
        await localProxyStore.toggle(id);
      }
    } catch (error, stackTrace) {
      commonPrint.log(
        'Failed to restore local proxy toggle: $error\n$stackTrace',
      );
    }
  }

  Future<void> _reapplyPreviousConfig() async {
    try {
      await _reloadIfEnabled();
    } catch (error, stackTrace) {
      commonPrint.log(
        'Failed to reapply previous local proxy config: $error\n$stackTrace',
      );
    }
  }

  void _handleAddUri({String? initialText}) async {
    final result = await BaseNavigator.push<bool>(
      context,
      LocalProxyImportPage(initialText: initialText),
    );
    if (result == true) {
      await _reloadIfEnabled();
    }
  }

  void _handleAddManual(String type) async {
    final result = await BaseNavigator.push<bool>(
      context,
      LocalProxyEditPage(initialType: type),
    );
    if (result == true) {
      await _reloadIfEnabled();
    }
  }

  Future<void> _handleScanQr() async {
    final raw = await BaseNavigator.push<String>(context, const ScanPage());
    if (!mounted || raw == null || raw.trim().isEmpty) return;
    _handleAddUri(initialText: raw.trim());
  }

  void _handleEdit(LocalProxy proxy) async {
    final result = await BaseNavigator.push<bool>(
      context,
      LocalProxyEditPage(proxy: proxy),
    );
    if (result == true) {
      await _reloadIfEnabled();
    }
  }

  Future<void> _handleDelete(LocalProxy proxy) async {
    final appLocalizations = context.appLocalizations;
    final res = await globalState.showMessage(
      title: appLocalizations.tip,
      message: TextSpan(
        text: appLocalizations.deleteTip(appLocalizations.proxy),
      ),
    );
    if (res != true) return;
    await localProxyStore.delete(proxy.id);
    await _reloadIfEnabled();
  }

  String _protocolLabel(String type) {
    final l10n = context.appLocalizations;
    return switch (type) {
      'ss' => l10n.ss,
      'vless' => l10n.vless,
      'trojan' => l10n.trojan,
      'anytls' => l10n.anytls,
      'nowhere' => l10n.nowhere,
      'hysteria2' => l10n.hysteria2,
      _ => type.toUpperCase(),
    };
  }

  void _showAddMenu() {
    final appLocalizations = context.appLocalizations;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.paste),
                  title: Text(appLocalizations.pasteShareLink),
                  onTap: () {
                    Navigator.of(context).pop();
                    _handleAddUri();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.qr_code_scanner),
                  title: Text(appLocalizations.scanQrcode),
                  onTap: () {
                    Navigator.of(context).pop();
                    _handleScanQr();
                  },
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      appLocalizations.selectProtocol,
                      style: context.textTheme.titleSmall,
                    ),
                  ),
                ),
                for (final type in manualProxyTypes)
                  ListTile(
                    leading: const Icon(Icons.edit_note),
                    title: Text(_protocolLabel(type)),
                    onTap: () {
                      Navigator.of(context).pop();
                      _handleAddManual(type);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    return CommonScaffold(
      title: appLocalizations.localProxies,
      body: ValueListenableBuilder<List<LocalProxy>>(
        valueListenable: localProxyStore.proxiesNotifier,
        builder: (_, proxies, child) {
          final filtered = _filter(proxies);
          final enabledCount = proxies.where((p) => p.enabled).length;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value.trim()),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: appLocalizations.searchLocalProxy,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    appLocalizations.localProxyCount(
                      proxies.length,
                      enabledCount,
                    ),
                    style: context.textTheme.labelLarge,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: filtered.isEmpty
                    ? NullStatus(label: appLocalizations.noLocalProxy)
                    : ListView.separated(
                        padding: const EdgeInsets.all(16).copyWith(bottom: 88),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final proxy = filtered[index];
                          return _ProxyCard(
                            proxy: proxy,
                            onEdit: () => _handleEdit(proxy),
                            onToggle: () => _handleToggle(proxy),
                            onDelete: () => _handleDelete(proxy),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: _showAddMenu,
        label: Text(appLocalizations.add),
        icon: const Icon(Icons.add),
      ),
    );
  }
}

class _ProxyCard extends StatelessWidget {
  final LocalProxy proxy;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _ProxyCard({
    required this.proxy,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    return CommonCard(
      child: ListItem(
        title: Text(proxy.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('${proxy.displayType} · ${proxy.serverDesc}'),
            const SizedBox(height: 4),
            Text(
              proxy.enabled
                  ? appLocalizations.enabled
                  : appLocalizations.disabled,
              style: context.textTheme.labelMedium?.copyWith(
                color: proxy.enabled
                    ? context.colorScheme.primary
                    : context.colorScheme.outline,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(value: proxy.enabled, onChanged: (_) => onToggle()),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outlined),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
