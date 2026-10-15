import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/local_proxies/services/local_proxy_store.dart';
import 'package:fl_clash/local_rules/services/local_rule_store.dart';
import 'package:fl_clash/local_rules/services/local_rule_targets.dart';
import 'package:fl_clash/models/local_rule.dart';

class LocalRuleConfigInjector {
  const LocalRuleConfigInjector();

  Future<void> inject(Map<String, dynamic> rawConfig) async {
    await localRuleStore.init();
    await localProxyStore.init();
    final config = localRuleStore.config;
    if (!config.enabled) return;

    final enabledRules = localRuleStore.rules
        .where((rule) => rule.enabled)
        .toList();
    if (enabledRules.isEmpty) return;

    final catalog = LocalRuleTargetCatalog.fromRawConfig(rawConfig);
    final injected = <String>[];
    for (final rule in enabledRules) {
      final skipReason = _skipReason(rule, catalog.validTargets);
      if (skipReason != null) {
        commonPrint.log(
          'Skipping local rule ${rule.id} ($skipReason).',
          logLevel: LogLevel.warning,
        );
        continue;
      }
      injected.add(rule.rawValue);
    }

    rawConfig['rules'] = [...injected, ..._existingRules(rawConfig)];
  }

  String? _skipReason(LocalRule rule, Set<String> validTargets) {
    if (!RuleAction.addedRuleActions.contains(rule.ruleAction)) {
      return 'unsupported action ${rule.ruleAction.value}';
    }
    if (!rule.hasContent) {
      return 'empty content';
    }
    if (!rule.hasTarget) {
      return 'empty target';
    }
    if (!validTargets.contains(rule.ruleTarget)) {
      return 'invalid target "${rule.ruleTarget}"';
    }
    return null;
  }

  List<String> _existingRules(Map<String, dynamic> rawConfig) {
    final rules = rawConfig['rules'];
    if (rules is! List) return const [];
    return [for (final rule in rules) rule.toString()];
  }
}

const localRuleConfigInjector = LocalRuleConfigInjector();
