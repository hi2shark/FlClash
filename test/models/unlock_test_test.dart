import 'dart:convert';

import 'package:fl_clash/models/unlock_test.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('unlock run params use the core wire keys', () {
    const params = UnlockTestRunParams(
      runId: 'run-1',
      routeMode: UnlockTestRouteMode.proxy,
      proxyName: 'Hong Kong',
      timeout: 10000,
      targetIds: ['chatgpt', 'netflix'],
    );

    expect(params.toJson(), {
      'run-id': 'run-1',
      'route-mode': 'proxy',
      'proxy-name': 'Hong Kong',
      'timeout': 10000,
      'target-ids': ['chatgpt', 'netflix'],
    });
  });

  test('unlock result round trips five-state fields and outbound chains', () {
    final encoded = jsonEncode({
      'run-id': 'run-1',
      'route-mode': 'appRoute',
      'results': [
        {
          'id': 'netflix',
          'status': 'partial',
          'reason': 'contentLimited',
          'region': 'US',
          'latency': 321,
          'outbound-chains': ['Proxy A', 'DIRECT'],
          'sanitized-detail': 'only originals',
        },
      ],
    });

    final result = UnlockTestRunResult.fromJson(
      jsonDecode(encoded) as Map<String, dynamic>,
    );

    expect(result.runId, 'run-1');
    expect(result.routeMode, UnlockTestRouteMode.appRoute);
    expect(result.results.single.status, UnlockTestStatus.partial);
    expect(result.results.single.reason, UnlockTestReason.contentLimited);
    expect(result.results.single.outboundChains, ['Proxy A', 'DIRECT']);
    expect(result.results.single.sanitizedDetail, 'only originals');
    expect(result.toJson()['results'], hasLength(1));
  });

  test('unknown wire values degrade to error and unexpected response', () {
    final item = UnlockTestRunItem.fromJson({
      'id': 'future-service',
      'status': 'future-status',
      'reason': 'future-reason',
    });

    expect(item.status, UnlockTestStatus.error);
    expect(item.reason, UnlockTestReason.unexpectedResponse);
  });
}
