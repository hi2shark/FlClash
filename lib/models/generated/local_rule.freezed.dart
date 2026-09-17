// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../local_rule.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LocalRule {

@JsonKey(fromJson: Snowflake.buildId) int get id; bool get enabled; RuleAction get ruleAction; String? get content; String? get ruleTarget; bool get noResolve; bool get src; int? get sortIndex;
/// Create a copy of LocalRule
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LocalRuleCopyWith<LocalRule> get copyWith => _$LocalRuleCopyWithImpl<LocalRule>(this as LocalRule, _$identity);

  /// Serializes this LocalRule to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LocalRule&&(identical(other.id, id) || other.id == id)&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.ruleAction, ruleAction) || other.ruleAction == ruleAction)&&(identical(other.content, content) || other.content == content)&&(identical(other.ruleTarget, ruleTarget) || other.ruleTarget == ruleTarget)&&(identical(other.noResolve, noResolve) || other.noResolve == noResolve)&&(identical(other.src, src) || other.src == src)&&(identical(other.sortIndex, sortIndex) || other.sortIndex == sortIndex));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,enabled,ruleAction,content,ruleTarget,noResolve,src,sortIndex);

@override
String toString() {
  return 'LocalRule(id: $id, enabled: $enabled, ruleAction: $ruleAction, content: $content, ruleTarget: $ruleTarget, noResolve: $noResolve, src: $src, sortIndex: $sortIndex)';
}


}

/// @nodoc
abstract mixin class $LocalRuleCopyWith<$Res>  {
  factory $LocalRuleCopyWith(LocalRule value, $Res Function(LocalRule) _then) = _$LocalRuleCopyWithImpl;
@useResult
$Res call({
@JsonKey(fromJson: Snowflake.buildId) int id, bool enabled, RuleAction ruleAction, String? content, String? ruleTarget, bool noResolve, bool src, int? sortIndex
});




}
/// @nodoc
class _$LocalRuleCopyWithImpl<$Res>
    implements $LocalRuleCopyWith<$Res> {
  _$LocalRuleCopyWithImpl(this._self, this._then);

  final LocalRule _self;
  final $Res Function(LocalRule) _then;

/// Create a copy of LocalRule
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? enabled = null,Object? ruleAction = null,Object? content = freezed,Object? ruleTarget = freezed,Object? noResolve = null,Object? src = null,Object? sortIndex = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,ruleAction: null == ruleAction ? _self.ruleAction : ruleAction // ignore: cast_nullable_to_non_nullable
as RuleAction,content: freezed == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String?,ruleTarget: freezed == ruleTarget ? _self.ruleTarget : ruleTarget // ignore: cast_nullable_to_non_nullable
as String?,noResolve: null == noResolve ? _self.noResolve : noResolve // ignore: cast_nullable_to_non_nullable
as bool,src: null == src ? _self.src : src // ignore: cast_nullable_to_non_nullable
as bool,sortIndex: freezed == sortIndex ? _self.sortIndex : sortIndex // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [LocalRule].
extension LocalRulePatterns on LocalRule {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LocalRule value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LocalRule() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LocalRule value)  $default,){
final _that = this;
switch (_that) {
case _LocalRule():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LocalRule value)?  $default,){
final _that = this;
switch (_that) {
case _LocalRule() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(fromJson: Snowflake.buildId)  int id,  bool enabled,  RuleAction ruleAction,  String? content,  String? ruleTarget,  bool noResolve,  bool src,  int? sortIndex)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LocalRule() when $default != null:
return $default(_that.id,_that.enabled,_that.ruleAction,_that.content,_that.ruleTarget,_that.noResolve,_that.src,_that.sortIndex);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(fromJson: Snowflake.buildId)  int id,  bool enabled,  RuleAction ruleAction,  String? content,  String? ruleTarget,  bool noResolve,  bool src,  int? sortIndex)  $default,) {final _that = this;
switch (_that) {
case _LocalRule():
return $default(_that.id,_that.enabled,_that.ruleAction,_that.content,_that.ruleTarget,_that.noResolve,_that.src,_that.sortIndex);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(fromJson: Snowflake.buildId)  int id,  bool enabled,  RuleAction ruleAction,  String? content,  String? ruleTarget,  bool noResolve,  bool src,  int? sortIndex)?  $default,) {final _that = this;
switch (_that) {
case _LocalRule() when $default != null:
return $default(_that.id,_that.enabled,_that.ruleAction,_that.content,_that.ruleTarget,_that.noResolve,_that.src,_that.sortIndex);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LocalRule implements LocalRule {
  const _LocalRule({@JsonKey(fromJson: Snowflake.buildId) required this.id, this.enabled = true, this.ruleAction = RuleAction.DOMAIN, this.content, this.ruleTarget, this.noResolve = false, this.src = false, this.sortIndex});
  factory _LocalRule.fromJson(Map<String, dynamic> json) => _$LocalRuleFromJson(json);

@override@JsonKey(fromJson: Snowflake.buildId) final  int id;
@override@JsonKey() final  bool enabled;
@override@JsonKey() final  RuleAction ruleAction;
@override final  String? content;
@override final  String? ruleTarget;
@override@JsonKey() final  bool noResolve;
@override@JsonKey() final  bool src;
@override final  int? sortIndex;

/// Create a copy of LocalRule
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LocalRuleCopyWith<_LocalRule> get copyWith => __$LocalRuleCopyWithImpl<_LocalRule>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LocalRuleToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LocalRule&&(identical(other.id, id) || other.id == id)&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.ruleAction, ruleAction) || other.ruleAction == ruleAction)&&(identical(other.content, content) || other.content == content)&&(identical(other.ruleTarget, ruleTarget) || other.ruleTarget == ruleTarget)&&(identical(other.noResolve, noResolve) || other.noResolve == noResolve)&&(identical(other.src, src) || other.src == src)&&(identical(other.sortIndex, sortIndex) || other.sortIndex == sortIndex));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,enabled,ruleAction,content,ruleTarget,noResolve,src,sortIndex);

@override
String toString() {
  return 'LocalRule(id: $id, enabled: $enabled, ruleAction: $ruleAction, content: $content, ruleTarget: $ruleTarget, noResolve: $noResolve, src: $src, sortIndex: $sortIndex)';
}


}

/// @nodoc
abstract mixin class _$LocalRuleCopyWith<$Res> implements $LocalRuleCopyWith<$Res> {
  factory _$LocalRuleCopyWith(_LocalRule value, $Res Function(_LocalRule) _then) = __$LocalRuleCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(fromJson: Snowflake.buildId) int id, bool enabled, RuleAction ruleAction, String? content, String? ruleTarget, bool noResolve, bool src, int? sortIndex
});




}
/// @nodoc
class __$LocalRuleCopyWithImpl<$Res>
    implements _$LocalRuleCopyWith<$Res> {
  __$LocalRuleCopyWithImpl(this._self, this._then);

  final _LocalRule _self;
  final $Res Function(_LocalRule) _then;

/// Create a copy of LocalRule
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? enabled = null,Object? ruleAction = null,Object? content = freezed,Object? ruleTarget = freezed,Object? noResolve = null,Object? src = null,Object? sortIndex = freezed,}) {
  return _then(_LocalRule(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,ruleAction: null == ruleAction ? _self.ruleAction : ruleAction // ignore: cast_nullable_to_non_nullable
as RuleAction,content: freezed == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String?,ruleTarget: freezed == ruleTarget ? _self.ruleTarget : ruleTarget // ignore: cast_nullable_to_non_nullable
as String?,noResolve: null == noResolve ? _self.noResolve : noResolve // ignore: cast_nullable_to_non_nullable
as bool,src: null == src ? _self.src : src // ignore: cast_nullable_to_non_nullable
as bool,sortIndex: freezed == sortIndex ? _self.sortIndex : sortIndex // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
