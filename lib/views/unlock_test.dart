import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/core/core.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'network_test.dart';

class UnlockTestView extends ConsumerStatefulWidget {
  final CoreController? controller;

  const UnlockTestView({super.key, this.controller});

  @override
  ConsumerState<UnlockTestView> createState() => _UnlockTestViewState();
}

class _UnlockTestViewState extends ConsumerState<UnlockTestView> {
  String _proxyName = 'DIRECT';

  void _handleEnableChanged(bool enable) {
    ref
        .read(unlockTestSettingProvider.notifier)
        .update((state) => state.copyWith(enable: enable));
  }

  void _handleTargetChanged(UnlockTestTarget target, bool selected) {
    ref.read(unlockTestSettingProvider.notifier).update((state) {
      final selectedTargets = [...state.selectedTargets];
      if (selected) {
        if (!selectedTargets.contains(target.id)) {
          selectedTargets.add(target.id);
        }
      } else {
        selectedTargets.remove(target.id);
      }
      return state.copyWith(selectedTargets: selectedTargets);
    });
  }

  Future<void> _handleStartTest() async {
    await ref
        .read(unlockDetectionProvider.notifier)
        .startCheck(proxyName: _proxyName);
  }

  Widget _buildTargetSelector(
    UnlockTestGroup group,
    List<String> selectedTargets,
  ) {
    final appLocalizations = context.appLocalizations;
    final targets = unlockTestTargetsOfGroup(group);
    return Column(
      children: [
        for (final target in targets) ...[
          ListItem<dynamic>.checkbox(
            title: Text(target.name),
            subtitle: Text(
              target.url,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            delegate: CheckboxDelegate(
              value: selectedTargets.contains(target.id),
              onChanged: (value) {
                _handleTargetChanged(target, value ?? false);
              },
            ),
          ),
          if (target != targets.last) const Divider(height: 0),
        ],
        if (targets.isEmpty) ListItem(title: Text(appLocalizations.noData)),
      ],
    );
  }

  Widget _buildTargetResultRow(
    UnlockTestTarget target,
    UnlockDetectionState detection,
  ) {
    final appLocalizations = context.appLocalizations;
    final result = detection.results[target.id];
    final details = <String>[
      if (result != null && result.region.isNotEmpty) result.region,
      if (result != null && result.latency > 0) '${result.latency} ms',
      if (result != null && result.error.isNotEmpty) result.error,
    ];
    final Widget statusWidget;
    if (result == null) {
      statusWidget = Text('—', style: context.textTheme.bodyMedium?.toLight);
    } else if (result.error.isNotEmpty) {
      statusWidget = Tooltip(
        message: result.error,
        child: Icon(
          Icons.error_outline,
          size: 18,
          color: context.colorScheme.error,
        ),
      );
    } else if (result.unlocked) {
      statusWidget = Tooltip(
        message: appLocalizations.unlocked,
        child: const Icon(Icons.check_circle, size: 18, color: Colors.green),
      );
    } else {
      statusWidget = Tooltip(
        message: appLocalizations.locked,
        child: Icon(Icons.cancel, size: 18, color: context.colorScheme.error),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              target.name,
              style: context.textTheme.bodyMedium?.toLight,
            ),
          ),
          if (details.isNotEmpty)
            Flexible(
              flex: 2,
              child: Tooltip(
                message: details.join(' · '),
                child: Text(
                  details.join(' · '),
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodyMedium?.toLight,
                ),
              ),
            ),
          const SizedBox(width: 8),
          statusWidget,
        ],
      ),
    );
  }

  Widget? _buildTestResult(
    List<UnlockTestTarget> targets,
    UnlockDetectionState detection,
  ) {
    if (detection.isLoading || detection.error.isNotEmpty) {
      return null;
    }
    if (detection.results.isEmpty) {
      return null;
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final target in targets) _buildTargetResultRow(target, detection),
      ],
    );
  }

  Widget _buildTestCard(
    bool enable,
    List<UnlockTestTarget> targets,
    UnlockDetectionState detection,
  ) {
    final appLocalizations = context.appLocalizations;
    final Widget? result;
    if (detection.error.isNotEmpty && !detection.isLoading) {
      result = Text(
        '${appLocalizations.testFailed}: ${detection.error}',
        style: context.textTheme.bodyMedium?.copyWith(
          color: context.colorScheme.error,
        ),
      );
    } else {
      result = _buildTestResult(targets, detection);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: CommonCard(
        radius: 18,
        onPressed: () {},
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: double.infinity,
                child: Text(
                  appLocalizations.unlockTestRunDesc,
                  style: context.textTheme.bodyMedium?.toLight,
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: detection.isLoading || !enable || targets.isEmpty
                    ? null
                    : _handleStartTest,
                icon: detection.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_arrow),
                label: Text(
                  detection.isLoading
                      ? appLocalizations.testing
                      : appLocalizations.startTest,
                ),
              ),
              if (result != null) ...[const Divider(height: 24), result],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    final unlockTestProps = ref.watch(unlockTestSettingProvider);
    final enable = unlockTestProps.enable;
    final selectedTargets = unlockTestProps.selectedTargets;
    final targets = resolveUnlockTestTargets(selectedTargets);
    final detection = ref.watch(unlockDetectionProvider);
    return CommonScaffold(
      title: appLocalizations.unlockTest,
      body: ListView(
        padding: const EdgeInsets.only(bottom: 20),
        children: [
          ...generateSection(
            title: appLocalizations.selectNode,
            items: [
              ListItem<dynamic>.open(
                leading: const Icon(Icons.dns),
                title: Text(appLocalizations.selectNode),
                subtitle: Text(_proxyName),
                delegate: OpenDelegate<dynamic>(
                  widget: NodeSelectionView(
                    currentName: _proxyName,
                    controller: widget.controller,
                  ),
                  onChanged: (name) {
                    if (name is String && name != _proxyName) {
                      setState(() {
                        _proxyName = name;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          ...generateSection(
            title: appLocalizations.unlockTest,
            items: [
              ListItem<dynamic>.switchItem(
                leading: const Icon(Icons.vpn_key),
                title: Text(appLocalizations.unlockTestEnable),
                delegate: SwitchDelegate(
                  value: enable,
                  onChanged: _handleEnableChanged,
                ),
              ),
            ],
          ),
          DisabledMask(
            status: !enable,
            child: ActivateBox(
              active: enable,
              child: Column(
                children: [
                  ...generateSection(
                    title: appLocalizations.aiServices,
                    items: [
                      _buildTargetSelector(UnlockTestGroup.ai, selectedTargets),
                    ],
                  ),
                  ...generateSection(
                    title: appLocalizations.mediaServices,
                    items: [
                      _buildTargetSelector(
                        UnlockTestGroup.media,
                        selectedTargets,
                      ),
                    ],
                  ),
                  ...generateSection(
                    title: appLocalizations.startTest,
                    items: [
                      if (targets.isEmpty)
                        ListItem(
                          leading: const Icon(Icons.info_outline),
                          title: Text(appLocalizations.unlockTestNoTargets),
                        )
                      else
                        _buildTestCard(enable, targets, detection),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
