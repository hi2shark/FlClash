import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/local_rules/pages/local_rule_list_page.dart';
import 'package:fl_clash/local_rules/services/local_rule_reload.dart';
import 'package:fl_clash/local_rules/services/local_rule_store.dart';
import 'package:fl_clash/local_rules/services/local_rule_targets.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';

class LocalRulesView extends StatefulWidget {
  const LocalRulesView({super.key});

  @override
  State<LocalRulesView> createState() => _LocalRulesViewState();
}

class _LocalRulesViewState extends State<LocalRulesView> {
  LocalRuleTargetCatalog _catalog = const LocalRuleTargetCatalog();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    localRuleStore.init();
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    final catalog = await LocalRuleTargetCatalog.loadCurrentProfile();
    if (!mounted) return;
    setState(() {
      _catalog = catalog;
    });
  }

  int _skippedCount(List<LocalRule> rules) {
    final validTargets = _catalog.validTargets;
    return rules
        .where(
          (rule) =>
              rule.enabled &&
              (!rule.hasContent ||
                  !rule.hasTarget ||
                  !validTargets.contains(rule.ruleTarget)),
        )
        .length;
  }

  Future<void> _setEnabled(bool enabled) async {
    if (_saving) return;
    final previous = localRuleStore.config;
    if (previous.enabled == enabled) return;
    _saving = true;
    try {
      var success = false;
      try {
        await localRuleStore.saveConfig(previous.copyWith(enabled: enabled));
        success = await applyLocalRuleChanges();
      } catch (error, stackTrace) {
        commonPrint.log(
          'Failed to save local rule mixin config: $error\n$stackTrace',
        );
      }
      if (success) {
        await _loadCatalog();
        return;
      }
      await localRuleStore.saveConfig(previous);
      await applyLocalRuleChanges();
      if (mounted) {
        globalState.showNotifier(
          context.appLocalizations.localRuleReloadFailed,
        );
      }
    } finally {
      _saving = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    return CommonScaffold(
      title: appLocalizations.localRules,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ValueListenableBuilder<LocalRuleMixinConfig>(
            valueListenable: localRuleStore.configNotifier,
            builder: (_, config, child) {
              return ValueListenableBuilder<List<LocalRule>>(
                valueListenable: localRuleStore.rulesNotifier,
                builder: (_, rules, child) {
                  final enabledCount = rules
                      .where((rule) => rule.enabled)
                      .length;
                  final skipped = _skippedCount(rules);
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CommonCard(
                        child: ListItem.switchItem(
                          title: Text(appLocalizations.localRuleMixin),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                config.enabled
                                    ? appLocalizations.localMixinEnabled
                                    : appLocalizations.localMixinDisabled,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                config.enabled
                                    ? appLocalizations.localRuleMixinStatus(
                                        rules.length,
                                        enabledCount,
                                        skipped,
                                      )
                                    : appLocalizations.localRulesDesc,
                              ),
                            ],
                          ),
                          delegate: SwitchDelegate<bool>(
                            value: config.enabled,
                            onChanged: _saving
                                ? null
                                : (value) {
                                    _setEnabled(value);
                                  },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      CommonCard(
                        onPressed: () async {
                          await BaseNavigator.push(
                            context,
                            const LocalRuleListPage(),
                          );
                          await _loadCatalog();
                        },
                        child: ListItem(
                          title: Text(appLocalizations.manageLocalRules),
                          subtitle: Text(
                            appLocalizations.localRuleCount(
                              rules.length,
                              enabledCount,
                            ),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
