import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Locale;

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/core/controller.dart';
import 'package:fl_clash/core/event.dart';
import 'package:fl_clash/database/database.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/plugins/service.dart';
import 'package:fl_clash/providers/config.dart';
import 'package:fl_clash/providers/core.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:wifi_ssid/wifi_ssid.dart';

part 'generated/app.g.dart';

@Riverpod(keepAlive: true)
bool safeMode(Ref ref) => safeModeBuild;

@Riverpod(keepAlive: true)
class AuthorizedTunEnable extends _$AuthorizedTunEnable
    with AutoDisposeNotifierMixin {
  @override
  TunAuthorizationState build() {
    return TunAuthorizationState.none;
  }
}

typedef UnlockTestHistoryWriter =
    Future<void> Function(UnlockTestRunRecord record);

@Riverpod(keepAlive: true)
UnlockTestHistoryWriter unlockTestHistoryWriter(Ref ref) {
  return database.unlockTestRunsDao.insertAndPrune;
}

@Riverpod(keepAlive: true)
class AndroidServiceSuspended extends _$AndroidServiceSuspended
    with AutoDisposeNotifierMixin {
  @override
  bool build() {
    return false;
  }
}

@Riverpod(keepAlive: true)
class Logs extends _$Logs with AutoDisposeNotifierMixin {
  @override
  FixedList<Log> build() {
    return FixedList(maxLogsLength);
  }

  void add(Log value) {
    if (!ref.mounted) {
      return;
    }
    this.value = state.append(value);
  }

  Future<bool> exportLogs() async {
    final logString = await encodeLogsTask(value.list);
    final tempFilePath = await appPath.tempFilePath;
    final file = File(tempFilePath);
    await file.safeWriteAsString(logString);
    bool res = false;
    res = await picker.saveFileWithPath(logFileName, tempFilePath) != null;
    return res;
  }
}

@Riverpod(keepAlive: true)
class Requests extends _$Requests with AutoDisposeNotifierMixin {
  @override
  FixedList<TrackerInfo> build() {
    return FixedList(maxRequestsLength);
  }

  void addRequest(TrackerInfo value) {
    if (!ref.mounted) {
      return;
    }
    this.value = state.append(value);
  }

  void updateTraffic(Map<String, RequestTraffic> traffic) {
    if (!ref.mounted) {
      return;
    }
    final pending = Map.of(traffic);
    final updated = <int, TrackerInfo>{};
    for (
      var index = state.length - 1;
      index >= 0 && pending.isNotEmpty;
      index--
    ) {
      final request = state[index];
      final item = pending.remove(request.id);
      if (item != null) {
        updated[index] = request.copyWith(
          upload: item.upload,
          download: item.download,
        );
      }
    }
    if (updated.isNotEmpty) {
      value = state.replace(updated);
    }
  }
}

@Riverpod(keepAlive: true)
class DnsQueries extends _$DnsQueries with AutoDisposeNotifierMixin {
  @override
  FixedList<DnsQuery> build() {
    return FixedList(maxDnsQueriesLength);
  }

  void addQuery(DnsQuery value) {
    if (!ref.mounted) {
      return;
    }
    this.value = state.append(value);
  }
}

@Riverpod(keepAlive: true)
class DnsQueryCount extends _$DnsQueryCount with AutoDisposeNotifierMixin {
  @override
  int build() {
    return 0;
  }
}

@Riverpod(keepAlive: true)
class RequestCount extends _$RequestCount with AutoDisposeNotifierMixin {
  @override
  int build() {
    return 0;
  }
}

@Riverpod(keepAlive: true)
class Providers extends _$Providers with AutoDisposeNotifierMixin {
  @override
  List<ExternalProvider> build() {
    return [];
  }

  void setProvider(ExternalProvider? provider) {
    if (provider == null) return;
    final index = value.indexWhere((item) => item.name == provider.name);
    if (index == -1) return;
    final newState = List<ExternalProvider>.from(value)..[index] = provider;
    value = newState;
  }

  Future<void> syncProviders() async {
    value = await ref.read(coreHandlerProvider).getExternalProviders();
  }
}

@Riverpod(keepAlive: true)
class Packages extends _$Packages with AutoDisposeNotifierMixin {
  @override
  List<Package> build() {
    return [];
  }
}

@Riverpod(keepAlive: true)
class SystemBrightness extends _$SystemBrightness
    with AutoDisposeNotifierMixin {
  @override
  Brightness build() {
    return Brightness.dark;
  }
}

@Riverpod(keepAlive: true)
class Traffics extends _$Traffics with AutoDisposeNotifierMixin {
  @override
  FixedList<Traffic> build() {
    return FixedList(trafficSampleLength);
  }

  void addTraffic(Traffic value) {
    if (!ref.mounted) {
      return;
    }
    this.value = state.append(value);
  }

  void clear() {
    value = state.copyWith()..clear();
  }
}

@Riverpod(keepAlive: true)
class TotalTraffic extends _$TotalTraffic with AutoDisposeNotifierMixin {
  @override
  Traffic build() {
    return const Traffic();
  }
}

@Riverpod(keepAlive: true)
class LoadedLocale extends _$LoadedLocale with AutoDisposeNotifierMixin {
  @override
  Locale? build() {
    return null;
  }
}

@Riverpod(keepAlive: true)
class LocalIp extends _$LocalIp with AutoDisposeNotifierMixin {
  @override
  String? build() {
    return null;
  }
}

@Riverpod(keepAlive: true)
class RunTime extends _$RunTime with AutoDisposeNotifierMixin {
  @override
  int? build() {
    return null;
  }
}

/// What the running Android service was started with: it builds the tunnel
/// once, so a later change waits for a restart.
@Riverpod(keepAlive: true)
class RunningVpnOptions extends _$RunningVpnOptions
    with AutoDisposeNotifierMixin {
  @override
  VpnOptions? build() {
    return null;
  }
}

/// False while the window is hidden or the Android activity is in the
/// background; work that only feeds the UI waits for it to come back.
@Riverpod(keepAlive: true)
class AppVisible extends _$AppVisible with AutoDisposeNotifierMixin {
  @override
  bool build() {
    return true;
  }
}

@Riverpod(keepAlive: true)
class ViewSize extends _$ViewSize with AutoDisposeNotifierMixin {
  @override
  Size build() {
    return Size.zero;
  }
}

@Riverpod(keepAlive: true)
class SideWidth extends _$SideWidth with AutoDisposeNotifierMixin {
  @override
  double build() {
    return 0;
  }
}

/// Whether the native window currently draws a backdrop behind the content.
@Riverpod(keepAlive: true)
class WindowBlur extends _$WindowBlur with AutoDisposeNotifierMixin {
  @override
  bool build() {
    return false;
  }
}

@Riverpod(keepAlive: true)
double viewWidth(Ref ref) {
  return ref.watch(viewSizeProvider).width;
}

@Riverpod(keepAlive: true)
ViewMode viewMode(Ref ref) {
  return getViewMode(ref.watch(viewWidthProvider));
}

@Riverpod(keepAlive: true)
bool isMobileView(Ref ref) {
  return ref.watch(viewModeProvider) == ViewMode.mobile;
}

@Riverpod(keepAlive: true)
class Init extends _$Init with AutoDisposeNotifierMixin {
  @override
  bool build() {
    return false;
  }
}

@Riverpod(keepAlive: true)
class CurrentPageLabel extends _$CurrentPageLabel
    with AutoDisposeNotifierMixin {
  @override
  PageLabel build() {
    return PageLabel.dashboard;
  }

  void toPage(PageLabel pageLabel) {
    value = pageLabel;
  }

  void toProfiles() {
    toPage(PageLabel.profiles);
  }
}

@Riverpod(keepAlive: true)
class SortNum extends _$SortNum with AutoDisposeNotifierMixin {
  @override
  int build() {
    return 0;
  }

  int add() => state++;
}

@Riverpod(keepAlive: true)
class CheckIpNum extends _$CheckIpNum with AutoDisposeNotifierMixin {
  @override
  int build() {
    return 0;
  }

  int add() => state++;
}

@Riverpod(keepAlive: true)
class Version extends _$Version with AutoDisposeNotifierMixin {
  @override
  int build() {
    return 0;
  }
}

@Riverpod(keepAlive: true)
class Groups extends _$Groups with AutoDisposeNotifierMixin {
  @override
  List<Group> build() {
    return [];
  }
}

@Riverpod(keepAlive: true)
class DelayDataSource extends _$DelayDataSource with AutoDisposeNotifierMixin {
  DelayMap? _owned;
  DelayMap? _published;

  static const _maxUrlBuckets = 3;

  @override
  DelayMap build() {
    return {};
  }

  void setDelay(Delay delay) {
    setDelays([delay]);
  }

  /// Publishes a live view, so a dependent that keeps the map must copy it.
  void setDelays(Iterable<Delay> delays) {
    final delayMap = _ownedDelayMap();
    var changed = false;
    for (final delay in delays) {
      if (delayMap[delay.url]?[delay.name] == delay.value) {
        continue;
      }
      (delayMap[delay.url] ??= {})[delay.name] = delay.value;
      changed = true;
    }
    if (changed) {
      _boundUrlBuckets(delayMap, delays.map((delay) => delay.url));
      value = _published = UnmodifiableMapView(delayMap);
    }
  }

  void _boundUrlBuckets(DelayMap delayMap, Iterable<String> activeUrls) {
    if (delayMap.length <= _maxUrlBuckets) {
      return;
    }
    final protected = activeUrls.toSet();
    final defaultTestUrl = ref.read(appSettingProvider).testUrl;
    if (defaultTestUrl.isNotEmpty) {
      protected.add(defaultTestUrl);
    }
    for (final url in delayMap.keys.toList()) {
      if (delayMap.length <= _maxUrlBuckets) {
        break;
      }
      if (!protected.contains(url)) {
        delayMap.remove(url);
      }
    }
  }

  DelayMap _ownedDelayMap() {
    final owned = _owned;
    if (owned != null && identical(state, _published)) {
      return owned;
    }
    return _owned = {
      for (final entry in state.entries) entry.key: {...entry.value},
    };
  }
}

@Riverpod(keepAlive: true)
class PendingDelayTests extends _$PendingDelayTests
    with AutoDisposeNotifierMixin {
  final Map<String, int> _holds = {};
  final Map<String, int> _runs = {};
  final Map<String, DelayTestPhase> _phases = {};

  @override
  Map<String, DelayTestPhase> build() {
    return const <String, DelayTestPhase>{};
  }

  /// [finished] keys had started, so they give up their run as well as their
  /// hold; [released] keys never started.
  void apply({
    Iterable<String> acquired = const [],
    Iterable<String> started = const [],
    Iterable<String> finished = const [],
    Iterable<String> released = const [],
  }) {
    final touched = <String>{};
    for (final key in acquired) {
      _holds[key] = (_holds[key] ?? 0) + 1;
      touched.add(key);
    }
    for (final key in started) {
      if (_holds.containsKey(key)) {
        _runs[key] = (_runs[key] ?? 0) + 1;
        touched.add(key);
      }
    }
    for (final key in finished) {
      _decrement(_runs, key);
      _decrement(_holds, key);
      touched.add(key);
    }
    for (final key in released) {
      _decrement(_holds, key);
      touched.add(key);
    }
    var changed = false;
    for (final key in touched) {
      final phase = !_holds.containsKey(key)
          ? null
          : _runs.containsKey(key)
          ? DelayTestPhase.running
          : DelayTestPhase.queued;
      if (_phases[key] == phase) {
        continue;
      }
      if (phase == null) {
        _phases.remove(key);
      } else {
        _phases[key] = phase;
      }
      changed = true;
    }
    if (changed) {
      _publish();
    }
  }

  void clear() {
    if (_holds.isEmpty) {
      return;
    }
    _holds.clear();
    _runs.clear();
    _phases.clear();
    _publish();
  }

  void _decrement(Map<String, int> counts, String key) {
    final count = counts[key];
    if (count == null) {
      return;
    }
    if (count > 1) {
      counts[key] = count - 1;
    } else {
      counts.remove(key);
    }
  }

  // A copy per publish would make a run over n nodes O(n²). The view is live,
  // so a dependent selects what it needs instead of keeping the map.
  void _publish() {
    value = UnmodifiableMapView(_phases);
  }
}

@Riverpod(keepAlive: true)
class DelayTestingGroups extends _$DelayTestingGroups
    with AutoDisposeNotifierMixin {
  @override
  Set<String> build() {
    return const <String>{};
  }

  bool start(String groupName) {
    if (value.contains(groupName)) {
      return false;
    }
    value = {...value, groupName};
    return true;
  }

  void stop(String groupName) {
    if (!value.contains(groupName)) {
      return;
    }
    value = {...value}..remove(groupName);
  }
}

@Riverpod(keepAlive: true)
class HotKeyFailures extends _$HotKeyFailures with AutoDisposeNotifierMixin {
  @override
  Map<HotAction, String> build() {
    return const {};
  }
}

@Riverpod(keepAlive: true)
class HotKeyRecording extends _$HotKeyRecording with AutoDisposeNotifierMixin {
  @override
  bool build() {
    return false;
  }
}

@Riverpod(keepAlive: true)
class SystemUiOverlayStyleState extends _$SystemUiOverlayStyleState
    with AutoDisposeNotifierMixin {
  @override
  SystemUiOverlayStyle build() {
    return const SystemUiOverlayStyle();
  }
}

@Riverpod(name: 'coreStatusProvider', keepAlive: true)
class _CoreStatus extends _$CoreStatus with AutoDisposeNotifierMixin {
  @override
  CoreStatus build() {
    return CoreStatus.disconnected;
  }
}

@riverpod
class Query extends _$Query with AutoDisposeNotifierMixin {
  @override
  String build(QueryTag tag) {
    return '';
  }
}

@Riverpod(keepAlive: true)
class Loading extends _$Loading with AutoDisposeNotifierMixin {
  DateTime? _start;
  Timer? _timer;

  @override
  bool build(LoadingTag tag) {
    ref.onDispose(() {
      _timer?.cancel();
    });
    return false;
  }

  void start() {
    _timer?.cancel();
    _timer = null;
    _start = DateTime.now();
    value = true;
  }

  Future<void> stop() async {
    if (_start == null) {
      value = false;
      return;
    }
    final startedAt = _start!;
    final elapsed = DateTime.now().difference(_start!).inMilliseconds;
    const minDuration = 1000;
    if (elapsed >= minDuration) {
      value = false;
      return;
    }
    _timer = Timer(Duration(milliseconds: minDuration - elapsed), () {
      if (_start != startedAt) {
        return;
      }
      value = false;
    });
  }
}

@riverpod
class Items extends _$Items with AutoDisposeNotifierMixin {
  @override
  Set<dynamic> build(String key) {
    return {};
  }
}

@Riverpod(keepAlive: true)
class UpdatingKeys extends _$UpdatingKeys {
  final _operations = <String, Set<int>>{};
  final _scopes = <String, UpdatingScope>{};
  int _operation = 0;

  @override
  Set<String> build() {
    ref.listen(coreStatusProvider, (_, next) {
      if (next != CoreStatus.connected) {
        _discardScope(UpdatingScope.core);
      }
    });
    return const <String>{};
  }

  int start(String key, {UpdatingScope scope = UpdatingScope.local}) {
    final operation = ++_operation;
    _operations.putIfAbsent(key, () => <int>{}).add(operation);
    _scopes[key] = scope;
    if (!state.contains(key)) {
      state = {...state, key};
    }
    return operation;
  }

  void stop(String key, int operation) {
    final operations = _operations[key];
    if (operations == null) {
      return;
    }
    operations.remove(operation);
    if (operations.isNotEmpty) {
      return;
    }
    _discard([key]);
  }

  void stopKeys(Iterable<String> keys) {
    _discard(keys.toList());
  }

  UpdatingScope? scopeOf(String key) => _scopes[key];

  void _discardScope(UpdatingScope scope) {
    _discard(state.where((key) => _scopes[key] == scope).toList());
  }

  void _discard(List<String> keys) {
    if (keys.isEmpty) {
      return;
    }
    for (final key in keys) {
      _operations.remove(key);
      _scopes.remove(key);
    }
    final next = state.where((key) => !keys.contains(key)).toSet();
    if (next.length == state.length) {
      return;
    }
    state = next;
  }
}

@riverpod
bool isUpdating(Ref ref, String name) {
  return ref.watch(updatingKeysProvider).contains(name);
}

@Riverpod(keepAlive: true)
class UnlockDetection extends _$UnlockDetection
    with AutoDisposeNotifierMixin, CoreEventListener {
  int _checkVersion = 0;
  String? _activeRunId;
  DateTime? _startedAt;

  @override
  UnlockDetectionState build() {
    coreEventManager.addListener(this);
    ref.onDispose(() => coreEventManager.removeListener(this));
    return const UnlockDetectionState(
      isLoading: false,
      proxyName: '',
      results: {},
    );
  }

  Future<void> startCheck({
    UnlockTestRouteMode routeMode = UnlockTestRouteMode.appRoute,
    String? proxyName,
    CoreController? controller,
  }) async {
    final unlockTestProps = ref.read(unlockTestSettingProvider);
    if (!unlockTestProps.enable) {
      return;
    }
    final targets = resolveUnlockTestTargets(unlockTestProps.selectedTargets);
    if (targets.isEmpty) {
      return;
    }
    if (routeMode == UnlockTestRouteMode.proxy &&
        (proxyName == null || proxyName.isEmpty)) {
      state = state.copyWith(error: 'A proxy must be selected');
      return;
    }
    final effectiveController =
        controller ?? ref.read<CoreController>(coreHandlerProvider);
    final version = ++_checkVersion;
    final runId = 'unlock-${DateTime.now().microsecondsSinceEpoch}-${utils.id}';
    _activeRunId = runId;
    _startedAt = DateTime.now();
    state = state.copyWith(
      isLoading: true,
      proxyName: routeMode == UnlockTestRouteMode.proxy ? proxyName! : '',
      error: '',
      testedAt: null,
      results: {
        for (final target in targets)
          target.id: UnlockTestRunItem.untested(target.id),
      },
    );
    try {
      final result = await effectiveController.getUnlockTest(
        UnlockTestRunParams(
          runId: runId,
          routeMode: routeMode,
          proxyName: routeMode == UnlockTestRouteMode.proxy ? proxyName : null,
          timeout: unlockTestTimeout,
          targetIds: targets.map((target) => target.id).toList(growable: false),
        ),
      );
      if (!ref.mounted || version != _checkVersion || _activeRunId != runId) {
        return;
      }
      final merged = Map<String, UnlockTestRunItem>.from(state.results);
      for (final item in result.results) {
        merged[item.id] = item;
      }
      _activeRunId = null;
      final completedAt = DateTime.now();
      state = state.copyWith(
        isLoading: false,
        error: result.error,
        results: merged,
        testedAt: result.cancelled || result.error.isNotEmpty
            ? null
            : completedAt,
      );
      if (!result.cancelled && result.error.isEmpty) {
        await _saveCompletedRun(
          result.runId.isEmpty
              ? UnlockTestRunResult(
                  runId: runId,
                  routeMode: routeMode,
                  proxyName: proxyName,
                  results: merged.values.toList(growable: false),
                )
              : UnlockTestRunResult(
                  runId: result.runId,
                  routeMode: result.routeMode,
                  proxyName: result.proxyName,
                  results: merged.values.toList(growable: false),
                ),
          completedAt: completedAt,
        );
      }
    } catch (e) {
      commonPrint.log('unlockDetection startCheck error: $e');
      if (!ref.mounted || version != _checkVersion || _activeRunId != runId) {
        return;
      }
      _activeRunId = null;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> stopCheck({CoreController? controller}) async {
    final runId = _activeRunId;
    if (runId == null) {
      return;
    }
    _activeRunId = null;
    _checkVersion++;
    state = state.copyWith(isLoading: false);
    await (controller ?? ref.read<CoreController>(coreHandlerProvider))
        .cancelUnlockTest(runId);
  }

  @override
  void onUnlockTestProgress(UnlockTestProgress progress) {
    if (!ref.mounted || progress.runId != _activeRunId) {
      return;
    }
    state = state.copyWith(
      results: {...state.results, progress.item.id: progress.item},
    );
  }

  Future<void> _saveCompletedRun(
    UnlockTestRunResult result, {
    required DateTime completedAt,
  }) async {
    try {
      final startedAt = _startedAt ?? DateTime.now();
      await ref.read(unlockTestHistoryWriterProvider)(
        UnlockTestRunRecord(
          runId: result.runId,
          createdAt: completedAt,
          durationMs: completedAt.difference(startedAt).inMilliseconds,
          routeMode: result.routeMode.name,
          proxyName: result.proxyName,
          catalogVersion: unlockTestCatalogVersion,
          resultsJson: jsonEncode(result.toJson()),
        ),
      );
    } catch (error) {
      commonPrint.log(
        'unlockDetection save history error: $error',
        logLevel: LogLevel.warning,
      );
    }
  }
}

Future<List<UnlockTestHistoryEntry>> loadUnlockTestHistory() async {
  final records = await database.unlockTestRunsDao.latest();
  return records
      .map(_historyEntryFromRecord)
      .whereType<UnlockTestHistoryEntry>()
      .toList();
}

Future<UnlockTestHistoryEntry?> loadLatestAppRouteUnlockTest() async {
  final record = await database.unlockTestRunsDao.latestAppRoute();
  return record == null ? null : _historyEntryFromRecord(record);
}

UnlockTestHistoryEntry? _historyEntryFromRecord(UnlockTestRunRecord record) {
  try {
    final result = UnlockTestRunResult.fromJson(
      Map<String, dynamic>.from(jsonDecode(record.resultsJson) as Map),
    );
    return UnlockTestHistoryEntry(
      createdAt: record.createdAt,
      durationMs: record.durationMs,
      catalogVersion: record.catalogVersion,
      result: result,
    );
  } catch (error) {
    commonPrint.log(
      'unlockDetection decode history error: $error',
      logLevel: LogLevel.warning,
    );
    return null;
  }
}

@Riverpod(keepAlive: true)
class WifiWatchStateJson extends _$WifiWatchStateJson
    with AutoDisposeNotifierMixin {
  @override
  String build() {
    return '';
  }
}

@Riverpod(keepAlive: true)
class WifiWatch extends _$WifiWatch with AutoDisposeNotifierMixin {
  Timer? _fallbackTimer;
  bool _initialized = false;

  @override
  WifiWatchState build() {
    if (!system.isAndroid) {
      return const WifiWatchState();
    }

    final androidSuspended = ref.watch(androidServiceSuspendedProvider);
    final stateJson = ref.watch(wifiWatchStateJsonProvider);

    if (!_initialized) {
      _initialized = true;
      _fetch();
      _fallbackTimer = Timer.periodic(
        const Duration(seconds: 10),
        (_) => _fetch(),
      );
      ref.onDispose(() {
        _fallbackTimer?.cancel();
        _fallbackTimer = null;
        _initialized = false;
      });
    }

    return buildWifiWatchState(stateJson, androidSuspended);
  }

  Future<void> _fetch() async {
    try {
      final data = await service?.getWifiWatchState();
      final currentWifiInfo = await _getCurrentWifiInfo();
      final merged = mergeServiceAndDeviceWifi(data, currentWifiInfo);
      final notifier = ref.read(wifiWatchStateJsonProvider.notifier);
      if (ref.read(wifiWatchStateJsonProvider) != merged) {
        notifier.value = merged;
      }
    } catch (e, stack) {
      commonPrint.log('WifiWatch fetch failed: $e\n$stack');
    }
  }

  Future<WifiConnectionInfo> _getCurrentWifiInfo() async {
    try {
      return await WifiSsidManager.instance.getCurrentWifiInfo();
    } catch (_) {
      try {
        return WifiConnectionInfo(
          ssid: await WifiSsidManager.instance.getSsid(),
        );
      } catch (_) {
        return const WifiConnectionInfo();
      }
    }
  }
}

WifiWatchState buildWifiWatchState(String stateJson, bool androidSuspended) {
  if (stateJson.isEmpty) {
    return WifiWatchState(suspended: androidSuspended);
  }
  try {
    final json = jsonDecode(stateJson) as Map<String, dynamic>;
    if (json.isEmpty) {
      return WifiWatchState(suspended: androidSuspended);
    }
    final serviceState = WifiWatchState.fromJson(json);
    return serviceState.withAndroidServiceSuspended(androidSuspended);
  } catch (e, stack) {
    commonPrint.log('WifiWatch parse failed: $e\n$stack');
    return WifiWatchState(suspended: androidSuspended);
  }
}

String mergeServiceAndDeviceWifi(
  String? data,
  WifiConnectionInfo currentWifiInfo,
) {
  final hasDeviceInfo =
      currentWifiInfo.ssid != null || currentWifiInfo.rssi != null;
  final fallback = wifiWatchStateFromDeviceInfo(currentWifiInfo);
  if (data == null || data.isEmpty) {
    return jsonEncode(fallback.toJson());
  }
  try {
    final json = jsonDecode(data) as Map<String, dynamic>;
    if (json.isEmpty) {
      return jsonEncode(fallback.toJson());
    }
    final serviceState = WifiWatchState.fromJson(json);
    final merged = serviceState.copyWith(
      rawSsid: serviceState.ssid ?? currentWifiInfo.ssid,
      rssi: serviceState.rssi ?? currentWifiInfo.rssi,
      wifiPresent: serviceState.wifiPresent || hasDeviceInfo,
    );
    return jsonEncode(merged.toJson());
  } catch (e) {
    return data;
  }
}

WifiWatchState wifiWatchStateFromDeviceInfo(WifiConnectionInfo info) {
  final hasDeviceInfo = info.ssid != null || info.rssi != null;
  return WifiWatchState(
    ssid: info.ssid,
    rawSsid: info.ssid,
    rssi: info.rssi,
    wifiPresent: hasDeviceInfo,
  );
}

@Riverpod(keepAlive: true)
class BatteryOptimizationDisable extends _$BatteryOptimizationDisable
    with AutoDisposeNotifierMixin {
  @override
  bool build() {
    return false;
  }
}

@Riverpod(keepAlive: true)
class BackgroundLocationPermissions extends _$BackgroundLocationPermissions
    with AutoDisposeNotifierMixin {
  @override
  WifiSsidPermission build() {
    return WifiSsidPermission.denied;
  }
}

@Riverpod(keepAlive: true)
class CurrentSSID extends _$CurrentSSID with AutoDisposeNotifierMixin {
  @override
  String? build() {
    return null;
  }
}

List<Override> buildAppStateOverrides(AppState appState) {
  return [
    initProvider.overrideWithBuild((_, _) => appState.isInit),
    currentPageLabelProvider.overrideWithBuild((_, _) => appState.pageLabel),
    packagesProvider.overrideWithBuild((_, _) => appState.packages),
    sortNumProvider.overrideWithBuild((_, _) => appState.sortNum),
    viewSizeProvider.overrideWithBuild((_, _) => appState.viewSize),
    sideWidthProvider.overrideWithBuild((_, _) => appState.sideWidth),
    delayDataSourceProvider.overrideWithBuild((_, _) => appState.delayMap),
    groupsProvider.overrideWithBuild((_, _) => appState.groups),
    systemBrightnessProvider.overrideWithBuild((_, _) => appState.brightness),
    runTimeProvider.overrideWithBuild((_, _) => appState.runTime),
    providersProvider.overrideWithBuild((_, _) => appState.providers),
    localIpProvider.overrideWithBuild((_, _) => appState.localIp),
    requestsProvider.overrideWithBuild((_, _) => appState.requests),
    versionProvider.overrideWithBuild((_, _) => appState.version),
    logsProvider.overrideWithBuild((_, _) => appState.logs),
    trafficsProvider.overrideWithBuild((_, _) => appState.traffics),
    totalTrafficProvider.overrideWithBuild((_, _) => appState.totalTraffic),
    authorizedTunEnableProvider.overrideWithBuild(
      (_, _) => appState.authorizedTunEnable,
    ),
    systemUiOverlayStyleStateProvider.overrideWithBuild(
      (_, _) => appState.systemUiOverlayStyle,
    ),
    coreStatusProvider.overrideWithBuild((_, _) => appState.coreStatus),
  ];
}
