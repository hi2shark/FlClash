import 'package:fl_clash/common/common.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'generated/local_proxy.freezed.dart';
part 'generated/local_proxy.g.dart';

@freezed
abstract class LocalProxy with _$LocalProxy {
  const factory LocalProxy({
    @JsonKey(fromJson: Snowflake.buildId) required int id,
    required String name,
    required String type,
    @Default(true) bool enabled,
    @Default({}) Map<String, dynamic> config,
    @Default([]) List<String> tags,
    int? sortIndex,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _LocalProxy;

  factory LocalProxy.fromJson(Map<String, Object?> json) =>
      _$LocalProxyFromJson(json);
}

extension LocalProxyExt on LocalProxy {
  String get displayType => type.toUpperCase();

  String get server => (config['server'] ?? '').toString();

  int? get port {
    final value = config['port'];
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  String get serverDesc => '$server:${port ?? ''}';
}
