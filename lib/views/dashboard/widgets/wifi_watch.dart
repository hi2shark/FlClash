import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/ui/icons/icons.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/app.dart';
import 'package:fl_clash/providers/config.dart';
import 'package:fl_clash/views/dashboard/layout.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'card.dart';

class WifiWatchCard extends StatelessWidget {
  const WifiWatchCard({super.key});

  Glyph _signalIcon(bool hasNetwork) {
    if (!hasNetwork) {
      return AppGlyphs.wifiOff;
    }
    return AppGlyphs.wifi;
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

  String _statusText(
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

  Text _displayText(
    BuildContext context, {
    required String? ssid,
    required String status,
    required bool hasServiceInfo,
    required bool hasNetwork,
    required bool isExcluded,
    required bool prioritizeActionStatus,
  }) {
    final style = AppTextStyle.subheadline.of(context).toLight;
    const maxLines = 1;
    const overflow = TextOverflow.ellipsis;

    if (!hasNetwork || ssid == null || prioritizeActionStatus) {
      return Text(status, style: style, maxLines: maxLines, overflow: overflow);
    }

    final display = hasServiceInfo ? '$ssid · $status' : ssid;
    if (!isExcluded) {
      return Text(
        display,
        style: style,
        maxLines: maxLines,
        overflow: overflow,
      );
    }

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: ssid,
            style: AppTextStyle.custom(
              context,
              size: AppTextStyle.subheadline.size,
              leading: AppTextStyle.subheadline.leading,
              weight: FontWeight.w700,
            ).copyWith(color: Colors.green),
          ),
          if (hasServiceInfo) TextSpan(text: ' · $status'),
        ],
      ),
      style: style,
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    final mobile = !DashboardDensityScope.of(context).isDesktop;
    return DashboardCard(
      semanticLabel: appLocalizations.wifiWatchTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: mobile ? MainAxisSize.min : MainAxisSize.max,
        children: [
          DashboardCardHeader(
            glyph: AppGlyphs.wifi,
            title: appLocalizations.wifiWatchTitle,
          ),
          if (mobile) const SizedBox(height: 12) else const Spacer(),
          Consumer(
            builder: (_, ref, child) {
              final state = ref.watch(wifiWatchProvider);
              final enabled = ref.watch(onDemandEnabledProvider);
              final currentSsid = ref.watch(currentSSIDProvider);
              final excludeSSIDs = ref.watch(excludeSSIDsProvider);
              final ssid = state.ssid ?? state.rawSsid ?? currentSsid;
              final hasServiceInfo =
                  state.wifiPresent ||
                  state.suspended ||
                  state.pendingSuspendDeadline != null;
              final hasNetwork = ssid != null;
              final isExcluded =
                  enabled && hasNetwork && excludeSSIDs.contains(ssid);
              final status = _statusText(context, state, isExcluded, enabled);
              return FadeThroughBox(
                child: Row(
                  children: [
                    GlyphIcon(
                      _signalIcon(hasNetwork),
                      size: 20,
                      color: _signalColor(
                        context,
                        state.rssi,
                        hasNetwork,
                        isExcluded,
                        state.validated,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TooltipText(
                        text: _displayText(
                          context,
                          ssid: ssid,
                          status: status,
                          hasServiceInfo: hasServiceInfo,
                          hasNetwork: hasNetwork,
                          isExcluded: isExcluded,
                          prioritizeActionStatus: state.prioritizeActionStatus,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 42,
                      height: 24,
                      child: FittedBox(
                        child: Switch(
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          value: enabled,
                          onChanged: (value) {
                            ref
                                .read(onDemandEnabledProvider.notifier)
                                .update((_) => value);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
