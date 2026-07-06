import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/plugins/app.dart';
import 'package:fl_clash/providers/app.dart';
import 'package:fl_clash/providers/config.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/views/profiles/overwrite/custom/widgets.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wifi_ssid/wifi_ssid.dart';

class OnDemandView extends ConsumerStatefulWidget {
  const OnDemandView({super.key});

  @override
  ConsumerState createState() => _OnDemandViewState();
}

class _OnDemandViewState extends ConsumerState<OnDemandView>
    with UniqueKeyStateMixin {
  void _handlePermanentlyDeniedLocationPermission() {
    if (system.isMacOS) {
      final appLocalizations = context.appLocalizations;
      globalState.showMessage(
        title: appLocalizations.locationPermissionRequired,
        cancelable: false,
        message: TextSpan(
          style: context.textTheme.bodyMedium,
          text: appLocalizations.locationPermissionGuide(appName),
        ),
      );
    } else if (system.isAndroid) {
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
    final res = await wifiSsidManager.requestPermission();
    globalState.container.read(locationPermissionsProvider.notifier).value =
        res;
    if (!mounted && res != WifiSsidPermission.permanentlyDenied) {
      return;
    }
    final needGo = await globalState.showMessage(
      title: appLocalizations.locationPermissionRequired,
      message: TextSpan(text: appLocalizations.locationPermissionDeniedMessage),
      confirmText: appLocalizations.go,
    );
    if (needGo != true) {
      return;
    }
    app?.openAppSettings();
  }

  Future<void> _handleRequestBackgroundLocationPermission() async {
    final permission = ref.read(backgroundLocationPermissionsProvider);
    if (permission == WifiSsidPermission.granted) {
      return;
    }
    if (permission == WifiSsidPermission.permanentlyDenied) {
      app?.openAppSettings();
      return;
    }
    final res = await wifiSsidManager.requestBackgroundPermission();
    globalState.container
        .read(backgroundLocationPermissionsProvider.notifier)
        .value = res;
  }

  void _handleOpenBatteryOptimizationSettings() {
    final isDisabled = ref.read(batteryOptimizationDisableProvider);
    if (isDisabled) {
      return;
    }
    permissions.needWaitingBatteryOptimizationSettings = true;
    app?.openBatteryOptimizationSettings();
  }

  Future<void> _handleAddOrUpdate([String? ssid]) async {
    final ssids = ref.read(excludeSSIDsProvider);
    final appLocalizations = context.appLocalizations;
    final newSSID = await globalState.showCommonDialog<String>(
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
    globalState.container.read(excludeSSIDsProvider.notifier).update((state) {
      final newSSIDS = state.toSet();
      if (ssid != null) {
        newSSIDS.remove(ssid);
      }
      return [...newSSIDS, newSSID];
    });
  }

  void _handleReorder(int oldIndex, newIndex) {
    globalState.container.read(excludeSSIDsProvider.notifier).update((value) {
      final nextItems = List<String>.from(value);
      final item = nextItems.removeAt(oldIndex);
      nextItems.insert(newIndex, item);
      return nextItems;
    });
  }

  IconData _signalIcon(int? rssi, bool hasNetwork) {
    if (rssi == null) {
      return hasNetwork ? Icons.wifi : Icons.signal_wifi_0_bar;
    }
    if (rssi >= -55) return Icons.signal_wifi_4_bar;
    if (rssi >= -70) return Icons.wifi;
    return Icons.signal_wifi_0_bar;
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
  ) {
    final appLocalizations = context.appLocalizations;
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
            final excludeSSIDs = ref.watch(excludeSSIDsProvider);
            final ssid = state.ssid ?? state.rawSsid;
            final hasSsid = ssid != null;
            final hasNetwork = hasSsid || state.wifiPresent;
            final isExcluded = hasSsid && excludeSSIDs.contains(ssid);
            return generateSectionV3(
              title: appLocalizations.currentWifiConnection,
              items: [
                DecorationListItem(
                  title: Text(appLocalizations.currentWifiSsid),
                  trailing: Text(
                    ssid ??
                        (hasNetwork
                            ? appLocalizations.wifiWatchResolving
                            : appLocalizations.wifiWatchNoWifi),
                    style: context.textTheme.bodyMedium?.toLight,
                  ),
                ),
                DecorationListItem(
                  title: Text(appLocalizations.currentWifiSignal),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (hasNetwork) ...[
                        Icon(
                          _signalIcon(state.rssi, hasNetwork),
                          size: 16.ap,
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
                        style: context.textTheme.bodyMedium?.toLight,
                      ),
                    ],
                  ),
                ),
                DecorationListItem(
                  title: Text(appLocalizations.currentWifiStatus),
                  trailing: Text(
                    _currentWifiStatus(context, state, isExcluded),
                    style: context.textTheme.bodyMedium?.toLight,
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
            minVerticalPadding: 8,
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
    globalState.container.read(excludeSSIDsProvider.notifier).update((
      excludeSSIDs,
    ) {
      return excludeSSIDs
          .where((item) => !selectedItems.contains(item))
          .toList();
    });
    ref.read(itemsProvider(key).notifier).value = {};
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    final isLoading = ref.watch(
      loadingProvider(LoadingTag.batteryOptimization),
    );
    final batteryOptimizationDisable = ref.watch(
      batteryOptimizationDisableProvider,
    );
    final excludeSSIDs = ref.watch(excludeSSIDsProvider);
    final locationPermissionsGranted = ref.watch(
      locationPermissionsProvider.select(
        (state) => state == WifiSsidPermission.granted,
      ),
    );
    final backgroundLocationGranted = ref.watch(
      backgroundLocationPermissionsProvider.select(
        (state) => state == WifiSsidPermission.granted,
      ),
    );
    final selectedItems = ref.watch(itemsProvider(key));
    return CommonScaffold(
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: generateSectionV3(
                title: appLocalizations.prerequisites,
                items: [
                  if (system.isAndroid)
                    DecorationListItem(
                      minVerticalPadding: 8,
                      title: Text(appLocalizations.ignoreBatteryOptimization),
                      subtitle: Text(appLocalizations.batteryOptimizationDesc),
                      trailing: isLoading
                          ? const SizedBox(
                              width: 100,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  SizedBox.square(
                                    dimension: 32,
                                    child: CommonCircleLoading(),
                                  ),
                                ],
                              ),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              spacing: 8,
                              children: [
                                InfoMessageButton(
                                  message: appLocalizations
                                      .batteryOptimizationStatusTip,
                                ),
                                CommonMinFilledButtonTheme(
                                  child: FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor:
                                          batteryOptimizationDisable
                                          ? null
                                          : context.colorScheme.error,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      minimumSize: const Size(80, 40),
                                    ),
                                    onPressed:
                                        _handleOpenBatteryOptimizationSettings,
                                    child: Text(
                                      batteryOptimizationDisable
                                          ? appLocalizations.authorized
                                          : appLocalizations.tapToAuthorize,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  if (system.isAndroid || system.isMacOS)
                    DecorationListItem(
                      minVerticalPadding: 8,
                      title: Text(appLocalizations.locationPermission),
                      subtitle: Text(appLocalizations.locationPermissionDesc),
                      trailing: CommonMinFilledButtonTheme(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: locationPermissionsGranted
                                ? null
                                : context.colorScheme.error,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            minimumSize: const Size(80, 40),
                          ),
                          onPressed: _handleRequestLocationPermission,
                          child: Text(
                            locationPermissionsGranted
                                ? appLocalizations.authorized
                                : appLocalizations.tapToAuthorize,
                          ),
                        ),
                      ),
                    ),
                  if (system.isAndroid)
                    DecorationListItem(
                      minVerticalPadding: 8,
                      title: Text(appLocalizations.backgroundLocationPermission),
                      subtitle: Text(
                        appLocalizations.backgroundLocationPermissionDesc,
                      ),
                      trailing: CommonMinFilledButtonTheme(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: backgroundLocationGranted
                                ? null
                                : context.colorScheme.error,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            minimumSize: const Size(80, 40),
                          ),
                          onPressed: _handleRequestBackgroundLocationPermission,
                          child: Text(
                            backgroundLocationGranted
                                ? appLocalizations.authorized
                                : appLocalizations.tapToAuthorize,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          _buildCurrentWifiSection(),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: ListHeader(
                title: appLocalizations.excludeSsids,
                subTitle: appLocalizations.excludeSsidsDesc,
                actions: [
                  const SizedBox(width: 8),
                  if (selectedItems.isNotEmpty)
                    CommonMinIconButtonTheme(
                      child: IconButton.filledTonal(
                        onPressed: _handleDelete,
                        icon: const Icon(Icons.delete),
                      ),
                    ),
                  const SizedBox(width: 2),
                  CommonMinFilledButtonTheme(
                    child: selectedItems.isNotEmpty
                        ? FilledButton(
                            onPressed: _handleSelectAll,
                            child: Text(appLocalizations.selectAll),
                          )
                        : FilledButton.tonal(
                            onPressed: _handleAddOrUpdate,
                            child: Text(appLocalizations.add),
                          ),
                  ),
                ],
              ),
            ),
          ),
          if (excludeSSIDs.isEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
              ).copyWith(top: 12),
              sliver: SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 0,
                    vertical: 48,
                  ),
                  child: NullStatus(label: appLocalizations.ssidsEmpty),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.only(top: 12),
              sliver: SliverReorderableList(
                itemBuilder: (_, index) {
                  final ssid = excludeSSIDs[index];
                  return _buildItem(
                    isEditing: selectedItems.isNotEmpty,
                    ssid: ssid,
                    index: index,
                    isSelected: selectedItems.contains(ssid),
                    length: excludeSSIDs.length,
                  );
                },
                proxyDecorator: (child, index, animation) {
                  final ssid = excludeSSIDs[index];
                  return commonProxyDecorator(
                    _buildItem(
                      isEditing: selectedItems.isNotEmpty,
                      ssid: ssid,
                      index: index,
                      isSelected: selectedItems.contains(ssid),
                      length: excludeSSIDs.length,
                    ),
                    index,
                    animation,
                  );
                },
                itemCount: excludeSSIDs.length,
                onReorderItem: _handleReorder,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
      title: appLocalizations.onDemand,
    );
  }
}
