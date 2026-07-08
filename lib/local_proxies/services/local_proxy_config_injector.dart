import 'package:collection/collection.dart';
import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/local_proxies/services/local_proxy_provider_generator.dart';
import 'package:fl_clash/local_proxies/services/local_proxy_store.dart';
import 'package:fl_clash/models/local_proxy_provider_config.dart';

class LocalProxyConfigInjector {
  const LocalProxyConfigInjector();

  Future<void> inject(Map<String, dynamic> rawConfig) async {
    await localProxyStore.init();
    final config = localProxyStore.config;
    if (!config.enabled) return;

    final enabledProxies = localProxyStore.proxies
        .where((p) => p.enabled)
        .toList();
    if (enabledProxies.isEmpty) return;

    await localProxyProviderGenerator.writeProviderFile(enabledProxies);

    final proxyProviders = rawConfig['proxy-providers'];
    if (proxyProviders != null && proxyProviders is! Map) {
      throw Exception('proxy-providers in profile is not a map');
    }
    final providers =
        (proxyProviders ?? <String, dynamic>{}) as Map<String, dynamic>;
    final existing = providers[config.providerKey];
    if (existing is Map && existing['path'] != config.providerPath) {
      throw Exception(
        'Provider key "${config.providerKey}" already exists in profile with a different path',
      );
    }
    providers[config.providerKey] = _buildProviderEntry(config);
    rawConfig['proxy-providers'] = providers;

    final groups = rawConfig['proxy-groups'];
    if (groups == null || groups is! List) {
      throw Exception('No proxy-groups found in current profile');
    }

    final missingGroups = <String>[];
    for (final target in config.targetGroups) {
      final group = groups.firstWhereOrNull(
        (g) => g is Map && g['name'] == target,
      );
      if (group == null) {
        missingGroups.add(target);
        continue;
      }
      final groupMap = group as Map<String, dynamic>;
      final use = groupMap['use'];
      final useList = (use is List ? List<String>.from(use) : <String>[]);
      if (!useList.contains(config.providerKey)) {
        useList.add(config.providerKey);
        groupMap['use'] = useList;
      }
    }

    if (missingGroups.isNotEmpty) {
      commonPrint.log(
        'Local proxy target groups not found: ${missingGroups.join(', ')}; skipping them',
        logLevel: LogLevel.warning,
      );
    }
  }

  Map<String, dynamic> _buildProviderEntry(LocalProxyProviderConfig config) {
    return {
      'type': 'file',
      'path': config.providerPath,
      'health-check': {
        'enable': config.healthCheckEnabled,
        'url': config.healthCheckUrl,
        'interval': config.healthCheckInterval,
        'timeout': config.healthCheckTimeout,
        'lazy': true,
        'expected-status': 204,
      },
    };
  }
}

const localProxyConfigInjector = LocalProxyConfigInjector();
