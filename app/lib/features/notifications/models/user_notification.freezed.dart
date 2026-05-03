// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_notification.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UserNotification {

 int get id; String get type; String get title; String get body;@JsonKey(name: 'action_data') Map<String, dynamic>? get actionData; String get status;
/// Create a copy of UserNotification
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserNotificationCopyWith<UserNotification> get copyWith => _$UserNotificationCopyWithImpl<UserNotification>(this as UserNotification, _$identity);

  /// Serializes this UserNotification to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserNotification&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.title, title) || other.title == title)&&(identical(other.body, body) || other.body == body)&&const DeepCollectionEquality().equals(other.actionData, actionData)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,type,title,body,const DeepCollectionEquality().hash(actionData),status);

@override
String toString() {
  return 'UserNotification(id: $id, type: $type, title: $title, body: $body, actionData: $actionData, status: $status)';
}


}

/// @nodoc
abstract mixin class $UserNotificationCopyWith<$Res>  {
  factory $UserNotificationCopyWith(UserNotification value, $Res Function(UserNotification) _then) = _$UserNotificationCopyWithImpl;
@useResult
$Res call({
 int id, String type, String title, String body,@JsonKey(name: 'action_data') Map<String, dynamic>? actionData, String status
});




}
/// @nodoc
class _$UserNotificationCopyWithImpl<$Res>
    implements $UserNotificationCopyWith<$Res> {
  _$UserNotificationCopyWithImpl(this._self, this._then);

  final UserNotification _self;
  final $Res Function(UserNotification) _then;

/// Create a copy of UserNotification
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? type = null,Object? title = null,Object? body = null,Object? actionData = freezed,Object? status = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,actionData: freezed == actionData ? _self.actionData : actionData // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [UserNotification].
extension UserNotificationPatterns on UserNotification {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserNotification value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserNotification() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserNotification value)  $default,){
final _that = this;
switch (_that) {
case _UserNotification():
return $default(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserNotification value)?  $default,){
final _that = this;
switch (_that) {
case _UserNotification() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String type,  String title,  String body, @JsonKey(name: 'action_data')  Map<String, dynamic>? actionData,  String status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserNotification() when $default != null:
return $default(_that.id,_that.type,_that.title,_that.body,_that.actionData,_that.status);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String type,  String title,  String body, @JsonKey(name: 'action_data')  Map<String, dynamic>? actionData,  String status)  $default,) {final _that = this;
switch (_that) {
case _UserNotification():
return $default(_that.id,_that.type,_that.title,_that.body,_that.actionData,_that.status);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String type,  String title,  String body, @JsonKey(name: 'action_data')  Map<String, dynamic>? actionData,  String status)?  $default,) {final _that = this;
switch (_that) {
case _UserNotification() when $default != null:
return $default(_that.id,_that.type,_that.title,_that.body,_that.actionData,_that.status);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UserNotification implements UserNotification {
  const _UserNotification({required this.id, required this.type, required this.title, required this.body, @JsonKey(name: 'action_data') final  Map<String, dynamic>? actionData, required this.status}): _actionData = actionData;
  factory _UserNotification.fromJson(Map<String, dynamic> json) => _$UserNotificationFromJson(json);

@override final  int id;
@override final  String type;
@override final  String title;
@override final  String body;
 final  Map<String, dynamic>? _actionData;
@override@JsonKey(name: 'action_data') Map<String, dynamic>? get actionData {
  final value = _actionData;
  if (value == null) return null;
  if (_actionData is EqualUnmodifiableMapView) return _actionData;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override final  String status;

/// Create a copy of UserNotification
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserNotificationCopyWith<_UserNotification> get copyWith => __$UserNotificationCopyWithImpl<_UserNotification>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserNotificationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserNotification&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.title, title) || other.title == title)&&(identical(other.body, body) || other.body == body)&&const DeepCollectionEquality().equals(other._actionData, _actionData)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,type,title,body,const DeepCollectionEquality().hash(_actionData),status);

@override
String toString() {
  return 'UserNotification(id: $id, type: $type, title: $title, body: $body, actionData: $actionData, status: $status)';
}


}

/// @nodoc
abstract mixin class _$UserNotificationCopyWith<$Res> implements $UserNotificationCopyWith<$Res> {
  factory _$UserNotificationCopyWith(_UserNotification value, $Res Function(_UserNotification) _then) = __$UserNotificationCopyWithImpl;
@override @useResult
$Res call({
 int id, String type, String title, String body,@JsonKey(name: 'action_data') Map<String, dynamic>? actionData, String status
});




}
/// @nodoc
class __$UserNotificationCopyWithImpl<$Res>
    implements _$UserNotificationCopyWith<$Res> {
  __$UserNotificationCopyWithImpl(this._self, this._then);

  final _UserNotification _self;
  final $Res Function(_UserNotification) _then;

/// Create a copy of UserNotification
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? type = null,Object? title = null,Object? body = null,Object? actionData = freezed,Object? status = null,}) {
  return _then(_UserNotification(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,actionData: freezed == actionData ? _self._actionData : actionData // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
