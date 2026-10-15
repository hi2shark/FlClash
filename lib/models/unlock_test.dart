enum UnlockTestRouteMode {
  appRoute,
  proxy;

  static UnlockTestRouteMode fromWire(Object? value) {
    return values.where((item) => item.name == value).firstOrNull ??
        UnlockTestRouteMode.appRoute;
  }
}

enum UnlockTestStatus {
  unlocked,
  partial,
  locked,
  error,
  untested;

  static UnlockTestStatus fromWire(Object? value) {
    return values.where((item) => item.name == value).firstOrNull ??
        UnlockTestStatus.error;
  }
}

enum UnlockTestReason {
  none(''),
  contentLimited('contentLimited'),
  geoBlocked('geoBlocked'),
  vpnBlocked('vpnBlocked'),
  rateLimited('rateLimited'),
  timeout('timeout'),
  networkError('networkError'),
  bootstrapFailed('bootstrapFailed'),
  unexpectedResponse('unexpectedResponse');

  final String wireValue;

  const UnlockTestReason(this.wireValue);

  static UnlockTestReason fromWire(Object? value) {
    return values.where((item) => item.wireValue == value).firstOrNull ??
        UnlockTestReason.unexpectedResponse;
  }
}

enum UnlockTestGroup { ai, globalMedia, europe, hongKongTaiwan, japan, korea }

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}

class UnlockTestRunParams {
  final String runId;
  final UnlockTestRouteMode routeMode;
  final String? proxyName;
  final int timeout;
  final List<String> targetIds;

  const UnlockTestRunParams({
    required this.runId,
    required this.routeMode,
    this.proxyName,
    this.timeout = 10000,
    this.targetIds = const [],
  });

  Map<String, Object?> toJson() => {
    'run-id': runId,
    'route-mode': routeMode.name,
    if (proxyName?.isNotEmpty == true) 'proxy-name': proxyName,
    'timeout': timeout,
    'target-ids': targetIds,
  };
}

class UnlockTestRunItem {
  final String id;
  final UnlockTestStatus status;
  final UnlockTestReason reason;
  final String region;
  final int latency;
  final List<String> outboundChains;
  final String sanitizedDetail;

  const UnlockTestRunItem({
    required this.id,
    this.status = UnlockTestStatus.untested,
    this.reason = UnlockTestReason.none,
    this.region = '',
    this.latency = 0,
    this.outboundChains = const [],
    this.sanitizedDetail = '',
  });

  const UnlockTestRunItem.untested(String id) : this(id: id);

  factory UnlockTestRunItem.fromJson(Map<String, dynamic> json) {
    return UnlockTestRunItem(
      id: json['id'] as String? ?? '',
      status: UnlockTestStatus.fromWire(json['status']),
      reason: UnlockTestReason.fromWire(json['reason'] ?? ''),
      region: json['region'] as String? ?? '',
      latency: (json['latency'] as num?)?.toInt() ?? 0,
      outboundChains:
          (json['outbound-chains'] as List<dynamic>?)
              ?.whereType<String>()
              .toList(growable: false) ??
          const [],
      sanitizedDetail: json['sanitized-detail'] as String? ?? '',
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'status': status.name,
    if (reason != UnlockTestReason.none) 'reason': reason.wireValue,
    if (region.isNotEmpty) 'region': region,
    'latency': latency,
    if (outboundChains.isNotEmpty) 'outbound-chains': outboundChains,
    if (sanitizedDetail.isNotEmpty) 'sanitized-detail': sanitizedDetail,
  };
}

class UnlockTestProgress {
  final String runId;
  final int completed;
  final int total;
  final UnlockTestRunItem item;

  const UnlockTestProgress({
    required this.runId,
    required this.completed,
    required this.total,
    required this.item,
  });

  factory UnlockTestProgress.fromJson(Map<String, dynamic> json) {
    return UnlockTestProgress(
      runId: json['run-id'] as String? ?? '',
      completed: (json['completed'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
      item: UnlockTestRunItem.fromJson(
        Map<String, dynamic>.from(json['item'] as Map? ?? const {}),
      ),
    );
  }
}

class UnlockTestRunResult {
  final String runId;
  final UnlockTestRouteMode routeMode;
  final String? proxyName;
  final List<UnlockTestRunItem> results;
  final bool cancelled;
  final String error;

  const UnlockTestRunResult({
    this.runId = '',
    this.routeMode = UnlockTestRouteMode.appRoute,
    this.proxyName,
    this.results = const [],
    this.cancelled = false,
    this.error = '',
  });

  factory UnlockTestRunResult.fromJson(Map<String, dynamic> json) {
    return UnlockTestRunResult(
      runId: json['run-id'] as String? ?? '',
      routeMode: UnlockTestRouteMode.fromWire(json['route-mode']),
      proxyName: json['proxy-name'] as String?,
      results:
          (json['results'] as List<dynamic>?)
              ?.whereType<Map>()
              .map(
                (item) =>
                    UnlockTestRunItem.fromJson(Map<String, dynamic>.from(item)),
              )
              .toList(growable: false) ??
          const [],
      cancelled: json['cancelled'] as bool? ?? false,
      error: json['error'] as String? ?? '',
    );
  }

  Map<String, Object?> toJson() => {
    'run-id': runId,
    'route-mode': routeMode.name,
    if (proxyName?.isNotEmpty == true) 'proxy-name': proxyName,
    'results': results.map((item) => item.toJson()).toList(growable: false),
    if (cancelled) 'cancelled': true,
    if (error.isNotEmpty) 'error': error,
  };
}

class UnlockTestHistoryEntry {
  final DateTime createdAt;
  final int durationMs;
  final int catalogVersion;
  final UnlockTestRunResult result;

  const UnlockTestHistoryEntry({
    required this.createdAt,
    required this.durationMs,
    required this.catalogVersion,
    required this.result,
  });
}
