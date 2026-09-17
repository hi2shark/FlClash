import 'package:freezed_annotation/freezed_annotation.dart';

part 'generated/local_rule_mixin_config.freezed.dart';
part 'generated/local_rule_mixin_config.g.dart';

@freezed
abstract class LocalRuleMixinConfig with _$LocalRuleMixinConfig {
  const factory LocalRuleMixinConfig({
    @Default(false) bool enabled,
  }) = _LocalRuleMixinConfig;

  factory LocalRuleMixinConfig.fromJson(Map<String, Object?> json) =>
      _$LocalRuleMixinConfigFromJson(json);
}
