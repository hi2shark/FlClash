// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../local_proxy_provider_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LocalProxyProviderConfig _$LocalProxyProviderConfigFromJson(
  Map<String, dynamic> json,
) => _LocalProxyProviderConfig(
  enabled: json['enabled'] as bool? ?? false,
  providerName: json['providerName'] as String? ?? 'FlClash Local',
  providerKey: json['providerKey'] as String? ?? '_flclash_local',
  providerPath:
      json['providerPath'] as String? ?? './proxy_providers/flclash-local.yaml',
  targetGroups:
      (json['targetGroups'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  healthCheckEnabled: json['healthCheckEnabled'] as bool? ?? true,
  healthCheckUrl:
      json['healthCheckUrl'] as String? ??
      'https://www.gstatic.com/generate_204',
  healthCheckInterval: (json['healthCheckInterval'] as num?)?.toInt() ?? 300,
  healthCheckTimeout: (json['healthCheckTimeout'] as num?)?.toInt() ?? 5000,
);

Map<String, dynamic> _$LocalProxyProviderConfigToJson(
  _LocalProxyProviderConfig instance,
) => <String, dynamic>{
  'enabled': instance.enabled,
  'providerName': instance.providerName,
  'providerKey': instance.providerKey,
  'providerPath': instance.providerPath,
  'targetGroups': instance.targetGroups,
  'healthCheckEnabled': instance.healthCheckEnabled,
  'healthCheckUrl': instance.healthCheckUrl,
  'healthCheckInterval': instance.healthCheckInterval,
  'healthCheckTimeout': instance.healthCheckTimeout,
};
