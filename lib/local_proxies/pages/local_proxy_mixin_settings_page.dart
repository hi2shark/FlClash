import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/core/controller.dart';
import 'package:fl_clash/local_proxies/services/local_proxy_store.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/models/local_proxy_provider_config.dart';
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

class _LocalProxyMixinSettingsPageState
    extends State<LocalProxyMixinSettingsPage> {
  late LocalProxyProviderConfig _config;
  List<_GroupInfo> _groups = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _config = localProxyStore.config;
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    try {
      final configMap = await coreController.getConfig(widget.profileId);
      final groupsRaw = configMap['proxy-groups'];
      final groups = <_GroupInfo>[];
      if (groupsRaw is List) {
        for (final item in groupsRaw) {
          if (item is Map) {
            final name = item['name']?.toString();
            final type = item['type']?.toString();
            if (name != null && name.isNotEmpty && type != null) {
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
    final appLocalizations = context.appLocalizations;
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
    await localProxyStore.saveConfig(_config);
    if (_config.enabled && _config.targetGroups.isNotEmpty) {
      globalState.container
          .read(setupActionProvider.notifier)
          .applyProfile(force: true);
    } else {
      globalState.container
          .read(setupActionProvider.notifier)
          .applyProfile(force: true);
    }
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    return CommonScaffold(
      title: appLocalizations.localProxyMixin,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: _handleSave,
        label: Text(appLocalizations.saveAndReload),
        icon: const Icon(Icons.save),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16).copyWith(bottom: 88),
              children: [
                ListItem.switchItem(
                  title: Text(appLocalizations.enableLocalProxyMixin),
                  delegate: SwitchDelegate<bool>(
                    value: _config.enabled,
                    onChanged: _setEnabled,
                  ),
                ),
                const SizedBox(height: 8),
                CommonCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
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
                          '${appLocalizations.enabledNodes}: ${localProxyStore.enabledCount}',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  appLocalizations.selectTargetGroups,
                  style: context.textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                if (_groups.isEmpty)
                  CommonCard(
                    child: ListItem(
                      title: Text(appLocalizations.noProxyGroups),
                    ),
                  ),
                for (final group in _groups)
                  CommonCard(
                    child: CheckboxListTile(
                      title: Text(group.name),
                      subtitle: Text(group.type),
                      value: _config.targetGroups.contains(group.name),
                      onChanged: _config.enabled
                          ? (_) => _toggleGroup(group.name)
                          : null,
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  appLocalizations.healthCheck,
                  style: context.textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                ListItem.switchItem(
                  title: Text(appLocalizations.enableHealthCheck),
                  delegate: SwitchDelegate<bool>(
                    value: _config.healthCheckEnabled,
                    onChanged: (value) {
                      setState(() {
                        _config = _config.copyWith(healthCheckEnabled: value);
                      });
                    },
                  ),
                ),
                ListItem(
                  title: TextFormField(
                    enabled: _config.healthCheckEnabled,
                    initialValue: _config.healthCheckUrl,
                    decoration: InputDecoration(
                      labelText: appLocalizations.healthCheckUrl,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      _config = _config.copyWith(healthCheckUrl: value);
                    },
                  ),
                ),
                ListItem(
                  title: TextFormField(
                    enabled: _config.healthCheckEnabled,
                    initialValue: _config.healthCheckInterval.toString(),
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: appLocalizations.healthCheckInterval,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      final interval = int.tryParse(value);
                      if (interval != null) {
                        _config = _config.copyWith(
                          healthCheckInterval: interval,
                        );
                      }
                    },
                  ),
                ),
                ListItem(
                  title: TextFormField(
                    enabled: _config.healthCheckEnabled,
                    initialValue: _config.healthCheckTimeout.toString(),
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: appLocalizations.healthCheckTimeout,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      final timeout = int.tryParse(value);
                      if (timeout != null) {
                        _config = _config.copyWith(healthCheckTimeout: timeout);
                      }
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
