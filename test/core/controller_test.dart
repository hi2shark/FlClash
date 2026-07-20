import 'dart:async';
import 'dart:convert';

import 'package:fl_clash/core/controller.dart';
import 'package:fl_clash/core/interface.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockCoreHandlerInterface extends Mock implements CoreHandlerInterface {}

class FakeCompleter extends Fake implements Completer<dynamic> {
  @override
  bool get isCompleted => true;
}

void main() {
  late MockCoreHandlerInterface mock;
  late CoreController controller;

  setUpAll(() {
    registerFallbackValue(
      const SetupParams(selectedMap: {}, testUrl: 'http://x.com'),
    );
    registerFallbackValue(const InitParams(homeDir: '.', version: 1));
    registerFallbackValue(
      const UpdateParams(
        tun: Tun(),
        mixedPort: 7890,
        allowLan: true,
        findProcessMode: FindProcessMode.off,
        mode: Mode.rule,
        logLevel: LogLevel.info,
        ipv6: false,
        tcpConcurrent: false,
        externalController: ExternalControllerStatus.close,
        unifiedDelay: false,
      ),
    );
    registerFallbackValue(
      const ChangeProxyParams(groupName: 'G', proxyName: 'P'),
    );
    registerFallbackValue(
      const UpdateGeoDataParams(geoType: 't', geoName: 'n'),
    );
    registerFallbackValue(const SpeedTestParams(proxyName: 'P'));
    registerFallbackValue(const QuicTestParams(proxyName: 'P'));
    registerFallbackValue(const UnlockTestParams(proxyName: 'P'));
  });

  setUp(() {
    mock = MockCoreHandlerInterface();
    CoreController.resetInstance();
    controller = CoreController.test(mock);
  });

  tearDown(() {
    CoreController.resetInstance();
  });

  group('isNetworkTestCandidate', () {
    test('filters normalized non-testable and group types', () {
      const excludedTypes = [
        'Reject',
        ' rejectDROP ',
        'pAsS',
        'PASSRULE',
        'Selector',
        ' UrL-tEsT ',
        'FALLBACK',
        'loadbalance',
        'relay',
      ];

      for (final type in excludedTypes) {
        expect(
          isNetworkTestCandidate({'name': 'node', 'type': type}),
          isFalse,
          reason: 'type=$type',
        );
      }
    });

    test('keeps local and ordinary proxies based on actual type', () {
      const candidates = [
        {'name': 'REJECT', 'type': 'Shadowsocks'},
        {'name': 'DIRECT', 'type': 'Direct'},
        {'name': 'COMPATIBLE', 'type': 'Compatible'},
      ];

      for (final proxy in candidates) {
        expect(isNetworkTestCandidate(proxy), isTrue, reason: 'proxy=$proxy');
      }
    });
  });

  group('CoreController singleton', () {
    test('test constructor injects mock interface', () {
      expect(controller, isA<CoreController>());
    });

    test('resetInstance allows fresh construction', () {
      CoreController.resetInstance();
      final instance = CoreController.test(mock);
      expect(instance, isA<CoreController>());
    });
  });

  group('lifecycle methods', () {
    test('preload delegates to interface', () async {
      when(() => mock.preload()).thenAnswer((_) async => 'ready');
      final result = await controller.preload();
      expect(result, 'ready');
      verify(() => mock.preload()).called(1);
    });

    test('shutdown delegates to interface', () async {
      when(() => mock.shutdown(true)).thenAnswer((_) async => true);
      await controller.shutdown(true);
      verify(() => mock.shutdown(true)).called(1);
    });

    test('isInit delegates to interface', () async {
      when(() => mock.isInit).thenAnswer((_) async => true);
      final result = await controller.isInit;
      expect(result, true);
    });
  });

  group('config methods', () {
    test('validateConfig delegates to interface', () async {
      when(() => mock.validateConfig('/path')).thenAnswer((_) async => 'ok');
      final result = await controller.validateConfig('/path');
      expect(result, 'ok');
      verify(() => mock.validateConfig('/path')).called(1);
    });

    test('updateConfig delegates to interface', () async {
      const params = UpdateParams(
        tun: Tun(enable: false),
        mixedPort: 7890,
        allowLan: true,
        findProcessMode: FindProcessMode.off,
        mode: Mode.rule,
        logLevel: LogLevel.info,
        ipv6: false,
        tcpConcurrent: false,
        externalController: ExternalControllerStatus.close,
        unifiedDelay: false,
      );
      when(() => mock.updateConfig(params)).thenAnswer((_) async => 'ok');
      final result = await controller.updateConfig(params);
      expect(result, 'ok');
    });
  });

  group('proxy methods', () {
    test('changeProxy delegates to interface', () async {
      const params = ChangeProxyParams(groupName: 'G1', proxyName: 'P1');
      when(() => mock.changeProxy(params)).thenAnswer((_) async => 'ok');
      final result = await controller.changeProxy(params);
      expect(result, 'ok');
    });
  });

  group('connection methods', () {
    test('getConnections parses JSON response', () async {
      when(() => mock.getConnections()).thenAnswer(
        (_) async => json.encode({
          'connections': [
            {
              'id': '1',
              'metadata': {'network': 'tcp'},
              'upload': 0,
              'download': 0,
              'start': '2024-01-01',
              'chains': ['Proxy'],
              'rule': 'DIRECT',
              'rulePayload': '',
            },
          ],
        }),
      );
      final result = await controller.getConnections();
      expect(result.length, 1);
      expect(result.first.id, '1');
    });

    test('getConnections handles empty connections', () async {
      when(
        () => mock.getConnections(),
      ).thenAnswer((_) async => json.encode({'connections': []}));
      final result = await controller.getConnections();
      expect(result, isEmpty);
    });

    test('closeConnection delegates', () async {
      when(() => mock.closeConnection('id1')).thenAnswer((_) async => true);
      await controller.closeConnection('id1');
      verify(() => mock.closeConnection('id1')).called(1);
    });
  });

  group('external providers', () {
    test('getExternalProviders parses JSON', () async {
      when(() => mock.getExternalProviders()).thenAnswer(
        (_) async => json.encode([
          {
            'name': 'provider1',
            'type': 'Proxy',
            'count': 5,
            'vehicle-type': 'HTTP',
            'update-at': DateTime.now().toIso8601String(),
          },
        ]),
      );
      final result = await controller.getExternalProviders();
      expect(result.length, 1);
      expect(result.first.name, 'provider1');
    });

    test('getExternalProviders handles empty string', () async {
      when(() => mock.getExternalProviders()).thenAnswer((_) async => '');
      final result = await controller.getExternalProviders();
      expect(result, isEmpty);
    });

    test('getExternalProvider returns null on empty', () async {
      when(() => mock.getExternalProvider(any())).thenAnswer((_) async => '');
      final result = await controller.getExternalProvider('test');
      expect(result, isNull);
    });
  });

  group('traffic methods', () {
    test('getTraffic handles empty string', () async {
      when(() => mock.getTraffic(false)).thenAnswer((_) async => '');
      final result = await controller.getTraffic(false);
      expect(result.up, 0);
      expect(result.down, 0);
    });

    test('getTotalTraffic handles empty string', () async {
      when(() => mock.getTotalTraffic(false)).thenAnswer((_) async => '');
      final result = await controller.getTotalTraffic(false);
      expect(result.up, 0);
      expect(result.down, 0);
    });

    test('getMemory handles empty string', () async {
      when(() => mock.getMemory()).thenAnswer((_) async => '');
      final result = await controller.getMemory();
      expect(result, 0);
    });
  });

  group('misc methods', () {
    test('getCountryCode returns null on empty string', () async {
      when(() => mock.getCountryCode(any())).thenAnswer((_) async => '');
      final result = await controller.getCountryCode('8.8.8.8');
      expect(result, isNull);
    });

    test('getDelay parses JSON response', () async {
      when(() => mock.asyncTestDelay(any(), any())).thenAnswer(
        (_) async =>
            json.encode({'name': 'P1', 'value': 100, 'url': 'test.com'}),
      );
      final result = await controller.getDelay('test.com', 'P1');
      expect(result.name, 'P1');
      expect(result.value, 100);
    });

    test('startListener delegates', () async {
      when(() => mock.startListener()).thenAnswer((_) async => true);
      final result = await controller.startListener();
      expect(result, true);
    });

    test('stopListener delegates', () async {
      when(() => mock.stopListener()).thenAnswer((_) async => false);
      final result = await controller.stopListener();
      expect(result, false);
    });

    test('updateGeoData delegates', () async {
      const params = UpdateGeoDataParams(geoType: 'mmdb', geoName: 'Country');
      when(() => mock.updateGeoData(params)).thenAnswer((_) async => 'ok');
      final result = await controller.updateGeoData(params);
      expect(result, 'ok');
    });

    test('requestGc delegates to forceGc', () async {
      when(() => mock.forceGc()).thenAnswer((_) async => true);
      await controller.requestGc();
      verify(() => mock.forceGc()).called(1);
    });

    test('deleteFile delegates', () async {
      when(() => mock.deleteFile('/tmp/x')).thenAnswer((_) async => 'ok');
      final result = await controller.deleteFile('/tmp/x');
      expect(result, 'ok');
    });
  });

  group('network test methods', () {
    test('getSpeedTest parses JSON response', () async {
      const params = SpeedTestParams(proxyName: 'P1');
      when(() => mock.speedTest(params)).thenAnswer(
        (_) async => json.encode({
          'name': 'P1',
          'latency': 120,
          'speed': 1024.5,
          'bytes': 204800,
          'error': '',
        }),
      );
      final result = await controller.getSpeedTest(params);
      expect(result.name, 'P1');
      expect(result.latency, 120);
      expect(result.speed, 1024.5);
      expect(result.bytes, 204800);
      expect(result.error, '');
    });

    test('getSpeedTest applies defaults for missing fields', () async {
      const params = SpeedTestParams(proxyName: 'P1');
      when(
        () => mock.speedTest(any()),
      ).thenAnswer((_) async => json.encode({'name': 'P1'}));
      final result = await controller.getSpeedTest(params);
      expect(result.name, 'P1');
      expect(result.latency, 0);
      expect(result.speed, 0);
      expect(result.bytes, 0);
      expect(result.error, '');
    });

    test('getQuicTest parses JSON response', () async {
      const params = QuicTestParams(proxyName: 'P1');
      when(() => mock.quicTest(params)).thenAnswer(
        (_) async => json.encode({
          'name': 'P1',
          'rtt': 80,
          'alpn': 'h3',
          'version': 1,
          'error': '',
          'stage': 'completed',
          'target': 'cloudflare-quic.com:443',
          'resolved-ip': '203.0.113.7:443',
          'network': 'udp4',
          'sent-packets': 2,
          'sent-bytes': 2400,
          'received-packets': 1,
          'received-bytes': 1200,
        }),
      );
      final result = await controller.getQuicTest(params);
      expect(result.name, 'P1');
      expect(result.rtt, 80);
      expect(result.alpn, 'h3');
      expect(result.version, 1);
      expect(result.error, '');
      expect(result.stage, 'completed');
      expect(result.target, 'cloudflare-quic.com:443');
      expect(result.resolvedIp, '203.0.113.7:443');
      expect(result.network, 'udp4');
      expect(result.sentPackets, 2);
      expect(result.sentBytes, 2400);
      expect(result.receivedPackets, 1);
      expect(result.receivedBytes, 1200);
    });

    test('getQuicTest applies defaults for missing fields', () async {
      const params = QuicTestParams(proxyName: 'P1');
      when(
        () => mock.quicTest(any()),
      ).thenAnswer((_) async => json.encode({'name': 'P1', 'error': 'x'}));
      final result = await controller.getQuicTest(params);
      expect(result.name, 'P1');
      expect(result.rtt, 0);
      expect(result.alpn, '');
      expect(result.version, 0);
      expect(result.error, 'x');
      expect(result.stage, '');
      expect(result.target, '');
      expect(result.resolvedIp, '');
      expect(result.network, '');
      expect(result.sentPackets, 0);
      expect(result.sentBytes, 0);
      expect(result.receivedPackets, 0);
      expect(result.receivedBytes, 0);
    });

    test('getAllProxies filters group types case-insensitively', () async {
      when(() => mock.getProxies()).thenAnswer(
        (_) async => const ProxiesData(
          proxies: {
            'ProxyA': {'name': 'ProxyA', 'type': 'Shadowsocks'},
            'Group1': {'name': 'Group1', 'type': 'Selector'},
            'ProxyB': {'name': 'ProxyB', 'type': 'Vmess'},
            'Group2': {'name': 'Group2', 'type': 'URLTest'},
            'Group3': {'name': 'Group3', 'type': 'sElEcT'},
            'Group4': {'name': 'Group4', 'type': ' url-test '},
            'Group5': {'name': 'Group5', 'type': 'LOAD-BALANCE'},
            'Group6': {'name': 'Group6', 'type': 'relay'},
            'Group7': {'name': 'Group7', 'type': 'FaLlBaCk'},
          },
          all: [
            'ProxyA',
            'Group1',
            'ProxyB',
            'Group2',
            'Group3',
            'Group4',
            'Group5',
            'Group6',
            'Group7',
          ],
        ),
      );
      final result = await controller.getAllProxies();
      expect(result.map((proxy) => proxy.name), ['ProxyA', 'ProxyB']);
      expect(result.every((proxy) => proxy.type != 'Selector'), true);
    });

    test(
      'getAllProxies filters non-testable adapter types case-insensitively',
      () async {
        when(() => mock.getProxies()).thenAnswer(
          (_) async => const ProxiesData(
            proxies: {
              'RejectAdapter': {'name': 'RejectAdapter', 'type': '  rEjEcT '},
              'RejectDropAdapter': {
                'name': 'RejectDropAdapter',
                'type': 'REJECTDROP',
              },
              'PassAdapter': {'name': 'PassAdapter', 'type': 'Pass'},
              'PassRuleAdapter': {
                'name': 'PassRuleAdapter',
                'type': 'pAsSrUlE',
              },
              'REJECT': {'name': 'REJECT', 'type': 'Shadowsocks'},
              'DIRECT': {'name': 'DIRECT', 'type': 'Direct'},
              'COMPATIBLE': {'name': 'COMPATIBLE', 'type': 'Compatible'},
            },
            all: [
              'RejectAdapter',
              'RejectDropAdapter',
              'PassAdapter',
              'PassRuleAdapter',
              'REJECT',
              'DIRECT',
              'COMPATIBLE',
            ],
          ),
        );
        final result = await controller.getAllProxies();

        expect(result.map((proxy) => proxy.name).toSet(), {
          'REJECT',
          'DIRECT',
          'COMPATIBLE',
        });
      },
    );

    test('getAllProxies returns empty list when no proxies', () async {
      when(
        () => mock.getProxies(),
      ).thenAnswer((_) async => const ProxiesData(proxies: {}, all: []));
      final result = await controller.getAllProxies();
      expect(result, isEmpty);
    });

    test('getUnlockTest parses JSON response', () async {
      const params = UnlockTestParams(
        proxyName: 'P1',
        tests: [UnlockTestItem(id: 'chatgpt', url: 'https://x.com')],
      );
      when(() => mock.unlockTest(params)).thenAnswer(
        (_) async => json.encode({
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
        }),
      );
      final result = await controller.getUnlockTest(params);
      expect(result.name, 'P1');
      expect(result.results, hasLength(2));
      expect(result.results[0].id, 'chatgpt');
      expect(result.results[0].unlocked, true);
      expect(result.results[0].region, 'US');
      expect(result.results[0].latency, 321);
      expect(result.results[1].unlocked, false);
      expect(result.error, '');
    });

    test('getUnlockTest applies defaults for missing fields', () async {
      const params = UnlockTestParams(proxyName: 'P1');
      when(
        () => mock.unlockTest(any()),
      ).thenAnswer((_) async => json.encode({'name': 'P1', 'error': 'x'}));
      final result = await controller.getUnlockTest(params);
      expect(result.name, 'P1');
      expect(result.results, isEmpty);
      expect(result.error, 'x');
    });
  });
}
