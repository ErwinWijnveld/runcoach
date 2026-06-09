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

 int get id;@JsonKey(name: 'goal_id') int get goalId;@JsonKey(name: 'week_number') int get weekNumber;@JsonKey(name: 'starts_at') String get startsAt;@JsonKey(name: 'total_km', fromJson: toDouble) double get totalKm; String get focus;@JsonKey(name: 'coach_notes') String? get coachNotes;@JsonKey(name: 'training_days') List<TrainingDay>? get trainingDays;/// Runs that fell within this week but matched no planned session
/// ("buiten schema"). Surfaced as blue tiles the runner can link.
@JsonKey(name: 'unplanned_runs') List<WearableActivitySummary>? get unplannedRuns;
/// Create a copy of TrainingWeek
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TrainingWeekCopyWith<TrainingWeek> get copyWith => _$TrainingWeekCopyWithImpl<TrainingWeek>(this as TrainingWeek, _$identity);

  /// Serializes this TrainingWeek to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TrainingWeek&&(identical(other.id, id) || other.id == id)&&(identical(other.goalId, goalId) || other.goalId == goalId)&&(identical(other.weekNumber, weekNumber) || other.weekNumber == weekNumber)&&(identical(other.startsAt, startsAt) || other.startsAt == startsAt)&&(identical(other.totalKm, totalKm) || other.totalKm == totalKm)&&(identical(other.focus, focus) || other.focus == focus)&&(identical(other.coachNotes, coachNotes) || other.coachNotes == coachNotes)&&const DeepCollectionEquality().equals(other.trainingDays, trainingDays)&&const DeepCollectionEquality().equals(other.unplannedRuns, unplannedRuns));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,goalId,weekNumber,startsAt,totalKm,focus,coachNotes,const DeepCollectionEquality().hash(trainingDays),const DeepCollectionEquality().hash(unplannedRuns));

@override
String toString() {
  return 'TrainingWeek(id: $id, goalId: $goalId, weekNumber: $weekNumber, startsAt: $startsAt, totalKm: $totalKm, focus: $focus, coachNotes: $coachNotes, trainingDays: $trainingDays, unplannedRuns: $unplannedRuns)';
}


}

/// @nodoc
abstract mixin class $TrainingWeekCopyWith<$Res>  {
  factory $TrainingWeekCopyWith(TrainingWeek value, $Res Function(TrainingWeek) _then) = _$TrainingWeekCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'goal_id') int goalId,@JsonKey(name: 'week_number') int weekNumber,@JsonKey(name: 'starts_at') String startsAt,@JsonKey(name: 'total_km', fromJson: toDouble) double totalKm, String focus,@JsonKey(name: 'coach_notes') String? coachNotes,@JsonKey(name: 'training_days') List<TrainingDay>? trainingDays,@JsonKey(name: 'unplanned_runs') List<WearableActivitySummary>? unplannedRuns
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
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? goalId = null,Object? weekNumber = null,Object? startsAt = null,Object? totalKm = null,Object? focus = null,Object? coachNotes = freezed,Object? trainingDays = freezed,Object? unplannedRuns = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,goalId: null == goalId ? _self.goalId : goalId // ignore: cast_nullable_to_non_nullable
as int,weekNumber: null == weekNumber ? _self.weekNumber : weekNumber // ignore: cast_nullable_to_non_nullable
as int,startsAt: null == startsAt ? _self.startsAt : startsAt // ignore: cast_nullable_to_non_nullable
as String,totalKm: null == totalKm ? _self.totalKm : totalKm // ignore: cast_nullable_to_non_nullable
as double,focus: null == focus ? _self.focus : focus // ignore: cast_nullable_to_non_nullable
as String,coachNotes: freezed == coachNotes ? _self.coachNotes : coachNotes // ignore: cast_nullable_to_non_nullable
as String?,trainingDays: freezed == trainingDays ? _self.trainingDays : trainingDays // ignore: cast_nullable_to_non_nullable
as List<TrainingDay>?,unplannedRuns: freezed == unplannedRuns ? _self.unplannedRuns : unplannedRuns // ignore: cast_nullable_to_non_nullable
as List<WearableActivitySummary>?,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'goal_id')  int goalId, @JsonKey(name: 'week_number')  int weekNumber, @JsonKey(name: 'starts_at')  String startsAt, @JsonKey(name: 'total_km', fromJson: toDouble)  double totalKm,  String focus, @JsonKey(name: 'coach_notes')  String? coachNotes, @JsonKey(name: 'training_days')  List<TrainingDay>? trainingDays, @JsonKey(name: 'unplanned_runs')  List<WearableActivitySummary>? unplannedRuns)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TrainingWeek() when $default != null:
return $default(_that.id,_that.goalId,_that.weekNumber,_that.startsAt,_that.totalKm,_that.focus,_that.coachNotes,_that.trainingDays,_that.unplannedRuns);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'goal_id')  int goalId, @JsonKey(name: 'week_number')  int weekNumber, @JsonKey(name: 'starts_at')  String startsAt, @JsonKey(name: 'total_km', fromJson: toDouble)  double totalKm,  String focus, @JsonKey(name: 'coach_notes')  String? coachNotes, @JsonKey(name: 'training_days')  List<TrainingDay>? trainingDays, @JsonKey(name: 'unplanned_runs')  List<WearableActivitySummary>? unplannedRuns)  $default,) {final _that = this;
switch (_that) {
case _TrainingWeek():
return $default(_that.id,_that.goalId,_that.weekNumber,_that.startsAt,_that.totalKm,_that.focus,_that.coachNotes,_that.trainingDays,_that.unplannedRuns);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(name: 'goal_id')  int goalId, @JsonKey(name: 'week_number')  int weekNumber, @JsonKey(name: 'starts_at')  String startsAt, @JsonKey(name: 'total_km', fromJson: toDouble)  double totalKm,  String focus, @JsonKey(name: 'coach_notes')  String? coachNotes, @JsonKey(name: 'training_days')  List<TrainingDay>? trainingDays, @JsonKey(name: 'unplanned_runs')  List<WearableActivitySummary>? unplannedRuns)?  $default,) {final _that = this;
switch (_that) {
case _TrainingWeek() when $default != null:
return $default(_that.id,_that.goalId,_that.weekNumber,_that.startsAt,_that.totalKm,_that.focus,_that.coachNotes,_that.trainingDays,_that.unplannedRuns);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TrainingWeek implements TrainingWeek {
  const _TrainingWeek({required this.id, @JsonKey(name: 'goal_id') required this.goalId, @JsonKey(name: 'week_number') required this.weekNumber, @JsonKey(name: 'starts_at') required this.startsAt, @JsonKey(name: 'total_km', fromJson: toDouble) required this.totalKm, required this.focus, @JsonKey(name: 'coach_notes') this.coachNotes, @JsonKey(name: 'training_days') final  List<TrainingDay>? trainingDays, @JsonKey(name: 'unplanned_runs') final  List<WearableActivitySummary>? unplannedRuns}): _trainingDays = trainingDays,_unplannedRuns = unplannedRuns;
  factory _TrainingWeek.fromJson(Map<String, dynamic> json) => _$TrainingWeekFromJson(json);

@override final  int id;
@override@JsonKey(name: 'goal_id') final  int goalId;
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

/// Runs that fell within this week but matched no planned session
/// ("buiten schema"). Surfaced as blue tiles the runner can link.
 final  List<WearableActivitySummary>? _unplannedRuns;
/// Runs that fell within this week but matched no planned session
/// ("buiten schema"). Surfaced as blue tiles the runner can link.
@override@JsonKey(name: 'unplanned_runs') List<WearableActivitySummary>? get unplannedRuns {
  final value = _unplannedRuns;
  if (value == null) return null;
  if (_unplannedRuns is EqualUnmodifiableListView) return _unplannedRuns;
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TrainingWeek&&(identical(other.id, id) || other.id == id)&&(identical(other.goalId, goalId) || other.goalId == goalId)&&(identical(other.weekNumber, weekNumber) || other.weekNumber == weekNumber)&&(identical(other.startsAt, startsAt) || other.startsAt == startsAt)&&(identical(other.totalKm, totalKm) || other.totalKm == totalKm)&&(identical(other.focus, focus) || other.focus == focus)&&(identical(other.coachNotes, coachNotes) || other.coachNotes == coachNotes)&&const DeepCollectionEquality().equals(other._trainingDays, _trainingDays)&&const DeepCollectionEquality().equals(other._unplannedRuns, _unplannedRuns));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,goalId,weekNumber,startsAt,totalKm,focus,coachNotes,const DeepCollectionEquality().hash(_trainingDays),const DeepCollectionEquality().hash(_unplannedRuns));

@override
String toString() {
  return 'TrainingWeek(id: $id, goalId: $goalId, weekNumber: $weekNumber, startsAt: $startsAt, totalKm: $totalKm, focus: $focus, coachNotes: $coachNotes, trainingDays: $trainingDays, unplannedRuns: $unplannedRuns)';
}


}

/// @nodoc
abstract mixin class _$TrainingWeekCopyWith<$Res> implements $TrainingWeekCopyWith<$Res> {
  factory _$TrainingWeekCopyWith(_TrainingWeek value, $Res Function(_TrainingWeek) _then) = __$TrainingWeekCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'goal_id') int goalId,@JsonKey(name: 'week_number') int weekNumber,@JsonKey(name: 'starts_at') String startsAt,@JsonKey(name: 'total_km', fromJson: toDouble) double totalKm, String focus,@JsonKey(name: 'coach_notes') String? coachNotes,@JsonKey(name: 'training_days') List<TrainingDay>? trainingDays,@JsonKey(name: 'unplanned_runs') List<WearableActivitySummary>? unplannedRuns
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? goalId = null,Object? weekNumber = null,Object? startsAt = null,Object? totalKm = null,Object? focus = null,Object? coachNotes = freezed,Object? trainingDays = freezed,Object? unplannedRuns = freezed,}) {
  return _then(_TrainingWeek(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,goalId: null == goalId ? _self.goalId : goalId // ignore: cast_nullable_to_non_nullable
as int,weekNumber: null == weekNumber ? _self.weekNumber : weekNumber // ignore: cast_nullable_to_non_nullable
as int,startsAt: null == startsAt ? _self.startsAt : startsAt // ignore: cast_nullable_to_non_nullable
as String,totalKm: null == totalKm ? _self.totalKm : totalKm // ignore: cast_nullable_to_non_nullable
as double,focus: null == focus ? _self.focus : focus // ignore: cast_nullable_to_non_nullable
as String,coachNotes: freezed == coachNotes ? _self.coachNotes : coachNotes // ignore: cast_nullable_to_non_nullable
as String?,trainingDays: freezed == trainingDays ? _self._trainingDays : trainingDays // ignore: cast_nullable_to_non_nullable
as List<TrainingDay>?,unplannedRuns: freezed == unplannedRuns ? _self._unplannedRuns : unplannedRuns // ignore: cast_nullable_to_non_nullable
as List<WearableActivitySummary>?,
  ));
}


}

// dart format on
