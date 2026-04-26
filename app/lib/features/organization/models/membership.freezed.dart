// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'membership.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MembershipCoach {

 int get id; String get name; String get email;
/// Create a copy of MembershipCoach
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MembershipCoachCopyWith<MembershipCoach> get copyWith => _$MembershipCoachCopyWithImpl<MembershipCoach>(this as MembershipCoach, _$identity);

  /// Serializes this MembershipCoach to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MembershipCoach&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.email, email) || other.email == email));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,email);

@override
String toString() {
  return 'MembershipCoach(id: $id, name: $name, email: $email)';
}


}

/// @nodoc
abstract mixin class $MembershipCoachCopyWith<$Res>  {
  factory $MembershipCoachCopyWith(MembershipCoach value, $Res Function(MembershipCoach) _then) = _$MembershipCoachCopyWithImpl;
@useResult
$Res call({
 int id, String name, String email
});




}
/// @nodoc
class _$MembershipCoachCopyWithImpl<$Res>
    implements $MembershipCoachCopyWith<$Res> {
  _$MembershipCoachCopyWithImpl(this._self, this._then);

  final MembershipCoach _self;
  final $Res Function(MembershipCoach) _then;

/// Create a copy of MembershipCoach
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? email = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [MembershipCoach].
extension MembershipCoachPatterns on MembershipCoach {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MembershipCoach value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MembershipCoach() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MembershipCoach value)  $default,){
final _that = this;
switch (_that) {
case _MembershipCoach():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MembershipCoach value)?  $default,){
final _that = this;
switch (_that) {
case _MembershipCoach() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name,  String email)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MembershipCoach() when $default != null:
return $default(_that.id,_that.name,_that.email);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name,  String email)  $default,) {final _that = this;
switch (_that) {
case _MembershipCoach():
return $default(_that.id,_that.name,_that.email);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name,  String email)?  $default,) {final _that = this;
switch (_that) {
case _MembershipCoach() when $default != null:
return $default(_that.id,_that.name,_that.email);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MembershipCoach implements MembershipCoach {
  const _MembershipCoach({required this.id, required this.name, required this.email});
  factory _MembershipCoach.fromJson(Map<String, dynamic> json) => _$MembershipCoachFromJson(json);

@override final  int id;
@override final  String name;
@override final  String email;

/// Create a copy of MembershipCoach
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MembershipCoachCopyWith<_MembershipCoach> get copyWith => __$MembershipCoachCopyWithImpl<_MembershipCoach>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MembershipCoachToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MembershipCoach&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.email, email) || other.email == email));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,email);

@override
String toString() {
  return 'MembershipCoach(id: $id, name: $name, email: $email)';
}


}

/// @nodoc
abstract mixin class _$MembershipCoachCopyWith<$Res> implements $MembershipCoachCopyWith<$Res> {
  factory _$MembershipCoachCopyWith(_MembershipCoach value, $Res Function(_MembershipCoach) _then) = __$MembershipCoachCopyWithImpl;
@override @useResult
$Res call({
 int id, String name, String email
});




}
/// @nodoc
class __$MembershipCoachCopyWithImpl<$Res>
    implements _$MembershipCoachCopyWith<$Res> {
  __$MembershipCoachCopyWithImpl(this._self, this._then);

  final _MembershipCoach _self;
  final $Res Function(_MembershipCoach) _then;

/// Create a copy of MembershipCoach
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? email = null,}) {
  return _then(_MembershipCoach(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$Membership {

 int get id; String get role; String get status; Organization? get organization; MembershipCoach? get coach;@JsonKey(name: 'invite_email') String? get inviteEmail;@JsonKey(name: 'invited_at') String? get invitedAt;@JsonKey(name: 'requested_at') String? get requestedAt;@JsonKey(name: 'joined_at') String? get joinedAt;
/// Create a copy of Membership
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MembershipCopyWith<Membership> get copyWith => _$MembershipCopyWithImpl<Membership>(this as Membership, _$identity);

  /// Serializes this Membership to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Membership&&(identical(other.id, id) || other.id == id)&&(identical(other.role, role) || other.role == role)&&(identical(other.status, status) || other.status == status)&&(identical(other.organization, organization) || other.organization == organization)&&(identical(other.coach, coach) || other.coach == coach)&&(identical(other.inviteEmail, inviteEmail) || other.inviteEmail == inviteEmail)&&(identical(other.invitedAt, invitedAt) || other.invitedAt == invitedAt)&&(identical(other.requestedAt, requestedAt) || other.requestedAt == requestedAt)&&(identical(other.joinedAt, joinedAt) || other.joinedAt == joinedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,role,status,organization,coach,inviteEmail,invitedAt,requestedAt,joinedAt);

@override
String toString() {
  return 'Membership(id: $id, role: $role, status: $status, organization: $organization, coach: $coach, inviteEmail: $inviteEmail, invitedAt: $invitedAt, requestedAt: $requestedAt, joinedAt: $joinedAt)';
}


}

/// @nodoc
abstract mixin class $MembershipCopyWith<$Res>  {
  factory $MembershipCopyWith(Membership value, $Res Function(Membership) _then) = _$MembershipCopyWithImpl;
@useResult
$Res call({
 int id, String role, String status, Organization? organization, MembershipCoach? coach,@JsonKey(name: 'invite_email') String? inviteEmail,@JsonKey(name: 'invited_at') String? invitedAt,@JsonKey(name: 'requested_at') String? requestedAt,@JsonKey(name: 'joined_at') String? joinedAt
});


$OrganizationCopyWith<$Res>? get organization;$MembershipCoachCopyWith<$Res>? get coach;

}
/// @nodoc
class _$MembershipCopyWithImpl<$Res>
    implements $MembershipCopyWith<$Res> {
  _$MembershipCopyWithImpl(this._self, this._then);

  final Membership _self;
  final $Res Function(Membership) _then;

/// Create a copy of Membership
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? role = null,Object? status = null,Object? organization = freezed,Object? coach = freezed,Object? inviteEmail = freezed,Object? invitedAt = freezed,Object? requestedAt = freezed,Object? joinedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,organization: freezed == organization ? _self.organization : organization // ignore: cast_nullable_to_non_nullable
as Organization?,coach: freezed == coach ? _self.coach : coach // ignore: cast_nullable_to_non_nullable
as MembershipCoach?,inviteEmail: freezed == inviteEmail ? _self.inviteEmail : inviteEmail // ignore: cast_nullable_to_non_nullable
as String?,invitedAt: freezed == invitedAt ? _self.invitedAt : invitedAt // ignore: cast_nullable_to_non_nullable
as String?,requestedAt: freezed == requestedAt ? _self.requestedAt : requestedAt // ignore: cast_nullable_to_non_nullable
as String?,joinedAt: freezed == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of Membership
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrganizationCopyWith<$Res>? get organization {
    if (_self.organization == null) {
    return null;
  }

  return $OrganizationCopyWith<$Res>(_self.organization!, (value) {
    return _then(_self.copyWith(organization: value));
  });
}/// Create a copy of Membership
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MembershipCoachCopyWith<$Res>? get coach {
    if (_self.coach == null) {
    return null;
  }

  return $MembershipCoachCopyWith<$Res>(_self.coach!, (value) {
    return _then(_self.copyWith(coach: value));
  });
}
}


/// Adds pattern-matching-related methods to [Membership].
extension MembershipPatterns on Membership {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Membership value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Membership() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Membership value)  $default,){
final _that = this;
switch (_that) {
case _Membership():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Membership value)?  $default,){
final _that = this;
switch (_that) {
case _Membership() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String role,  String status,  Organization? organization,  MembershipCoach? coach, @JsonKey(name: 'invite_email')  String? inviteEmail, @JsonKey(name: 'invited_at')  String? invitedAt, @JsonKey(name: 'requested_at')  String? requestedAt, @JsonKey(name: 'joined_at')  String? joinedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Membership() when $default != null:
return $default(_that.id,_that.role,_that.status,_that.organization,_that.coach,_that.inviteEmail,_that.invitedAt,_that.requestedAt,_that.joinedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String role,  String status,  Organization? organization,  MembershipCoach? coach, @JsonKey(name: 'invite_email')  String? inviteEmail, @JsonKey(name: 'invited_at')  String? invitedAt, @JsonKey(name: 'requested_at')  String? requestedAt, @JsonKey(name: 'joined_at')  String? joinedAt)  $default,) {final _that = this;
switch (_that) {
case _Membership():
return $default(_that.id,_that.role,_that.status,_that.organization,_that.coach,_that.inviteEmail,_that.invitedAt,_that.requestedAt,_that.joinedAt);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String role,  String status,  Organization? organization,  MembershipCoach? coach, @JsonKey(name: 'invite_email')  String? inviteEmail, @JsonKey(name: 'invited_at')  String? invitedAt, @JsonKey(name: 'requested_at')  String? requestedAt, @JsonKey(name: 'joined_at')  String? joinedAt)?  $default,) {final _that = this;
switch (_that) {
case _Membership() when $default != null:
return $default(_that.id,_that.role,_that.status,_that.organization,_that.coach,_that.inviteEmail,_that.invitedAt,_that.requestedAt,_that.joinedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Membership implements Membership {
  const _Membership({required this.id, required this.role, required this.status, this.organization, this.coach, @JsonKey(name: 'invite_email') this.inviteEmail, @JsonKey(name: 'invited_at') this.invitedAt, @JsonKey(name: 'requested_at') this.requestedAt, @JsonKey(name: 'joined_at') this.joinedAt});
  factory _Membership.fromJson(Map<String, dynamic> json) => _$MembershipFromJson(json);

@override final  int id;
@override final  String role;
@override final  String status;
@override final  Organization? organization;
@override final  MembershipCoach? coach;
@override@JsonKey(name: 'invite_email') final  String? inviteEmail;
@override@JsonKey(name: 'invited_at') final  String? invitedAt;
@override@JsonKey(name: 'requested_at') final  String? requestedAt;
@override@JsonKey(name: 'joined_at') final  String? joinedAt;

/// Create a copy of Membership
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MembershipCopyWith<_Membership> get copyWith => __$MembershipCopyWithImpl<_Membership>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MembershipToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Membership&&(identical(other.id, id) || other.id == id)&&(identical(other.role, role) || other.role == role)&&(identical(other.status, status) || other.status == status)&&(identical(other.organization, organization) || other.organization == organization)&&(identical(other.coach, coach) || other.coach == coach)&&(identical(other.inviteEmail, inviteEmail) || other.inviteEmail == inviteEmail)&&(identical(other.invitedAt, invitedAt) || other.invitedAt == invitedAt)&&(identical(other.requestedAt, requestedAt) || other.requestedAt == requestedAt)&&(identical(other.joinedAt, joinedAt) || other.joinedAt == joinedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,role,status,organization,coach,inviteEmail,invitedAt,requestedAt,joinedAt);

@override
String toString() {
  return 'Membership(id: $id, role: $role, status: $status, organization: $organization, coach: $coach, inviteEmail: $inviteEmail, invitedAt: $invitedAt, requestedAt: $requestedAt, joinedAt: $joinedAt)';
}


}

/// @nodoc
abstract mixin class _$MembershipCopyWith<$Res> implements $MembershipCopyWith<$Res> {
  factory _$MembershipCopyWith(_Membership value, $Res Function(_Membership) _then) = __$MembershipCopyWithImpl;
@override @useResult
$Res call({
 int id, String role, String status, Organization? organization, MembershipCoach? coach,@JsonKey(name: 'invite_email') String? inviteEmail,@JsonKey(name: 'invited_at') String? invitedAt,@JsonKey(name: 'requested_at') String? requestedAt,@JsonKey(name: 'joined_at') String? joinedAt
});


@override $OrganizationCopyWith<$Res>? get organization;@override $MembershipCoachCopyWith<$Res>? get coach;

}
/// @nodoc
class __$MembershipCopyWithImpl<$Res>
    implements _$MembershipCopyWith<$Res> {
  __$MembershipCopyWithImpl(this._self, this._then);

  final _Membership _self;
  final $Res Function(_Membership) _then;

/// Create a copy of Membership
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? role = null,Object? status = null,Object? organization = freezed,Object? coach = freezed,Object? inviteEmail = freezed,Object? invitedAt = freezed,Object? requestedAt = freezed,Object? joinedAt = freezed,}) {
  return _then(_Membership(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,organization: freezed == organization ? _self.organization : organization // ignore: cast_nullable_to_non_nullable
as Organization?,coach: freezed == coach ? _self.coach : coach // ignore: cast_nullable_to_non_nullable
as MembershipCoach?,inviteEmail: freezed == inviteEmail ? _self.inviteEmail : inviteEmail // ignore: cast_nullable_to_non_nullable
as String?,invitedAt: freezed == invitedAt ? _self.invitedAt : invitedAt // ignore: cast_nullable_to_non_nullable
as String?,requestedAt: freezed == requestedAt ? _self.requestedAt : requestedAt // ignore: cast_nullable_to_non_nullable
as String?,joinedAt: freezed == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of Membership
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrganizationCopyWith<$Res>? get organization {
    if (_self.organization == null) {
    return null;
  }

  return $OrganizationCopyWith<$Res>(_self.organization!, (value) {
    return _then(_self.copyWith(organization: value));
  });
}/// Create a copy of Membership
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MembershipCoachCopyWith<$Res>? get coach {
    if (_self.coach == null) {
    return null;
  }

  return $MembershipCoachCopyWith<$Res>(_self.coach!, (value) {
    return _then(_self.copyWith(coach: value));
  });
}
}

// dart format on
