import 'dart:convert';
import 'dart:io';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/local_proxy.dart';
import 'package:fl_clash/models/local_proxy_provider_config.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';

class _LocalProxyData {
  final LocalProxyProviderConfig config;
  final List<LocalProxy> proxies;

  const _LocalProxyData({required this.config, required this.proxies});

  Map<String, dynamic> toJson() => {
    'providerConfig': config.toJson(),
    'proxies': proxies.map((e) => e.toJson()).toList(),
  };

  factory _LocalProxyData.fromJson(Map<String, dynamic> json) {
    return _LocalProxyData(
      config: LocalProxyProviderConfig.fromJson(
        (json['providerConfig'] as Map?)?.cast<String, Object?>() ?? {},
      ),
      proxies: (json['proxies'] as List? ?? [])
          .map((e) => LocalProxy.fromJson((e as Map).cast<String, Object?>()))
          .toList(),
    );
  }
}

class LocalProxyStore {
  static LocalProxyStore? _instance;
  bool _initialized = false;
  _LocalProxyData _data = const _LocalProxyData(
    config: LocalProxyProviderConfig(),
    proxies: [],
  );
  final ValueNotifier<List<LocalProxy>> proxiesNotifier = ValueNotifier([]);
  final ValueNotifier<LocalProxyProviderConfig> configNotifier = ValueNotifier(
    const LocalProxyProviderConfig(),
  );

  LocalProxyStore._internal();

  factory LocalProxyStore() {
    _instance ??= LocalProxyStore._internal();
    return _instance!;
  }

  Future<String> get _filePath async =>
      join(await appPath.homeDirPath, 'local_proxies.json');

  Future<void> init() async {
    if (_initialized) return;
    await _load();
    _initialized = true;
    _notify();
  }

  LocalProxyProviderConfig get config => _data.config;

  List<LocalProxy> get proxies => List.unmodifiable(_data.proxies);

  int get enabledCount => _data.proxies.where((p) => p.enabled).length;

  Future<void> _load() async {
    try {
      final file = File(await _filePath);
      if (!await file.exists()) {
        return;
      }
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      _data = _LocalProxyData.fromJson(json);
    } catch (e, s) {
      commonPrint.log(
        'Failed to load local proxies: $e\n$s',
        logLevel: LogLevel.warning,
      );
      _data = const _LocalProxyData(
        config: LocalProxyProviderConfig(),
        proxies: [],
      );
    }
  }

  Future<void> _save() async {
    final file = File(await _filePath);
    final content = const JsonEncoder.withIndent('  ').convert(_data.toJson());
    await file.safeWriteAsString(content);
    _notify();
  }

  void _notify() {
    proxiesNotifier.value = List.unmodifiable(_data.proxies);
    configNotifier.value = _data.config;
  }

  Future<void> saveConfig(LocalProxyProviderConfig config) async {
    await init();
    _data = _LocalProxyData(config: config, proxies: _data.proxies);
    await _save();
  }

  /// Disables mixin and clears target groups when switching profiles.
  /// Keeps local nodes and other config fields intact.
  /// Returns true if a reset was performed.
  Future<bool> resetMixinOnProfileSwitch() async {
    await init();
    if (!_data.config.enabled) return false;
    await saveConfig(
      _data.config.copyWith(enabled: false, targetGroups: []),
    );
    return true;
  }

  Future<void> add(LocalProxy proxy) async {
    await init();
    final nextSortIndex = _data.proxies.isEmpty
        ? 0
        : (_data.proxies
                  .map((p) => p.sortIndex ?? 0)
                  .reduce((a, b) => a > b ? a : b) +
              1);
    final sortedProxy = proxy.copyWith(sortIndex: nextSortIndex);
    _data = _LocalProxyData(
      config: _data.config,
      proxies: [..._data.proxies, sortedProxy],
    );
    await _save();
  }

  Future<void> update(LocalProxy proxy) async {
    await init();
    final index = _data.proxies.indexWhere((p) => p.id == proxy.id);
    if (index == -1) return;
    final list = List<LocalProxy>.from(_data.proxies);
    list[index] = proxy.copyWith(updatedAt: DateTime.now());
    _data = _LocalProxyData(config: _data.config, proxies: list);
    await _save();
  }

  Future<void> delete(int id) async {
    await init();
    _data = _LocalProxyData(
      config: _data.config,
      proxies: _data.proxies.where((p) => p.id != id).toList(),
    );
    await _save();
  }

  Future<void> toggle(int id) async {
    await init();
    final index = _data.proxies.indexWhere((p) => p.id == id);
    if (index == -1) return;
    final proxy = _data.proxies[index];
    final list = List<LocalProxy>.from(_data.proxies);
    list[index] = proxy.copyWith(enabled: !proxy.enabled);
    _data = _LocalProxyData(config: _data.config, proxies: list);
    await _save();
  }

  Future<void> import(List<LocalProxy> proxies) async {
    await init();
    final startSortIndex = _data.proxies.isEmpty
        ? 0
        : (_data.proxies
                  .map((p) => p.sortIndex ?? 0)
                  .reduce((a, b) => a > b ? a : b) +
              1);
    final usedNames = _data.proxies.map((p) => p.name).toSet();
    final imported = <LocalProxy>[];
    for (var i = 0; i < proxies.length; i++) {
      final uniqueName = _uniqueNameInSet(proxies[i].name, usedNames);
      usedNames.add(uniqueName);
      imported.add(
        proxies[i].copyWith(sortIndex: startSortIndex + i, name: uniqueName),
      );
    }
    _data = _LocalProxyData(
      config: _data.config,
      proxies: [..._data.proxies, ...imported],
    );
    await _save();
  }

  String _uniqueName(String base) {
    return _uniqueNameInSet(base, _data.proxies.map((p) => p.name).toSet());
  }

  String _uniqueNameInSet(String base, Set<String> names) {
    if (!names.contains(base)) return base;
    final match = RegExp(r'^(.*)\s+(\d+)$').firstMatch(base);
    final prefix = match?.group(1) ?? base;
    var index = int.tryParse(match?.group(2) ?? '') ?? 1;
    var candidate = '$prefix ${index + 1}';
    while (names.contains(candidate)) {
      index++;
      candidate = '$prefix ${index + 1}';
    }
    return candidate;
  }

  String uniqueName(String base) {
    return _uniqueName(base);
  }

  void resetForTest() {
    _initialized = false;
    _data = const _LocalProxyData(
      config: LocalProxyProviderConfig(),
      proxies: [],
    );
    _notify();
  }
}

final localProxyStore = LocalProxyStore();
