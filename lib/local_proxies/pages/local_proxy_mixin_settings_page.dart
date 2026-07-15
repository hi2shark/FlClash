import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/core/controller.dart';
import 'package:fl_clash/local_proxies/services/local_proxy_store.dart';
import 'package:fl_clash/models/local_proxy.dart';
import 'package:fl_clash/models/local_proxy_provider_config.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';

class LocalProxyMixinSettingsPage extends StatefulWidget {
  final int profileId;

  const LocalProxyMixinSettingsPage({super.key, required this.profileId});

  @override
  State<LocalProxyMixinSettingsPage> createState() =>
      _LocalProxyMixinSettingsPageState();
}

class _GroupInfo {
  final String name;
  final String type;

  _GroupInfo({required this.name, required this.type});
}

const _providerGroupTypes = {'select', 'url-test', 'fallback', 'load-balance'};

class _LocalProxyMixinSettingsPageState
    extends State<LocalProxyMixinSettingsPage> {
  late LocalProxyProviderConfig _config;
  List<_GroupInfo> _groups = [];
  bool _loading = true;
  bool _saving = false;
  late final TextEditingController _healthCheckUrlController;
  late final TextEditingController _healthCheckIntervalController;
  late final TextEditingController _healthCheckTimeoutController;

  @override
  void initState() {
    super.initState();
    _config = localProxyStore.config;
    _healthCheckUrlController = TextEditingController(
      text: _config.healthCheckUrl,
    );
    _healthCheckIntervalController = TextEditingController(
      text: _config.healthCheckInterval.toString(),
    );
    _healthCheckTimeoutController = TextEditingController(
      text: _config.healthCheckTimeout.toString(),
    );
    _loadGroups();
  }

  @override
  void dispose() {
    _healthCheckUrlController.dispose();
    _healthCheckIntervalController.dispose();
    _healthCheckTimeoutController.dispose();
    super.dispose();
  }

  Future<void> _loadGroups() async {
    try {
      final configMap = await coreController.getConfig(widget.profileId);
      if (!mounted) return;
      final groupsRaw = configMap['proxy-groups'];
      final groups = <_GroupInfo>[];
      if (groupsRaw is List) {
        for (final item in groupsRaw) {
          if (item is Map) {
            final name = item['name']?.toString();
            final type = item['type']?.toString();
            if (name != null &&
                name.isNotEmpty &&
                type != null &&
                _providerGroupTypes.contains(type)) {
              groups.add(_GroupInfo(name: name, type: type));
            }
          }
        }
      }
      setState(() {
        _groups = groups;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      globalState.showNotifier(e.toString());
    }
  }

  void _setEnabled(bool value) {
    setState(() {
      _config = _config.copyWith(enabled: value);
    });
  }

  void _toggleGroup(String name) {
    final targetGroups = List<String>.from(_config.targetGroups);
    if (targetGroups.contains(name)) {
      targetGroups.remove(name);
    } else {
      targetGroups.add(name);
    }
    setState(() {
      _config = _config.copyWith(targetGroups: targetGroups);
    });
  }

  Future<void> _handleSave() async {
    if (_saving) return;
    final appLocalizations = context.appLocalizations;
    if (_config.enabled && _config.targetGroups.isEmpty) {
      globalState.showMessage(
        title: appLocalizations.cannotSaveLocalMixin,
        message: TextSpan(text: appLocalizations.selectTargetGroups),
      );
      return;
    }
    if (_config.enabled) {
      final missing = _config.targetGroups
          .where((name) => !_groups.any((g) => g.name == name))
          .toList();
      if (missing.isNotEmpty) {
        globalState.showMessage(
          title: appLocalizations.cannotSaveLocalMixin,
          message: TextSpan(
            text: appLocalizations.localMixinMissingGroups(
              missing.map((e) => '"$e"').join('、'),
            ),
          ),
        );
        return;
      }
    }

    final healthCheckUrl = _healthCheckUrlController.text.trim();
    final healthCheckUri = Uri.tryParse(healthCheckUrl);
    final interval = int.tryParse(_healthCheckIntervalController.text.trim());
    final timeout = int.tryParse(_healthCheckTimeoutController.text.trim());
    final healthCheckScheme = healthCheckUri?.scheme.toLowerCase();
    if (_config.enabled &&
        _config.healthCheckEnabled &&
        (healthCheckUri == null ||
            !healthCheckUri.isAbsolute ||
            healthCheckUri.host.isEmpty ||
            (healthCheckScheme != 'http' && healthCheckScheme != 'https') ||
            interval == null ||
            interval <= 0 ||
            timeout == null ||
            timeout <= 0)) {
      globalState.showMessage(
        title: appLocalizations.cannotSaveLocalMixin,
        message: TextSpan(text: appLocalizations.localProxyHealthCheckInvalid),
      );
      return;
    }

    final previous = localProxyStore.config;
    final next = _config.copyWith(
      healthCheckUrl: healthCheckUrl.isEmpty
          ? _config.healthCheckUrl
          : healthCheckUrl,
      healthCheckInterval: interval != null && interval > 0
          ? interval
          : _config.healthCheckInterval,
      healthCheckTimeout: timeout != null && timeout > 0
          ? timeout
          : _config.healthCheckTimeout,
    );

    _saving = true;
    try {
      var success = false;
      try {
        await localProxyStore.saveConfig(next);
        success = await globalState.container
            .read(setupActionProvider.notifier)
            .applyProfile(force: true);
      } catch (error, stackTrace) {
        commonPrint.log(
          'Failed to save local proxy mixin config: $error\n$stackTrace',
        );
      }

      if (!success) {
        await _restorePreviousConfig(previous);
        if (mounted) {
          globalState.showNotifier(appLocalizations.localProxyReloadFailed);
        }
        return;
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } finally {
      _saving = false;
    }
  }

  Future<void> _restorePreviousConfig(LocalProxyProviderConfig previous) async {
    try {
      await localProxyStore.saveConfig(previous);
    } catch (error, stackTrace) {
      commonPrint.log(
        'Failed to restore local proxy mixin config: $error\n$stackTrace',
      );
    }

    try {
      final success = await globalState.container
          .read(setupActionProvider.notifier)
          .applyProfile(force: true);
      if (!success) {
        commonPrint.log('Failed to reapply previous local proxy mixin config.');
      }
    } catch (error, stackTrace) {
      commonPrint.log(
        'Failed to reapply previous local proxy mixin config: '
        '$error\n$stackTrace',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    final healthEnabled = _config.enabled && _config.healthCheckEnabled;
    return CommonScaffold(
      title: appLocalizations.localProxyMixin,
      floatingActionButton: CommonFloatingActionButton(
        onPressed: _handleSave,
        icon: const Icon(Icons.save),
        label: appLocalizations.saveAndReload,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16).copyWith(bottom: 88),
              children: [
                CommonCard(
                  child: ListItem.switchItem(
                    title: Text(appLocalizations.enableLocalProxyMixin),
                    delegate: SwitchDelegate<bool>(
                      value: _config.enabled,
                      onChanged: _setEnabled,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                CommonCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: ValueListenableBuilder<List<LocalProxy>>(
                      valueListenable: localProxyStore.proxiesNotifier,
                      builder: (_, proxies, _) {
                        final enabledCount = proxies
                            .where((p) => p.enabled)
                            .length;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              appLocalizations.providerInfo,
                              style: context.textTheme.titleSmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${appLocalizations.providerName}: ${_config.providerName}',
                            ),
                            Text(
                              '${appLocalizations.providerType}: ${appLocalizations.localFile}',
                            ),
                            Text(
                              '${appLocalizations.enabledNodes}: $enabledCount',
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                InfoHeader(
                  info: Info(label: appLocalizations.selectTargetGroups),
                ),
                const SizedBox(height: 8),
                if (_groups.isEmpty)
                  CommonCard(
                    child: ListItem(
                      title: Text(appLocalizations.noProxyGroups),
                    ),
                  )
                else
                  CommonCard(
                    child: Column(
                      children: [
                        for (var i = 0; i < _groups.length; i++) ...[
                          if (i > 0) const Divider(height: 1),
                          ListItem.checkbox(
                            title: Text(_groups[i].name),
                            subtitle: Text(_groups[i].type),
                            delegate: CheckboxDelegate(
                              value: _config.targetGroups.contains(
                                _groups[i].name,
                              ),
                              onChanged: _config.enabled
                                  ? (_) => _toggleGroup(_groups[i].name)
                                  : null,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                InfoHeader(info: Info(label: appLocalizations.healthCheck)),
                const SizedBox(height: 8),
                CommonCard(
                  child: Column(
                    children: [
                      ListItem.switchItem(
                        title: Text(appLocalizations.enableHealthCheck),
                        delegate: SwitchDelegate<bool>(
                          value: _config.healthCheckEnabled,
                          onChanged: _config.enabled
                              ? (value) {
                                  setState(() {
                                    _config = _config.copyWith(
                                      healthCheckEnabled: value,
                                    );
                                  });
                                }
                              : null,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: TextFormField(
                          controller: _healthCheckUrlController,
                          enabled: healthEnabled,
                          decoration: InputDecoration(
                            labelText: appLocalizations.healthCheckUrl,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: TextFormField(
                          controller: _healthCheckIntervalController,
                          enabled: healthEnabled,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: appLocalizations.healthCheckInterval,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: TextFormField(
                          controller: _healthCheckTimeoutController,
                          enabled: healthEnabled,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: appLocalizations.healthCheckTimeout,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
