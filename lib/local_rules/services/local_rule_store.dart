import 'dart:convert';
import 'dart:io';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/local_rule.dart';
import 'package:fl_clash/models/local_rule_mixin_config.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';

class _LocalRuleData {
  final LocalRuleMixinConfig config;
  final List<LocalRule> rules;

  const _LocalRuleData({required this.config, required this.rules});

  Map<String, dynamic> toJson() => {
    'mixinConfig': config.toJson(),
    'rules': rules.map((rule) => rule.toJson()).toList(),
  };

  factory _LocalRuleData.fromJson(Map<String, dynamic> json) {
    return _LocalRuleData(
      config: LocalRuleMixinConfig.fromJson(
        (json['mixinConfig'] as Map?)?.cast<String, Object?>() ?? {},
      ),
      rules: (json['rules'] as List? ?? []).map((item) {
        return LocalRule.fromJson((item as Map).cast<String, Object?>());
      }).toList(),
    );
  }
}

class LocalRuleStore {
  static LocalRuleStore? _instance;
  bool _initialized = false;
  _LocalRuleData _data = const _LocalRuleData(
    config: LocalRuleMixinConfig(),
    rules: [],
  );
  final ValueNotifier<List<LocalRule>> rulesNotifier = ValueNotifier([]);
  final ValueNotifier<LocalRuleMixinConfig> configNotifier = ValueNotifier(
    const LocalRuleMixinConfig(),
  );

  LocalRuleStore._internal();

  factory LocalRuleStore() {
    _instance ??= LocalRuleStore._internal();
    return _instance!;
  }

  Future<String> get _filePath async =>
      join(await appPath.homeDirPath, 'local_rules.json');

  Future<void> init() async {
    if (_initialized) return;
    final needsMigration = await _load();
    if (needsMigration) {
      await _write();
    }
    _initialized = true;
    _notify();
  }

  LocalRuleMixinConfig get config => _data.config;

  List<LocalRule> get rules {
    final list = List<LocalRule>.from(_data.rules);
    list.sort((a, b) => (a.sortIndex ?? 0).compareTo(b.sortIndex ?? 0));
    return List.unmodifiable(list);
  }

  int get enabledCount => _data.rules.where((rule) => rule.enabled).length;

  Future<bool> _load() async {
    try {
      final file = File(await _filePath);
      if (!await file.exists()) {
        return false;
      }
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      final loadedData = _LocalRuleData.fromJson(json);
      final repairedRules = _repairRuleIds(loadedData.rules);
      _data = repairedRules == null
          ? loadedData
          : _LocalRuleData(config: loadedData.config, rules: repairedRules);
      return repairedRules != null;
    } catch (e, s) {
      commonPrint.log(
        'Failed to load local rules: $e\n$s',
        logLevel: LogLevel.warning,
      );
      _data = const _LocalRuleData(
        config: LocalRuleMixinConfig(),
        rules: [],
      );
      return false;
    }
  }

  Future<void> _write() async {
    final file = File(await _filePath);
    final content = const JsonEncoder.withIndent('  ').convert(_data.toJson());
    await file.safeWriteAsString(content);
  }

  Future<void> _save() async {
    await _write();
    _notify();
  }

  void _notify() {
    rulesNotifier.value = rules;
    configNotifier.value = _data.config;
  }

  int _nextUniqueId(Set<int> usedIds) {
    while (true) {
      final id = snowflake.id;
      if (id > 0 && usedIds.add(id)) {
        return id;
      }
    }
  }

  List<LocalRule>? _repairRuleIds(List<LocalRule> rules) {
    final usedIds = rules
        .where((rule) => rule.id > 0)
        .map((rule) => rule.id)
        .toSet();
    final seenIds = <int>{};
    List<LocalRule>? repaired;

    for (var i = 0; i < rules.length; i++) {
      final rule = rules[i];
      if (rule.id > 0 && seenIds.add(rule.id)) {
        continue;
      }
      repaired ??= List<LocalRule>.from(rules);
      repaired[i] = rule.copyWith(id: _nextUniqueId(usedIds));
    }

    return repaired;
  }

  int _nextSortIndex(List<LocalRule> rules) {
    if (rules.isEmpty) return 0;
    return rules
            .map((rule) => rule.sortIndex ?? 0)
            .reduce((a, b) => a > b ? a : b) +
        1;
  }

  Future<void> saveConfig(LocalRuleMixinConfig config) async {
    await init();
    _data = _LocalRuleData(config: config, rules: _data.rules);
    await _save();
  }

  Future<void> add(LocalRule rule) async {
    await init();
    final sortedRule = rule.copyWith(
      sortIndex: rule.sortIndex ?? _nextSortIndex(_data.rules),
    );
    _data = _LocalRuleData(
      config: _data.config,
      rules: [..._data.rules, sortedRule],
    );
    await _save();
  }

  Future<void> update(LocalRule rule) async {
    await init();
    final index = _data.rules.indexWhere((item) => item.id == rule.id);
    if (index == -1) return;
    final list = List<LocalRule>.from(_data.rules);
    list[index] = rule;
    _data = _LocalRuleData(config: _data.config, rules: list);
    await _save();
  }

  Future<void> delete(int id) async {
    await init();
    final index = _data.rules.indexWhere((rule) => rule.id == id);
    if (index == -1) return;
    final rules = List<LocalRule>.from(_data.rules)..removeAt(index);
    _data = _LocalRuleData(config: _data.config, rules: rules);
    await _save();
  }

  Future<void> toggle(int id) async {
    await init();
    final index = _data.rules.indexWhere((rule) => rule.id == id);
    if (index == -1) return;
    final rule = _data.rules[index];
    final list = List<LocalRule>.from(_data.rules);
    list[index] = rule.copyWith(enabled: !rule.enabled);
    _data = _LocalRuleData(config: _data.config, rules: list);
    await _save();
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    await init();
    final list = rules;
    if (oldIndex < 0 || oldIndex >= list.length) return;
    if (newIndex < 0 || newIndex >= list.length) return;
    final reordered = list.copyAndReorder(oldIndex, newIndex);
    final reindexed = [
      for (var i = 0; i < reordered.length; i++)
        reordered[i].copyWith(sortIndex: i),
    ];
    _data = _LocalRuleData(config: _data.config, rules: reindexed);
    await _save();
  }

  Future<void> replaceAll({
    LocalRuleMixinConfig? config,
    List<LocalRule>? rules,
  }) async {
    await init();
    _data = _LocalRuleData(
      config: config ?? _data.config,
      rules: rules ?? _data.rules,
    );
    await _save();
  }

  void resetForTest() {
    _initialized = false;
    _data = const _LocalRuleData(
      config: LocalRuleMixinConfig(),
      rules: [],
    );
    _notify();
  }
}

final localRuleStore = LocalRuleStore();
