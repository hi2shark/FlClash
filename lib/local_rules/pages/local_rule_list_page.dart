import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/local_rules/pages/local_rule_edit_page.dart';
import 'package:fl_clash/local_rules/services/local_rule_reload.dart';
import 'package:fl_clash/local_rules/services/local_rule_store.dart';
import 'package:fl_clash/local_rules/services/local_rule_targets.dart';
import 'package:fl_clash/models/local_rule.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';

class LocalRuleListPage extends StatefulWidget {
  const LocalRuleListPage({super.key});

  @override
  State<LocalRuleListPage> createState() => _LocalRuleListPageState();
}

class _LocalRuleListPageState extends State<LocalRuleListPage> {
  Future<void> _toggleQueue = Future<void>.value();
  LocalRuleTargetCatalog _catalog = const LocalRuleTargetCatalog();

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

  LocalRule? _findRule(int id) {
    for (final rule in localRuleStore.rules) {
      if (rule.id == id) return rule;
    }
    return null;
  }

  bool _isInvalid(LocalRule rule) {
    return !rule.hasContent ||
        !rule.hasTarget ||
        !_catalog.validTargets.contains(rule.ruleTarget);
  }

  void _handleToggle(LocalRule rule) {
    final previous = _toggleQueue;
    _toggleQueue = _runQueuedToggle(previous, rule.id);
  }

  Future<void> _runQueuedToggle(Future<void> previous, int id) async {
    try {
      await previous;
    } catch (error, stackTrace) {
      commonPrint.log(
        'Previous local rule toggle failed: $error\n$stackTrace',
      );
    }

    try {
      await _toggleAndReload(id);
    } catch (error, stackTrace) {
      commonPrint.log(
        'Unexpected local rule toggle failure: $error\n$stackTrace',
      );
    }
  }

  Future<void> _toggleAndReload(int id) async {
    final original = _findRule(id);
    if (original == null) return;

    var success = false;
    try {
      await localRuleStore.toggle(id);
      success = await applyLocalRuleChanges();
    } catch (error, stackTrace) {
      commonPrint.log(
        'Failed to reload after local rule toggle: $error\n$stackTrace',
      );
    }
    if (success) return;

    await _restoreToggle(id, original.enabled);
    try {
      await applyLocalRuleChanges();
    } catch (error, stackTrace) {
      commonPrint.log(
        'Failed to reapply previous local rule config: $error\n$stackTrace',
      );
    }
    if (mounted) {
      globalState.showNotifier(context.appLocalizations.localRuleReloadFailed);
    }
  }

  Future<void> _restoreToggle(int id, bool enabled) async {
    try {
      final current = _findRule(id);
      if (current != null && current.enabled != enabled) {
        await localRuleStore.toggle(id);
      }
    } catch (error, stackTrace) {
      commonPrint.log(
        'Failed to restore local rule toggle: $error\n$stackTrace',
      );
    }
  }

  Future<void> _handleAddOrEdit({LocalRule? rule}) async {
    final result = await BaseNavigator.push<bool>(
      context,
      LocalRuleEditPage(rule: rule, catalog: _catalog),
    );
    if (result == true) {
      await applyLocalRuleChanges();
      await _loadCatalog();
    }
  }

  Future<void> _handleDelete(LocalRule rule) async {
    final appLocalizations = context.appLocalizations;
    final res = await globalState.showMessage(
      title: appLocalizations.tip,
      message: TextSpan(
        text: appLocalizations.deleteTip(appLocalizations.rule),
      ),
    );
    if (res != true) return;
    final previous = localRuleStore.rules;
    await localRuleStore.delete(rule.id);
    final success = await applyLocalRuleChanges();
    if (success) return;
    await localRuleStore.replaceAll(rules: previous);
    await applyLocalRuleChanges();
    if (mounted) {
      globalState.showNotifier(context.appLocalizations.localRuleReloadFailed);
    }
  }

  Future<void> _handleReorder(int oldIndex, int newIndex) async {
    final previous = localRuleStore.rules;
    await localRuleStore.reorder(oldIndex, newIndex);
    final success = await applyLocalRuleChanges();
    if (success) return;
    await localRuleStore.replaceAll(rules: previous);
    await applyLocalRuleChanges();
    if (mounted) {
      globalState.showNotifier(context.appLocalizations.localRuleReloadFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    return CommonScaffold(
      title: appLocalizations.localRules,
      body: ValueListenableBuilder<List<LocalRule>>(
        valueListenable: localRuleStore.rulesNotifier,
        builder: (_, rules, child) {
          final enabledCount = rules.where((rule) => rule.enabled).length;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    appLocalizations.localRuleCount(rules.length, enabledCount),
                    style: context.textTheme.labelLarge,
                  ),
                ),
              ),
              Expanded(
                child: rules.isEmpty
                    ? NullStatus(
                        label: appLocalizations.noLocalRule,
                        illustration: const RuleEmptyIllustration(),
                      )
                    : ReorderableListView.builder(
                        padding: const EdgeInsets.all(16).copyWith(bottom: 88),
                        buildDefaultDragHandles: false,
                        itemCount: rules.length,
                        onReorderItem: _handleReorder,
                        itemBuilder: (context, index) {
                          final rule = rules[index];
                          return Padding(
                            key: ValueKey(rule.id),
                            padding: EdgeInsets.only(
                              bottom: index == rules.length - 1 ? 0 : 12,
                            ),
                            child: ReorderableDelayedDragStartListener(
                              index: index,
                              child: _RuleCard(
                                rule: rule,
                                invalid: _isInvalid(rule),
                                onEdit: () => _handleAddOrEdit(rule: rule),
                                onToggle: () => _handleToggle(rule),
                                onDelete: () => _handleDelete(rule),
                              ),
                            ),
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
        onPressed: () => _handleAddOrEdit(),
        label: Text(appLocalizations.add),
        icon: const Icon(Icons.add),
      ),
    );
  }
}

class _RuleCard extends StatelessWidget {
  final LocalRule rule;
  final bool invalid;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _RuleCard({
    required this.rule,
    required this.invalid,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    final target = rule.ruleTarget ?? '';
    return CommonCard(
      isError: invalid,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListItem(
            title: Text(rule.ruleAction.value),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(rule.content ?? ''),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (invalid)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Icon(
                          Icons.info,
                          size: 16,
                          color: context.colorScheme.error,
                        ),
                      ),
                    Expanded(
                      child: Text(
                        target.isEmpty
                            ? appLocalizations.selectSplitStrategy
                            : target,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.labelMedium?.copyWith(
                          color: invalid
                              ? context.colorScheme.error
                              : context.colorScheme.tertiary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  rule.enabled
                      ? appLocalizations.enabled
                      : appLocalizations.disabled,
                  style: context.textTheme.labelMedium?.copyWith(
                    color: rule.enabled
                        ? context.colorScheme.primary
                        : context.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Switch(value: rule.enabled, onChanged: (_) => onToggle()),
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
          ),
        ],
      ),
    );
  }
}
