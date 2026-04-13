// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'training_week.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TrainingWeek {

 int get id;@JsonKey(name: 'race_id') int get raceId;@JsonKey(name: 'week_number') int get weekNumber;@JsonKey(name: 'starts_at') String get startsAt;@JsonKey(name: 'total_km', fromJson: toDouble) double get totalKm; String get focus;@JsonKey(name: 'coach_notes') String? get coachNotes;@JsonKey(name: 'training_days') List<TrainingDay>? get trainingDays;
/// Create a copy of TrainingWeek
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TrainingWeekCopyWith<TrainingWeek> get copyWith => _$TrainingWeekCopyWithImpl<TrainingWeek>(this as TrainingWeek, _$identity);

  /// Serializes this TrainingWeek to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TrainingWeek&&(identical(other.id, id) || other.id == id)&&(identical(other.raceId, raceId) || other.raceId == raceId)&&(identical(other.weekNumber, weekNumber) || other.weekNumber == weekNumber)&&(identical(other.startsAt, startsAt) || other.startsAt == startsAt)&&(identical(other.totalKm, totalKm) || other.totalKm == totalKm)&&(identical(other.focus, focus) || other.focus == focus)&&(identical(other.coachNotes, coachNotes) || other.coachNotes == coachNotes)&&const DeepCollectionEquality().equals(other.trainingDays, trainingDays));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,raceId,weekNumber,startsAt,totalKm,focus,coachNotes,const DeepCollectionEquality().hash(trainingDays));

@override
String toString() {
  return 'TrainingWeek(id: $id, raceId: $raceId, weekNumber: $weekNumber, startsAt: $startsAt, totalKm: $totalKm, focus: $focus, coachNotes: $coachNotes, trainingDays: $trainingDays)';
}


}

/// @nodoc
abstract mixin class $TrainingWeekCopyWith<$Res>  {
  factory $TrainingWeekCopyWith(TrainingWeek value, $Res Function(TrainingWeek) _then) = _$TrainingWeekCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'race_id') int raceId,@JsonKey(name: 'week_number') int weekNumber,@JsonKey(name: 'starts_at') String startsAt,@JsonKey(name: 'total_km', fromJson: toDouble) double totalKm, String focus,@JsonKey(name: 'coach_notes') String? coachNotes,@JsonKey(name: 'training_days') List<TrainingDay>? trainingDays
});




}
/// @nodoc
class _$TrainingWeekCopyWithImpl<$Res>
    implements $TrainingWeekCopyWith<$Res> {
  _$TrainingWeekCopyWithImpl(this._self, this._then);

  final TrainingWeek _self;
  final $Res Function(TrainingWeek) _then;

/// Create a copy of TrainingWeek
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? raceId = null,Object? weekNumber = null,Object? startsAt = null,Object? totalKm = null,Object? focus = null,Object? coachNotes = freezed,Object? trainingDays = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,raceId: null == raceId ? _self.raceId : raceId // ignore: cast_nullable_to_non_nullable
as int,weekNumber: null == weekNumber ? _self.weekNumber : weekNumber // ignore: cast_nullable_to_non_nullable
as int,startsAt: null == startsAt ? _self.startsAt : startsAt // ignore: cast_nullable_to_non_nullable
as String,totalKm: null == totalKm ? _self.totalKm : totalKm // ignore: cast_nullable_to_non_nullable
as double,focus: null == focus ? _self.focus : focus // ignore: cast_nullable_to_non_nullable
as String,coachNotes: freezed == coachNotes ? _self.coachNotes : coachNotes // ignore: cast_nullable_to_non_nullable
as String?,trainingDays: freezed == trainingDays ? _self.trainingDays : trainingDays // ignore: cast_nullable_to_non_nullable
as List<TrainingDay>?,
  ));
}

}


/// Adds pattern-matching-related methods to [TrainingWeek].
extension TrainingWeekPatterns on TrainingWeek {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TrainingWeek value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TrainingWeek() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TrainingWeek value)  $default,){
final _that = this;
switch (_that) {
case _TrainingWeek():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TrainingWeek value)?  $default,){
final _that = this;
switch (_that) {
case _TrainingWeek() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'race_id')  int raceId, @JsonKey(name: 'week_number')  int weekNumber, @JsonKey(name: 'starts_at')  String startsAt, @JsonKey(name: 'total_km', fromJson: toDouble)  double totalKm,  String focus, @JsonKey(name: 'coach_notes')  String? coachNotes, @JsonKey(name: 'training_days')  List<TrainingDay>? trainingDays)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TrainingWeek() when $default != null:
return $default(_that.id,_that.raceId,_that.weekNumber,_that.startsAt,_that.totalKm,_that.focus,_that.coachNotes,_that.trainingDays);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'race_id')  int raceId, @JsonKey(name: 'week_number')  int weekNumber, @JsonKey(name: 'starts_at')  String startsAt, @JsonKey(name: 'total_km', fromJson: toDouble)  double totalKm,  String focus, @JsonKey(name: 'coach_notes')  String? coachNotes, @JsonKey(name: 'training_days')  List<TrainingDay>? trainingDays)  $default,) {final _that = this;
switch (_that) {
case _TrainingWeek():
return $default(_that.id,_that.raceId,_that.weekNumber,_that.startsAt,_that.totalKm,_that.focus,_that.coachNotes,_that.trainingDays);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(name: 'race_id')  int raceId, @JsonKey(name: 'week_number')  int weekNumber, @JsonKey(name: 'starts_at')  String startsAt, @JsonKey(name: 'total_km', fromJson: toDouble)  double totalKm,  String focus, @JsonKey(name: 'coach_notes')  String? coachNotes, @JsonKey(name: 'training_days')  List<TrainingDay>? trainingDays)?  $default,) {final _that = this;
switch (_that) {
case _TrainingWeek() when $default != null:
return $default(_that.id,_that.raceId,_that.weekNumber,_that.startsAt,_that.totalKm,_that.focus,_that.coachNotes,_that.trainingDays);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TrainingWeek implements TrainingWeek {
  const _TrainingWeek({required this.id, @JsonKey(name: 'race_id') required this.raceId, @JsonKey(name: 'week_number') required this.weekNumber, @JsonKey(name: 'starts_at') required this.startsAt, @JsonKey(name: 'total_km', fromJson: toDouble) required this.totalKm, required this.focus, @JsonKey(name: 'coach_notes') this.coachNotes, @JsonKey(name: 'training_days') final  List<TrainingDay>? trainingDays}): _trainingDays = trainingDays;
  factory _TrainingWeek.fromJson(Map<String, dynamic> json) => _$TrainingWeekFromJson(json);

@override final  int id;
@override@JsonKey(name: 'race_id') final  int raceId;
@override@JsonKey(name: 'week_number') final  int weekNumber;
@override@JsonKey(name: 'starts_at') final  String startsAt;
@override@JsonKey(name: 'total_km', fromJson: toDouble) final  double totalKm;
@override final  String focus;
@override@JsonKey(name: 'coach_notes') final  String? coachNotes;
 final  List<TrainingDay>? _trainingDays;
@override@JsonKey(name: 'training_days') List<TrainingDay>? get trainingDays {
  final value = _trainingDays;
  if (value == null) return null;
  if (_trainingDays is EqualUnmodifiableListView) return _trainingDays;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of TrainingWeek
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TrainingWeekCopyWith<_TrainingWeek> get copyWith => __$TrainingWeekCopyWithImpl<_TrainingWeek>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TrainingWeekToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TrainingWeek&&(identical(other.id, id) || other.id == id)&&(identical(other.raceId, raceId) || other.raceId == raceId)&&(identical(other.weekNumber, weekNumber) || other.weekNumber == weekNumber)&&(identical(other.startsAt, startsAt) || other.startsAt == startsAt)&&(identical(other.totalKm, totalKm) || other.totalKm == totalKm)&&(identical(other.focus, focus) || other.focus == focus)&&(identical(other.coachNotes, coachNotes) || other.coachNotes == coachNotes)&&const DeepCollectionEquality().equals(other._trainingDays, _trainingDays));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,raceId,weekNumber,startsAt,totalKm,focus,coachNotes,const DeepCollectionEquality().hash(_trainingDays));

@override
String toString() {
  return 'TrainingWeek(id: $id, raceId: $raceId, weekNumber: $weekNumber, startsAt: $startsAt, totalKm: $totalKm, focus: $focus, coachNotes: $coachNotes, trainingDays: $trainingDays)';
}


}

/// @nodoc
abstract mixin class _$TrainingWeekCopyWith<$Res> implements $TrainingWeekCopyWith<$Res> {
  factory _$TrainingWeekCopyWith(_TrainingWeek value, $Res Function(_TrainingWeek) _then) = __$TrainingWeekCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'race_id') int raceId,@JsonKey(name: 'week_number') int weekNumber,@JsonKey(name: 'starts_at') String startsAt,@JsonKey(name: 'total_km', fromJson: toDouble) double totalKm, String focus,@JsonKey(name: 'coach_notes') String? coachNotes,@JsonKey(name: 'training_days') List<TrainingDay>? trainingDays
});




}
/// @nodoc
class __$TrainingWeekCopyWithImpl<$Res>
    implements _$TrainingWeekCopyWith<$Res> {
  __$TrainingWeekCopyWithImpl(this._self, this._then);

  final _TrainingWeek _self;
  final $Res Function(_TrainingWeek) _then;

/// Create a copy of TrainingWeek
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? raceId = null,Object? weekNumber = null,Object? startsAt = null,Object? totalKm = null,Object? focus = null,Object? coachNotes = freezed,Object? trainingDays = freezed,}) {
  return _then(_TrainingWeek(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,raceId: null == raceId ? _self.raceId : raceId // ignore: cast_nullable_to_non_nullable
as int,weekNumber: null == weekNumber ? _self.weekNumber : weekNumber // ignore: cast_nullable_to_non_nullable
as int,startsAt: null == startsAt ? _self.startsAt : startsAt // ignore: cast_nullable_to_non_nullable
as String,totalKm: null == totalKm ? _self.totalKm : totalKm // ignore: cast_nullable_to_non_nullable
as double,focus: null == focus ? _self.focus : focus // ignore: cast_nullable_to_non_nullable
as String,coachNotes: freezed == coachNotes ? _self.coachNotes : coachNotes // ignore: cast_nullable_to_non_nullable
as String?,trainingDays: freezed == trainingDays ? _self._trainingDays : trainingDays // ignore: cast_nullable_to_non_nullable
as List<TrainingDay>?,
  ));
}


}

// dart format on
