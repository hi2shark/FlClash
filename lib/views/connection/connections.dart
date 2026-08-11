import 'dart:async';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/core/controller.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

import 'item.dart';

/// UI render cap for connections list (core snapshot remains full).
const int connectionsDisplayLimit = 500;

class ConnectionsView extends ConsumerStatefulWidget {
  const ConnectionsView({super.key});

  @override
  ConsumerState<ConnectionsView> createState() => _ConnectionsViewState();
}

class _ConnectionsViewState extends ConsumerState<ConnectionsView> {
  final _connectionsStateNotifier = ValueNotifier<TrackerInfosState>(
    const TrackerInfosState(),
  );
  final ScrollController _scrollController = ScrollController();
  bool _showAll = false;

  Timer? timer;

  List<Widget> _buildActions() {
    final appLocalizations = context.appLocalizations;
    return [
      IconButton(
        tooltip: _showAll
            ? appLocalizations.connectionsLimitDisplay
            : appLocalizations.connectionsShowAll,
        onPressed: () {
          setState(() {
            _showAll = !_showAll;
          });
        },
        icon: Icon(_showAll ? Icons.filter_list : Icons.unfold_more),
      ),
      IconButton(
        onPressed: () async {
          coreController.closeConnections();
          await _updateConnections();
        },
        icon: const Icon(Icons.delete_sweep_outlined),
      ),
    ];
  }

  void _onSearch(String value) {
    _connectionsStateNotifier.value = _connectionsStateNotifier.value.copyWith(
      query: value,
    );
  }

  void _onKeywordsUpdate(List<String> keywords) {
    _connectionsStateNotifier.value = _connectionsStateNotifier.value.copyWith(
      keywords: keywords,
    );
  }

  Future<void> _updateConnectionsTask() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }
      await _updateConnections();
      if (!mounted) {
        return;
      }
      timer = Timer(const Duration(seconds: 1), () async {
        if (mounted) {
          await _updateConnectionsTask();
        }
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _updateConnectionsTask();
  }

  Future<void> _updateConnections() async {
    if (!mounted) {
      return;
    }
    final connections = await coreController.getConnections();
    if (!mounted) {
      return;
    }
    _connectionsStateNotifier.value = _connectionsStateNotifier.value.copyWith(
      trackerInfos: connections,
    );
  }

  Future<void> _handleBlockConnection(String id) async {
    await coreController.closeConnection(id);
    await _updateConnections();
  }

  List<TrackerInfo> _visibleConnections(List<TrackerInfo> connections) {
    if (_showAll || connections.length <= connectionsDisplayLimit) {
      return connections;
    }
    return connections.sublist(0, connectionsDisplayLimit);
  }

  @override
  void dispose() {
    timer?.cancel();
    _connectionsStateNotifier.dispose();
    _scrollController.dispose();
    timer = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    return CommonScaffold(
      title: appLocalizations.connections,
      onKeywordsUpdate: _onKeywordsUpdate,
      searchState: AppBarSearchState(onSearch: _onSearch),
      actions: _buildActions(),
      body: ValueListenableBuilder<TrackerInfosState>(
        valueListenable: _connectionsStateNotifier,
        builder: (context, state, _) {
          final connections = state.list;
          if (connections.isEmpty) {
            return NullStatus(
              label: appLocalizations.nullTip(appLocalizations.connections),
              illustration: const ConnectionEmptyIllustration(),
            );
          }
          final visible = _visibleConnections(connections);
          return SuperListView.builder(
            controller: _scrollController,
            itemBuilder: (context, index) {
              final trackerInfo = visible[index];
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TrackerInfoItem(
                    key: Key(trackerInfo.id),
                    trackerInfo: trackerInfo,
                    onClickKeyword: (value) {
                      context.commonScaffoldState?.addKeyword(value);
                    },
                    trailing: IconButton(
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      style: IconButton.styleFrom(minimumSize: Size.zero),
                      icon: const Icon(Icons.block),
                      onPressed: () {
                        _handleBlockConnection(trackerInfo.id);
                      },
                    ),
                    detailTitle: appLocalizations.details(
                      appLocalizations.connection,
                    ),
                  ),
                  if (index < visible.length - 1) const Divider(height: 0),
                ],
              );
            },
            itemCount: visible.length,
          );
        },
      ),
    );
  }
}
