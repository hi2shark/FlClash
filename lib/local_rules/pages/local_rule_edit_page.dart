import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/local_rules/services/local_rule_store.dart';
import 'package:fl_clash/local_rules/services/local_rule_targets.dart';
import 'package:fl_clash/models/local_rule.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';

class LocalRuleEditPage extends StatefulWidget {
  const LocalRuleEditPage({super.key, this.rule, this.catalog});

  final LocalRule? rule;
  final LocalRuleTargetCatalog? catalog;

  @override
  State<LocalRuleEditPage> createState() => _LocalRuleEditPageState();
}

class _LocalRuleEditPageState extends State<LocalRuleEditPage> {
  final _formKey = GlobalKey<FormState>();
  late LocalRule _rule;
  late LocalRuleTargetCatalog _catalog;
  late final TextEditingController _contentController;
  bool _saving = false;

  bool get _isEditing => widget.rule != null;

  @override
  void initState() {
    super.initState();
    _rule =
        widget.rule ??
        LocalRule(
          id: snowflake.id,
          ruleAction: RuleAction.addedRuleActions.first,
          ruleTarget: RuleTarget.DIRECT.name,
        );
    _catalog = widget.catalog ?? const LocalRuleTargetCatalog();
    _contentController = TextEditingController(text: _rule.content ?? '');
    if (widget.catalog == null) {
      _loadCatalog();
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadCatalog() async {
    final catalog = await LocalRuleTargetCatalog.loadCurrentProfile();
    if (!mounted) return;
    setState(() {
      _catalog = catalog;
    });
  }

  Future<void> _handleSelectAction() async {
    final selected = await globalState.showCommonDialog<RuleAction>(
      filter: false,
      child: OptionsDialog<RuleAction>(
        title: context.appLocalizations.ruleName,
        options: RuleAction.addedRuleActions,
        textBuilder: (item) => item.value,
        value: _rule.ruleAction,
      ),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _rule = _rule.copyWith(ruleAction: selected);
    });
  }

  Future<void> _handleSelectTarget() async {
    final selected = await BaseNavigator.push<String>(
      context,
      LocalRuleTargetPage(catalog: _catalog, selected: _rule.ruleTarget),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _rule = _rule.copyWith(ruleTarget: selected);
    });
  }

  Future<void> _handleSave() async {
    if (_saving) return;
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;
    if ((_rule.ruleTarget ?? '').isEmpty) {
      globalState.showNotifier(context.appLocalizations.selectSplitStrategy);
      return;
    }

    _saving = true;
    try {
      final next = _rule.copyWith(content: _contentController.text.trim());
      if (_isEditing) {
        await localRuleStore.update(next);
      } else {
        await localRuleStore.add(next);
      }
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } finally {
      _saving = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    final target = _rule.ruleTarget ?? '';
    final invalidTarget =
        target.isNotEmpty && !_catalog.validTargets.contains(target);
    return CommonScaffold(
      title: _isEditing
          ? appLocalizations.editLocalRule
          : appLocalizations.addLocalRule,
      floatingActionButton: CommonFloatingActionButton(
        onPressed: _handleSave,
        icon: const Icon(Icons.save),
        label: appLocalizations.save,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16).copyWith(bottom: 88),
          children: [
            CommonCard(
              child: ListItem(
                title: Text(appLocalizations.ruleName),
                subtitle: Text(_rule.ruleAction.value),
                trailing: const Icon(Icons.chevron_right),
                onTap: _handleSelectAction,
              ),
            ),
            const SizedBox(height: 12),
            CommonCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextFormField(
                  controller: _contentController,
                  keyboardType: TextInputType.text,
                  inputFormatters: TextInputLimits.limit(TextInputLimits.rule),
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: appLocalizations.content,
                    hintText: appLocalizations.inputRuleContent,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return appLocalizations.emptyTip(
                        appLocalizations.content,
                      );
                    }
                    return null;
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            CommonCard(
              isError: invalidTarget,
              child: ListItem(
                title: Text(appLocalizations.splitStrategy),
                subtitle: Text(
                  target.isEmpty
                      ? appLocalizations.selectSplitStrategy
                      : invalidTarget
                      ? appLocalizations.invalidPolicy(target)
                      : target,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: _handleSelectTarget,
              ),
            ),
            if (_rule.ruleAction.hasParams) ...[
              const SizedBox(height: 12),
              CommonCard(
                child: Column(
                  children: [
                    ListItem.switchItem(
                      title: Text(appLocalizations.matchSourceIp),
                      delegate: SwitchDelegate<bool>(
                        value: _rule.src,
                        onChanged: (value) {
                          setState(() {
                            _rule = _rule.copyWith(src: value);
                          });
                        },
                      ),
                    ),
                    const Divider(height: 1),
                    ListItem.switchItem(
                      title: Text(appLocalizations.noResolveHostname),
                      delegate: SwitchDelegate<bool>(
                        value: _rule.noResolve,
                        onChanged: (value) {
                          setState(() {
                            _rule = _rule.copyWith(noResolve: value);
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class LocalRuleTargetPage extends StatelessWidget {
  const LocalRuleTargetPage({
    super.key,
    required this.catalog,
    this.selected,
  });

  final LocalRuleTargetCatalog catalog;
  final String? selected;

  Widget _buildItem({
    required BuildContext context,
    required String title,
    String? subtitle,
    required bool isFirst,
  }) {
    return Column(
      children: [
        if (!isFirst) const Divider(height: 1),
        ListItem(
          title: Text(title),
          subtitle: subtitle != null ? Text(subtitle) : null,
          trailing: selected == title ? const Icon(Icons.check) : null,
          onTap: () {
            Navigator.of(context).pop(title);
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    final groups = catalog.groups;
    final localNodes = catalog.localNodes;
    return CommonScaffold(
      title: appLocalizations.splitStrategy,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          InfoHeader(info: Info(label: appLocalizations.basicStrategy)),
          const SizedBox(height: 8),
          CommonCard(
            child: Column(
              children: [
                for (var i = 0; i < RuleTarget.values.length; i++)
                  _buildItem(
                    context: context,
                    title: RuleTarget.values[i].name,
                    isFirst: i == 0,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          InfoHeader(info: Info(label: appLocalizations.proxyGroup)),
          const SizedBox(height: 8),
          if (groups.isEmpty)
            CommonCard(
              child: ListItem(
                title: Text(appLocalizations.noLocalRuleGroups),
              ),
            )
          else
            CommonCard(
              child: Column(
                children: [
                  for (var i = 0; i < groups.length; i++)
                    _buildItem(
                      context: context,
                      title: groups[i],
                      isFirst: i == 0,
                    ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          InfoHeader(info: Info(label: appLocalizations.localNodes)),
          const SizedBox(height: 8),
          if (!catalog.localProxyMixinActive)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                appLocalizations.localRuleNodesNeedMixin,
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colorScheme.outline,
                ),
              ),
            ),
          if (localNodes.isEmpty)
            CommonCard(
              child: ListItem(title: Text(appLocalizations.noLocalProxy)),
            )
          else
            CommonCard(
              child: Column(
                children: [
                  for (var i = 0; i < localNodes.length; i++)
                    _buildItem(
                      context: context,
                      title: localNodes[i],
                      isFirst: i == 0,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
