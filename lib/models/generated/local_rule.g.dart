// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../local_rule.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LocalRule _$LocalRuleFromJson(Map<String, dynamic> json) => _LocalRule(
  id: Snowflake.buildId((json['id'] as num?)?.toInt()),
  enabled: json['enabled'] as bool? ?? true,
  ruleAction:
      $enumDecodeNullable(_$RuleActionEnumMap, json['ruleAction']) ??
      RuleAction.DOMAIN,
  content: json['content'] as String?,
  ruleTarget: json['ruleTarget'] as String?,
  noResolve: json['noResolve'] as bool? ?? false,
  src: json['src'] as bool? ?? false,
  sortIndex: (json['sortIndex'] as num?)?.toInt(),
);

Map<String, dynamic> _$LocalRuleToJson(_LocalRule instance) =>
    <String, dynamic>{
      'id': instance.id,
      'enabled': instance.enabled,
      'ruleAction': _$RuleActionEnumMap[instance.ruleAction]!,
      'content': instance.content,
      'ruleTarget': instance.ruleTarget,
      'noResolve': instance.noResolve,
      'src': instance.src,
      'sortIndex': instance.sortIndex,
    };

const _$RuleActionEnumMap = {
  RuleAction.DOMAIN: 'DOMAIN',
  RuleAction.DOMAIN_SUFFIX: 'DOMAIN_SUFFIX',
  RuleAction.DOMAIN_KEYWORD: 'DOMAIN_KEYWORD',
  RuleAction.DOMAIN_REGEX: 'DOMAIN_REGEX',
  RuleAction.DOMAIN_WILDCARD: 'DOMAIN_WILDCARD',
  RuleAction.GEOSITE: 'GEOSITE',
  RuleAction.IP_CIDR: 'IP_CIDR',
  RuleAction.IP_CIDR6: 'IP_CIDR6',
  RuleAction.IP_SUFFIX: 'IP_SUFFIX',
  RuleAction.IP_ASN: 'IP_ASN',
  RuleAction.GEOIP: 'GEOIP',
  RuleAction.SRC_GEOIP: 'SRC_GEOIP',
  RuleAction.SRC_IP_ASN: 'SRC_IP_ASN',
  RuleAction.SRC_IP_CIDR: 'SRC_IP_CIDR',
  RuleAction.SRC_IP_SUFFIX: 'SRC_IP_SUFFIX',
  RuleAction.DST_PORT: 'DST_PORT',
  RuleAction.SRC_PORT: 'SRC_PORT',
  RuleAction.IN_PORT: 'IN_PORT',
  RuleAction.IN_TYPE: 'IN_TYPE',
  RuleAction.IN_USER: 'IN_USER',
  RuleAction.IN_NAME: 'IN_NAME',
  RuleAction.REMATCH_NAME: 'REMATCH_NAME',
  RuleAction.PROCESS_PATH: 'PROCESS_PATH',
  RuleAction.PROCESS_PATH_REGEX: 'PROCESS_PATH_REGEX',
  RuleAction.PROCESS_PATH_WILDCARD: 'PROCESS_PATH_WILDCARD',
  RuleAction.PROCESS_NAME: 'PROCESS_NAME',
  RuleAction.PROCESS_NAME_REGEX: 'PROCESS_NAME_REGEX',
  RuleAction.PROCESS_NAME_WILDCARD: 'PROCESS_NAME_WILDCARD',
  RuleAction.UID: 'UID',
  RuleAction.NETWORK: 'NETWORK',
  RuleAction.DSCP: 'DSCP',
  RuleAction.RULE_SET: 'RULE_SET',
  RuleAction.AND: 'AND',
  RuleAction.OR: 'OR',
  RuleAction.NOT: 'NOT',
  RuleAction.SUB_RULE: 'SUB_RULE',
  RuleAction.MATCH: 'MATCH',
};
