import 'dart:async';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/core/controller.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/icons/icons.dart';
import 'package:fl_clash/manager/background_resource_manager.dart';
import 'package:fl_clash/providers/app.dart';
import 'package:fl_clash/providers/core.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/views/dashboard/widget_metrics.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

final _coreMemoryStateNotifier = ValueNotifier<num>(0);

class CoreMemoryInfo extends ConsumerStatefulWidget {
  const CoreMemoryInfo({super.key});

  @override
  ConsumerState<CoreMemoryInfo> createState() => _CoreMemoryInfoState();
}

class _CoreMemoryInfoState extends ConsumerState<CoreMemoryInfo>
    with WidgetsBindingObserver {
  Timer? timer;

  CoreController get _core => ref.read(coreHandlerProvider);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    backgroundResourceManager.isBackgroundNotifier.addListener(
      _onBackgroundChanged,
    );
    _updateMemory();
  }

  @override
  void dispose() {
    timer?.cancel();
    backgroundResourceManager.isBackgroundNotifier.removeListener(
      _onBackgroundChanged,
    );
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onBackgroundChanged() {
    if (backgroundResourceManager.isBackground) {
      timer?.cancel();
      timer = null;
      return;
    }
    _updateMemory();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updateMemory();
      return;
    }
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        (state == AppLifecycleState.inactive && !system.isDesktop)) {
      timer?.cancel();
      timer = null;
    }
  }

  bool get _shouldPoll {
    if (backgroundResourceManager.isBackground) return false;
    final lifecycleState = WidgetsBinding.instance.lifecycleState;
    return lifecycleState == null ||
        lifecycleState == AppLifecycleState.resumed;
  }

  Future<void> _updateMemory() async {
    timer?.cancel();
    timer = null;
    if (!mounted || !_shouldPoll) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || !_shouldPoll) return;
      try {
        if (ref.read(coreStatusProvider) == CoreStatus.connected) {
          _coreMemoryStateNotifier.value =
              (await _core.getMemoryStats())?.rss ?? 0;
        } else {
          _coreMemoryStateNotifier.value = 0;
        }
      } catch (_) {
        if (!mounted) return;
        _coreMemoryStateNotifier.value = 0;
      }
      if (!mounted || !_shouldPoll) return;
      timer = Timer(const Duration(seconds: 2), () {
        unawaited(_updateMemory());
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    return SizedBox(
      height: DashboardWidgetMetrics.heightOf(context, 1),
      child: RepaintBoundary(
        child: CommonCard(
          info: Info(
            label: appLocalizations.coreMemoryInfo,
            glyph: AppGlyphs.memory,
          ),
          onPressed: () {
            _core.requestGc();
          },
          child: Container(
            padding: baseInfoEdgeInsets.copyWith(top: 0),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: globalState.measure.bodyMediumHeight + 2,
                  child: ValueListenableBuilder(
                    valueListenable: _coreMemoryStateNotifier,
                    builder: (_, memory, _) {
                      final traffic = memory.traffic;
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            traffic.value,
                            style: context.textTheme.bodyMedium?.toLight
                                .adjustSize(1),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            traffic.unit,
                            style: context.textTheme.bodyMedium?.toLight
                                .adjustSize(1),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
