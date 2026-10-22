import 'dart:async';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/plugins/app.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/ui/icons/icons.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wifi_ssid/wifi_ssid.dart';

class OnDemandView extends ConsumerStatefulWidget {
  const OnDemandView({super.key, this.isAndroid, this.isMacOS});

  final bool? isAndroid;
  final bool? isMacOS;

  @override
  ConsumerState createState() => _OnDemandViewState();
}

class _OnDemandViewState extends ConsumerState<OnDemandView>
    with UniqueKeyStateMixin {
  static const _authorizeButtonPadding = 12.0;
  static const _minAuthorizeButtonWidth = 80.0;

  bool get _isAndroid => widget.isAndroid ?? system.isAndroid;

  bool get _isMacOS => widget.isMacOS ?? system.isMacOS;

  Future<void> _handleCopySsid(BuildContext context, String? ssid) async {
    if (ssid == null || ssid.isEmpty) {
      return;
    }
    await Clipboard.setData(ClipboardData(text: ssid));
    if (context.mounted) {
      context.showNotifier(context.appLocalizations.copySuccess);
    }
  }

  void _handlePermanentlyDeniedLocationPermission() {
    if (_isMacOS) {
      final appLocalizations = context.appLocalizations;
      dialogs.showMessage(
        title: appLocalizations.locationPermissionRequired,
        cancelable: false,
        message: TextSpan(
          style: AppTextStyle.subheadline.of(context),
          text: appLocalizations.locationPermissionGuide(appName),
        ),
      );
    } else if (_isAndroid) {
      app?.openAppSettings();
    }
  }

  Future<void> _handleRequestLocationPermission() async {
    final appLocalizations = context.appLocalizations;
    final permission = ref.read(locationPermissionsProvider);
    if (permission == WifiSsidPermission.granted) {
      return;
    }
    if (permission == WifiSsidPermission.permanentlyDenied) {
      _handlePermanentlyDeniedLocationPermission();
      return;
    }
    final WifiSsidPermission? res;
    try {
      res = await ref.read(locationPermissionsProvider.notifier).request();
    } on PlatformException catch (e) {
      commonPrint.log('requestPermission error $e', logLevel: LogLevel.warning);
      return;
    }
    if (res == null || !mounted) {
      return;
    }
    switch (res) {
      case WifiSsidPermission.granted:
        return;
      case WifiSsidPermission.permanentlyDenied:
        _handlePermanentlyDeniedLocationPermission();
        return;
      case WifiSsidPermission.denied:
        break;
    }
    final needGo = await dialogs.showMessage(
      title: appLocalizations.locationPermissionRequired,
      message: TextSpan(text: appLocalizations.locationPermissionDeniedMessage),
      confirmText: appLocalizations.go,
    );
    if (needGo != true) {
      return;
    }
    unawaited(app?.openAppSettings());
  }

  void _handleRequestIgnoreBatteryOptimization() {
    if (ref.read(batteryOptimizationIgnoredProvider).value == true) {
      return;
    }
    unawaited(ref.read(batteryOptimizationIgnoredProvider.notifier).request());
  }

  Future<void> _handleRequestBackgroundLocationPermission() async {
    final permission = ref.read(backgroundLocationPermissionsProvider);
    if (permission == WifiSsidPermission.granted) {
      return;
    }
    if (permission == WifiSsidPermission.permanentlyDenied) {
      unawaited(app?.openAppSettings());
      return;
    }
    final res = await wifiSsidManager.requestBackgroundPermission();
    if (!mounted) {
      return;
    }
    ref.read(backgroundLocationPermissionsProvider.notifier).value = res;
  }

  Future<void> _handleAddOrUpdate([String? ssid]) async {
    final ssids = ref.read(excludeSSIDsProvider);
    final appLocalizations = context.appLocalizations;
    final newSSID = await dialogs.showCommonDialog<String>(
      child: InputDialog(
        title: ssid == null
            ? appLocalizations.addSsid
            : appLocalizations.editSsid,
        value: ssid ?? '',
        maxLength: 32,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return appLocalizations.emptyTip('SSID').trim();
          }
          if (ssids.contains(value) && ssid != value) {
            return appLocalizations.existsTip('SSID').trim();
          }
          return null;
        },
      ),
    );
    if (newSSID == null || ssid == newSSID) {
      return;
    }
    ref.read(excludeSSIDsProvider.notifier).update((state) {
      final newSSIDS = state.toSet();
      if (ssid != null) {
        newSSIDS.remove(ssid);
      }
      return [...newSSIDS, newSSID];
    });
  }

  void _handleReorder(int oldIndex, newIndex) {
    ref.read(excludeSSIDsProvider.notifier).update((value) {
      return value.copyAndReorder(oldIndex, newIndex);
    });
  }

  Glyph _signalGlyph(int? rssi, bool hasNetwork) {
    if (rssi != null && rssi < -70) {
      return AppGlyphs.wifiOff;
    }
    return hasNetwork || rssi != null ? AppGlyphs.wifi : AppGlyphs.wifiOff;
  }

  Color _signalColor(
    BuildContext context,
    int? rssi,
    bool hasNetwork,
    bool isExcluded,
    bool validated,
  ) {
    if (isExcluded && validated) {
      return context.colorScheme.error;
    }
    if (rssi == null) {
      return hasNetwork
          ? context.colorScheme.primary
          : context.colorScheme.outline;
    }
    if (rssi >= -60) return Colors.green;
    if (rssi >= -75) return Colors.orange;
    return context.colorScheme.error;
  }

  String _currentWifiStatus(
    BuildContext context,
    WifiWatchState state,
    bool isExcluded,
    bool enabled,
  ) {
    final appLocalizations = context.appLocalizations;
    if (!enabled) {
      return appLocalizations.disabled;
    }
    final hasKnownSsid = state.ssid != null || state.rawSsid != null;
    if (state.suspended) {
      return appLocalizations.suspended;
    }
    final deadline = state.pendingSuspendDeadline;
    if (deadline != null) {
      final remaining = deadline.difference(DateTime.now()).inSeconds;
      if (remaining <= 0) {
        return appLocalizations.wifiWatchSuspendingNow;
      }
      if (isExcluded) {
        return appLocalizations.wifiWatchExcludedWillSuspend(
          remaining.toString(),
        );
      }
      return appLocalizations.wifiWatchWillSuspend(remaining.toString());
    }
    if (!state.wifiPresent && !hasKnownSsid) {
      return appLocalizations.wifiWatchNoWifi;
    }
    if (!hasKnownSsid) {
      return appLocalizations.wifiWatchResolving;
    }
    if (isExcluded) {
      return state.validated
          ? appLocalizations.wifiWatchExcluded
          : appLocalizations.wifiWatchExcludedInactive;
    }
    if (state.validated) {
      return appLocalizations.wifiWatchTrusted;
    }
    return appLocalizations.wifiWatchListening;
  }

  Widget _buildCurrentWifiSection() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(top: 16),
      sliver: SliverToBoxAdapter(
        child: Consumer(
          builder: (context, ref, _) {
            final appLocalizations = context.appLocalizations;
            final state = ref.watch(wifiWatchProvider);
            final enabled = ref.watch(onDemandEnabledProvider);
            final excludeSSIDs = ref.watch(excludeSSIDsProvider);
            final ssid = state.ssid ?? state.rawSsid;
            final hasSsid = ssid != null;
            final hasNetwork = hasSsid || state.wifiPresent;
            final isExcluded =
                enabled && hasSsid && excludeSSIDs.contains(ssid);
            final ssidTextStyle = AppTextStyle.subheadline.of(context).toLight;
            final matchedSsidTextStyle = AppTextStyle.custom(
              context,
              size: AppTextStyle.subheadline.size,
              leading: AppTextStyle.subheadline.leading,
              weight: FontWeight.w700,
            ).copyWith(color: Colors.green);
            return generateSection(
              title: appLocalizations.currentWifiConnection,
              items: [
                DecorationListItem(
                  title: Text(appLocalizations.currentWifiSsid),
                  trailing: Text(
                    ssid ??
                        (hasNetwork
                            ? appLocalizations.wifiWatchResolving
                            : appLocalizations.wifiWatchNoWifi),
                    style: isExcluded ? matchedSsidTextStyle : ssidTextStyle,
                  ),
                  onPressed: hasSsid
                      ? () => _handleCopySsid(context, ssid)
                      : null,
                ),
                DecorationListItem(
                  title: Text(appLocalizations.currentWifiSignal),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (hasNetwork) ...[
                        GlyphIcon(
                          _signalGlyph(state.rssi, hasNetwork),
                          size: 16.ap(context),
                          color: _signalColor(
                            context,
                            state.rssi,
                            hasNetwork,
                            isExcluded,
                            state.validated,
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        state.rssi != null ? '${state.rssi} dBm' : '-',
                        style: AppTextStyle.subheadline.of(context).toLight,
                      ),
                    ],
                  ),
                ),
                DecorationListItem(
                  title: Text(appLocalizations.currentWifiStatus),
                  trailing: Text(
                    _currentWifiStatus(context, state, isExcluded, enabled),
                    style: AppTextStyle.subheadline.of(context).toLight,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildItem({
    required String ssid,
    required int index,
    required int length,
    required bool isSelected,
    required bool isEditing,
  }) {
    final position = ItemPosition.get(index, length);
    return ReorderableDelayedDragStartListener(
      key: ValueKey(ssid),
      index: index,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ItemPositionProvider(
          position: position,
          child: SelectedDecorationListItem(
            isEditing: isEditing,
            title: TooltipText(
              text: Text(ssid, maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
            isSelected: isSelected,
            onSelected: () {
              ref.read(itemsProvider(key).notifier).update((state) {
                final newState = Set<String>.from(state)..addOrRemove(ssid);
                return newState;
              });
            },
            onPressed: () {
              _handleAddOrUpdate(ssid);
            },
          ),
        ),
      ),
    );
  }

  void _handleSelectAll() {
    final excludeSSIDs = ref.read(excludeSSIDsProvider).toSet();
    ref.read(itemsProvider(key).notifier).update((selected) {
      return selected.containsAll(excludeSSIDs) ? {} : excludeSSIDs;
    });
  }

  void _handleDelete() {
    final selectedItems = ref.read(itemsProvider(key));
    ref.read(excludeSSIDsProvider.notifier).update((excludeSSIDs) {
      return excludeSSIDs
          .where((item) => !selectedItems.contains(item))
          .toList();
    });
    ref.read(itemsProvider(key).notifier).value = {};
  }

  Widget _buildAuthorizeButton({
    required bool authorized,
    required VoidCallback onPressed,
  }) {
    final appLocalizations = context.appLocalizations;
    return CommonMinFilledButtonTheme(
      child: ElasticButton(
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: authorized
                ? null
                : context.colorScheme.errorContainer,
            foregroundColor: authorized
                ? null
                : context.colorScheme.onErrorContainer,
            padding: const EdgeInsets.symmetric(
              horizontal: _authorizeButtonPadding,
            ),
            minimumSize: const Size(_minAuthorizeButtonWidth, 40),
          ),
          onPressed: onPressed,
          child: Stack(
            alignment: Alignment.center,
            children: [
              ExcludeSemantics(
                child: Opacity(
                  opacity: 0,
                  child: Text(
                    authorized
                        ? appLocalizations.tapToAuthorize
                        : appLocalizations.authorized,
                  ),
                ),
              ),
              Text(
                authorized
                    ? appLocalizations.authorized
                    : appLocalizations.tapToAuthorize,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrerequisiteItem({
    required String title,
    required Widget action,
  }) {
    return DecorationListItem(title: TooltipLabel(title), trailing: action);
  }

  Widget _buildBatteryOptimizationItem() {
    final appLocalizations = context.appLocalizations;
    final ignored = ref.watch(batteryOptimizationIgnoredProvider);
    final isLoading = ignored.isLoading;
    return _buildPrerequisiteItem(
      title: appLocalizations.ignoreBatteryOptimization,
      action: Stack(
        alignment: Alignment.centerRight,
        children: [
          Visibility(
            visible: !isLoading,
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            child: _buildAuthorizeButton(
              authorized: ignored.value ?? false,
              onPressed: _handleRequestIgnoreBatteryOptimization,
            ),
          ),
          if (isLoading) const CommonCircleLoading(size: 24),
        ],
      ),
    );
  }

  Widget _buildLocationPermissionItem() {
    final appLocalizations = context.appLocalizations;
    final granted = ref.watch(
      locationPermissionsProvider.select(
        (state) => state == WifiSsidPermission.granted,
      ),
    );
    return _buildPrerequisiteItem(
      title: appLocalizations.locationPermission,
      action: _buildAuthorizeButton(
        authorized: granted,
        onPressed: _handleRequestLocationPermission,
      ),
    );
  }

  Widget _buildBackgroundLocationPermissionItem() {
    final appLocalizations = context.appLocalizations;
    final granted = ref.watch(
      backgroundLocationPermissionsProvider.select(
        (state) => state == WifiSsidPermission.granted,
      ),
    );
    return _buildPrerequisiteItem(
      title: appLocalizations.backgroundLocationPermission,
      action: _buildAuthorizeButton(
        authorized: granted,
        onPressed: _handleRequestBackgroundLocationPermission,
      ),
    );
  }

  Widget _buildPrerequisites() {
    final appLocalizations = context.appLocalizations;
    return generateSection(
      title: appLocalizations.prerequisites,
      items: [
        if (_isAndroid) _buildBatteryOptimizationItem(),
        if (_isAndroid || _isMacOS) _buildLocationPermissionItem(),
        if (_isAndroid) _buildBackgroundLocationPermissionItem(),
      ],
      footer: [
        if (_isAndroid) appLocalizations.batteryOptimizationDesc,
        if (_isAndroid || _isMacOS) appLocalizations.locationPermissionDesc,
        if (_isAndroid) appLocalizations.backgroundLocationPermissionDesc,
      ].join('\n'),
    );
  }

  Widget _buildOnDemandSection() {
    final appLocalizations = context.appLocalizations;
    final enabled = ref.watch(onDemandEnabledProvider);
    return generateSection(
      items: [
        ListItem.toggle(
          title: Text(appLocalizations.onDemand),
          subtitle: Text(appLocalizations.onDemandDesc),
          value: enabled,
          onChanged: (value) {
            ref.read(onDemandEnabledProvider.notifier).update((_) => value);
          },
        ),
      ],
    );
  }

  Widget _buildExcludeSsidsHeader() {
    final appLocalizations = context.appLocalizations;
    final hasSelection = ref.watch(itemsProvider(key)).isNotEmpty;
    return ListHeader(
      title: appLocalizations.excludeSsids,
      actions: [
        if (hasSelection) ...[
          IconButtonData(
            glyph: AppGlyphs.delete,
            tooltip: appLocalizations.delete,
            onPressed: _handleDelete,
          ),
          IconButtonData(
            glyph: AppGlyphs.selectAll,
            tooltip: appLocalizations.selectAll,
            onPressed: _handleSelectAll,
          ),
        ] else
          IconButtonData(
            glyph: AppGlyphs.addCircle,
            tooltip: appLocalizations.add,
            onPressed: _handleAddOrUpdate,
          ),
      ],
    );
  }

  Widget _buildExcludeSsidsList(
    List<String> excludeSSIDs,
    Set<dynamic> selectedItems,
  ) {
    if (excludeSSIDs.isEmpty) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(top: 12),
        sliver: SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 48),
            child: NullStatus(
              label: context.appLocalizations.ssidsEmpty,
              illustration: NullStatusIllustration.wifi,
            ),
          ),
        ),
      );
    }
    Widget itemAt(int index) => _buildItem(
      isEditing: selectedItems.isNotEmpty,
      ssid: excludeSSIDs[index],
      index: index,
      isSelected: selectedItems.contains(excludeSSIDs[index]),
      length: excludeSSIDs.length,
    );
    return SliverPadding(
      padding: const EdgeInsets.only(top: 12),
      sliver: SliverReorderableList(
        itemBuilder: (_, index) => itemAt(index),
        proxyDecorator: (child, index, animation) =>
            commonProxyDecorator(itemAt(index), index, animation),
        itemCount: excludeSSIDs.length,
        onReorderItem: _handleReorder,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final excludeSSIDs = ref.watch(excludeSSIDsProvider);
    final selectedItems = ref.watch(itemsProvider(key));
    return CommonScaffold(
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
            ).copyWith(top: context.appBarInset),
            sliver: SliverToBoxAdapter(child: _buildPrerequisites()),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(child: _buildOnDemandSection()),
          ),
          _buildCurrentWifiSection(),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(child: _buildExcludeSsidsHeader()),
          ),
          _buildExcludeSsidsList(excludeSSIDs, selectedItems),
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
            ).copyWith(bottom: 16),
            sliver: SliverToBoxAdapter(
              child: ListFooter(
                text: context.appLocalizations.excludeSsidsDesc,
              ),
            ),
          ),
        ],
      ),
      title: context.appLocalizations.onDemand,
    );
  }
}
