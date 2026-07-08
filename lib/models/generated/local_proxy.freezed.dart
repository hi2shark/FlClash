// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../local_proxy.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LocalProxy {

@JsonKey(fromJson: Snowflake.buildId) int get id; String get name; String get type; bool get enabled; Map<String, dynamic> get config; List<String> get tags; int? get sortIndex; DateTime get createdAt; DateTime get updatedAt;
/// Create a copy of LocalProxy
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LocalProxyCopyWith<LocalProxy> get copyWith => _$LocalProxyCopyWithImpl<LocalProxy>(this as LocalProxy, _$identity);

  /// Serializes this LocalProxy to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LocalProxy&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.enabled, enabled) || other.enabled == enabled)&&const DeepCollectionEquality().equals(other.config, config)&&const DeepCollectionEquality().equals(other.tags, tags)&&(identical(other.sortIndex, sortIndex) || other.sortIndex == sortIndex)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,type,enabled,const DeepCollectionEquality().hash(config),const DeepCollectionEquality().hash(tags),sortIndex,createdAt,updatedAt);

@override
String toString() {
  return 'LocalProxy(id: $id, name: $name, type: $type, enabled: $enabled, config: $config, tags: $tags, sortIndex: $sortIndex, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $LocalProxyCopyWith<$Res>  {
  factory $LocalProxyCopyWith(LocalProxy value, $Res Function(LocalProxy) _then) = _$LocalProxyCopyWithImpl;
@useResult
$Res call({
@JsonKey(fromJson: Snowflake.buildId) int id, String name, String type, bool enabled, Map<String, dynamic> config, List<String> tags, int? sortIndex, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class _$LocalProxyCopyWithImpl<$Res>
    implements $LocalProxyCopyWith<$Res> {
  _$LocalProxyCopyWithImpl(this._self, this._then);

  final LocalProxy _self;
  final $Res Function(LocalProxy) _then;

/// Create a copy of LocalProxy
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? type = null,Object? enabled = null,Object? config = null,Object? tags = null,Object? sortIndex = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,config: null == config ? _self.config : config // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,sortIndex: freezed == sortIndex ? _self.sortIndex : sortIndex // ignore: cast_nullable_to_non_nullable
as int?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [LocalProxy].
extension LocalProxyPatterns on LocalProxy {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LocalProxy value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LocalProxy() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LocalProxy value)  $default,){
final _that = this;
switch (_that) {
case _LocalProxy():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LocalProxy value)?  $default,){
final _that = this;
switch (_that) {
case _LocalProxy() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(fromJson: Snowflake.buildId)  int id,  String name,  String type,  bool enabled,  Map<String, dynamic> config,  List<String> tags,  int? sortIndex,  DateTime createdAt,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LocalProxy() when $default != null:
return $default(_that.id,_that.name,_that.type,_that.enabled,_that.config,_that.tags,_that.sortIndex,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(fromJson: Snowflake.buildId)  int id,  String name,  String type,  bool enabled,  Map<String, dynamic> config,  List<String> tags,  int? sortIndex,  DateTime createdAt,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _LocalProxy():
return $default(_that.id,_that.name,_that.type,_that.enabled,_that.config,_that.tags,_that.sortIndex,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(fromJson: Snowflake.buildId)  int id,  String name,  String type,  bool enabled,  Map<String, dynamic> config,  List<String> tags,  int? sortIndex,  DateTime createdAt,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _LocalProxy() when $default != null:
return $default(_that.id,_that.name,_that.type,_that.enabled,_that.config,_that.tags,_that.sortIndex,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LocalProxy implements LocalProxy {
  const _LocalProxy({@JsonKey(fromJson: Snowflake.buildId) required this.id, required this.name, required this.type, this.enabled = true, final  Map<String, dynamic> config = const {}, final  List<String> tags = const [], this.sortIndex, required this.createdAt, required this.updatedAt}): _config = config,_tags = tags;
  factory _LocalProxy.fromJson(Map<String, dynamic> json) => _$LocalProxyFromJson(json);

@override@JsonKey(fromJson: Snowflake.buildId) final  int id;
@override final  String name;
@override final  String type;
@override@JsonKey() final  bool enabled;
 final  Map<String, dynamic> _config;
@override@JsonKey() Map<String, dynamic> get config {
  if (_config is EqualUnmodifiableMapView) return _config;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_config);
}

 final  List<String> _tags;
@override@JsonKey() List<String> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}

@override final  int? sortIndex;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;

/// Create a copy of LocalProxy
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LocalProxyCopyWith<_LocalProxy> get copyWith => __$LocalProxyCopyWithImpl<_LocalProxy>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LocalProxyToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LocalProxy&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.enabled, enabled) || other.enabled == enabled)&&const DeepCollectionEquality().equals(other._config, _config)&&const DeepCollectionEquality().equals(other._tags, _tags)&&(identical(other.sortIndex, sortIndex) || other.sortIndex == sortIndex)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,type,enabled,const DeepCollectionEquality().hash(_config),const DeepCollectionEquality().hash(_tags),sortIndex,createdAt,updatedAt);

@override
String toString() {
  return 'LocalProxy(id: $id, name: $name, type: $type, enabled: $enabled, config: $config, tags: $tags, sortIndex: $sortIndex, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$LocalProxyCopyWith<$Res> implements $LocalProxyCopyWith<$Res> {
  factory _$LocalProxyCopyWith(_LocalProxy value, $Res Function(_LocalProxy) _then) = __$LocalProxyCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(fromJson: Snowflake.buildId) int id, String name, String type, bool enabled, Map<String, dynamic> config, List<String> tags, int? sortIndex, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class __$LocalProxyCopyWithImpl<$Res>
    implements _$LocalProxyCopyWith<$Res> {
  __$LocalProxyCopyWithImpl(this._self, this._then);

  final _LocalProxy _self;
  final $Res Function(_LocalProxy) _then;

/// Create a copy of LocalProxy
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? type = null,Object? enabled = null,Object? config = null,Object? tags = null,Object? sortIndex = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_LocalProxy(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,config: null == config ? _self._config : config // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,sortIndex: freezed == sortIndex ? _self.sortIndex : sortIndex // ignore: cast_nullable_to_non_nullable
as int?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
