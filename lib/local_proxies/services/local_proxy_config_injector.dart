import 'package:fl_clash/local_proxies/services/local_proxy_provider_generator.dart';
import 'package:fl_clash/local_proxies/services/local_proxy_store.dart';
import 'package:fl_clash/models/local_proxy_provider_config.dart';

class LocalProxyConfigInjector {
  const LocalProxyConfigInjector();

  Future<void> inject(Map<String, dynamic> rawConfig) async {
    await localProxyStore.init();
    final config = localProxyStore.config;
    if (!config.enabled || config.targetGroups.isEmpty) return;

    final enabledProxies = localProxyStore.proxies
        .where((proxy) => proxy.enabled)
        .toList();
    if (enabledProxies.isEmpty) return;

    final proxyProviders = rawConfig['proxy-providers'];
    if (proxyProviders != null && proxyProviders is! Map) {
      throw StateError(
        '"proxy-providers" must be a Map for local proxy injection.',
      );
    }

    final existingProviders = proxyProviders as Map?;
    if (existingProviders?.containsKey(config.providerKey) ?? false) {
      throw StateError(
        'Local proxy provider key "${config.providerKey}" already exists.',
      );
    }

    final proxyGroups = rawConfig['proxy-groups'];
    if (proxyGroups is! List) {
      throw StateError(
        '"proxy-groups" must be a List for local proxy injection.',
      );
    }
    final targetIndexes = _validateTargetGroups(
      proxyGroups,
      config.targetGroups,
    );

    final nextProviders = Map<dynamic, dynamic>.from(
      existingProviders ?? const <dynamic, dynamic>{},
    );
    nextProviders[config.providerKey] = _buildProviderEntry(config);

    final nextGroups = proxyGroups.map<dynamic>((group) {
      return group is Map ? Map<dynamic, dynamic>.from(group) : group;
    }).toList();
    for (final index in targetIndexes.values) {
      final group = nextGroups[index] as Map<dynamic, dynamic>;
      final use = group['use'] as List?;
      final nextUse = use == null ? <String>[] : List<String>.from(use);
      if (!nextUse.contains(config.providerKey)) {
        nextUse.add(config.providerKey);
      }
      group['use'] = nextUse;
    }

    await localProxyProviderGenerator.writeProviderFile(
      enabledProxies,
      providerPath: config.providerPath,
    );

    rawConfig.addAll({
      'proxy-providers': nextProviders,
      'proxy-groups': nextGroups,
    });
  }

  Map<String, int> _validateTargetGroups(
    List<dynamic> groups,
    List<String> targets,
  ) {
    final indexes = <String, int>{};
    for (final target in targets) {
      final index = groups.indexWhere(
        (group) => group is Map && group['name'] == target,
      );
      if (index == -1) {
        throw StateError('Local proxy target group "$target" was not found.');
      }

      final group = groups[index];
      if (group is! Map) {
        throw StateError('Local proxy target group "$target" must be a Map.');
      }
      final use = group['use'];
      if (use != null &&
          (use is! List || use.any((entry) => entry is! String))) {
        throw StateError(
          'Local proxy target group "$target" has invalid "use"; '
          'expected null or a List<String>.',
        );
      }
      indexes[target] = index;
    }
    return indexes;
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
