import 'package:freezed_annotation/freezed_annotation.dart';

part 'generated/local_proxy_provider_config.freezed.dart';
part 'generated/local_proxy_provider_config.g.dart';

@freezed
abstract class LocalProxyProviderConfig with _$LocalProxyProviderConfig {
  const factory LocalProxyProviderConfig({
    @Default(false) bool enabled,
    @Default('FlClash Local') String providerName,
    @Default('_flclash_local') String providerKey,
    @Default('./proxy_providers/flclash-local.yaml') String providerPath,
    @Default([]) List<String> targetGroups,
    @Default(true) bool healthCheckEnabled,
    @Default('https://www.gstatic.com/generate_204') String healthCheckUrl,
    @Default(300) int healthCheckInterval,
    @Default(5000) int healthCheckTimeout,
  }) = _LocalProxyProviderConfig;

  factory LocalProxyProviderConfig.fromJson(Map<String, Object?> json) =>
      _$LocalProxyProviderConfigFromJson(json);
}
