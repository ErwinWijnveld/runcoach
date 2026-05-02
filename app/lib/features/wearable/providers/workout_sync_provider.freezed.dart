// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'workout_sync_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WorkoutSyncState {

 Map<int, AnalyzingRun> get analyzing; bool get isSyncing; LastSyncResult? get lastSyncResult; DateTime? get lastSyncedAt;
/// Create a copy of WorkoutSyncState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkoutSyncStateCopyWith<WorkoutSyncState> get copyWith => _$WorkoutSyncStateCopyWithImpl<WorkoutSyncState>(this as WorkoutSyncState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkoutSyncState&&const DeepCollectionEquality().equals(other.analyzing, analyzing)&&(identical(other.isSyncing, isSyncing) || other.isSyncing == isSyncing)&&(identical(other.lastSyncResult, lastSyncResult) || other.lastSyncResult == lastSyncResult)&&(identical(other.lastSyncedAt, lastSyncedAt) || other.lastSyncedAt == lastSyncedAt));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(analyzing),isSyncing,lastSyncResult,lastSyncedAt);

@override
String toString() {
  return 'WorkoutSyncState(analyzing: $analyzing, isSyncing: $isSyncing, lastSyncResult: $lastSyncResult, lastSyncedAt: $lastSyncedAt)';
}


}

/// @nodoc
abstract mixin class $WorkoutSyncStateCopyWith<$Res>  {
  factory $WorkoutSyncStateCopyWith(WorkoutSyncState value, $Res Function(WorkoutSyncState) _then) = _$WorkoutSyncStateCopyWithImpl;
@useResult
$Res call({
 Map<int, AnalyzingRun> analyzing, bool isSyncing, LastSyncResult? lastSyncResult, DateTime? lastSyncedAt
});


$LastSyncResultCopyWith<$Res>? get lastSyncResult;

}
/// @nodoc
class _$WorkoutSyncStateCopyWithImpl<$Res>
    implements $WorkoutSyncStateCopyWith<$Res> {
  _$WorkoutSyncStateCopyWithImpl(this._self, this._then);

  final WorkoutSyncState _self;
  final $Res Function(WorkoutSyncState) _then;

/// Create a copy of WorkoutSyncState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? analyzing = null,Object? isSyncing = null,Object? lastSyncResult = freezed,Object? lastSyncedAt = freezed,}) {
  return _then(_self.copyWith(
analyzing: null == analyzing ? _self.analyzing : analyzing // ignore: cast_nullable_to_non_nullable
as Map<int, AnalyzingRun>,isSyncing: null == isSyncing ? _self.isSyncing : isSyncing // ignore: cast_nullable_to_non_nullable
as bool,lastSyncResult: freezed == lastSyncResult ? _self.lastSyncResult : lastSyncResult // ignore: cast_nullable_to_non_nullable
as LastSyncResult?,lastSyncedAt: freezed == lastSyncedAt ? _self.lastSyncedAt : lastSyncedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of WorkoutSyncState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LastSyncResultCopyWith<$Res>? get lastSyncResult {
    if (_self.lastSyncResult == null) {
    return null;
  }

  return $LastSyncResultCopyWith<$Res>(_self.lastSyncResult!, (value) {
    return _then(_self.copyWith(lastSyncResult: value));
  });
}
}


/// Adds pattern-matching-related methods to [WorkoutSyncState].
extension WorkoutSyncStatePatterns on WorkoutSyncState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkoutSyncState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkoutSyncState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkoutSyncState value)  $default,){
final _that = this;
switch (_that) {
case _WorkoutSyncState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkoutSyncState value)?  $default,){
final _that = this;
switch (_that) {
case _WorkoutSyncState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Map<int, AnalyzingRun> analyzing,  bool isSyncing,  LastSyncResult? lastSyncResult,  DateTime? lastSyncedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkoutSyncState() when $default != null:
return $default(_that.analyzing,_that.isSyncing,_that.lastSyncResult,_that.lastSyncedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Map<int, AnalyzingRun> analyzing,  bool isSyncing,  LastSyncResult? lastSyncResult,  DateTime? lastSyncedAt)  $default,) {final _that = this;
switch (_that) {
case _WorkoutSyncState():
return $default(_that.analyzing,_that.isSyncing,_that.lastSyncResult,_that.lastSyncedAt);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Map<int, AnalyzingRun> analyzing,  bool isSyncing,  LastSyncResult? lastSyncResult,  DateTime? lastSyncedAt)?  $default,) {final _that = this;
switch (_that) {
case _WorkoutSyncState() when $default != null:
return $default(_that.analyzing,_that.isSyncing,_that.lastSyncResult,_that.lastSyncedAt);case _:
  return null;

}
}

}

/// @nodoc


class _WorkoutSyncState implements WorkoutSyncState {
  const _WorkoutSyncState({final  Map<int, AnalyzingRun> analyzing = const <int, AnalyzingRun>{}, this.isSyncing = false, this.lastSyncResult, this.lastSyncedAt}): _analyzing = analyzing;
  

 final  Map<int, AnalyzingRun> _analyzing;
@override@JsonKey() Map<int, AnalyzingRun> get analyzing {
  if (_analyzing is EqualUnmodifiableMapView) return _analyzing;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_analyzing);
}

@override@JsonKey() final  bool isSyncing;
@override final  LastSyncResult? lastSyncResult;
@override final  DateTime? lastSyncedAt;

/// Create a copy of WorkoutSyncState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkoutSyncStateCopyWith<_WorkoutSyncState> get copyWith => __$WorkoutSyncStateCopyWithImpl<_WorkoutSyncState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkoutSyncState&&const DeepCollectionEquality().equals(other._analyzing, _analyzing)&&(identical(other.isSyncing, isSyncing) || other.isSyncing == isSyncing)&&(identical(other.lastSyncResult, lastSyncResult) || other.lastSyncResult == lastSyncResult)&&(identical(other.lastSyncedAt, lastSyncedAt) || other.lastSyncedAt == lastSyncedAt));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_analyzing),isSyncing,lastSyncResult,lastSyncedAt);

@override
String toString() {
  return 'WorkoutSyncState(analyzing: $analyzing, isSyncing: $isSyncing, lastSyncResult: $lastSyncResult, lastSyncedAt: $lastSyncedAt)';
}


}

/// @nodoc
abstract mixin class _$WorkoutSyncStateCopyWith<$Res> implements $WorkoutSyncStateCopyWith<$Res> {
  factory _$WorkoutSyncStateCopyWith(_WorkoutSyncState value, $Res Function(_WorkoutSyncState) _then) = __$WorkoutSyncStateCopyWithImpl;
@override @useResult
$Res call({
 Map<int, AnalyzingRun> analyzing, bool isSyncing, LastSyncResult? lastSyncResult, DateTime? lastSyncedAt
});


@override $LastSyncResultCopyWith<$Res>? get lastSyncResult;

}
/// @nodoc
class __$WorkoutSyncStateCopyWithImpl<$Res>
    implements _$WorkoutSyncStateCopyWith<$Res> {
  __$WorkoutSyncStateCopyWithImpl(this._self, this._then);

  final _WorkoutSyncState _self;
  final $Res Function(_WorkoutSyncState) _then;

/// Create a copy of WorkoutSyncState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? analyzing = null,Object? isSyncing = null,Object? lastSyncResult = freezed,Object? lastSyncedAt = freezed,}) {
  return _then(_WorkoutSyncState(
analyzing: null == analyzing ? _self._analyzing : analyzing // ignore: cast_nullable_to_non_nullable
as Map<int, AnalyzingRun>,isSyncing: null == isSyncing ? _self.isSyncing : isSyncing // ignore: cast_nullable_to_non_nullable
as bool,lastSyncResult: freezed == lastSyncResult ? _self.lastSyncResult : lastSyncResult // ignore: cast_nullable_to_non_nullable
as LastSyncResult?,lastSyncedAt: freezed == lastSyncedAt ? _self.lastSyncedAt : lastSyncedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of WorkoutSyncState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LastSyncResultCopyWith<$Res>? get lastSyncResult {
    if (_self.lastSyncResult == null) {
    return null;
  }

  return $LastSyncResultCopyWith<$Res>(_self.lastSyncResult!, (value) {
    return _then(_self.copyWith(lastSyncResult: value));
  });
}
}

/// @nodoc
mixin _$LastSyncResult {

 int get created; int get updated; List<int> get newRunIds; DateTime get at;
/// Create a copy of LastSyncResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LastSyncResultCopyWith<LastSyncResult> get copyWith => _$LastSyncResultCopyWithImpl<LastSyncResult>(this as LastSyncResult, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LastSyncResult&&(identical(other.created, created) || other.created == created)&&(identical(other.updated, updated) || other.updated == updated)&&const DeepCollectionEquality().equals(other.newRunIds, newRunIds)&&(identical(other.at, at) || other.at == at));
}


@override
int get hashCode => Object.hash(runtimeType,created,updated,const DeepCollectionEquality().hash(newRunIds),at);

@override
String toString() {
  return 'LastSyncResult(created: $created, updated: $updated, newRunIds: $newRunIds, at: $at)';
}


}

/// @nodoc
abstract mixin class $LastSyncResultCopyWith<$Res>  {
  factory $LastSyncResultCopyWith(LastSyncResult value, $Res Function(LastSyncResult) _then) = _$LastSyncResultCopyWithImpl;
@useResult
$Res call({
 int created, int updated, List<int> newRunIds, DateTime at
});




}
/// @nodoc
class _$LastSyncResultCopyWithImpl<$Res>
    implements $LastSyncResultCopyWith<$Res> {
  _$LastSyncResultCopyWithImpl(this._self, this._then);

  final LastSyncResult _self;
  final $Res Function(LastSyncResult) _then;

/// Create a copy of LastSyncResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? created = null,Object? updated = null,Object? newRunIds = null,Object? at = null,}) {
  return _then(_self.copyWith(
created: null == created ? _self.created : created // ignore: cast_nullable_to_non_nullable
as int,updated: null == updated ? _self.updated : updated // ignore: cast_nullable_to_non_nullable
as int,newRunIds: null == newRunIds ? _self.newRunIds : newRunIds // ignore: cast_nullable_to_non_nullable
as List<int>,at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [LastSyncResult].
extension LastSyncResultPatterns on LastSyncResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LastSyncResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LastSyncResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LastSyncResult value)  $default,){
final _that = this;
switch (_that) {
case _LastSyncResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LastSyncResult value)?  $default,){
final _that = this;
switch (_that) {
case _LastSyncResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int created,  int updated,  List<int> newRunIds,  DateTime at)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LastSyncResult() when $default != null:
return $default(_that.created,_that.updated,_that.newRunIds,_that.at);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int created,  int updated,  List<int> newRunIds,  DateTime at)  $default,) {final _that = this;
switch (_that) {
case _LastSyncResult():
return $default(_that.created,_that.updated,_that.newRunIds,_that.at);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int created,  int updated,  List<int> newRunIds,  DateTime at)?  $default,) {final _that = this;
switch (_that) {
case _LastSyncResult() when $default != null:
return $default(_that.created,_that.updated,_that.newRunIds,_that.at);case _:
  return null;

}
}

}

/// @nodoc


class _LastSyncResult implements LastSyncResult {
  const _LastSyncResult({required this.created, required this.updated, required final  List<int> newRunIds, required this.at}): _newRunIds = newRunIds;
  

@override final  int created;
@override final  int updated;
 final  List<int> _newRunIds;
@override List<int> get newRunIds {
  if (_newRunIds is EqualUnmodifiableListView) return _newRunIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_newRunIds);
}

@override final  DateTime at;

/// Create a copy of LastSyncResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LastSyncResultCopyWith<_LastSyncResult> get copyWith => __$LastSyncResultCopyWithImpl<_LastSyncResult>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LastSyncResult&&(identical(other.created, created) || other.created == created)&&(identical(other.updated, updated) || other.updated == updated)&&const DeepCollectionEquality().equals(other._newRunIds, _newRunIds)&&(identical(other.at, at) || other.at == at));
}


@override
int get hashCode => Object.hash(runtimeType,created,updated,const DeepCollectionEquality().hash(_newRunIds),at);

@override
String toString() {
  return 'LastSyncResult(created: $created, updated: $updated, newRunIds: $newRunIds, at: $at)';
}


}

/// @nodoc
abstract mixin class _$LastSyncResultCopyWith<$Res> implements $LastSyncResultCopyWith<$Res> {
  factory _$LastSyncResultCopyWith(_LastSyncResult value, $Res Function(_LastSyncResult) _then) = __$LastSyncResultCopyWithImpl;
@override @useResult
$Res call({
 int created, int updated, List<int> newRunIds, DateTime at
});




}
/// @nodoc
class __$LastSyncResultCopyWithImpl<$Res>
    implements _$LastSyncResultCopyWith<$Res> {
  __$LastSyncResultCopyWithImpl(this._self, this._then);

  final _LastSyncResult _self;
  final $Res Function(_LastSyncResult) _then;

/// Create a copy of LastSyncResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? created = null,Object? updated = null,Object? newRunIds = null,Object? at = null,}) {
  return _then(_LastSyncResult(
created: null == created ? _self.created : created // ignore: cast_nullable_to_non_nullable
as int,updated: null == updated ? _self.updated : updated // ignore: cast_nullable_to_non_nullable
as int,newRunIds: null == newRunIds ? _self._newRunIds : newRunIds // ignore: cast_nullable_to_non_nullable
as List<int>,at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
