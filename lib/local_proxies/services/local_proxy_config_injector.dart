import 'package:collection/collection.dart';
import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/local_proxies/services/local_proxy_provider_generator.dart';
import 'package:fl_clash/local_proxies/services/local_proxy_store.dart';
import 'package:fl_clash/models/local_proxy_provider_config.dart';

class LocalProxyConfigInjector {
  const LocalProxyConfigInjector();

  Future<void> inject(Map<String, dynamic> rawConfig) async {
    try {
      await _inject(rawConfig);
    } catch (e, s) {
      commonPrint.log(
        'Local proxy mixin skipped due to error: $e\n$s',
        logLevel: LogLevel.warning,
      );
    }
  }

  Future<void> _inject(Map<String, dynamic> rawConfig) async {
    await localProxyStore.init();
    final config = localProxyStore.config;
    if (!config.enabled) return;
    if (config.targetGroups.isEmpty) {
      commonPrint.log(
        'Local proxy mixin enabled but no target groups selected; skipping inject',
        logLevel: LogLevel.warning,
      );
      return;
    }

    final enabledProxies = localProxyStore.proxies
        .where((p) => p.enabled)
        .toList();
    if (enabledProxies.isEmpty) return;

    final proxyProviders = rawConfig['proxy-providers'];
    if (proxyProviders != null && proxyProviders is! Map) {
      commonPrint.log(
        'proxy-providers in profile is not a map; skipping local proxy mixin',
        logLevel: LogLevel.warning,
      );
      return;
    }

    final groups = rawConfig['proxy-groups'];
    if (groups == null || groups is! List) {
      commonPrint.log(
        'No proxy-groups found in current profile; skipping local proxy mixin',
        logLevel: LogLevel.warning,
      );
      return;
    }

    final providers = Map<String, dynamic>.from(
      (proxyProviders as Map?)?.cast<dynamic, dynamic>() ??
          <dynamic, dynamic>{},
    );
    final existing = providers[config.providerKey];
    if (existing is Map && existing['path'] != config.providerPath) {
      commonPrint.log(
        'Provider key "${config.providerKey}" already exists with a different path; skipping local proxy mixin',
        logLevel: LogLevel.warning,
      );
      return;
    }

    await localProxyProviderGenerator.writeProviderFile(enabledProxies);

    providers[config.providerKey] = _buildProviderEntry(config);
    rawConfig['proxy-providers'] = providers;

    final missingGroups = <String>[];
    for (final target in config.targetGroups) {
      final group = groups.firstWhereOrNull(
        (g) => g is Map && g['name'] == target,
      );
      if (group == null) {
        missingGroups.add(target);
        continue;
      }
      final groupMap = (group as Map).cast<String, dynamic>();
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
