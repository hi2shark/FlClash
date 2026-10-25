// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../core.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SetupParams _$SetupParamsFromJson(Map<String, dynamic> json) => _SetupParams(
  selectedMap: Map<String, String>.from(json['selected-map'] as Map),
  testUrl: json['test-url'] as String,
  skipCertVerify: json['skip-cert-verify'] as bool? ?? false,
  base: json['base'] == null
      ? null
      : SetupBase.fromJson(json['base'] as Map<String, dynamic>),
);

Map<String, dynamic> _$SetupParamsToJson(_SetupParams instance) =>
    <String, dynamic>{
      'selected-map': instance.selectedMap,
      'test-url': instance.testUrl,
      'skip-cert-verify': instance.skipCertVerify,
      'base': ?instance.base,
    };

_SetupBase _$SetupBaseFromJson(Map<String, dynamic> json) => _SetupBase(
  path: json['path'] as String,
  overlay: json['overlay'] as String,
);

Map<String, dynamic> _$SetupBaseToJson(_SetupBase instance) =>
    <String, dynamic>{'path': instance.path, 'overlay': instance.overlay};

_ProfileBase _$ProfileBaseFromJson(Map<String, dynamic> json) => _ProfileBase(
  config: json['config'] as Map<String, dynamic>,
  digest: json['digest'] as String,
  matchRules:
      (json['match-rules'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  proxies: (json['proxies'] as num?)?.toInt() ?? 0,
  proxyGroups: (json['proxy-groups'] as num?)?.toInt() ?? 0,
  rules: (json['rules'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$ProfileBaseToJson(_ProfileBase instance) =>
    <String, dynamic>{
      'config': instance.config,
      'digest': instance.digest,
      'match-rules': instance.matchRules,
      'proxies': instance.proxies,
      'proxy-groups': instance.proxyGroups,
      'rules': instance.rules,
    };

_UpdateParams _$UpdateParamsFromJson(Map<String, dynamic> json) =>
    _UpdateParams(
      tun: Tun.fromJson(json['tun'] as Map<String, dynamic>),
      mixedPort: (json['mixed-port'] as num).toInt(),
      allowLan: json['allow-lan'] as bool,
      findProcessMode: $enumDecode(
        _$FindProcessModeEnumMap,
        json['find-process-mode'],
      ),
      mode: $enumDecode(_$ModeEnumMap, json['mode']),
      logLevel: $enumDecode(_$LogLevelEnumMap, json['log-level']),
      ipv6: json['ipv6'] as bool?,
      tcpConcurrent: json['tcp-concurrent'] as bool?,
      externalController: $enumDecode(
        _$ExternalControllerStatusEnumMap,
        json['external-controller'],
      ),
      secret: json['secret'] as String? ?? '',
      unifiedDelay: json['unified-delay'] as bool?,
      authentication:
          (json['authentication'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      geoAutoUpdate: json['geo-auto-update'] as bool? ?? false,
      geoUpdateInterval: (json['geo-update-interval'] as num?)?.toInt() ?? 24,
      geoXUrl:
          (json['geox-url'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const {},
      skipCertVerify: json['skip-cert-verify'] as bool? ?? false,
    );

Map<String, dynamic> _$UpdateParamsToJson(_UpdateParams instance) =>
    <String, dynamic>{
      'tun': _tunCoreJson(instance.tun),
      'mixed-port': instance.mixedPort,
      'allow-lan': instance.allowLan,
      'find-process-mode': _$FindProcessModeEnumMap[instance.findProcessMode]!,
      'mode': _$ModeEnumMap[instance.mode]!,
      'log-level': _$LogLevelEnumMap[instance.logLevel]!,
      'ipv6': instance.ipv6,
      'tcp-concurrent': instance.tcpConcurrent,
      'external-controller':
          _$ExternalControllerStatusEnumMap[instance.externalController]!,
      'secret': instance.secret,
      'unified-delay': instance.unifiedDelay,
      'authentication': instance.authentication,
      'geo-auto-update': instance.geoAutoUpdate,
      'geo-update-interval': instance.geoUpdateInterval,
      'geox-url': instance.geoXUrl,
      'skip-cert-verify': instance.skipCertVerify,
    };

const _$FindProcessModeEnumMap = {
  FindProcessMode.always: 'always',
  FindProcessMode.off: 'off',
};

const _$ModeEnumMap = {
  Mode.rule: 'rule',
  Mode.global: 'global',
  Mode.direct: 'direct',
};

const _$LogLevelEnumMap = {
  LogLevel.debug: 'debug',
  LogLevel.info: 'info',
  LogLevel.warning: 'warning',
  LogLevel.error: 'error',
  LogLevel.silent: 'silent',
};

const _$ExternalControllerStatusEnumMap = {
  ExternalControllerStatus.close: '',
  ExternalControllerStatus.open: '127.0.0.1:9090',
};

_VpnOptions _$VpnOptionsFromJson(Map<String, dynamic> json) => _VpnOptions(
  enable: json['enable'] as bool,
  port: (json['port'] as num).toInt(),
  ipv6: json['ipv6'] as bool,
  dnsHijacking: json['dnsHijacking'] as bool,
  dnsEnable: json['dnsEnable'] as bool? ?? false,
  accessControlProps: AccessControlProps.fromJson(
    json['accessControlProps'] as Map<String, dynamic>,
  ),
  allowBypass: json['allowBypass'] as bool,
  systemProxy: json['systemProxy'] as bool,
  bypassDomain: (json['bypassDomain'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  stack: json['stack'] as String,
  routeAddress:
      (json['routeAddress'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  mtu: (json['mtu'] as num?)?.toInt() ?? 0,
  congestionController: json['congestionController'] as String? ?? '',
);

Map<String, dynamic> _$VpnOptionsToJson(_VpnOptions instance) =>
    <String, dynamic>{
      'enable': instance.enable,
      'port': instance.port,
      'ipv6': instance.ipv6,
      'dnsHijacking': instance.dnsHijacking,
      'dnsEnable': instance.dnsEnable,
      'accessControlProps': instance.accessControlProps,
      'allowBypass': instance.allowBypass,
      'systemProxy': instance.systemProxy,
      'bypassDomain': instance.bypassDomain,
      'stack': instance.stack,
      'routeAddress': instance.routeAddress,
      'mtu': instance.mtu,
      'congestionController': instance.congestionController,
    };

_InitParams _$InitParamsFromJson(Map<String, dynamic> json) => _InitParams(
  homeDir: json['home-dir'] as String,
  version: (json['version'] as num).toInt(),
);

Map<String, dynamic> _$InitParamsToJson(_InitParams instance) =>
    <String, dynamic>{
      'home-dir': instance.homeDir,
      'version': instance.version,
    };

_ChangeProxyParams _$ChangeProxyParamsFromJson(Map<String, dynamic> json) =>
    _ChangeProxyParams(
      groupName: json['group-name'] as String,
      proxyName: json['proxy-name'] as String,
    );

Map<String, dynamic> _$ChangeProxyParamsToJson(_ChangeProxyParams instance) =>
    <String, dynamic>{
      'group-name': instance.groupName,
      'proxy-name': instance.proxyName,
    };

_ChangeProxyResult _$ChangeProxyResultFromJson(Map<String, dynamic> json) =>
    _ChangeProxyResult(
      message: json['message'] as String? ?? '',
      changed: json['changed'] as bool? ?? false,
    );

Map<String, dynamic> _$ChangeProxyResultToJson(_ChangeProxyResult instance) =>
    <String, dynamic>{'message': instance.message, 'changed': instance.changed};

_RouteSnapshot _$RouteSnapshotFromJson(Map<String, dynamic> json) =>
    _RouteSnapshot(
      coreEpoch: (json['core-epoch'] as num?)?.toInt() ?? 0,
      routeVersion: (json['route-version'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$RouteSnapshotToJson(_RouteSnapshot instance) =>
    <String, dynamic>{
      'core-epoch': instance.coreEpoch,
      'route-version': instance.routeVersion,
    };

_RouteHit _$RouteHitFromJson(Map<String, dynamic> json) => _RouteHit(
  host: json['host'] as String? ?? '',
  proxy: json['proxy'] as String? ?? '',
  exit: json['exit'] as String? ?? '',
);

Map<String, dynamic> _$RouteHitToJson(_RouteHit instance) => <String, dynamic>{
  'host': instance.host,
  'proxy': instance.proxy,
  'exit': instance.exit,
};

_CheckRoutesParams _$CheckRoutesParamsFromJson(Map<String, dynamic> json) =>
    _CheckRoutesParams(
      routes:
          (json['routes'] as List<dynamic>?)
              ?.map(
                (e) => (e as List<dynamic>)
                    .map((e) => RouteHit.fromJson(e as Map<String, dynamic>))
                    .toList(),
              )
              .toList() ??
          const [],
    );

Map<String, dynamic> _$CheckRoutesParamsToJson(_CheckRoutesParams instance) =>
    <String, dynamic>{'routes': instance.routes};

_RouteCheck _$RouteCheckFromJson(Map<String, dynamic> json) => _RouteCheck(
  coreEpoch: (json['core-epoch'] as num?)?.toInt() ?? 0,
  routeVersion: (json['route-version'] as num?)?.toInt() ?? 0,
  held:
      (json['held'] as List<dynamic>?)?.map((e) => e as bool).toList() ??
      const [],
);

Map<String, dynamic> _$RouteCheckToJson(_RouteCheck instance) =>
    <String, dynamic>{
      'core-epoch': instance.coreEpoch,
      'route-version': instance.routeVersion,
      'held': instance.held,
    };

_CoreEvent _$CoreEventFromJson(Map<String, dynamic> json) => _CoreEvent(
  type: $enumDecode(_$CoreEventTypeEnumMap, json['type']),
  data: json['data'],
);

Map<String, dynamic> _$CoreEventToJson(_CoreEvent instance) =>
    <String, dynamic>{
      'type': _$CoreEventTypeEnumMap[instance.type]!,
      'data': instance.data,
    };

const _$CoreEventTypeEnumMap = {
  CoreEventType.log: 'log',
  CoreEventType.delay: 'delay',
  CoreEventType.request: 'request',
  CoreEventType.requestTraffic: 'requestTraffic',
  CoreEventType.dns: 'dns',
  CoreEventType.loaded: 'loaded',
  CoreEventType.crash: 'crash',
  CoreEventType.geoUpdate: 'geoUpdate',
  CoreEventType.routeChanged: 'routeChanged',
  CoreEventType.dialerLoop: 'dialerLoop',
};

_Delay _$DelayFromJson(Map<String, dynamic> json) => _Delay(
  name: json['name'] as String,
  url: json['url'] as String,
  value: (json['value'] as num?)?.toInt(),
);

Map<String, dynamic> _$DelayToJson(_Delay instance) => <String, dynamic>{
  'name': instance.name,
  'url': instance.url,
  'value': instance.value,
};

_ProbeParams _$ProbeParamsFromJson(Map<String, dynamic> json) => _ProbeParams(
  url: json['url'] as String,
  proxyName: json['proxy-name'] as String? ?? '',
  headers:
      (json['headers'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ) ??
      const {},
  timeout: (json['timeout'] as num).toInt(),
  maxBody: (json['max-body'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$ProbeParamsToJson(_ProbeParams instance) =>
    <String, dynamic>{
      'url': instance.url,
      'proxy-name': instance.proxyName,
      'headers': instance.headers,
      'timeout': instance.timeout,
      'max-body': instance.maxBody,
    };

_ProbeResult _$ProbeResultFromJson(Map<String, dynamic> json) => _ProbeResult(
  statusCode: (json['status-code'] as num?)?.toInt() ?? 0,
  delay: (json['delay'] as num?)?.toInt() ?? 0,
  body: json['body'] as String? ?? '',
  url: json['url'] as String? ?? '',
  chains:
      (json['chains'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  rule: json['rule'] as String? ?? '',
  rulePayload: json['rule-payload'] as String? ?? '',
  error: json['error'] as String?,
  message: json['message'] as String?,
);

Map<String, dynamic> _$ProbeResultToJson(_ProbeResult instance) =>
    <String, dynamic>{
      'status-code': instance.statusCode,
      'delay': instance.delay,
      'body': instance.body,
      'url': instance.url,
      'chains': instance.chains,
      'rule': instance.rule,
      'rule-payload': instance.rulePayload,
      'error': instance.error,
      'message': instance.message,
    };

_OutboundIpParams _$OutboundIpParamsFromJson(Map<String, dynamic> json) =>
    _OutboundIpParams(
      proxyName: json['proxy-name'] as String? ?? '',
      urls:
          (json['urls'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          const [],
      timeout: (json['timeout'] as num).toInt(),
    );

Map<String, dynamic> _$OutboundIpParamsToJson(_OutboundIpParams instance) =>
    <String, dynamic>{
      'proxy-name': instance.proxyName,
      'urls': instance.urls,
      'timeout': instance.timeout,
    };

_OutboundIpResult _$OutboundIpResultFromJson(Map<String, dynamic> json) =>
    _OutboundIpResult(
      url: json['url'] as String? ?? '',
      body: json['body'] as String? ?? '',
      delay: (json['delay'] as num?)?.toInt() ?? 0,
      chains:
          (json['chains'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      error: json['error'] as String?,
      coreEpoch: (json['core-epoch'] as num?)?.toInt() ?? 0,
      routeVersion: (json['route-version'] as num?)?.toInt() ?? 0,
      hits:
          (json['hits'] as List<dynamic>?)
              ?.map((e) => RouteHit.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      nodeHits:
          (json['node-hits'] as List<dynamic>?)
              ?.map((e) => RouteHit.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$OutboundIpResultToJson(_OutboundIpResult instance) =>
    <String, dynamic>{
      'url': instance.url,
      'body': instance.body,
      'delay': instance.delay,
      'chains': instance.chains,
      'error': instance.error,
      'core-epoch': instance.coreEpoch,
      'route-version': instance.routeVersion,
      'hits': instance.hits,
      'node-hits': instance.nodeHits,
    };

_ServiceCheckParams _$ServiceCheckParamsFromJson(Map<String, dynamic> json) =>
    _ServiceCheckParams(
      proxyName: json['proxy-name'] as String? ?? '',
      names:
          (json['names'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          const [],
      timeout: (json['timeout'] as num).toInt(),
    );

Map<String, dynamic> _$ServiceCheckParamsToJson(_ServiceCheckParams instance) =>
    <String, dynamic>{
      'proxy-name': instance.proxyName,
      'names': instance.names,
      'timeout': instance.timeout,
    };

_ServiceCheckItem _$ServiceCheckItemFromJson(Map<String, dynamic> json) =>
    _ServiceCheckItem(
      name: json['name'] as String? ?? '',
      status: json['status'] as String? ?? '',
      region: json['region'] as String? ?? '',
      delay: (json['delay'] as num?)?.toInt() ?? 0,
      chains:
          (json['chains'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      checkedAt: (json['checked-at'] as num?)?.toInt() ?? 0,
      coreEpoch: (json['core-epoch'] as num?)?.toInt() ?? 0,
      routeVersion: (json['route-version'] as num?)?.toInt() ?? 0,
      hits:
          (json['hits'] as List<dynamic>?)
              ?.map((e) => RouteHit.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$ServiceCheckItemToJson(_ServiceCheckItem instance) =>
    <String, dynamic>{
      'name': instance.name,
      'status': instance.status,
      'region': instance.region,
      'delay': instance.delay,
      'chains': instance.chains,
      'checked-at': instance.checkedAt,
      'core-epoch': instance.coreEpoch,
      'route-version': instance.routeVersion,
      'hits': instance.hits,
    };

_CoreMemoryStats _$CoreMemoryStatsFromJson(Map<String, dynamic> json) =>
    _CoreMemoryStats(
      rss: (json['rss'] as num?)?.toInt() ?? 0,
      heapInuse: (json['heapInuse'] as num?)?.toInt() ?? 0,
      heapIdle: (json['heapIdle'] as num?)?.toInt() ?? 0,
      stackInuse: (json['stackInuse'] as num?)?.toInt() ?? 0,
      runtimeOther: (json['runtimeOther'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$CoreMemoryStatsToJson(_CoreMemoryStats instance) =>
    <String, dynamic>{
      'rss': instance.rss,
      'heapInuse': instance.heapInuse,
      'heapIdle': instance.heapIdle,
      'stackInuse': instance.stackInuse,
      'runtimeOther': instance.runtimeOther,
    };

_ExternalProvider _$ExternalProviderFromJson(Map<String, dynamic> json) =>
    _ExternalProvider(
      name: json['name'] as String,
      type: json['type'] as String,
      path: json['path'] as String?,
      count: (json['count'] as num).toInt(),
      subscriptionInfo: subscriptionInfoFormCore(
        json['subscription-info'] as Map<String, Object?>?,
      ),
      vehicleType: json['vehicle-type'] as String,
      updateAt: DateTime.parse(json['update-at'] as String),
    );

Map<String, dynamic> _$ExternalProviderToJson(_ExternalProvider instance) =>
    <String, dynamic>{
      'name': instance.name,
      'type': instance.type,
      'path': instance.path,
      'count': instance.count,
      'subscription-info': instance.subscriptionInfo,
      'vehicle-type': instance.vehicleType,
      'update-at': instance.updateAt.toIso8601String(),
    };

_ProxiesData _$ProxiesDataFromJson(Map<String, dynamic> json) => _ProxiesData(
  proxies: json['proxies'] as Map<String, dynamic>,
  all: (json['all'] as List<dynamic>).map((e) => e as String).toList(),
);

Map<String, dynamic> _$ProxiesDataToJson(_ProxiesData instance) =>
    <String, dynamic>{'proxies': instance.proxies, 'all': instance.all};

_ActionResult _$ActionResultFromJson(Map<String, dynamic> json) =>
    _ActionResult(
      method: $enumDecode(_$CoreMethodEnumMap, json['method']),
      data: json['data'],
      id: json['id'] as String?,
      code:
          $enumDecodeNullable(_$ResultTypeEnumMap, json['code']) ??
          ResultType.success,
    );

Map<String, dynamic> _$ActionResultToJson(_ActionResult instance) =>
    <String, dynamic>{
      'method': _$CoreMethodEnumMap[instance.method]!,
      'data': instance.data,
      'id': instance.id,
      'code': _$ResultTypeEnumMap[instance.code]!,
    };

const _$CoreMethodEnumMap = {
  CoreMethod.message: 'message',
  CoreMethod.initClash: 'initClash',
  CoreMethod.getIsInit: 'getIsInit',
  CoreMethod.forceGc: 'forceGc',
  CoreMethod.shutdown: 'shutdown',
  CoreMethod.validateConfig: 'validateConfig',
  CoreMethod.decryptConfig: 'decryptConfig',
  CoreMethod.validateProxies: 'validateProxies',
  CoreMethod.validateFilters: 'validateFilters',
  CoreMethod.convertProxies: 'convertProxies',
  CoreMethod.encodeShareLinks: 'encodeShareLinks',
  CoreMethod.decodeShareLinks: 'decodeShareLinks',
  CoreMethod.updateConfig: 'updateConfig',
  CoreMethod.getConfig: 'getConfig',
  CoreMethod.getProfileBase: 'getProfileBase',
  CoreMethod.getProfileOutbounds: 'getProfileOutbounds',
  CoreMethod.getProxyDefinition: 'getProxyDefinition',
  CoreMethod.buildProfile: 'buildProfile',
  CoreMethod.dumpRuleSet: 'dumpRuleSet',
  CoreMethod.compileRuleSet: 'compileRuleSet',
  CoreMethod.getProxies: 'getProxies',
  CoreMethod.changeProxy: 'changeProxy',
  CoreMethod.getTraffic: 'getTraffic',
  CoreMethod.getTotalTraffic: 'getTotalTraffic',
  CoreMethod.resetTraffic: 'resetTraffic',
  CoreMethod.asyncTestDelay: 'asyncTestDelay',
  CoreMethod.speedTest: 'speedTest',
  CoreMethod.quicTest: 'quicTest',
  CoreMethod.probe: 'probe',
  CoreMethod.outboundIp: 'outboundIp',
  CoreMethod.serviceCheck: 'serviceCheck',
  CoreMethod.getConnections: 'getConnections',
  CoreMethod.getConnectionCount: 'getConnectionCount',
  CoreMethod.closeConnections: 'closeConnections',
  CoreMethod.resetConnections: 'resetConnections',
  CoreMethod.clearDnsCache: 'clearDnsCache',
  CoreMethod.closeConnection: 'closeConnection',
  CoreMethod.getExternalProviders: 'getExternalProviders',
  CoreMethod.getExternalProvider: 'getExternalProvider',
  CoreMethod.updateGeoData: 'updateGeoData',
  CoreMethod.updateExternalProvider: 'updateExternalProvider',
  CoreMethod.sideLoadExternalProvider: 'sideLoadExternalProvider',
  CoreMethod.startLog: 'startLog',
  CoreMethod.stopLog: 'stopLog',
  CoreMethod.startListener: 'startListener',
  CoreMethod.stopListener: 'stopListener',
  CoreMethod.getMemoryStats: 'getMemoryStats',
  CoreMethod.crash: 'crash',
  CoreMethod.setupConfig: 'setupConfig',
  CoreMethod.clearEffect: 'clearEffect',
  CoreMethod.updateDns: 'updateDns',
  CoreMethod.watchRoute: 'watchRoute',
  CoreMethod.checkRoutes: 'checkRoutes',
};

const _$ResultTypeEnumMap = {ResultType.success: 0, ResultType.error: -1};

_SpeedTestParams _$SpeedTestParamsFromJson(Map<String, dynamic> json) =>
    _SpeedTestParams(
      proxyName: json['proxy-name'] as String,
      testUrl: json['test-url'] as String?,
      timeout: (json['timeout'] as num?)?.toInt(),
    );

Map<String, dynamic> _$SpeedTestParamsToJson(_SpeedTestParams instance) =>
    <String, dynamic>{
      'proxy-name': instance.proxyName,
      'test-url': instance.testUrl,
      'timeout': instance.timeout,
    };

_SpeedTestResult _$SpeedTestResultFromJson(Map<String, dynamic> json) =>
    _SpeedTestResult(
      name: json['name'] as String? ?? '',
      latency: (json['latency'] as num?)?.toInt() ?? 0,
      speed: (json['speed'] as num?)?.toDouble() ?? 0,
      bytes: (json['bytes'] as num?)?.toInt() ?? 0,
      error: json['error'] as String? ?? '',
    );

Map<String, dynamic> _$SpeedTestResultToJson(_SpeedTestResult instance) =>
    <String, dynamic>{
      'name': instance.name,
      'latency': instance.latency,
      'speed': instance.speed,
      'bytes': instance.bytes,
      'error': instance.error,
    };

_QuicTestParams _$QuicTestParamsFromJson(Map<String, dynamic> json) =>
    _QuicTestParams(
      proxyName: json['proxy-name'] as String,
      host: json['host'] as String?,
      timeout: (json['timeout'] as num?)?.toInt(),
    );

Map<String, dynamic> _$QuicTestParamsToJson(_QuicTestParams instance) =>
    <String, dynamic>{
      'proxy-name': instance.proxyName,
      'host': instance.host,
      'timeout': instance.timeout,
    };

_QuicTestResult _$QuicTestResultFromJson(Map<String, dynamic> json) =>
    _QuicTestResult(
      name: json['name'] as String? ?? '',
      rtt: (json['rtt'] as num?)?.toInt() ?? 0,
      alpn: json['alpn'] as String? ?? '',
      version: (json['version'] as num?)?.toInt() ?? 0,
      error: json['error'] as String? ?? '',
      stage: json['stage'] as String? ?? '',
      target: json['target'] as String? ?? '',
      resolvedIp: json['resolved-ip'] as String? ?? '',
      network: json['network'] as String? ?? '',
      sentPackets: (json['sent-packets'] as num?)?.toInt() ?? 0,
      sentBytes: (json['sent-bytes'] as num?)?.toInt() ?? 0,
      receivedPackets: (json['received-packets'] as num?)?.toInt() ?? 0,
      receivedBytes: (json['received-bytes'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$QuicTestResultToJson(_QuicTestResult instance) =>
    <String, dynamic>{
      'name': instance.name,
      'rtt': instance.rtt,
      'alpn': instance.alpn,
      'version': instance.version,
      'error': instance.error,
      'stage': instance.stage,
      'target': instance.target,
      'resolved-ip': instance.resolvedIp,
      'network': instance.network,
      'sent-packets': instance.sentPackets,
      'sent-bytes': instance.sentBytes,
      'received-packets': instance.receivedPackets,
      'received-bytes': instance.receivedBytes,
    };
