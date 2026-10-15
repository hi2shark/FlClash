import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/core/controller.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/local_proxies/services/local_proxy_store.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';

class LocalRuleTargetCatalog {
  const LocalRuleTargetCatalog({
    this.groups = const [],
    this.localNodes = const [],
    this.localProxyMixinActive = false,
  });

  final List<String> groups;
  final List<String> localNodes;
  final bool localProxyMixinActive;

  Set<String> get validTargets => {
    ...RuleTarget.baseTargets,
    ...groups,
    if (localProxyMixinActive) ...localNodes,
  };

  static bool get isLocalProxyMixinActive {
    final config = localProxyStore.config;
    return config.enabled && config.targetGroups.isNotEmpty;
  }

  static List<String> groupNamesFrom(Map<String, dynamic> rawConfig) {
    final groups = rawConfig['proxy-groups'];
    if (groups is! List) return const [];
    final names = <String>[];
    for (final group in groups) {
      if (group is! Map) continue;
      final name = group['name']?.toString();
      if (name == null || name.isEmpty) continue;
      names.add(name);
    }
    return names;
  }

  static List<String> enabledLocalNodeNames() {
    return localProxyStore.proxies
        .where((proxy) => proxy.enabled && proxy.name.isNotEmpty)
        .map((proxy) => proxy.name)
        .toList();
  }

  static LocalRuleTargetCatalog fromRawConfig(Map<String, dynamic> rawConfig) {
    return LocalRuleTargetCatalog(
      groups: groupNamesFrom(rawConfig),
      localNodes: enabledLocalNodeNames(),
      localProxyMixinActive: isLocalProxyMixinActive,
    );
  }

  static Future<LocalRuleTargetCatalog> loadCurrentProfile() async {
    await localProxyStore.init();
    var rawConfig = const <String, dynamic>{};
    try {
      final profile = globalState.container.read(currentProfileProvider);
      if (profile != null) {
        rawConfig = await coreController.getConfig(profile.id);
      }
    } catch (error, stackTrace) {
      commonPrint.log(
        'Failed to load profile groups for local rules: $error\n$stackTrace',
        logLevel: LogLevel.warning,
      );
    }
    return fromRawConfig(rawConfig);
  }
}
