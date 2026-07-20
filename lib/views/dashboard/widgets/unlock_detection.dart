import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/views/unlock_test.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UnlockDetection extends ConsumerWidget {
  const UnlockDetection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    final enable = ref.watch(
      unlockTestSettingProvider.select((state) => state.enable),
    );
    final detection = ref.watch(unlockDetectionProvider);
    final descTextStyle = context.textTheme.titleSmall?.copyWith(
      color: context.colorScheme.onSurfaceVariant,
    );
    return SizedBox(
      height: getWidgetHeight(1),
      child: CommonCard(
        onPressed: () {
          BaseNavigator.push(context, const UnlockTestView());
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              height: globalState.measure.titleMediumHeight + 16,
              padding: baseInfoEdgeInsets.copyWith(bottom: 0),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Icon(
                    Icons.vpn_key,
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    flex: 1,
                    child: TooltipText(
                      text: Text(
                        appLocalizations.unlockTest,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: descTextStyle,
                      ),
                    ),
                  ),
                  if (enable) ...[
                    const SizedBox(width: 2),
                    AspectRatio(
                      aspectRatio: 1,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        onPressed: detection.isLoading
                            ? null
                            : () {
                                ref
                                    .read(unlockDetectionProvider.notifier)
                                    .startCheck();
                              },
                        icon: Icon(
                          size: 16.ap,
                          Icons.refresh,
                          color: context.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: baseInfoEdgeInsets.copyWith(top: 0),
              child: SizedBox(
                height: globalState.measure.bodyMediumHeight + 2,
                child: FadeThroughBox(
                  child: _buildContent(context, enable, detection),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    bool enable,
    UnlockDetectionState detection,
  ) {
    final appLocalizations = context.appLocalizations;
    final textStyle = context.textTheme.bodyMedium?.toLight.adjustSize(1);
    if (!enable) {
      return TooltipText(
        text: Text(
          appLocalizations.unlockTestDisabledTip,
          style: textStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }
    if (detection.isLoading) {
      return Container(
        padding: const EdgeInsets.all(2),
        child: const AspectRatio(aspectRatio: 1, child: CommonCircleLoading()),
      );
    }
    if (detection.error.isNotEmpty) {
      return TooltipText(
        text: Text(
          appLocalizations.testFailed,
          style: textStyle?.copyWith(color: context.colorScheme.error),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }
    if (detection.results.isEmpty) {
      return Text(
        '—',
        style: textStyle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }
    final aiSummary = _groupSummary(UnlockTestGroup.ai, detection);
    final mediaSummary = _groupSummary(UnlockTestGroup.media, detection);
    return TooltipText(
      text: Text(
        'AI $aiSummary · ${appLocalizations.mediaShort} $mediaSummary',
        style: textStyle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  String _groupSummary(UnlockTestGroup group, UnlockDetectionState detection) {
    final targets = unlockTestTargetsOfGroup(group);
    var unlocked = 0;
    var tested = 0;
    for (final target in targets) {
      final result = detection.results[target.id];
      if (result == null) {
        continue;
      }
      tested++;
      if (result.unlocked) {
        unlocked++;
      }
    }
    return '$unlocked/$tested';
  }
}
