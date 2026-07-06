import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/app.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WifiWatchCard extends StatelessWidget {
  const WifiWatchCard({super.key});

  IconData _signalIcon(int? rssi) {
    if (rssi == null) return Icons.signal_wifi_0_bar;
    if (rssi >= -55) return Icons.signal_wifi_4_bar;
    if (rssi >= -70) return Icons.wifi;
    return Icons.signal_wifi_0_bar;
  }

  Color _signalColor(BuildContext context, int? rssi) {
    if (rssi == null) return context.colorScheme.outline;
    if (rssi >= -60) return Colors.green;
    if (rssi >= -75) return Colors.orange;
    return context.colorScheme.error;
  }

  String _statusText(BuildContext context, WifiWatchState state) {
    final appLocalizations = context.appLocalizations;
    if (state.suspended) {
      return appLocalizations.suspended;
    }
    final deadline = state.pendingSuspendDeadline;
    if (deadline != null) {
      final remaining = deadline.difference(DateTime.now()).inSeconds;
      if (remaining <= 0) {
        return appLocalizations.wifiWatchSuspendingNow;
      }
      return appLocalizations.wifiWatchWillSuspend(remaining.toString());
    }
    if (!state.wifiPresent) {
      return appLocalizations.wifiWatchNoWifi;
    }
    if (state.ssid == null) {
      return appLocalizations.wifiWatchResolving;
    }
    if (state.validated) {
      return appLocalizations.wifiWatchTrusted;
    }
    return appLocalizations.wifiWatchListening;
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    final titleStyle = context.textTheme.titleSmall?.copyWith(
      color: context.colorScheme.onSurfaceVariant,
    );
    return SizedBox(
      height: getWidgetHeight(2),
      child: CommonCard(
        info: Info(
          label: appLocalizations.wifiWatchTitle,
          iconData: Icons.wifi_tethering,
        ),
        onPressed: () {},
        child: Container(
          padding: baseInfoEdgeInsets.copyWith(top: 0),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Consumer(
                builder: (_, ref, __) {
                  final state = ref.watch(wifiWatchProvider);
                  return FadeThroughBox(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.wifi,
                              size: 16.ap,
                              color: context.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: TooltipText(
                                text: Text(
                                  state.ssid ?? appLocalizations.wifiWatchNoWifi,
                                  style: context.textTheme.bodyMedium
                                      ?.toLight
                                      .adjustSize(1),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              _signalIcon(state.rssi),
                              size: 16.ap,
                              color: _signalColor(context, state.rssi),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                state.rssi != null
                                    ? appLocalizations.wifiWatchSignal(
                                        state.rssi.toString(),
                                      )
                                    : _statusText(context, state),
                                style: context.textTheme.bodyMedium
                                    ?.toLight
                                    .adjustSize(-1),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              Consumer(
                builder: (_, ref, __) {
                  final state = ref.watch(wifiWatchProvider);
                  return SizedBox(
                    height: globalState.measure.bodyMediumHeight + 2,
                    child: FadeThroughBox(
                      child: Text(
                        _statusText(context, state),
                        style: context.textTheme.bodyMedium
                            ?.toLight
                            .adjustSize(1),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
