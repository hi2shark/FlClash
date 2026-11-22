import 'dart:async';

import 'package:fl_clash/common/print.dart';
import 'package:fl_clash/common/system.dart';
import 'package:fl_clash/core/controller.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/plugins/app.dart';
import 'package:fl_clash/plugins/service.dart';
import 'package:fl_clash/providers/action.dart';
import 'package:fl_clash/providers/app.dart';
import 'package:fl_clash/providers/config.dart';
import 'package:fl_clash/state.dart';
import 'package:flutter/widgets.dart';

/// UI-shell background reclaim that never touches startListener/stopListener.
class BackgroundResourceManager {
  static BackgroundResourceManager? _instance;
  Timer? _cleanupTimer;
  Timer? _bulkPauseTimer;
  bool _bulkStreamsPaused = false;
  final bool? _isAndroidOverride;
  final Future<void> Function(bool foreground)? _onForegroundChanged;
  final VoidCallback? _onPauseLog;
  final VoidCallback? _onResumeLog;
  final VoidCallback? _onClearPackageIcons;
  final ValueNotifier<bool> isBackgroundNotifier = ValueNotifier(false);

  BackgroundResourceManager._internal()
    : _isAndroidOverride = null,
      _onForegroundChanged = null,
      _onPauseLog = null,
      _onResumeLog = null,
      _onClearPackageIcons = null;

  @visibleForTesting
  BackgroundResourceManager.forTest({
    required bool isAndroid,
    Future<void> Function(bool foreground)? onForegroundChanged,
    VoidCallback? onPauseLog,
    VoidCallback? onResumeLog,
    VoidCallback? onClearPackageIcons,
  }) : _isAndroidOverride = isAndroid,
       _onForegroundChanged = onForegroundChanged,
       _onPauseLog = onPauseLog,
       _onResumeLog = onResumeLog,
       _onClearPackageIcons = onClearPackageIcons;

  factory BackgroundResourceManager() {
    _instance ??= BackgroundResourceManager._internal();
    return _instance!;
  }

  bool get _isAndroid => _isAndroidOverride ?? system.isAndroid;

  bool get isBackground => isBackgroundNotifier.value;

  bool get isBulkStreamsPaused => _bulkStreamsPaused;

  void enterBackground() {
    if (isBackground) return;
    isBackgroundNotifier.value = true;
    if (_isAndroidOverride == null) {
      globalState.container.read(setupActionProvider.notifier).pausePolling();
    }
    _scheduleBulkPause();
    _scheduleCleanup();
  }

  void leaveBackground() {
    if (!isBackground) return;
    isBackgroundNotifier.value = false;
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
    _bulkPauseTimer?.cancel();
    _bulkPauseTimer = null;
    _resumeBulkStreams();
    if (_isAndroidOverride == null) {
      globalState.container.read(setupActionProvider.notifier).resumePolling();
    }
  }

  void _scheduleBulkPause() {
    if (!_isAndroid) return;
    _bulkPauseTimer?.cancel();
    _bulkPauseTimer = Timer(const Duration(seconds: 5), () {
      _bulkPauseTimer = null;
      if (!isBackground) return;
      _bulkStreamsPaused = true;
      final onForegroundChanged = _onForegroundChanged;
      if (onForegroundChanged != null) {
        unawaited(onForegroundChanged(false));
      } else {
        unawaited(service?.setForeground(false));
      }
      (_onPauseLog ?? coreController.stopLog)();
    });
  }

  void _resumeBulkStreams() {
    if (!_bulkStreamsPaused) return;
    _bulkStreamsPaused = false;
    final onForegroundChanged = _onForegroundChanged;
    if (onForegroundChanged != null) {
      unawaited(onForegroundChanged(true));
    } else {
      unawaited(service?.setForeground(true));
    }
    final onResumeLog = _onResumeLog;
    if (onResumeLog != null) {
      onResumeLog();
      return;
    }
    final container = globalState.container;
    if (container.read(coreStatusProvider) == CoreStatus.connected &&
        container.read(appSettingProvider).openLogs) {
      coreController.startLog();
    }
  }

  void _scheduleCleanup() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer(const Duration(seconds: 45), () {
      _cleanupTimer = null;
      unawaited(_cleanup());
    });
  }

  Future<void> _cleanup() async {
    if (!isBackground) return;

    (_onClearPackageIcons ?? () => app?.clearPackageIconCache())();
    PaintingBinding.instance.imageCache.clearLiveImages();

    await Future.delayed(const Duration(milliseconds: 250));
    if (!isBackground) return;
    WidgetsBinding.instance.handleMemoryPressure();

    await Future.delayed(const Duration(milliseconds: 250));
    if (!isBackground) return;
    if (_isAndroidOverride == null) {
      await coreController.requestGc();
    }
    commonPrint.log('background soft reclaim completed');
  }
}

final backgroundResourceManager = BackgroundResourceManager();
