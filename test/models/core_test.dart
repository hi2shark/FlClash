import 'dart:convert';

import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:test/test.dart';

void main() {
  group('SetupParams', () {
    test('fromJson uses snake-case keys', () {
      final json = {
        'selected-map': {'G1': 'P1'},
        'test-url': 'http://test.com',
      };
      final params = SetupParams.fromJson(json);
      expect(params.selectedMap, {'G1': 'P1'});
      expect(params.testUrl, 'http://test.com');
    });

    test('toJson uses snake-case keys', () {
      const params = SetupParams(
        selectedMap: {'G1': 'P1'},
        testUrl: 'http://t.com',
      );
      final json = params.toJson();
      expect(json['selected-map'], {'G1': 'P1'});
      expect(json['test-url'], 'http://t.com');
    });
  });

  group('UpdateParams', () {
    test('fromJson with all fields', () {
      final json = {
        'tun': {'enable': true},
        'mixed-port': 7890,
        'allow-lan': true,
        'find-process-mode': 'off',
        'mode': 'rule',
        'log-level': 'info',
        'ipv6': false,
        'tcp-concurrent': false,
        'external-controller': '',
        'unified-delay': false,
      };
      final params = UpdateParams.fromJson(json);
      expect(params.mixedPort, 7890);
      expect(params.allowLan, true);
      expect(params.mode, Mode.rule);
      expect(params.logLevel, LogLevel.info);
    });
  });

  group('InitParams', () {
    test('fromJson and toJson', () {
      final json = {'home-dir': '/data/clash', 'version': 3};
      final params = InitParams.fromJson(json);
      expect(params.homeDir, '/data/clash');
      expect(params.version, 3);
      final restored = jsonDecode(jsonEncode(params.toJson()));
      expect(restored['home-dir'], '/data/clash');
      expect(restored['version'], 3);
    });
  });

  group('ChangeProxyParams', () {
    test('fromJson and toJson use snake-case', () {
      final json = {'group-name': 'Proxy', 'proxy-name': 'auto'};
      final params = ChangeProxyParams.fromJson(json);
      expect(params.groupName, 'Proxy');
      expect(params.proxyName, 'auto');
      final out = params.toJson();
      expect(out['group-name'], 'Proxy');
      expect(out['proxy-name'], 'auto');
    });
  });

  group('UpdateGeoDataParams', () {
    test('fromJson with snake-case keys', () {
      final json = {'geo-type': 'mmdb', 'geo-name': 'Country'};
      final params = UpdateGeoDataParams.fromJson(json);
      expect(params.geoType, 'mmdb');
      expect(params.geoName, 'Country');
    });
  });

  group('Delay', () {
    test('fromJson and toJson', () {
      final json = {'name': 'P1', 'url': 'test.com', 'value': 42};
      final delay = Delay.fromJson(json);
      expect(delay.name, 'P1');
      expect(delay.url, 'test.com');
      expect(delay.value, 42);
      final out = delay.toJson();
      expect(out['value'], 42);
    });

    test('null value', () {
      final delay = Delay.fromJson({'name': 'P1', 'url': 'test.com'});
      expect(delay.value, null);
    });
  });

  group('Now', () {
    test('fromJson and toJson', () {
      final now = Now.fromJson({'name': 'test', 'value': '123'});
      expect(now.name, 'test');
      expect(now.value, '123');
    });
  });

  group('ProxiesData', () {
    test('fromJson with proxies and all list', () {
      final json = {
        'proxies': {
          'G1': {
            'type': 'Selector',
            'now': 'auto',
            'all': ['auto', 'P1'],
          },
        },
        'all': ['G1'],
      };
      final data = ProxiesData.fromJson(json);
      expect(data.all, ['G1']);
      expect(data.proxies['G1'], isA<Map>());
    });
  });

  group('ExternalProvider', () {
    test('fromJson with subscription info', () {
      final json = {
        'name': 'TestProvider',
        'type': 'Proxy',
        'count': 10,
        'vehicle-type': 'HTTP',
        'update-at': '2024-01-01T00:00:00.000Z',
        'subscription-info': {
          'Upload': 100,
          'Download': 200,
          'Total': 1000,
          'Expire': 1700000000,
        },
      };
      final provider = ExternalProvider.fromJson(json);
      expect(provider.name, 'TestProvider');
      expect(provider.count, 10);
      expect(provider.subscriptionInfo!.upload, 100);
      expect(provider.subscriptionInfo!.download, 200);
      expect(provider.subscriptionInfo!.total, 1000);
      expect(provider.subscriptionInfo!.expire, 1700000000);
    });

    test('updatingKey uses provider_ prefix', () {
      final provider = ExternalProvider(
        name: 'MyProvider',
        type: 'Proxy',
        count: 5,
        vehicleType: 'HTTP',
        updateAt: DateTime.now(),
      );
      expect(provider.updatingKey, 'provider_MyProvider');
    });
  });

  group('CoreEvent', () {
    test('fromJson with type and data', () {
      final event = CoreEvent.fromJson({'type': 'log', 'data': 'test log'});
      expect(event.type, CoreEventType.log);
      expect(event.data, 'test log');
    });
  });

  group('InvokeMessage', () {
    test('fromJson', () {
      final msg = InvokeMessage.fromJson({
        'type': 'protect',
        'data': {'method': 'test'},
      });
      expect(msg.type, InvokeMessageType.protect);
    });
  });

  group('ActionResult', () {
    test('toResult returns success Result for success code', () {
      const ar = ActionResult(
        method: ActionMethod.getConfig,
        data: {'key': 'value'},
        code: ResultType.success,
      );
      final result = ar.toResult;
      expect(result.isSuccess, true);
      expect(result.data, {'key': 'value'});
    });

    test('toResult returns error Result for error code', () {
      const ar = ActionResult(
        method: ActionMethod.getConfig,
        data: 'something went wrong',
        code: ResultType.error,
      );
      final result = ar.toResult;
      expect(result.isSuccess, false);
      expect(result.message, 'something went wrong');
    });
  });

  group('SharedState', () {
    test('round trip includes suspend-on WiFi SSIDs', () {
      const state = SharedState(
        currentProfileName: 'Profile',
        stopText: 'Stop',
        stopTip: 'Stopping VPN...',
        startTip: 'Starting VPN...',
        onlyStatisticsProxy: false,
        crashlytics: true,
        suspendOnWifiSsids: ['Home', 'Office'],
      );

      final restored = SharedState.fromJson(
        jsonDecode(jsonEncode(state.toJson())) as Map<String, Object?>,
      );

      expect(restored.suspendOnWifiSsids, ['Home', 'Office']);
    });

    test('reads legacy excludeSSIDs key into suspend-on WiFi SSIDs', () {
      final restored = SharedState.fromJson({
        'currentProfileName': 'Profile',
        'stopText': 'Stop',
        'stopTip': 'Stopping VPN...',
        'startTip': 'Starting VPN...',
        'onlyStatisticsProxy': false,
        'crashlytics': true,
        'excludeSSIDs': ['Home'],
      });

      expect(restored.suspendOnWifiSsids, ['Home']);
    });

    test('needSyncSharedState keeps suspend-on WiFi SSIDs', () {
      const state = SharedState(
        setupParams: SetupParams(
          selectedMap: {'Proxy': 'Auto'},
          testUrl: 'https://example.com',
        ),
        currentProfileName: 'Profile',
        stopText: 'Stop',
        stopTip: 'Stopping VPN...',
        startTip: 'Starting VPN...',
        onlyStatisticsProxy: false,
        crashlytics: true,
        suspendOnWifiSsids: ['Home'],
      );

      final synced = state.needSyncSharedState;

      expect(synced.setupParams, null);
      expect(synced.suspendOnWifiSsids, ['Home']);
    });
  });

  group('UnlockTestParams', () {
    test('toJson uses snake-case keys with nested items', () {
      const params = UnlockTestParams(
        proxyName: 'P1',
        timeout: 5000,
        tests: [
          UnlockTestItem(
            id: 'chatgpt',
            url: 'https://chat.openai.com/cdn-cgi/trace',
            regionRegex: 'loc=([A-Z]{2})',
            expectedStatus: [200],
          ),
        ],
      );
      final json = params.toJson();
      expect(json['proxy-name'], 'P1');
      expect(json['timeout'], 5000);
      final tests = json['tests'] as List<dynamic>;
      expect(tests, hasLength(1));
    });

    test('round trip preserves nested items', () {
      const params = UnlockTestParams(
        proxyName: 'P1',
        timeout: 3000,
        tests: [
          UnlockTestItem(
            id: 'chatgpt',
            url: 'https://chat.openai.com/cdn-cgi/trace',
            regionRegex: 'loc=([A-Z]{2})',
            expectedStatus: [200, 204],
          ),
          UnlockTestItem(id: 'claude', url: 'https://claude.ai/'),
        ],
      );
      final restored = UnlockTestParams.fromJson(
        jsonDecode(jsonEncode(params.toJson())) as Map<String, Object?>,
      );
      expect(restored.proxyName, 'P1');
      expect(restored.timeout, 3000);
      expect(restored.tests, hasLength(2));
      expect(restored.tests[0].id, 'chatgpt');
      expect(restored.tests[0].regionRegex, 'loc=([A-Z]{2})');
      expect(restored.tests[0].expectedStatus, [200, 204]);
      expect(restored.tests[1].regionRegex, null);
      expect(restored.tests[1].expectedStatus, null);
    });
  });

  group('UnlockTestResult', () {
    test('fromJson parses nested results', () {
      final result = UnlockTestResult.fromJson({
        'name': 'P1',
        'results': [
          {
            'id': 'chatgpt',
            'status': 200,
            'latency': 321,
            'region': 'US',
            'unlocked': true,
            'error': '',
          },
          {
            'id': 'netflix',
            'status': 403,
            'latency': 120,
            'region': '',
            'unlocked': false,
            'error': '',
          },
        ],
        'error': '',
      });
      expect(result.name, 'P1');
      expect(result.results, hasLength(2));
      expect(result.results[0].unlocked, true);
      expect(result.results[0].region, 'US');
      expect(result.results[1].status, 403);
      expect(result.error, '');
    });

    test('fromJson applies defaults for missing fields', () {
      final result = UnlockTestResult.fromJson({'name': 'P1'});
      expect(result.name, 'P1');
      expect(result.results, isEmpty);
      expect(result.error, '');
      const item = UnlockTestResultItem();
      expect(item.id, '');
      expect(item.status, 0);
      expect(item.latency, 0);
      expect(item.region, '');
      expect(item.unlocked, false);
      expect(item.error, '');
    });
  });
}
