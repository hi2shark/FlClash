import 'dart:async';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/core/controller.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/ui/icons/icons.dart';
import 'package:fl_clash/manager/background_resource_manager.dart';
import 'package:fl_clash/providers/app.dart';
import 'package:fl_clash/providers/core.dart';
import 'package:fl_clash/views/dashboard/layout.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'card.dart';

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
    final mobile = !DashboardDensityScope.of(context).isDesktop;
    return DashboardCard(
      semanticLabel: appLocalizations.coreMemoryInfo,
      onTap: () {
        _core.requestGc();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: mobile ? MainAxisSize.min : MainAxisSize.max,
        children: [
          DashboardCardHeader(
            glyph: AppGlyphs.memory,
            title: appLocalizations.coreMemoryInfo,
          ),
          if (mobile) const SizedBox(height: 12) else const Spacer(),
          ValueListenableBuilder(
            valueListenable: _coreMemoryStateNotifier,
            builder: (_, memory, _) {
              final traffic = memory.traffic;
              final style = AppTextStyle.subheadline.of(context).toLight;
              return Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(traffic.value, style: style),
                  const SizedBox(width: 8),
                  Text(traffic.unit, style: style),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
