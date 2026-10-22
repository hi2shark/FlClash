import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/ui/icons/icons.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/views/unlock_test.dart';
import 'package:fl_clash/views/dashboard/layout.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'card.dart';

typedef UnlockTestAppRouteHistoryLoader =
    Future<UnlockTestHistoryEntry?> Function();

class UnlockDetection extends ConsumerStatefulWidget {
  final UnlockTestAppRouteHistoryLoader historyLoader;

  const UnlockDetection({
    super.key,
    this.historyLoader = loadLatestAppRouteUnlockTest,
  });

  @override
  ConsumerState<UnlockDetection> createState() => _UnlockDetectionState();
}

class _UnlockDetectionState extends ConsumerState<UnlockDetection> {
  late Future<UnlockTestHistoryEntry?> _history;

  @override
  void initState() {
    super.initState();
    _history = widget.historyLoader();
  }

  Future<void> _refresh() async {
    await ref
        .read(unlockDetectionProvider.notifier)
        .startCheck(routeMode: UnlockTestRouteMode.appRoute);
    if (!mounted) {
      return;
    }
    setState(() {
      _history = widget.historyLoader();
    });
  }

  @override
  Widget build(BuildContext context) {
    final enabled = ref.watch(
      unlockTestSettingProvider.select((state) => state.enable),
    );
    final detection = ref.watch(unlockDetectionProvider);
    final mobile = !DashboardDensityScope.of(context).isDesktop;
    final results = !enabled
        ? _EmptyDashboard(
            glyph: AppGlyphs.toggle,
            message: context.appLocalizations.unlockTestDisabledTip,
          )
        : FutureBuilder<UnlockTestHistoryEntry?>(
            future: _history,
            builder: (context, snapshot) {
              final currentIsAppRoute =
                  detection.proxyName.isEmpty &&
                  (detection.isLoading || detection.results.isNotEmpty);
              final results = currentIsAppRoute
                  ? detection.results
                  : {
                      for (final item
                          in snapshot.data?.result.results ??
                              const <UnlockTestRunItem>[])
                        item.id: item,
                    };
              if (results.isEmpty) {
                return _EmptyDashboard(
                  glyph: AppGlyphs.checkDouble,
                  message: context.appLocalizations.unlockTestNoResults,
                );
              }
              return _DashboardResults(
                results: results,
                isLoading: currentIsAppRoute && detection.isLoading,
                error: currentIsAppRoute ? detection.error : '',
                testedAt: currentIsAppRoute
                    ? detection.testedAt
                    : snapshot.data?.createdAt,
                mobile: mobile,
              );
            },
          );
    return DashboardCard(
      semanticLabel: context.appLocalizations.unlockTest,
      onTap: () {
        BaseNavigator.push(context, const UnlockTestView());
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: mobile ? MainAxisSize.min : MainAxisSize.max,
        children: [
          _DashboardHeader(
            enabled: enabled,
            isLoading: detection.isLoading,
            onRefresh: _refresh,
          ),
          const SizedBox(height: 6),
          if (mobile) results else Expanded(child: results),
        ],
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  final bool enabled;
  final bool isLoading;
  final Future<void> Function() onRefresh;

  const _DashboardHeader({
    required this.enabled,
    required this.isLoading,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: Row(
        children: [
          GlyphIcon(
            AppGlyphs.locate,
            size: 20,
            color: context.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.appLocalizations.unlockTest,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyle.subheadline.of(context, emphasized: true),
            ),
          ),
          Tooltip(
            message: context.appLocalizations.unlockTestFollowRules,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 120),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GlyphIcon(
                    AppGlyphs.split,
                    size: 14,
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      context.appLocalizations.unlockTestFollowRules,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyle.caption2
                          .of(context)
                          .copyWith(
                            color: context.colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: MaterialLocalizations.of(
              context,
            ).refreshIndicatorSemanticLabel,
            visualDensity: VisualDensity.compact,
            onPressed: enabled && !isLoading ? onRefresh : null,
            icon: isLoading
                ? const SizedBox.square(
                    dimension: 16,
                    child: CommonCircleLoading(size: 16),
                  )
                : const GlyphIcon(AppGlyphs.refresh, size: 19),
          ),
          GlyphIcon(
            AppGlyphs.chevronForward,
            size: 18,
            color: context.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

class _EmptyDashboard extends StatelessWidget {
  final Glyph glyph;
  final String message;

  const _EmptyDashboard({required this.glyph, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GlyphIcon(
            glyph,
            size: 22,
            color: context.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyle.footnote
                  .of(context)
                  .copyWith(color: context.colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardResults extends StatelessWidget {
  final Map<String, UnlockTestRunItem> results;
  final bool isLoading;
  final String error;
  final DateTime? testedAt;
  final bool mobile;

  const _DashboardResults({
    required this.results,
    required this.isLoading,
    required this.error,
    required this.testedAt,
    required this.mobile,
  });

  @override
  Widget build(BuildContext context) {
    final ordered = results.values.toList(growable: false)
      ..sort((a, b) {
        final byStatus = _statusPriority(
          a.status,
        ).compareTo(_statusPriority(b.status));
        if (byStatus != 0) {
          return byStatus;
        }
        return a.id.compareTo(b.id);
      });
    final visible = ordered.take(8).toList(growable: false);
    final completed = results.values
        .where((item) => item.status != UnlockTestStatus.untested)
        .length;

    return Column(
      children: [
        SizedBox(
          height: 24,
          child: Row(
            children: [
              for (final status in UnlockTestStatus.values)
                Expanded(
                  child: _CompactStatus(
                    status: status,
                    count: results.values
                        .where((item) => item.status == status)
                        .length,
                  ),
                ),
              const SizedBox(width: 4),
              Text(
                isLoading
                    ? '$completed/${results.length}'
                    : error.isNotEmpty
                    ? context.appLocalizations.testFailed
                    : _formatTestedAt(context, testedAt),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyle.caption2
                    .of(context)
                    .copyWith(
                      color: error.isNotEmpty
                          ? context.colorScheme.error
                          : context.colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        if (mobile)
          _resultsGrid(visible, tileHeight: 44)
        else
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) => _resultsGrid(
                visible,
                tileHeight: (constraints.maxHeight - _gridSpacing) / 2,
              ),
            ),
          ),
      ],
    );
  }

  static const _gridSpacing = 6.0;

  Widget _resultsGrid(
    List<UnlockTestRunItem> visible, {
    required double tileHeight,
  }) {
    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: mobile,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: visible.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: _gridSpacing,
        mainAxisSpacing: _gridSpacing,
        mainAxisExtent: tileHeight,
      ),
      itemBuilder: (context, index) {
        return _ServiceTile(item: visible[index]);
      },
    );
  }
}

class _CompactStatus extends StatelessWidget {
  final UnlockTestStatus status;
  final int count;

  const _CompactStatus({required this.status, required this.count});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(context, status);
    return Tooltip(
      message: _statusLabel(context, status),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GlyphIcon(_statusIcon(status), size: 13, color: color),
          const SizedBox(width: 2),
          Text(
            '$count',
            style: AppTextStyle.caption2.of(context).copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  final UnlockTestRunItem item;

  const _ServiceTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final target = unlockTestTargetOf(item.id);
    final statusColor = _statusColor(context, item.status);
    final name = target?.name ?? item.id;
    final monogram =
        target?.monogram ?? (name.isEmpty ? '?' : name.characters.first);
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: statusColor.withValues(alpha: 0.09),
        shape: AppShape.all(
          10,
        ).copyWith(side: BorderSide(color: statusColor.withValues(alpha: 0.2))),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: ShapeDecoration(
                color: statusColor.withValues(alpha: 0.14),
                shape: AppShape.sm,
              ),
              child: Text(
                monogram,
                maxLines: 1,
                style: AppTextStyle.custom(
                  context,
                  size: AppTextStyle.caption2.size,
                  leading: AppTextStyle.caption2.leading,
                  weight: FontWeight.w700,
                ).copyWith(color: statusColor),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyle.caption2
                        .of(context, emphasized: true)
                        .copyWith(color: context.colorScheme.onSurface),
                  ),
                  Text(
                    _statusLabel(context, item.status),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyle.custom(
                      context,
                      size: 9,
                      leading: 11,
                    ).copyWith(color: statusColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

int _statusPriority(UnlockTestStatus status) {
  return switch (status) {
    UnlockTestStatus.error => 0,
    UnlockTestStatus.locked => 1,
    UnlockTestStatus.partial => 2,
    UnlockTestStatus.unlocked => 3,
    UnlockTestStatus.untested => 4,
  };
}

Glyph _statusIcon(UnlockTestStatus status) {
  return switch (status) {
    UnlockTestStatus.unlocked => AppGlyphs.checkCircle,
    UnlockTestStatus.partial => AppGlyphs.check,
    UnlockTestStatus.locked => AppGlyphs.block,
    UnlockTestStatus.error => AppGlyphs.error,
    UnlockTestStatus.untested => AppGlyphs.clock,
  };
}

Color _statusColor(BuildContext context, UnlockTestStatus status) {
  final colors = context.colorScheme;
  return switch (status) {
    UnlockTestStatus.unlocked => colors.primary,
    UnlockTestStatus.partial => colors.tertiary,
    UnlockTestStatus.locked => colors.error,
    UnlockTestStatus.error => colors.error,
    UnlockTestStatus.untested => colors.onSurfaceVariant,
  };
}

String _statusLabel(BuildContext context, UnlockTestStatus status) {
  final localizations = context.appLocalizations;
  return switch (status) {
    UnlockTestStatus.unlocked => localizations.unlocked,
    UnlockTestStatus.partial => localizations.unlockTestPartial,
    UnlockTestStatus.locked => localizations.locked,
    UnlockTestStatus.error => localizations.unlockTestError,
    UnlockTestStatus.untested => localizations.unlockTestUntested,
  };
}

String _formatTestedAt(BuildContext context, DateTime? dateTime) {
  if (dateTime == null) {
    return context.appLocalizations.unlockTestCurrentResults;
  }
  return MaterialLocalizations.of(context).formatTimeOfDay(
    TimeOfDay.fromDateTime(dateTime.toLocal()),
    alwaysUse24HourFormat: true,
  );
}
