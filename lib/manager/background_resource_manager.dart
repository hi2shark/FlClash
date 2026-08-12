import 'dart:async';

import 'package:fl_clash/common/print.dart';
import 'package:fl_clash/core/controller.dart';
import 'package:fl_clash/providers/action.dart';
import 'package:fl_clash/state.dart';
import 'package:flutter/widgets.dart';

/// UI-shell background reclaim that never touches startListener/stopListener.
class BackgroundResourceManager {
  static BackgroundResourceManager? _instance;
  Timer? _cleanupTimer;
  final ValueNotifier<bool> isBackgroundNotifier = ValueNotifier(false);

  BackgroundResourceManager._internal();

  factory BackgroundResourceManager() {
    _instance ??= BackgroundResourceManager._internal();
    return _instance!;
  }

  bool get isBackground => isBackgroundNotifier.value;

  void enterBackground() {
    if (isBackground) return;
    isBackgroundNotifier.value = true;
    globalState.container.read(setupActionProvider.notifier).pausePolling();
    _scheduleCleanup();
  }

  void leaveBackground() {
    if (!isBackground) return;
    isBackgroundNotifier.value = false;
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
    globalState.container.read(setupActionProvider.notifier).resumePolling();
  }

  void _scheduleCleanup() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer(const Duration(minutes: 3), () {
      _cleanupTimer = null;
      unawaited(_cleanup());
    });
  }

  Future<void> _cleanup() async {
    if (!isBackground) return;

    PaintingBinding.instance.imageCache.clearLiveImages();

    await Future.delayed(const Duration(milliseconds: 250));
    if (!isBackground) return;
    WidgetsBinding.instance.handleMemoryPressure();

    await Future.delayed(const Duration(milliseconds: 250));
    if (!isBackground) return;
    await coreController.requestGc();
    commonPrint.log('background soft reclaim completed');
  }
}

final backgroundResourceManager = BackgroundResourceManager();
