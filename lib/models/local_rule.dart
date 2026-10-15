import 'package:fl_clash/common/snowflake.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'generated/local_rule.freezed.dart';
part 'generated/local_rule.g.dart';

@freezed
abstract class LocalRule with _$LocalRule {
  const factory LocalRule({
    @JsonKey(fromJson: Snowflake.buildId) required int id,
    @Default(true) bool enabled,
    @Default(RuleAction.DOMAIN) RuleAction ruleAction,
    String? content,
    String? ruleTarget,
    @Default(false) bool noResolve,
    @Default(false) bool src,
    int? sortIndex,
  }) = _LocalRule;

  factory LocalRule.fromJson(Map<String, Object?> json) =>
      _$LocalRuleFromJson(json);
}

extension LocalRuleExt on LocalRule {
  String get rawValue {
    return [
      ruleAction.value,
      content,
      ruleTarget,
      if (ruleAction.hasParams) ...[
        if (src) 'src',
        if (noResolve) 'no-resolve',
      ],
    ].join(',');
  }

  bool get hasContent => (content ?? '').trim().isNotEmpty;

  bool get hasTarget => (ruleTarget ?? '').trim().isNotEmpty;
}
