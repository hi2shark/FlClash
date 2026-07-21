import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/views/unlock_test.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    return SizedBox(
      height: getWidgetHeight(2),
      child: CommonCard(
        onPressed: () {
          BaseNavigator.push(context, const UnlockTestView());
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Column(
            children: [
              _DashboardHeader(
                enabled: enabled,
                isLoading: detection.isLoading,
                onRefresh: _refresh,
              ),
              const SizedBox(height: 6),
              Expanded(
                child: !enabled
                    ? _EmptyDashboard(
                        icon: Icons.power_settings_new_rounded,
                        message: context.appLocalizations.unlockTestDisabledTip,
                      )
                    : FutureBuilder<UnlockTestHistoryEntry?>(
                        future: _history,
                        builder: (context, snapshot) {
                          final currentIsAppRoute =
                              detection.proxyName.isEmpty &&
                              (detection.isLoading ||
                                  detection.results.isNotEmpty);
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
                              icon: Icons.fact_check_outlined,
                              message:
                                  context.appLocalizations.unlockTestNoResults,
                            );
                          }
                          return _DashboardResults(
                            results: results,
                            isLoading: currentIsAppRoute && detection.isLoading,
                            error: currentIsAppRoute ? detection.error : '',
                            testedAt: currentIsAppRoute
                                ? detection.testedAt
                                : snapshot.data?.createdAt,
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
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
          Icon(
            Icons.travel_explore_rounded,
            size: 20,
            color: context.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.appLocalizations.unlockTest,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.titleSmall,
            ),
          ),
          Tooltip(
            message: context.appLocalizations.unlockTestFollowRules,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 120),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.alt_route_rounded,
                    size: 14,
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      context.appLocalizations.unlockTestFollowRules,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.labelSmall?.copyWith(
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
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded, size: 19),
          ),
          Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: context.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

class _EmptyDashboard extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyDashboard({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22, color: context.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
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

  const _DashboardResults({
    required this.results,
    required this.isLoading,
    required this.error,
    required this.testedAt,
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
                style: context.textTheme.labelSmall?.copyWith(
                  color: error.isNotEmpty
                      ? context.colorScheme.error
                      : context.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 6.0;
              final tileHeight = (constraints.maxHeight - spacing) / 2;
              return GridView.builder(
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: visible.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: spacing,
                  mainAxisSpacing: spacing,
                  mainAxisExtent: tileHeight,
                ),
                itemBuilder: (context, index) {
                  return _ServiceTile(item: visible[index]);
                },
              );
            },
          ),
        ),
      ],
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
          Icon(_statusIcon(status), size: 13, color: color),
          const SizedBox(width: 2),
          Text(
            '$count',
            style: context.textTheme.labelSmall?.copyWith(color: color),
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
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: statusColor.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                monogram,
                maxLines: 1,
                style: context.textTheme.labelSmall?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w700,
                ),
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
                    style: context.textTheme.labelSmall?.copyWith(
                      color: context.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _statusLabel(context, item.status),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.labelSmall?.copyWith(
                      color: statusColor,
                      fontSize: 9,
                    ),
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

IconData _statusIcon(UnlockTestStatus status) {
  return switch (status) {
    UnlockTestStatus.unlocked => Icons.check_circle_rounded,
    UnlockTestStatus.partial => Icons.adjust_rounded,
    UnlockTestStatus.locked => Icons.block_rounded,
    UnlockTestStatus.error => Icons.error_rounded,
    UnlockTestStatus.untested => Icons.help_rounded,
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
