import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/core/core.dart';
import 'package:fl_clash/icons/icons.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'network_test.dart';

typedef UnlockTestHistoryLoader =
    Future<List<UnlockTestHistoryEntry>> Function();

class UnlockTestView extends ConsumerStatefulWidget {
  final CoreController? controller;
  final UnlockTestHistoryLoader? historyLoader;

  const UnlockTestView({super.key, this.controller, this.historyLoader});

  @override
  ConsumerState<UnlockTestView> createState() => _UnlockTestViewState();
}

class _UnlockTestViewState extends ConsumerState<UnlockTestView> {
  final _searchController = TextEditingController();
  UnlockTestRouteMode _routeMode = UnlockTestRouteMode.appRoute;
  String _proxyName = 'DIRECT';
  UnlockTestStatus? _statusFilter;
  UnlockTestGroup? _groupFilter;
  String _query = '';
  UnlockTestHistoryEntry? _selectedHistory;
  late Future<List<UnlockTestHistoryEntry>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = _loadHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<UnlockTestHistoryEntry>> _loadHistory() {
    return (widget.historyLoader ?? loadUnlockTestHistory)();
  }

  void _reloadHistory() {
    if (!mounted) {
      return;
    }
    setState(() {
      _historyFuture = _loadHistory();
    });
  }

  void _handleEnableChanged(bool enable) {
    ref
        .read(unlockTestSettingProvider.notifier)
        .update((state) => state.copyWith(enable: enable));
  }

  Future<void> _handleStartTest() async {
    setState(() {
      _selectedHistory = null;
    });
    await ref
        .read(unlockDetectionProvider.notifier)
        .startCheck(
          routeMode: _routeMode,
          proxyName: _routeMode == UnlockTestRouteMode.proxy
              ? _proxyName
              : null,
          controller: widget.controller,
        );
    _reloadHistory();
  }

  Future<void> _handleStopTest() {
    return ref
        .read(unlockDetectionProvider.notifier)
        .stopCheck(controller: widget.controller);
  }

  Future<void> _selectProxy() async {
    final selected = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => NodeSelectionView(
          currentName: _proxyName,
          controller: widget.controller,
        ),
      ),
    );
    if (selected != null && selected.isNotEmpty && mounted) {
      setState(() {
        _proxyName = selected;
      });
    }
  }

  Future<void> _showTargetSelector() async {
    final initial = ref.read(unlockTestSettingProvider).selectedTargets.toSet();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        var selected = initial;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            void update(Iterable<String> values) {
              selected = values.toSet();
              setSheetState(() {});
              ref
                  .read(unlockTestSettingProvider.notifier)
                  .update(
                    (state) => state.copyWith(
                      selectedTargets: unlockTestTargets
                          .where((target) => selected.contains(target.id))
                          .map((target) => target.id)
                          .toList(growable: false),
                    ),
                  );
            }

            return SafeArea(
              child: SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.82,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 12, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              context.appLocalizations.unlockTestSelectTargets,
                              style: context.textTheme.titleLarge,
                            ),
                          ),
                          TextButton(
                            onPressed: () => update(
                              unlockTestTargets.map((target) => target.id),
                            ),
                            child: Text(
                              context.appLocalizations.unlockTestSelectAll,
                            ),
                          ),
                          TextButton(
                            onPressed: () => update(const []),
                            child: Text(
                              context.appLocalizations.unlockTestClearAll,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                        children: [
                          for (final group in UnlockTestGroup.values)
                            _TargetGroupSelector(
                              group: group,
                              selected: selected,
                              onChanged: update,
                            ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  update(defaultUnlockTestTargetIds),
                              icon: const GlyphIcon(AppGlyphs.reset),
                              label: Text(
                                context.appLocalizations.unlockTestResetDefault,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(
                                context.appLocalizations.unlockTestDone,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final props = ref.watch(unlockTestSettingProvider);
    final detection = ref.watch(unlockDetectionProvider);
    final currentTargets = resolveUnlockTestTargets(props.selectedTargets);
    final displayResults = _displayResults(currentTargets, detection);
    final filteredTargets = _filteredTargets(currentTargets, displayResults);
    final completed = displayResults.values
        .where((item) => item.status != UnlockTestStatus.untested)
        .length;
    final total = displayResults.length;

    return CommonScaffold(
      title: context.appLocalizations.unlockTest,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final columns = switch (constraints.maxWidth) {
            >= 1080 => 3,
            >= 680 => 2,
            _ => 1,
          };
          final horizontalPadding = constraints.maxWidth >= 900 ? 24.0 : 16.0;
          return ListView(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              8,
              horizontalPadding,
              28,
            ),
            children: [
              _buildControlCard(
                props: props,
                detection: detection,
                selectedCount: currentTargets.length,
                completed: completed,
                total: total,
              ),
              const SizedBox(height: 16),
              _buildSummary(displayResults),
              const SizedBox(height: 16),
              _buildFilterBar(),
              if (_selectedHistory != null) ...[
                const SizedBox(height: 12),
                _buildHistoryBanner(),
              ],
              const SizedBox(height: 12),
              if (filteredTargets.isEmpty)
                _buildEmptyState()
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredTargets.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    mainAxisExtent: 174,
                  ),
                  itemBuilder: (context, index) {
                    final target = filteredTargets[index];
                    return _UnlockServiceCard(
                      target: target,
                      item:
                          displayResults[target.id] ??
                          UnlockTestRunItem.untested(target.id),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }

  Map<String, UnlockTestRunItem> _displayResults(
    List<UnlockTestTarget> currentTargets,
    UnlockDetectionState detection,
  ) {
    if (_selectedHistory != null) {
      return {
        for (final item in _selectedHistory!.result.results) item.id: item,
      };
    }
    return {
      for (final target in currentTargets)
        target.id:
            detection.results[target.id] ??
            UnlockTestRunItem.untested(target.id),
    };
  }

  List<UnlockTestTarget> _filteredTargets(
    List<UnlockTestTarget> currentTargets,
    Map<String, UnlockTestRunItem> results,
  ) {
    final baseTargets = _selectedHistory == null
        ? currentTargets
        : unlockTestTargets
              .where((target) => results.containsKey(target.id))
              .toList();
    final normalizedQuery = _query.trim().toLowerCase();
    return baseTargets.where((target) {
      final item = results[target.id] ?? UnlockTestRunItem.untested(target.id);
      return (_groupFilter == null || target.group == _groupFilter) &&
          (_statusFilter == null || item.status == _statusFilter) &&
          (normalizedQuery.isEmpty ||
              target.name.toLowerCase().contains(normalizedQuery));
    }).toList();
  }

  Widget _buildControlCard({
    required UnlockTestProps props,
    required UnlockDetectionState detection,
    required int selectedCount,
    required int completed,
    required int total,
  }) {
    final colorScheme = context.colorScheme;
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainer,
      shape: AppShape.all(
        24,
      ).copyWith(side: BorderSide(color: colorScheme.outlineVariant)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: GlyphIcon(
                AppGlyphs.locate,
                color: colorScheme.primary,
              ),
              title: Text(
                context.appLocalizations.unlockTestEnable,
                style: context.textTheme.titleMedium,
              ),
              subtitle: Text(context.appLocalizations.unlockTestDesc),
              value: props.enable,
              onChanged: detection.isLoading ? null : _handleEnableChanged,
            ),
            const SizedBox(height: 12),
            SegmentedButton<UnlockTestRouteMode>(
              segments: [
                ButtonSegment(
                  value: UnlockTestRouteMode.appRoute,
                  icon: const GlyphIcon(AppGlyphs.split),
                  label: Text(context.appLocalizations.unlockTestFollowRules),
                ),
                ButtonSegment(
                  value: UnlockTestRouteMode.proxy,
                  icon: const GlyphIcon(AppGlyphs.dns),
                  label: Text(context.appLocalizations.unlockTestSpecifiedNode),
                ),
              ],
              selected: {_routeMode},
              onSelectionChanged: !props.enable || detection.isLoading
                  ? null
                  : (selection) {
                      setState(() {
                        _routeMode = selection.single;
                      });
                    },
            ),
            if (_routeMode == UnlockTestRouteMode.proxy) ...[
              const SizedBox(height: 12),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                leading: const GlyphIcon(AppGlyphs.shuffle),
                title: Text(context.appLocalizations.selectNode),
                subtitle: Text(_proxyName),
                trailing: const GlyphIcon(AppGlyphs.chevronForward),
                enabled: props.enable && !detection.isLoading,
                onTap: _selectProxy,
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                OutlinedButton.icon(
                  onPressed: detection.isLoading ? null : _showTargetSelector,
                  icon: const GlyphIcon(AppGlyphs.sliders),
                  label: Text(
                    '${context.appLocalizations.unlockTestSelectTargets} ($selectedCount)',
                  ),
                ),
                SizedBox(width: 230, child: _buildHistorySelector()),
                if (detection.isLoading)
                  FilledButton.tonalIcon(
                    onPressed: _handleStopTest,
                    icon: const GlyphIcon(AppGlyphs.close, fill: 1),
                    label: Text(context.appLocalizations.unlockTestStop),
                  )
                else
                  FilledButton.icon(
                    onPressed:
                        props.enable &&
                            selectedCount > 0 &&
                            _selectedHistory == null
                        ? _handleStartTest
                        : null,
                    icon: const GlyphIcon(AppGlyphs.bolt, fill: 1),
                    label: Text(context.appLocalizations.startTest),
                  ),
              ],
            ),
            if (detection.isLoading) ...[
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      label: '$completed of $total',
                      child: LinearProgressIndicator(
                        value: total == 0 ? null : completed / total,
                        minHeight: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '$completed / $total',
                    style: context.textTheme.labelLarge,
                  ),
                ],
              ),
            ],
            if (detection.error.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                '${context.appLocalizations.testFailed}: ${detection.error}',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHistorySelector() {
    return FutureBuilder<List<UnlockTestHistoryEntry>>(
      future: _historyFuture,
      builder: (context, snapshot) {
        final history = snapshot.data ?? const <UnlockTestHistoryEntry>[];
        final value = _selectedHistory?.result.runId ?? '__current__';
        return DropdownButtonFormField<String>(
          initialValue: history.any((entry) => entry.result.runId == value)
              ? value
              : '__current__',
          isExpanded: true,
          decoration: InputDecoration(
            labelText: context.appLocalizations.unlockTestHistory,
            prefixIcon: const GlyphIcon(AppGlyphs.history),
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          items: [
            DropdownMenuItem(
              value: '__current__',
              child: Text(
                context.appLocalizations.unlockTestCurrentResults,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            for (final entry in history)
              DropdownMenuItem(
                value: entry.result.runId,
                child: Text(
                  _historyLabel(entry),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: (runId) {
            setState(() {
              if (runId == null || runId == '__current__') {
                _selectedHistory = null;
              } else {
                _selectedHistory = history
                    .where((entry) => entry.result.runId == runId)
                    .firstOrNull;
              }
            });
          },
        );
      },
    );
  }

  String _historyLabel(UnlockTestHistoryEntry entry) {
    final localizations = MaterialLocalizations.of(context);
    final date = localizations.formatCompactDate(entry.createdAt);
    final time = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(entry.createdAt),
      alwaysUse24HourFormat: true,
    );
    final source = entry.result.routeMode == UnlockTestRouteMode.appRoute
        ? context.appLocalizations.unlockTestFollowRules
        : (entry.result.proxyName ??
              context.appLocalizations.unlockTestSpecifiedNode);
    return '$date $time · $source';
  }

  Widget _buildSummary(Map<String, UnlockTestRunItem> results) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final status in UnlockTestStatus.values)
          _StatusSummaryCard(
            status: status,
            count: results.values.where((item) => item.status == status).length,
            selected: _statusFilter == status,
            onPressed: () {
              setState(() {
                _statusFilter = _statusFilter == status ? null : status;
              });
            },
          ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SearchBar(
          controller: _searchController,
          hintText: context.appLocalizations.unlockTestSearch,
          leading: const GlyphIcon(AppGlyphs.search),
          trailing: [
            if (_query.isNotEmpty)
              IconButton(
                tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _query = '';
                  });
                },
                icon: const GlyphIcon(AppGlyphs.close),
              ),
          ],
          onChanged: (value) {
            setState(() {
              _query = value;
            });
          },
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ChoiceChip(
                label: Text(context.appLocalizations.unlockTestAll),
                selected: _groupFilter == null,
                onSelected: (_) => setState(() => _groupFilter = null),
              ),
              const SizedBox(width: 8),
              for (final group in UnlockTestGroup.values) ...[
                ChoiceChip(
                  label: Text(_groupLabel(context, group)),
                  selected: _groupFilter == group,
                  onSelected: (_) => setState(() => _groupFilter = group),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: ShapeDecoration(
        color: context.colorScheme.tertiaryContainer,
        shape: AppShape.md,
      ),
      child: Row(
        children: [
          GlyphIcon(
            AppGlyphs.history,
            color: context.colorScheme.onTertiaryContainer,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${context.appLocalizations.unlockTestHistoryResult} · ${_historyLabel(_selectedHistory!)}',
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onTertiaryContainer,
              ),
            ),
          ),
          IconButton(
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            onPressed: () => setState(() => _selectedHistory = null),
            icon: const GlyphIcon(AppGlyphs.close),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 56),
      alignment: Alignment.center,
      child: Column(
        children: [
          GlyphIcon(
            AppGlyphs.locate,
            size: 48,
            color: context.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            context.appLocalizations.unlockTestNoResults,
            style: context.textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

class _TargetGroupSelector extends StatelessWidget {
  final UnlockTestGroup group;
  final Set<String> selected;
  final ValueChanged<Iterable<String>> onChanged;

  const _TargetGroupSelector({
    required this.group,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final targets = unlockTestTargetsOfGroup(group);
    final selectedInGroup = targets
        .where((target) => selected.contains(target.id))
        .length;
    final allSelected = selectedInGroup == targets.length;
    return Card(
      elevation: 0,
      color: context.colorScheme.surfaceContainerLow,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          CheckboxListTile(
            value: allSelected
                ? true
                : selectedInGroup == 0
                ? false
                : null,
            tristate: true,
            title: Text(
              _groupLabel(context, group),
              style: context.textTheme.titleSmall,
            ),
            subtitle: Text('$selectedInGroup / ${targets.length}'),
            onChanged: (value) {
              final next = selected.toSet();
              if (value == true) {
                next.addAll(targets.map((target) => target.id));
              } else {
                next.removeAll(targets.map((target) => target.id));
              }
              onChanged(next);
            },
          ),
          const Divider(height: 1),
          for (final target in targets)
            CheckboxListTile(
              value: selected.contains(target.id),
              secondary: _ServiceMonogram(target: target, size: 36),
              title: Text(target.name),
              onChanged: (value) {
                final next = selected.toSet();
                if (value == true) {
                  next.add(target.id);
                } else {
                  next.remove(target.id);
                }
                onChanged(next);
              },
            ),
        ],
      ),
    );
  }
}

class _StatusSummaryCard extends StatelessWidget {
  final UnlockTestStatus status;
  final int count;
  final bool selected;
  final VoidCallback onPressed;

  const _StatusSummaryCard({
    required this.status,
    required this.count,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final presentation = _statusPresentation(context, status);
    return Semantics(
      button: true,
      selected: selected,
      label: '${presentation.label}: $count',
      child: Material(
        color: selected
            ? presentation.color.withValues(alpha: 0.18)
            : context.colorScheme.surfaceContainer,
        shape: AppShape.all(18).copyWith(
          side: BorderSide(
            color: selected
                ? presentation.color
                : context.colorScheme.outlineVariant,
          ),
        ),
        child: InkWell(
          customBorder: AppShape.all(18),
          onTap: onPressed,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 118, minHeight: 72),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GlyphIcon(
                    presentation.glyph,
                    color: presentation.color,
                    size: 22,
                  ),
                  const SizedBox(width: 9),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$count', style: context.textTheme.titleLarge),
                      Text(
                        presentation.label,
                        style: context.textTheme.labelMedium,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UnlockServiceCard extends StatelessWidget {
  final UnlockTestTarget target;
  final UnlockTestRunItem item;

  const _UnlockServiceCard({required this.target, required this.item});

  @override
  Widget build(BuildContext context) {
    final presentation = _statusPresentation(context, item.status);
    final reason = _reasonLabel(context, item.reason);
    final outbound = item.outboundChains.isEmpty
        ? ''
        : item.outboundChains.length == 1
        ? item.outboundChains.first
        : '${item.outboundChains.first} +${item.outboundChains.length - 1}';
    return Semantics(
      container: true,
      label: '${target.name}, ${presentation.label}',
      child: Card(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        color: context.colorScheme.surfaceContainerLow,
        shape: AppShape.all(
          22,
        ).copyWith(side: BorderSide(color: context.colorScheme.outlineVariant)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  _ServiceMonogram(target: target),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      target.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.titleMedium,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: ShapeDecoration(
                      color: presentation.color.withValues(alpha: 0.14),
                      shape: AppShape.full,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GlyphIcon(
                          presentation.glyph,
                          size: 16,
                          color: presentation.color,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          presentation.label,
                          style: context.textTheme.labelMedium?.copyWith(
                            color: presentation.color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (reason.isNotEmpty)
                Text(
                  reason,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                )
              else
                const SizedBox(height: 32),
              const Spacer(),
              Wrap(
                spacing: 12,
                runSpacing: 6,
                children: [
                  if (item.region.isNotEmpty)
                    _MetaLabel(
                      glyph: AppGlyphs.cloud,
                      text:
                          '${context.appLocalizations.unlockTestRegion} ${item.region}',
                    )
                  else
                    _MetaLabel(
                      glyph: AppGlyphs.cloud,
                      text: _groupLabel(context, target.group),
                    ),
                  if (item.latency > 0)
                    _MetaLabel(
                      glyph: AppGlyphs.speed,
                      text: '${item.latency} ms',
                    ),
                  if (outbound.isNotEmpty)
                    Tooltip(
                      message: item.outboundChains.join(' → '),
                      child: _MetaLabel(glyph: AppGlyphs.split, text: outbound),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaLabel extends StatelessWidget {
  final Glyph glyph;
  final String text;

  const _MetaLabel({required this.glyph, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GlyphIcon(glyph, size: 15, color: context.colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 130),
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.labelSmall?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _ServiceMonogram extends StatelessWidget {
  final UnlockTestTarget target;
  final double size;

  const _ServiceMonogram({required this.target, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: target.name,
      image: true,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: ShapeDecoration(
          color: context.colorScheme.primaryContainer,
          shape: AppShape.all(size * 0.34),
        ),
        child: Text(
          target.monogram,
          style: context.textTheme.labelLarge?.copyWith(
            color: context.colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w800,
            fontSize: size > 40 ? 13 : 11,
          ),
        ),
      ),
    );
  }
}

class _StatusPresentation {
  final String label;
  final Glyph glyph;
  final Color color;

  const _StatusPresentation({
    required this.label,
    required this.glyph,
    required this.color,
  });
}

_StatusPresentation _statusPresentation(
  BuildContext context,
  UnlockTestStatus status,
) {
  final localizations = context.appLocalizations;
  final colors = context.colorScheme;
  return switch (status) {
    UnlockTestStatus.unlocked => _StatusPresentation(
      label: localizations.unlocked,
      glyph: AppGlyphs.checkCircle,
      color: colors.primary,
    ),
    UnlockTestStatus.partial => _StatusPresentation(
      label: localizations.unlockTestPartial,
      glyph: AppGlyphs.check,
      color: colors.tertiary,
    ),
    UnlockTestStatus.locked => _StatusPresentation(
      label: localizations.locked,
      glyph: AppGlyphs.block,
      color: colors.error,
    ),
    UnlockTestStatus.error => _StatusPresentation(
      label: localizations.unlockTestError,
      glyph: AppGlyphs.error,
      color: colors.error,
    ),
    UnlockTestStatus.untested => _StatusPresentation(
      label: localizations.unlockTestUntested,
      glyph: AppGlyphs.clock,
      color: colors.onSurfaceVariant,
    ),
  };
}

String _reasonLabel(BuildContext context, UnlockTestReason reason) {
  final localizations = context.appLocalizations;
  return switch (reason) {
    UnlockTestReason.none => '',
    UnlockTestReason.contentLimited => localizations.unlockReasonContentLimited,
    UnlockTestReason.geoBlocked => localizations.unlockReasonGeoBlocked,
    UnlockTestReason.vpnBlocked => localizations.unlockReasonVpnBlocked,
    UnlockTestReason.rateLimited => localizations.unlockReasonRateLimited,
    UnlockTestReason.timeout => localizations.unlockReasonTimeout,
    UnlockTestReason.networkError => localizations.unlockReasonNetworkError,
    UnlockTestReason.bootstrapFailed =>
      localizations.unlockReasonBootstrapFailed,
    UnlockTestReason.unexpectedResponse =>
      localizations.unlockReasonUnexpectedResponse,
  };
}

String _groupLabel(BuildContext context, UnlockTestGroup group) {
  final localizations = context.appLocalizations;
  return switch (group) {
    UnlockTestGroup.ai => localizations.aiServices,
    UnlockTestGroup.globalMedia => localizations.unlockTestGroupGlobalMedia,
    UnlockTestGroup.europe => localizations.unlockTestGroupEurope,
    UnlockTestGroup.hongKongTaiwan =>
      localizations.unlockTestGroupHongKongTaiwan,
    UnlockTestGroup.japan => localizations.unlockTestGroupJapan,
    UnlockTestGroup.korea => localizations.unlockTestGroupKorea,
  };
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
