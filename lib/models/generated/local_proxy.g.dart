// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../local_proxy.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LocalProxy _$LocalProxyFromJson(Map<String, dynamic> json) => _LocalProxy(
  id: Snowflake.buildId((json['id'] as num?)?.toInt()),
  name: json['name'] as String,
  type: json['type'] as String,
  enabled: json['enabled'] as bool? ?? true,
  config: json['config'] as Map<String, dynamic>? ?? const {},
  tags:
      (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  sortIndex: (json['sortIndex'] as num?)?.toInt(),
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$LocalProxyToJson(_LocalProxy instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'type': instance.type,
      'enabled': instance.enabled,
      'config': instance.config,
      'tags': instance.tags,
      'sortIndex': instance.sortIndex,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
