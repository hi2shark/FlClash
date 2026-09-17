// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../local_rule_mixin_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LocalRuleMixinConfig {

 bool get enabled;
/// Create a copy of LocalRuleMixinConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LocalRuleMixinConfigCopyWith<LocalRuleMixinConfig> get copyWith => _$LocalRuleMixinConfigCopyWithImpl<LocalRuleMixinConfig>(this as LocalRuleMixinConfig, _$identity);

  /// Serializes this LocalRuleMixinConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LocalRuleMixinConfig&&(identical(other.enabled, enabled) || other.enabled == enabled));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,enabled);

@override
String toString() {
  return 'LocalRuleMixinConfig(enabled: $enabled)';
}


}

/// @nodoc
abstract mixin class $LocalRuleMixinConfigCopyWith<$Res>  {
  factory $LocalRuleMixinConfigCopyWith(LocalRuleMixinConfig value, $Res Function(LocalRuleMixinConfig) _then) = _$LocalRuleMixinConfigCopyWithImpl;
@useResult
$Res call({
 bool enabled
});




}
/// @nodoc
class _$LocalRuleMixinConfigCopyWithImpl<$Res>
    implements $LocalRuleMixinConfigCopyWith<$Res> {
  _$LocalRuleMixinConfigCopyWithImpl(this._self, this._then);

  final LocalRuleMixinConfig _self;
  final $Res Function(LocalRuleMixinConfig) _then;

/// Create a copy of LocalRuleMixinConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? enabled = null,}) {
  return _then(_self.copyWith(
enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [LocalRuleMixinConfig].
extension LocalRuleMixinConfigPatterns on LocalRuleMixinConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LocalRuleMixinConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LocalRuleMixinConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LocalRuleMixinConfig value)  $default,){
final _that = this;
switch (_that) {
case _LocalRuleMixinConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LocalRuleMixinConfig value)?  $default,){
final _that = this;
switch (_that) {
case _LocalRuleMixinConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool enabled)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LocalRuleMixinConfig() when $default != null:
return $default(_that.enabled);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool enabled)  $default,) {final _that = this;
switch (_that) {
case _LocalRuleMixinConfig():
return $default(_that.enabled);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool enabled)?  $default,) {final _that = this;
switch (_that) {
case _LocalRuleMixinConfig() when $default != null:
return $default(_that.enabled);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LocalRuleMixinConfig implements LocalRuleMixinConfig {
  const _LocalRuleMixinConfig({this.enabled = false});
  factory _LocalRuleMixinConfig.fromJson(Map<String, dynamic> json) => _$LocalRuleMixinConfigFromJson(json);

@override@JsonKey() final  bool enabled;

/// Create a copy of LocalRuleMixinConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LocalRuleMixinConfigCopyWith<_LocalRuleMixinConfig> get copyWith => __$LocalRuleMixinConfigCopyWithImpl<_LocalRuleMixinConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LocalRuleMixinConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LocalRuleMixinConfig&&(identical(other.enabled, enabled) || other.enabled == enabled));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,enabled);

@override
String toString() {
  return 'LocalRuleMixinConfig(enabled: $enabled)';
}


}

/// @nodoc
abstract mixin class _$LocalRuleMixinConfigCopyWith<$Res> implements $LocalRuleMixinConfigCopyWith<$Res> {
  factory _$LocalRuleMixinConfigCopyWith(_LocalRuleMixinConfig value, $Res Function(_LocalRuleMixinConfig) _then) = __$LocalRuleMixinConfigCopyWithImpl;
@override @useResult
$Res call({
 bool enabled
});




}
/// @nodoc
class __$LocalRuleMixinConfigCopyWithImpl<$Res>
    implements _$LocalRuleMixinConfigCopyWith<$Res> {
  __$LocalRuleMixinConfigCopyWithImpl(this._self, this._then);

  final _LocalRuleMixinConfig _self;
  final $Res Function(_LocalRuleMixinConfig) _then;

/// Create a copy of LocalRuleMixinConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? enabled = null,}) {
  return _then(_LocalRuleMixinConfig(
enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
