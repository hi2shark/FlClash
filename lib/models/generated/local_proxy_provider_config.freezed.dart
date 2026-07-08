// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../local_proxy_provider_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LocalProxyProviderConfig {

 bool get enabled; String get providerName; String get providerKey; String get providerPath; List<String> get targetGroups; bool get healthCheckEnabled; String get healthCheckUrl; int get healthCheckInterval; int get healthCheckTimeout;
/// Create a copy of LocalProxyProviderConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LocalProxyProviderConfigCopyWith<LocalProxyProviderConfig> get copyWith => _$LocalProxyProviderConfigCopyWithImpl<LocalProxyProviderConfig>(this as LocalProxyProviderConfig, _$identity);

  /// Serializes this LocalProxyProviderConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LocalProxyProviderConfig&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.providerName, providerName) || other.providerName == providerName)&&(identical(other.providerKey, providerKey) || other.providerKey == providerKey)&&(identical(other.providerPath, providerPath) || other.providerPath == providerPath)&&const DeepCollectionEquality().equals(other.targetGroups, targetGroups)&&(identical(other.healthCheckEnabled, healthCheckEnabled) || other.healthCheckEnabled == healthCheckEnabled)&&(identical(other.healthCheckUrl, healthCheckUrl) || other.healthCheckUrl == healthCheckUrl)&&(identical(other.healthCheckInterval, healthCheckInterval) || other.healthCheckInterval == healthCheckInterval)&&(identical(other.healthCheckTimeout, healthCheckTimeout) || other.healthCheckTimeout == healthCheckTimeout));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,enabled,providerName,providerKey,providerPath,const DeepCollectionEquality().hash(targetGroups),healthCheckEnabled,healthCheckUrl,healthCheckInterval,healthCheckTimeout);

@override
String toString() {
  return 'LocalProxyProviderConfig(enabled: $enabled, providerName: $providerName, providerKey: $providerKey, providerPath: $providerPath, targetGroups: $targetGroups, healthCheckEnabled: $healthCheckEnabled, healthCheckUrl: $healthCheckUrl, healthCheckInterval: $healthCheckInterval, healthCheckTimeout: $healthCheckTimeout)';
}


}

/// @nodoc
abstract mixin class $LocalProxyProviderConfigCopyWith<$Res>  {
  factory $LocalProxyProviderConfigCopyWith(LocalProxyProviderConfig value, $Res Function(LocalProxyProviderConfig) _then) = _$LocalProxyProviderConfigCopyWithImpl;
@useResult
$Res call({
 bool enabled, String providerName, String providerKey, String providerPath, List<String> targetGroups, bool healthCheckEnabled, String healthCheckUrl, int healthCheckInterval, int healthCheckTimeout
});




}
/// @nodoc
class _$LocalProxyProviderConfigCopyWithImpl<$Res>
    implements $LocalProxyProviderConfigCopyWith<$Res> {
  _$LocalProxyProviderConfigCopyWithImpl(this._self, this._then);

  final LocalProxyProviderConfig _self;
  final $Res Function(LocalProxyProviderConfig) _then;

/// Create a copy of LocalProxyProviderConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? enabled = null,Object? providerName = null,Object? providerKey = null,Object? providerPath = null,Object? targetGroups = null,Object? healthCheckEnabled = null,Object? healthCheckUrl = null,Object? healthCheckInterval = null,Object? healthCheckTimeout = null,}) {
  return _then(_self.copyWith(
enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,providerName: null == providerName ? _self.providerName : providerName // ignore: cast_nullable_to_non_nullable
as String,providerKey: null == providerKey ? _self.providerKey : providerKey // ignore: cast_nullable_to_non_nullable
as String,providerPath: null == providerPath ? _self.providerPath : providerPath // ignore: cast_nullable_to_non_nullable
as String,targetGroups: null == targetGroups ? _self.targetGroups : targetGroups // ignore: cast_nullable_to_non_nullable
as List<String>,healthCheckEnabled: null == healthCheckEnabled ? _self.healthCheckEnabled : healthCheckEnabled // ignore: cast_nullable_to_non_nullable
as bool,healthCheckUrl: null == healthCheckUrl ? _self.healthCheckUrl : healthCheckUrl // ignore: cast_nullable_to_non_nullable
as String,healthCheckInterval: null == healthCheckInterval ? _self.healthCheckInterval : healthCheckInterval // ignore: cast_nullable_to_non_nullable
as int,healthCheckTimeout: null == healthCheckTimeout ? _self.healthCheckTimeout : healthCheckTimeout // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [LocalProxyProviderConfig].
extension LocalProxyProviderConfigPatterns on LocalProxyProviderConfig {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LocalProxyProviderConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LocalProxyProviderConfig() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LocalProxyProviderConfig value)  $default,){
final _that = this;
switch (_that) {
case _LocalProxyProviderConfig():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LocalProxyProviderConfig value)?  $default,){
final _that = this;
switch (_that) {
case _LocalProxyProviderConfig() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool enabled,  String providerName,  String providerKey,  String providerPath,  List<String> targetGroups,  bool healthCheckEnabled,  String healthCheckUrl,  int healthCheckInterval,  int healthCheckTimeout)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LocalProxyProviderConfig() when $default != null:
return $default(_that.enabled,_that.providerName,_that.providerKey,_that.providerPath,_that.targetGroups,_that.healthCheckEnabled,_that.healthCheckUrl,_that.healthCheckInterval,_that.healthCheckTimeout);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool enabled,  String providerName,  String providerKey,  String providerPath,  List<String> targetGroups,  bool healthCheckEnabled,  String healthCheckUrl,  int healthCheckInterval,  int healthCheckTimeout)  $default,) {final _that = this;
switch (_that) {
case _LocalProxyProviderConfig():
return $default(_that.enabled,_that.providerName,_that.providerKey,_that.providerPath,_that.targetGroups,_that.healthCheckEnabled,_that.healthCheckUrl,_that.healthCheckInterval,_that.healthCheckTimeout);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool enabled,  String providerName,  String providerKey,  String providerPath,  List<String> targetGroups,  bool healthCheckEnabled,  String healthCheckUrl,  int healthCheckInterval,  int healthCheckTimeout)?  $default,) {final _that = this;
switch (_that) {
case _LocalProxyProviderConfig() when $default != null:
return $default(_that.enabled,_that.providerName,_that.providerKey,_that.providerPath,_that.targetGroups,_that.healthCheckEnabled,_that.healthCheckUrl,_that.healthCheckInterval,_that.healthCheckTimeout);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LocalProxyProviderConfig implements LocalProxyProviderConfig {
  const _LocalProxyProviderConfig({this.enabled = false, this.providerName = 'FlClash Local', this.providerKey = '_flclash_local', this.providerPath = './proxy_providers/flclash-local.yaml', final  List<String> targetGroups = const [], this.healthCheckEnabled = true, this.healthCheckUrl = 'https://www.gstatic.com/generate_204', this.healthCheckInterval = 300, this.healthCheckTimeout = 5000}): _targetGroups = targetGroups;
  factory _LocalProxyProviderConfig.fromJson(Map<String, dynamic> json) => _$LocalProxyProviderConfigFromJson(json);

@override@JsonKey() final  bool enabled;
@override@JsonKey() final  String providerName;
@override@JsonKey() final  String providerKey;
@override@JsonKey() final  String providerPath;
 final  List<String> _targetGroups;
@override@JsonKey() List<String> get targetGroups {
  if (_targetGroups is EqualUnmodifiableListView) return _targetGroups;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_targetGroups);
}

@override@JsonKey() final  bool healthCheckEnabled;
@override@JsonKey() final  String healthCheckUrl;
@override@JsonKey() final  int healthCheckInterval;
@override@JsonKey() final  int healthCheckTimeout;

/// Create a copy of LocalProxyProviderConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LocalProxyProviderConfigCopyWith<_LocalProxyProviderConfig> get copyWith => __$LocalProxyProviderConfigCopyWithImpl<_LocalProxyProviderConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LocalProxyProviderConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LocalProxyProviderConfig&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.providerName, providerName) || other.providerName == providerName)&&(identical(other.providerKey, providerKey) || other.providerKey == providerKey)&&(identical(other.providerPath, providerPath) || other.providerPath == providerPath)&&const DeepCollectionEquality().equals(other._targetGroups, _targetGroups)&&(identical(other.healthCheckEnabled, healthCheckEnabled) || other.healthCheckEnabled == healthCheckEnabled)&&(identical(other.healthCheckUrl, healthCheckUrl) || other.healthCheckUrl == healthCheckUrl)&&(identical(other.healthCheckInterval, healthCheckInterval) || other.healthCheckInterval == healthCheckInterval)&&(identical(other.healthCheckTimeout, healthCheckTimeout) || other.healthCheckTimeout == healthCheckTimeout));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,enabled,providerName,providerKey,providerPath,const DeepCollectionEquality().hash(_targetGroups),healthCheckEnabled,healthCheckUrl,healthCheckInterval,healthCheckTimeout);

@override
String toString() {
  return 'LocalProxyProviderConfig(enabled: $enabled, providerName: $providerName, providerKey: $providerKey, providerPath: $providerPath, targetGroups: $targetGroups, healthCheckEnabled: $healthCheckEnabled, healthCheckUrl: $healthCheckUrl, healthCheckInterval: $healthCheckInterval, healthCheckTimeout: $healthCheckTimeout)';
}


}

/// @nodoc
abstract mixin class _$LocalProxyProviderConfigCopyWith<$Res> implements $LocalProxyProviderConfigCopyWith<$Res> {
  factory _$LocalProxyProviderConfigCopyWith(_LocalProxyProviderConfig value, $Res Function(_LocalProxyProviderConfig) _then) = __$LocalProxyProviderConfigCopyWithImpl;
@override @useResult
$Res call({
 bool enabled, String providerName, String providerKey, String providerPath, List<String> targetGroups, bool healthCheckEnabled, String healthCheckUrl, int healthCheckInterval, int healthCheckTimeout
});




}
/// @nodoc
class __$LocalProxyProviderConfigCopyWithImpl<$Res>
    implements _$LocalProxyProviderConfigCopyWith<$Res> {
  __$LocalProxyProviderConfigCopyWithImpl(this._self, this._then);

  final _LocalProxyProviderConfig _self;
  final $Res Function(_LocalProxyProviderConfig) _then;

/// Create a copy of LocalProxyProviderConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? enabled = null,Object? providerName = null,Object? providerKey = null,Object? providerPath = null,Object? targetGroups = null,Object? healthCheckEnabled = null,Object? healthCheckUrl = null,Object? healthCheckInterval = null,Object? healthCheckTimeout = null,}) {
  return _then(_LocalProxyProviderConfig(
enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,providerName: null == providerName ? _self.providerName : providerName // ignore: cast_nullable_to_non_nullable
as String,providerKey: null == providerKey ? _self.providerKey : providerKey // ignore: cast_nullable_to_non_nullable
as String,providerPath: null == providerPath ? _self.providerPath : providerPath // ignore: cast_nullable_to_non_nullable
as String,targetGroups: null == targetGroups ? _self._targetGroups : targetGroups // ignore: cast_nullable_to_non_nullable
as List<String>,healthCheckEnabled: null == healthCheckEnabled ? _self.healthCheckEnabled : healthCheckEnabled // ignore: cast_nullable_to_non_nullable
as bool,healthCheckUrl: null == healthCheckUrl ? _self.healthCheckUrl : healthCheckUrl // ignore: cast_nullable_to_non_nullable
as String,healthCheckInterval: null == healthCheckInterval ? _self.healthCheckInterval : healthCheckInterval // ignore: cast_nullable_to_non_nullable
as int,healthCheckTimeout: null == healthCheckTimeout ? _self.healthCheckTimeout : healthCheckTimeout // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
