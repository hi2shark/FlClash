import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/core/controller.dart';
import 'package:fl_clash/core/event.dart';
import 'package:fl_clash/database/database.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/plugins/service.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:wifi_ssid/wifi_ssid.dart';

part 'generated/app.g.dart';

typedef UnlockTestHistoryWriter =
    Future<void> Function(UnlockTestRunRecord record);

@Riverpod(keepAlive: true)
UnlockTestHistoryWriter unlockTestHistoryWriter(Ref ref) {
  return database.unlockTestRunsDao.insertAndPrune;
}

@riverpod
class RealTunEnable extends _$RealTunEnable with AutoDisposeNotifierMixin {
  @override
  bool build() {
    return false;
  }
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
    return FixedList(0);
  }

  void add(Log value) {
    if (!ref.mounted) {
      return;
    }
    this.value = state.copyWith()..add(value);
  }

  Future<bool> exportLogs() async {
    final logString = await encodeLogsTask(value.list);
    final tempFilePath = await appPath.tempFilePath;
    final file = File(tempFilePath);
    await file.safeWriteAsString(logString);
    bool res = false;
    res = await picker.saveFileWithPath(utils.logFile, tempFilePath) != null;
    return res;
  }
}

@Riverpod(keepAlive: true)
class Requests extends _$Requests with AutoDisposeNotifierMixin {
  @override
  FixedList<TrackerInfo> build() {
    return FixedList(0);
  }

  void addRequest(TrackerInfo value) {
    this.value = state.copyWith()..add(value);
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
    value = await coreController.getExternalProviders();
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
    return FixedList(0);
  }

  void addTraffic(Traffic value) {
    this.value = state.copyWith()..add(value);
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

@Riverpod(keepAlive: true)
double viewWidth(Ref ref) {
  return ref.watch(viewSizeProvider).width;
}

@Riverpod(keepAlive: true)
ViewMode viewMode(Ref ref) {
  return utils.getViewMode(ref.watch(viewWidthProvider));
}

@Riverpod(keepAlive: true)
bool isMobileView(Ref ref) {
  return ref.watch(viewModeProvider) == ViewMode.mobile;
}

@Riverpod(keepAlive: true)
double viewHeight(Ref ref) {
  return ref.watch(viewSizeProvider).height;
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
class BackBlock extends _$BackBlock with AutoDisposeNotifierMixin {
  @override
  bool build() {
    return false;
  }

  void backBlock() {
    value = true;
  }

  void unBackBlock() {
    value = false;
  }
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
  @override
  DelayMap build() {
    return {};
  }

  void setDelay(Delay delay) {
    if (state[delay.url]?[delay.name] != delay.value) {
      final DelayMap newDelayMap = Map.from(state);
      if (newDelayMap[delay.url] == null) {
        newDelayMap[delay.url] = {};
      }
      newDelayMap[delay.url]![delay.name] = delay.value;
      value = newDelayMap;
    }
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

@riverpod
class Item extends _$Item with AutoDisposeNotifierMixin {
  @override
  dynamic build(String key) {
    return null;
  }
}

@riverpod
class IsUpdating extends _$IsUpdating with AutoDisposeNotifierMixin {
  @override
  bool build(String name) {
    return false;
  }
}

@Riverpod(keepAlive: true)
class NetworkDetection extends _$NetworkDetection
    with AutoDisposeNotifierMixin {
  static const _timeoutDisplayDelay = Duration(seconds: 2);

  bool? _preIsStart;
  CancelToken? _cancelToken;
  Timer? _timeoutTimer;
  int _checkVersion = 0;

  @override
  NetworkDetectionState build() {
    ref.onDispose(() {
      _resetCheckSession(null);
    });
    return const NetworkDetectionState(isLoading: true, ipInfo: null);
  }

  void startCheck() {
    debouncer.call(FunctionTag.checkIp, () {
      _checkIp();
    }, duration: commonDuration);
  }

  Future<void> _checkIp() async {
    final isInit = ref.read(initProvider);
    if (!isInit) {
      return;
    }
    final isStart = ref.read(isStartProvider);
    if (!isStart && _preIsStart == false && state.ipInfo != null) {
      return;
    }
    final cancelToken = CancelToken();
    final version = _resetCheckSession(cancelToken);
    commonPrint.log('checkIp start');
    state = state.copyWith(isLoading: true, ipInfo: null);
    _preIsStart = isStart;
    final res = await request.checkIp(cancelToken: cancelToken);
    commonPrint.log('checkIp res: $res');

    if (!ref.mounted ||
        version != _checkVersion ||
        cancelToken != _cancelToken) {
      return;
    }
    final ipInfo = res.data;
    if (ipInfo == null) {
      _delayTimeoutDisplay(version);
      return;
    }
    state = state.copyWith(isLoading: false, ipInfo: ipInfo);
  }

  int _resetCheckSession(CancelToken? cancelToken) {
    _cancelTimeoutTimer();
    final version = ++_checkVersion;
    final previousCancelToken = _cancelToken;
    _cancelToken = cancelToken;
    previousCancelToken?.cancel();
    return version;
  }

  void _delayTimeoutDisplay(int version) {
    _cancelTimeoutTimer();
    _timeoutTimer = Timer(_timeoutDisplayDelay, () {
      _timeoutTimer = null;
      if (!ref.mounted || version != _checkVersion || state.ipInfo != null) {
        return;
      }
      state = state.copyWith(isLoading: false, ipInfo: null);
    });
  }

  void _cancelTimeoutTimer() {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
  }
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
    final effectiveController = controller ?? coreController;
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
    await (controller ?? coreController).cancelUnlockTest(runId);
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
class CurrentSSID extends _$CurrentSSID with AutoDisposeNotifierMixin {
  @override
  String? build() {
    return null;
  }
}

/// Raw WiFi-watch state JSON pushed by the native side via
/// `WIFI_WATCH_STATE_CHANGED` broadcast → `AndroidManager.onWifiWatchState`.
/// Empty until the first push/poll lands. [WifiWatch] watches this so it can
/// refresh on native events without a high-frequency poll.
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

    // Reactive to suspend broadcasts (ref.watch, not ref.read, so suspend
    // changes refresh this provider immediately).
    final androidSuspended = ref.watch(androidServiceSuspendedProvider);
    // Reactive to native wifi-watch state pushes.
    final stateJson = ref.watch(wifiWatchStateJsonProvider);

    // One-shot setup that must survive rebuilds. Riverpod keeps the same
    // Notifier instance across rebuilds while the provider is alive, so the
    // fields below persist; we must NOT re-run this block on every rebuild or
    // we'd leak timers and dispose handlers (each rebuild would otherwise
    // create a new Timer.periodic that only gets cancelled on full dispose).
    if (!_initialized) {
      _initialized = true;
      // Kick off a single initial pull so the UI has data before the first
      // native push arrives.
      _fetch();
      // Low-frequency fallback poll in case a native push is missed (process
      // death, race during service restart). Once per 10s is enough because the
      // event channel is the primary signal.
      _fallbackTimer = Timer.periodic(
        const Duration(seconds: 10),
        (_) => _fetch(),
      );
      ref.onDispose(() {
        _fallbackTimer?.cancel();
        _fallbackTimer = null;
        // Allow a future re-create (after full dispose) to set up again.
        _initialized = false;
      });
    }

    // Build from whatever we have right now.
    return buildWifiWatchState(stateJson, androidSuspended);
  }

  /// Pull-based refresh: fetch service JSON and write it to the shared
  /// [wifiWatchStateJsonProvider]. Going through the holder means the poll
  /// path and the native-push path both funnel through a single state holder,
  /// so [WifiWatch] re-builds exactly once per update. Guarded against reentry
  /// via [_initialized] so a rebuild caused by this write does not trigger
  /// another pull.
  Future<void> _fetch() async {
    try {
      final data = await service?.getWifiWatchState();
      final currentWifiInfo = await _getCurrentWifiInfo();
      final merged = mergeServiceAndDeviceWifi(data, currentWifiInfo);
      final notifier = ref.read(wifiWatchStateJsonProvider.notifier);
      // Only write if the value actually changed; this keeps a no-op poll
      // (service returned identical state) from forcing an extra rebuild.
      if (ref.read(wifiWatchStateJsonProvider) != merged) {
        notifier.value = merged;
      }
    } catch (e, stack) {
      // Keep the previous state on failure so the UI does not flicker, but
      // log the error so malformed service JSON does not stay hidden.
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

/// Parses the JSON held by [wifiWatchStateJsonProvider] into a [WifiWatchState]
/// and composes in the latest android-service-suspended flag. Top-level so it
/// can be unit-tested without a live Riverpod container or Android platform.
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

/// Merges the service-side WiFi-watch JSON with device-side WiFi info. The
/// service is authoritative for SSID/trust; device info only fills gaps (RSSI,
/// and rawSsid/ssid when the service hasn't resolved them yet). Returns JSON
/// suitable for [wifiWatchStateJsonProvider]. Top-level so it can be unit-
/// tested directly.
///
/// Previously rawSsid was overwritten unconditionally and rssi logic was
/// inverted (service value cleared when present); both are fixed here.
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
    // Malformed service JSON: fall back to whatever the service gave us rather
    // than silently substituting device-only info.
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
class LocationPermissions extends _$LocationPermissions
    with AutoDisposeNotifierMixin {
  @override
  WifiSsidPermission build() {
    return WifiSsidPermission.denied;
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

List<Override> buildAppStateOverrides(AppState appState) {
  return [
    initProvider.overrideWithBuild((_, _) => appState.isInit),
    backBlockProvider.overrideWithBuild((_, _) => appState.backBlock),
    currentPageLabelProvider.overrideWithBuild((_, _) => appState.pageLabel),
    packagesProvider.overrideWithBuild((_, _) => appState.packages),
    sortNumProvider.overrideWithBuild((_, _) => appState.sortNum),
    viewSizeProvider.overrideWithBuild((_, _) => appState.viewSize),
    sideWidthProvider.overrideWithBuild((_, _) => appState.sideWidth),
    delayDataSourceProvider.overrideWithBuild((_, _) => appState.delayMap),
    groupsProvider.overrideWithBuild((_, _) => appState.groups),
    checkIpNumProvider.overrideWithBuild((_, _) => appState.checkIpNum),
    systemBrightnessProvider.overrideWithBuild((_, _) => appState.brightness),
    runTimeProvider.overrideWithBuild((_, _) => appState.runTime),
    providersProvider.overrideWithBuild((_, _) => appState.providers),
    localIpProvider.overrideWithBuild((_, _) => appState.localIp),
    requestsProvider.overrideWithBuild((_, _) => appState.requests),
    versionProvider.overrideWithBuild((_, _) => appState.version),
    logsProvider.overrideWithBuild((_, _) => appState.logs),
    trafficsProvider.overrideWithBuild((_, _) => appState.traffics),
    totalTrafficProvider.overrideWithBuild((_, _) => appState.totalTraffic),
    realTunEnableProvider.overrideWithBuild((_, _) => appState.realTunEnable),
    systemUiOverlayStyleStateProvider.overrideWithBuild(
      (_, _) => appState.systemUiOverlayStyle,
    ),
    coreStatusProvider.overrideWithBuild((_, _) => appState.coreStatus),
  ];
}
