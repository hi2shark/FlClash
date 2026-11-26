// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../core.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SetupParams _$SetupParamsFromJson(Map<String, dynamic> json) => _SetupParams(
  base: json['base'] == null
      ? null
      : SetupBase.fromJson(json['base'] as Map<String, dynamic>),
  selectedMap: Map<String, String>.from(json['selected-map'] as Map),
  options: CoreOptions.fromJson(json['options'] as Map<String, dynamic>),
);

Map<String, dynamic> _$SetupParamsToJson(_SetupParams instance) =>
    <String, dynamic>{
      'base': ?instance.base,
      'selected-map': instance.selectedMap,
      'options': instance.options,
    };

_CoreOptions _$CoreOptionsFromJson(Map<String, dynamic> json) => _CoreOptions(
  testUrl: json['test-url'] as String,
  skipCertVerify: json['skip-cert-verify'] as bool? ?? false,
  delayTestTimeout:
      (json['delay-test-timeout'] as num?)?.toInt() ?? defaultDelayTestTimeout,
  mitmCapture: json['mitm-capture'] as bool? ?? false,
);

Map<String, dynamic> _$CoreOptionsToJson(_CoreOptions instance) =>
    <String, dynamic>{
      'test-url': instance.testUrl,
      'skip-cert-verify': instance.skipCertVerify,
      'delay-test-timeout': instance.delayTestTimeout,
      'mitm-capture': instance.mitmCapture,
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
      geoAutoUpdate: json['geo-auto-update'] as bool? ?? true,
      geoUpdateInterval: (json['geo-update-interval'] as num?)?.toInt() ?? 24,
      geoXUrl:
          (json['geox-url'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const {},
      options: CoreOptions.fromJson(json['options'] as Map<String, dynamic>),
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
      'options': instance.options,
    };

const _$FindProcessModeEnumMap = {
  FindProcessMode.always: 'always',
  FindProcessMode.strict: 'strict',
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

_MitmCertificate _$MitmCertificateFromJson(Map<String, dynamic> json) =>
    _MitmCertificate(
      pem: json['pem'] as String,
      fingerprint: json['fingerprint'] as String,
      subject: json['subject'] as String,
      notBefore: DateTime.parse(json['not-before'] as String),
      notAfter: DateTime.parse(json['not-after'] as String),
    );

Map<String, dynamic> _$MitmCertificateToJson(_MitmCertificate instance) =>
    <String, dynamic>{
      'pem': instance.pem,
      'fingerprint': instance.fingerprint,
      'subject': instance.subject,
      'not-before': instance.notBefore.toIso8601String(),
      'not-after': instance.notAfter.toIso8601String(),
    };

_MitmScriptOutput _$MitmScriptOutputFromJson(Map<String, dynamic> json) =>
    _MitmScriptOutput(
      logs:
          (json['logs'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          const [],
      result: json['result'] as String? ?? '',
      error: json['error'] as String? ?? '',
    );

Map<String, dynamic> _$MitmScriptOutputToJson(_MitmScriptOutput instance) =>
    <String, dynamic>{
      'logs': instance.logs,
      'result': instance.result,
      'error': instance.error,
    };

MitmUrlRewriteView _$MitmUrlRewriteViewFromJson(Map<String, dynamic> json) =>
    MitmUrlRewriteView(
      pattern: json['pattern'] as String,
      action: json['action'] as String,
      replacement: json['replacement'] as String?,
      requestHead: json['requestHead'] as String?,
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$MitmUrlRewriteViewToJson(MitmUrlRewriteView instance) =>
    <String, dynamic>{
      'pattern': instance.pattern,
      'action': instance.action,
      'replacement': instance.replacement,
      'requestHead': instance.requestHead,
      'type': instance.$type,
    };

MitmHeaderRewriteView _$MitmHeaderRewriteViewFromJson(
  Map<String, dynamic> json,
) => MitmHeaderRewriteView(
  phase: json['phase'] as String,
  pattern: json['pattern'] as String,
  requestHead: json['requestHead'] as String?,
  responseHead: json['responseHead'] as String?,
  action: json['action'] as String,
  name: json['name'] as String?,
  value: json['value'] as String?,
  regex: json['regex'] as String?,
  replacement: json['replacement'] as String?,
  $type: json['type'] as String?,
);

Map<String, dynamic> _$MitmHeaderRewriteViewToJson(
  MitmHeaderRewriteView instance,
) => <String, dynamic>{
  'phase': instance.phase,
  'pattern': instance.pattern,
  'requestHead': instance.requestHead,
  'responseHead': instance.responseHead,
  'action': instance.action,
  'name': instance.name,
  'value': instance.value,
  'regex': instance.regex,
  'replacement': instance.replacement,
  'type': instance.$type,
};

MitmBodyRewriteView _$MitmBodyRewriteViewFromJson(Map<String, dynamic> json) =>
    MitmBodyRewriteView(
      phase: json['phase'] as String,
      pattern: json['pattern'] as String,
      requestHead: json['requestHead'] as String?,
      responseHead: json['responseHead'] as String?,
      replacements:
          (json['replacements'] as List<dynamic>?)
              ?.map(
                (e) => MitmBodyReplacement.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      jq: json['jq'] as String?,
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$MitmBodyRewriteViewToJson(
  MitmBodyRewriteView instance,
) => <String, dynamic>{
  'phase': instance.phase,
  'pattern': instance.pattern,
  'requestHead': instance.requestHead,
  'responseHead': instance.responseHead,
  'replacements': instance.replacements,
  'jq': instance.jq,
  'type': instance.$type,
};

MitmMapLocalView _$MitmMapLocalViewFromJson(Map<String, dynamic> json) =>
    MitmMapLocalView(
      pattern: json['pattern'] as String,
      requestHead: json['requestHead'] as String?,
      dataType: json['dataType'] as String,
      data: json['data'] as String? ?? '',
      status: (json['status'] as num?)?.toInt(),
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$MitmMapLocalViewToJson(MitmMapLocalView instance) =>
    <String, dynamic>{
      'pattern': instance.pattern,
      'requestHead': instance.requestHead,
      'dataType': instance.dataType,
      'data': instance.data,
      'status': instance.status,
      'type': instance.$type,
    };

MitmScriptView _$MitmScriptViewFromJson(Map<String, dynamic> json) =>
    MitmScriptView(
      name: json['name'] as String,
      kind: json['kind'] as String,
      pattern: json['pattern'] as String?,
      cronexp: json['cronexp'] as String?,
      event: json['event'] as String?,
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$MitmScriptViewToJson(MitmScriptView instance) =>
    <String, dynamic>{
      'name': instance.name,
      'kind': instance.kind,
      'pattern': instance.pattern,
      'cronexp': instance.cronexp,
      'event': instance.event,
      'type': instance.$type,
    };

MitmHostsView _$MitmHostsViewFromJson(Map<String, dynamic> json) =>
    MitmHostsView(
      entries:
          (json['entries'] as List<dynamic>?)
              ?.map((e) => MitmHostEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$MitmHostsViewToJson(MitmHostsView instance) =>
    <String, dynamic>{'entries': instance.entries, 'type': instance.$type};

MitmSourcesView _$MitmSourcesViewFromJson(Map<String, dynamic> json) =>
    MitmSourcesView(
      entries:
          (json['entries'] as List<dynamic>?)
              ?.map((e) => MitmSourceEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$MitmSourcesViewToJson(MitmSourcesView instance) =>
    <String, dynamic>{'entries': instance.entries, 'type': instance.$type};

_MitmBodyReplacement _$MitmBodyReplacementFromJson(Map<String, dynamic> json) =>
    _MitmBodyReplacement(
      regex: json['regex'] as String,
      replacement: json['replacement'] as String,
    );

Map<String, dynamic> _$MitmBodyReplacementToJson(
  _MitmBodyReplacement instance,
) => <String, dynamic>{
  'regex': instance.regex,
  'replacement': instance.replacement,
};

_MitmHostEntry _$MitmHostEntryFromJson(Map<String, dynamic> json) =>
    _MitmHostEntry(
      host: json['host'] as String,
      port: (json['port'] as num?)?.toInt(),
      exclude: json['exclude'] as bool? ?? false,
    );

Map<String, dynamic> _$MitmHostEntryToJson(_MitmHostEntry instance) =>
    <String, dynamic>{
      'host': instance.host,
      'port': instance.port,
      'exclude': instance.exclude,
    };

_MitmSourceEntry _$MitmSourceEntryFromJson(Map<String, dynamic> json) =>
    _MitmSourceEntry(
      network: json['network'] as String,
      exclude: json['exclude'] as bool? ?? false,
    );

Map<String, dynamic> _$MitmSourceEntryToJson(_MitmSourceEntry instance) =>
    <String, dynamic>{'network': instance.network, 'exclude': instance.exclude};

_MitmExchangeSummary _$MitmExchangeSummaryFromJson(Map<String, dynamic> json) =>
    _MitmExchangeSummary(
      id: (json['id'] as num).toInt(),
      start: DateTime.parse(json['start'] as String),
      pending: json['pending'] as bool? ?? false,
      duration: (json['duration'] as num?)?.toInt() ?? 0,
      method: json['method'] as String? ?? '',
      url: json['url'] as String? ?? '',
      status: (json['status'] as num?)?.toInt() ?? 0,
      requestSize: (json['request-size'] as num?)?.toInt() ?? 0,
      responseSize: (json['response-size'] as num?)?.toInt() ?? 0,
      error: json['error'] as String? ?? '',
      host: json['host'] as String? ?? '',
      path: json['path'] as String? ?? '',
      contentType: json['content-type'] as String? ?? '',
      statusClass: json['status-class'] as String? ?? '',
      kind: json['kind'] as String? ?? '',
      rewritten: json['rewritten'] as bool? ?? false,
      actionKinds:
          (json['action-kinds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      answer: json['answer'] as String? ?? '',
      connectionId: _connectionIdOf(json['connection-id']),
      app: json['app'] == null
          ? null
          : MitmApp.fromJson(json['app'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MitmExchangeSummaryToJson(
  _MitmExchangeSummary instance,
) => <String, dynamic>{
  'id': instance.id,
  'start': instance.start.toIso8601String(),
  'pending': instance.pending,
  'duration': instance.duration,
  'method': instance.method,
  'url': instance.url,
  'status': instance.status,
  'request-size': instance.requestSize,
  'response-size': instance.responseSize,
  'error': instance.error,
  'host': instance.host,
  'path': instance.path,
  'content-type': instance.contentType,
  'status-class': instance.statusClass,
  'kind': instance.kind,
  'rewritten': instance.rewritten,
  'action-kinds': instance.actionKinds,
  'answer': instance.answer,
  'connection-id': instance.connectionId,
  'app': instance.app,
};

_MitmApp _$MitmAppFromJson(Map<String, dynamic> json) => _MitmApp(
  process: json['process'] as String? ?? '',
  processPath: json['process-path'] as String? ?? '',
  uid: (json['uid'] as num?)?.toInt(),
);

Map<String, dynamic> _$MitmAppToJson(_MitmApp instance) => <String, dynamic>{
  'process': instance.process,
  'process-path': instance.processPath,
  'uid': instance.uid,
};

_MitmQueryPage _$MitmQueryPageFromJson(
  Map<String, dynamic> json,
) => _MitmQueryPage(
  capturing: json['capturing'] as bool? ?? false,
  since: json['since'] == null ? null : DateTime.parse(json['since'] as String),
  version: (json['version'] as num?)?.toInt() ?? 0,
  oldest: (json['oldest'] as num?)?.toInt() ?? 0,
  held: (json['held'] as num?)?.toInt() ?? 0,
  matched: (json['matched'] as num?)?.toInt() ?? 0,
  exchanges:
      (json['exchanges'] as List<dynamic>?)
          ?.map((e) => MitmExchangeSummary.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  next: (json['next'] as num?)?.toInt(),
  unmatched:
      (json['unmatched'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList() ??
      const [],
);

Map<String, dynamic> _$MitmQueryPageToJson(_MitmQueryPage instance) =>
    <String, dynamic>{
      'capturing': instance.capturing,
      'since': instance.since?.toIso8601String(),
      'version': instance.version,
      'oldest': instance.oldest,
      'held': instance.held,
      'matched': instance.matched,
      'exchanges': instance.exchanges,
      'next': instance.next,
      'unmatched': instance.unmatched,
    };

_MitmExchangeList _$MitmExchangeListFromJson(
  Map<String, dynamic> json,
) => _MitmExchangeList(
  capturing: json['capturing'] as bool? ?? false,
  since: json['since'] == null ? null : DateTime.parse(json['since'] as String),
  exchanges:
      (json['exchanges'] as List<dynamic>?)
          ?.map((e) => MitmExchangeSummary.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  closed: json['closed'] as bool? ?? false,
);

Map<String, dynamic> _$MitmExchangeListToJson(_MitmExchangeList instance) =>
    <String, dynamic>{
      'capturing': instance.capturing,
      'since': instance.since?.toIso8601String(),
      'exchanges': instance.exchanges,
      'closed': instance.closed,
    };

_MitmAction _$MitmActionFromJson(Map<String, dynamic> json) => _MitmAction(
  kind: json['kind'] as String,
  phase: json['phase'] as String? ?? '',
  detail: json['detail'] as String? ?? '',
  module: json['module'] as String? ?? '',
);

Map<String, dynamic> _$MitmActionToJson(_MitmAction instance) =>
    <String, dynamic>{
      'kind': instance.kind,
      'phase': instance.phase,
      'detail': instance.detail,
      'module': instance.module,
    };

_MitmRoute _$MitmRouteFromJson(Map<String, dynamic> json) => _MitmRoute(
  rule: json['rule'] as String? ?? '',
  rulePayload: json['rule-payload'] as String? ?? '',
  chains:
      (json['chains'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
);

Map<String, dynamic> _$MitmRouteToJson(_MitmRoute instance) =>
    <String, dynamic>{
      'rule': instance.rule,
      'rule-payload': instance.rulePayload,
      'chains': instance.chains,
    };

_MitmExchange _$MitmExchangeFromJson(
  Map<String, dynamic> json,
) => _MitmExchange(
  id: (json['id'] as num).toInt(),
  start: DateTime.parse(json['start'] as String),
  pending: json['pending'] as bool? ?? false,
  duration: (json['duration'] as num?)?.toInt() ?? 0,
  ttfb: (json['ttfb'] as num?)?.toInt() ?? 0,
  method: json['method'] as String? ?? '',
  url: json['url'] as String? ?? '',
  originalUrl: json['original-url'] as String? ?? '',
  proto: json['proto'] as String? ?? '',
  status: (json['status'] as num?)?.toInt() ?? 0,
  reason: json['reason'] as String? ?? '',
  requestSize: (json['request-size'] as num?)?.toInt() ?? 0,
  responseSize: (json['response-size'] as num?)?.toInt() ?? 0,
  error: json['error'] as String? ?? '',
  connection: json['connection'] as String? ?? '',
  requestHeader:
      (json['request-header'] as Map<String, dynamic>?)?.map(
        (k, e) =>
            MapEntry(k, (e as List<dynamic>).map((e) => e as String).toList()),
      ) ??
      const {},
  responseHeader:
      (json['response-header'] as Map<String, dynamic>?)?.map(
        (k, e) =>
            MapEntry(k, (e as List<dynamic>).map((e) => e as String).toList()),
      ) ??
      const {},
  actions:
      (json['actions'] as List<dynamic>?)
          ?.map((e) => MitmAction.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  route: json['route'] == null
      ? null
      : MitmRoute.fromJson(json['route'] as Map<String, dynamic>),
);

Map<String, dynamic> _$MitmExchangeToJson(_MitmExchange instance) =>
    <String, dynamic>{
      'id': instance.id,
      'start': instance.start.toIso8601String(),
      'pending': instance.pending,
      'duration': instance.duration,
      'ttfb': instance.ttfb,
      'method': instance.method,
      'url': instance.url,
      'original-url': instance.originalUrl,
      'proto': instance.proto,
      'status': instance.status,
      'reason': instance.reason,
      'request-size': instance.requestSize,
      'response-size': instance.responseSize,
      'error': instance.error,
      'connection': instance.connection,
      'request-header': instance.requestHeader,
      'response-header': instance.responseHeader,
      'actions': instance.actions,
      'route': instance.route,
    };

_MitmBody _$MitmBodyFromJson(Map<String, dynamic> json) => _MitmBody(
  data: json['data'] as String? ?? '',
  truncated: json['truncated'] as bool? ?? false,
  encoding: json['encoding'] as String? ?? '',
);

Map<String, dynamic> _$MitmBodyToJson(_MitmBody instance) => <String, dynamic>{
  'data': instance.data,
  'truncated': instance.truncated,
  'encoding': instance.encoding,
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
  routeExcludeAddress:
      (json['routeExcludeAddress'] as List<dynamic>?)
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
      'routeExcludeAddress': instance.routeExcludeAddress,
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
      running: json['running'] as bool? ?? false,
    );

Map<String, dynamic> _$RouteSnapshotToJson(_RouteSnapshot instance) =>
    <String, dynamic>{
      'core-epoch': instance.coreEpoch,
      'route-version': instance.routeVersion,
      'running': instance.running,
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

_TestDelayParams _$TestDelayParamsFromJson(Map<String, dynamic> json) =>
    _TestDelayParams(
      proxyName: json['proxy-name'] as String,
      testUrl: json['test-url'] as String,
      timeout: (json['timeout'] as num).toInt(),
    );

Map<String, dynamic> _$TestDelayParamsToJson(_TestDelayParams instance) =>
    <String, dynamic>{
      'proxy-name': instance.proxyName,
      'test-url': instance.testUrl,
      'timeout': instance.timeout,
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
      ip: json['ip'] as String? ?? '',
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
      'ip': instance.ip,
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
      heapInuse: (json['heap-inuse'] as num?)?.toInt() ?? 0,
      heapIdle: (json['heap-idle'] as num?)?.toInt() ?? 0,
      stackInuse: (json['stack-inuse'] as num?)?.toInt() ?? 0,
      runtimeOther: (json['runtime-other'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$CoreMemoryStatsToJson(_CoreMemoryStats instance) =>
    <String, dynamic>{
      'rss': instance.rss,
      'heap-inuse': instance.heapInuse,
      'heap-idle': instance.heapIdle,
      'stack-inuse': instance.stackInuse,
      'runtime-other': instance.runtimeOther,
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
  CoreMethod.coreInit: 'coreInit',
  CoreMethod.coreInitialized: 'coreInitialized',
  CoreMethod.coreGc: 'coreGc',
  CoreMethod.coreMemory: 'coreMemory',
  CoreMethod.coreCrash: 'coreCrash',
  CoreMethod.configSetup: 'configSetup',
  CoreMethod.configUpdate: 'configUpdate',
  CoreMethod.configValidate: 'configValidate',
  CoreMethod.configDecrypt: 'configDecrypt',
  CoreMethod.configRead: 'configRead',
  CoreMethod.profileBase: 'profileBase',
  CoreMethod.profileOutbounds: 'profileOutbounds',
  CoreMethod.profileBuild: 'profileBuild',
  CoreMethod.profileClearEffect: 'profileClearEffect',
  CoreMethod.proxyList: 'proxyList',
  CoreMethod.proxySelect: 'proxySelect',
  CoreMethod.proxyDefinition: 'proxyDefinition',
  CoreMethod.proxyTestDelay: 'proxyTestDelay',
  CoreMethod.proxyValidate: 'proxyValidate',
  CoreMethod.proxyConvert: 'proxyConvert',
  CoreMethod.shareLinkEncode: 'shareLinkEncode',
  CoreMethod.shareLinkDecode: 'shareLinkDecode',
  CoreMethod.filterValidate: 'filterValidate',
  CoreMethod.providerList: 'providerList',
  CoreMethod.providerGet: 'providerGet',
  CoreMethod.providerUpdate: 'providerUpdate',
  CoreMethod.providerSideLoad: 'providerSideLoad',
  CoreMethod.ruleList: 'ruleList',
  CoreMethod.ruleSetDump: 'ruleSetDump',
  CoreMethod.ruleSetCompile: 'ruleSetCompile',
  CoreMethod.geoUpdate: 'geoUpdate',
  CoreMethod.trafficCurrent: 'trafficCurrent',
  CoreMethod.trafficTotal: 'trafficTotal',
  CoreMethod.trafficReset: 'trafficReset',
  CoreMethod.connectionList: 'connectionList',
  CoreMethod.connectionCount: 'connectionCount',
  CoreMethod.connectionClose: 'connectionClose',
  CoreMethod.connectionCloseAll: 'connectionCloseAll',
  CoreMethod.connectionReset: 'connectionReset',
  CoreMethod.dnsClearCache: 'dnsClearCache',
  CoreMethod.networkChanged: 'networkChanged',
  CoreMethod.logStart: 'logStart',
  CoreMethod.logStop: 'logStop',
  CoreMethod.listenerStart: 'listenerStart',
  CoreMethod.listenerStop: 'listenerStop',
  CoreMethod.routeWatch: 'routeWatch',
  CoreMethod.routeCheck: 'routeCheck',
  CoreMethod.probeOutboundIp: 'probeOutboundIp',
  CoreMethod.probeServices: 'probeServices',
  CoreMethod.probeSpeedTest: 'probeSpeedTest',
  CoreMethod.probeQuicTest: 'probeQuicTest',
  CoreMethod.mitmCertificate: 'mitmCertificate',
  CoreMethod.mitmGenerateCertificate: 'mitmGenerateCertificate',
  CoreMethod.mitmValidate: 'mitmValidate',
  CoreMethod.mitmIssueCertificate: 'mitmIssueCertificate',
  CoreMethod.mitmRunScript: 'mitmRunScript',
  CoreMethod.mitmExchanges: 'mitmExchanges',
  CoreMethod.mitmQuery: 'mitmQuery',
  CoreMethod.mitmExchange: 'mitmExchange',
  CoreMethod.mitmBody: 'mitmBody',
  CoreMethod.message: 'message',
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
