// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'onboarding_form_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$OnboardingFormData {

@JsonKey(name: 'goal_type') OnboardingGoalType? get goalType;@JsonKey(name: 'goal_name') String? get goalName;@JsonKey(name: 'distance_meters') int? get distanceMeters;@JsonKey(name: 'target_date') String? get targetDate;// YYYY-MM-DD
@JsonKey(name: 'goal_time_seconds') int? get goalTimeSeconds;@JsonKey(name: 'pr_current_seconds') int? get prCurrentSeconds;@JsonKey(name: 'days_per_week') int? get daysPerWeek;@JsonKey(name: 'preferred_weekdays') List<int>? get preferredWeekdays;@JsonKey(name: 'coach_style') CoachStyleOption? get coachStyle; String? get notes;@JsonKey(name: 'additional_notes') String? get additionalNotes;
/// Create a copy of OnboardingFormData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OnboardingFormDataCopyWith<OnboardingFormData> get copyWith => _$OnboardingFormDataCopyWithImpl<OnboardingFormData>(this as OnboardingFormData, _$identity);

  /// Serializes this OnboardingFormData to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OnboardingFormData&&(identical(other.goalType, goalType) || other.goalType == goalType)&&(identical(other.goalName, goalName) || other.goalName == goalName)&&(identical(other.distanceMeters, distanceMeters) || other.distanceMeters == distanceMeters)&&(identical(other.targetDate, targetDate) || other.targetDate == targetDate)&&(identical(other.goalTimeSeconds, goalTimeSeconds) || other.goalTimeSeconds == goalTimeSeconds)&&(identical(other.prCurrentSeconds, prCurrentSeconds) || other.prCurrentSeconds == prCurrentSeconds)&&(identical(other.daysPerWeek, daysPerWeek) || other.daysPerWeek == daysPerWeek)&&const DeepCollectionEquality().equals(other.preferredWeekdays, preferredWeekdays)&&(identical(other.coachStyle, coachStyle) || other.coachStyle == coachStyle)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.additionalNotes, additionalNotes) || other.additionalNotes == additionalNotes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,goalType,goalName,distanceMeters,targetDate,goalTimeSeconds,prCurrentSeconds,daysPerWeek,const DeepCollectionEquality().hash(preferredWeekdays),coachStyle,notes,additionalNotes);

@override
String toString() {
  return 'OnboardingFormData(goalType: $goalType, goalName: $goalName, distanceMeters: $distanceMeters, targetDate: $targetDate, goalTimeSeconds: $goalTimeSeconds, prCurrentSeconds: $prCurrentSeconds, daysPerWeek: $daysPerWeek, preferredWeekdays: $preferredWeekdays, coachStyle: $coachStyle, notes: $notes, additionalNotes: $additionalNotes)';
}


}

/// @nodoc
abstract mixin class $OnboardingFormDataCopyWith<$Res>  {
  factory $OnboardingFormDataCopyWith(OnboardingFormData value, $Res Function(OnboardingFormData) _then) = _$OnboardingFormDataCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'goal_type') OnboardingGoalType? goalType,@JsonKey(name: 'goal_name') String? goalName,@JsonKey(name: 'distance_meters') int? distanceMeters,@JsonKey(name: 'target_date') String? targetDate,@JsonKey(name: 'goal_time_seconds') int? goalTimeSeconds,@JsonKey(name: 'pr_current_seconds') int? prCurrentSeconds,@JsonKey(name: 'days_per_week') int? daysPerWeek,@JsonKey(name: 'preferred_weekdays') List<int>? preferredWeekdays,@JsonKey(name: 'coach_style') CoachStyleOption? coachStyle, String? notes,@JsonKey(name: 'additional_notes') String? additionalNotes
});




}
/// @nodoc
class _$OnboardingFormDataCopyWithImpl<$Res>
    implements $OnboardingFormDataCopyWith<$Res> {
  _$OnboardingFormDataCopyWithImpl(this._self, this._then);

  final OnboardingFormData _self;
  final $Res Function(OnboardingFormData) _then;

/// Create a copy of OnboardingFormData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? goalType = freezed,Object? goalName = freezed,Object? distanceMeters = freezed,Object? targetDate = freezed,Object? goalTimeSeconds = freezed,Object? prCurrentSeconds = freezed,Object? daysPerWeek = freezed,Object? preferredWeekdays = freezed,Object? coachStyle = freezed,Object? notes = freezed,Object? additionalNotes = freezed,}) {
  return _then(_self.copyWith(
goalType: freezed == goalType ? _self.goalType : goalType // ignore: cast_nullable_to_non_nullable
as OnboardingGoalType?,goalName: freezed == goalName ? _self.goalName : goalName // ignore: cast_nullable_to_non_nullable
as String?,distanceMeters: freezed == distanceMeters ? _self.distanceMeters : distanceMeters // ignore: cast_nullable_to_non_nullable
as int?,targetDate: freezed == targetDate ? _self.targetDate : targetDate // ignore: cast_nullable_to_non_nullable
as String?,goalTimeSeconds: freezed == goalTimeSeconds ? _self.goalTimeSeconds : goalTimeSeconds // ignore: cast_nullable_to_non_nullable
as int?,prCurrentSeconds: freezed == prCurrentSeconds ? _self.prCurrentSeconds : prCurrentSeconds // ignore: cast_nullable_to_non_nullable
as int?,daysPerWeek: freezed == daysPerWeek ? _self.daysPerWeek : daysPerWeek // ignore: cast_nullable_to_non_nullable
as int?,preferredWeekdays: freezed == preferredWeekdays ? _self.preferredWeekdays : preferredWeekdays // ignore: cast_nullable_to_non_nullable
as List<int>?,coachStyle: freezed == coachStyle ? _self.coachStyle : coachStyle // ignore: cast_nullable_to_non_nullable
as CoachStyleOption?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,additionalNotes: freezed == additionalNotes ? _self.additionalNotes : additionalNotes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [OnboardingFormData].
extension OnboardingFormDataPatterns on OnboardingFormData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OnboardingFormData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OnboardingFormData() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OnboardingFormData value)  $default,){
final _that = this;
switch (_that) {
case _OnboardingFormData():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OnboardingFormData value)?  $default,){
final _that = this;
switch (_that) {
case _OnboardingFormData() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'goal_type')  OnboardingGoalType? goalType, @JsonKey(name: 'goal_name')  String? goalName, @JsonKey(name: 'distance_meters')  int? distanceMeters, @JsonKey(name: 'target_date')  String? targetDate, @JsonKey(name: 'goal_time_seconds')  int? goalTimeSeconds, @JsonKey(name: 'pr_current_seconds')  int? prCurrentSeconds, @JsonKey(name: 'days_per_week')  int? daysPerWeek, @JsonKey(name: 'preferred_weekdays')  List<int>? preferredWeekdays, @JsonKey(name: 'coach_style')  CoachStyleOption? coachStyle,  String? notes, @JsonKey(name: 'additional_notes')  String? additionalNotes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OnboardingFormData() when $default != null:
return $default(_that.goalType,_that.goalName,_that.distanceMeters,_that.targetDate,_that.goalTimeSeconds,_that.prCurrentSeconds,_that.daysPerWeek,_that.preferredWeekdays,_that.coachStyle,_that.notes,_that.additionalNotes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'goal_type')  OnboardingGoalType? goalType, @JsonKey(name: 'goal_name')  String? goalName, @JsonKey(name: 'distance_meters')  int? distanceMeters, @JsonKey(name: 'target_date')  String? targetDate, @JsonKey(name: 'goal_time_seconds')  int? goalTimeSeconds, @JsonKey(name: 'pr_current_seconds')  int? prCurrentSeconds, @JsonKey(name: 'days_per_week')  int? daysPerWeek, @JsonKey(name: 'preferred_weekdays')  List<int>? preferredWeekdays, @JsonKey(name: 'coach_style')  CoachStyleOption? coachStyle,  String? notes, @JsonKey(name: 'additional_notes')  String? additionalNotes)  $default,) {final _that = this;
switch (_that) {
case _OnboardingFormData():
return $default(_that.goalType,_that.goalName,_that.distanceMeters,_that.targetDate,_that.goalTimeSeconds,_that.prCurrentSeconds,_that.daysPerWeek,_that.preferredWeekdays,_that.coachStyle,_that.notes,_that.additionalNotes);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'goal_type')  OnboardingGoalType? goalType, @JsonKey(name: 'goal_name')  String? goalName, @JsonKey(name: 'distance_meters')  int? distanceMeters, @JsonKey(name: 'target_date')  String? targetDate, @JsonKey(name: 'goal_time_seconds')  int? goalTimeSeconds, @JsonKey(name: 'pr_current_seconds')  int? prCurrentSeconds, @JsonKey(name: 'days_per_week')  int? daysPerWeek, @JsonKey(name: 'preferred_weekdays')  List<int>? preferredWeekdays, @JsonKey(name: 'coach_style')  CoachStyleOption? coachStyle,  String? notes, @JsonKey(name: 'additional_notes')  String? additionalNotes)?  $default,) {final _that = this;
switch (_that) {
case _OnboardingFormData() when $default != null:
return $default(_that.goalType,_that.goalName,_that.distanceMeters,_that.targetDate,_that.goalTimeSeconds,_that.prCurrentSeconds,_that.daysPerWeek,_that.preferredWeekdays,_that.coachStyle,_that.notes,_that.additionalNotes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OnboardingFormData implements OnboardingFormData {
  const _OnboardingFormData({@JsonKey(name: 'goal_type') this.goalType, @JsonKey(name: 'goal_name') this.goalName, @JsonKey(name: 'distance_meters') this.distanceMeters, @JsonKey(name: 'target_date') this.targetDate, @JsonKey(name: 'goal_time_seconds') this.goalTimeSeconds, @JsonKey(name: 'pr_current_seconds') this.prCurrentSeconds, @JsonKey(name: 'days_per_week') this.daysPerWeek, @JsonKey(name: 'preferred_weekdays') final  List<int>? preferredWeekdays, @JsonKey(name: 'coach_style') this.coachStyle, this.notes, @JsonKey(name: 'additional_notes') this.additionalNotes}): _preferredWeekdays = preferredWeekdays;
  factory _OnboardingFormData.fromJson(Map<String, dynamic> json) => _$OnboardingFormDataFromJson(json);

@override@JsonKey(name: 'goal_type') final  OnboardingGoalType? goalType;
@override@JsonKey(name: 'goal_name') final  String? goalName;
@override@JsonKey(name: 'distance_meters') final  int? distanceMeters;
@override@JsonKey(name: 'target_date') final  String? targetDate;
// YYYY-MM-DD
@override@JsonKey(name: 'goal_time_seconds') final  int? goalTimeSeconds;
@override@JsonKey(name: 'pr_current_seconds') final  int? prCurrentSeconds;
@override@JsonKey(name: 'days_per_week') final  int? daysPerWeek;
 final  List<int>? _preferredWeekdays;
@override@JsonKey(name: 'preferred_weekdays') List<int>? get preferredWeekdays {
  final value = _preferredWeekdays;
  if (value == null) return null;
  if (_preferredWeekdays is EqualUnmodifiableListView) return _preferredWeekdays;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override@JsonKey(name: 'coach_style') final  CoachStyleOption? coachStyle;
@override final  String? notes;
@override@JsonKey(name: 'additional_notes') final  String? additionalNotes;

/// Create a copy of OnboardingFormData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OnboardingFormDataCopyWith<_OnboardingFormData> get copyWith => __$OnboardingFormDataCopyWithImpl<_OnboardingFormData>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OnboardingFormDataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OnboardingFormData&&(identical(other.goalType, goalType) || other.goalType == goalType)&&(identical(other.goalName, goalName) || other.goalName == goalName)&&(identical(other.distanceMeters, distanceMeters) || other.distanceMeters == distanceMeters)&&(identical(other.targetDate, targetDate) || other.targetDate == targetDate)&&(identical(other.goalTimeSeconds, goalTimeSeconds) || other.goalTimeSeconds == goalTimeSeconds)&&(identical(other.prCurrentSeconds, prCurrentSeconds) || other.prCurrentSeconds == prCurrentSeconds)&&(identical(other.daysPerWeek, daysPerWeek) || other.daysPerWeek == daysPerWeek)&&const DeepCollectionEquality().equals(other._preferredWeekdays, _preferredWeekdays)&&(identical(other.coachStyle, coachStyle) || other.coachStyle == coachStyle)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.additionalNotes, additionalNotes) || other.additionalNotes == additionalNotes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,goalType,goalName,distanceMeters,targetDate,goalTimeSeconds,prCurrentSeconds,daysPerWeek,const DeepCollectionEquality().hash(_preferredWeekdays),coachStyle,notes,additionalNotes);

@override
String toString() {
  return 'OnboardingFormData(goalType: $goalType, goalName: $goalName, distanceMeters: $distanceMeters, targetDate: $targetDate, goalTimeSeconds: $goalTimeSeconds, prCurrentSeconds: $prCurrentSeconds, daysPerWeek: $daysPerWeek, preferredWeekdays: $preferredWeekdays, coachStyle: $coachStyle, notes: $notes, additionalNotes: $additionalNotes)';
}


}

/// @nodoc
abstract mixin class _$OnboardingFormDataCopyWith<$Res> implements $OnboardingFormDataCopyWith<$Res> {
  factory _$OnboardingFormDataCopyWith(_OnboardingFormData value, $Res Function(_OnboardingFormData) _then) = __$OnboardingFormDataCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'goal_type') OnboardingGoalType? goalType,@JsonKey(name: 'goal_name') String? goalName,@JsonKey(name: 'distance_meters') int? distanceMeters,@JsonKey(name: 'target_date') String? targetDate,@JsonKey(name: 'goal_time_seconds') int? goalTimeSeconds,@JsonKey(name: 'pr_current_seconds') int? prCurrentSeconds,@JsonKey(name: 'days_per_week') int? daysPerWeek,@JsonKey(name: 'preferred_weekdays') List<int>? preferredWeekdays,@JsonKey(name: 'coach_style') CoachStyleOption? coachStyle, String? notes,@JsonKey(name: 'additional_notes') String? additionalNotes
});




}
/// @nodoc
class __$OnboardingFormDataCopyWithImpl<$Res>
    implements _$OnboardingFormDataCopyWith<$Res> {
  __$OnboardingFormDataCopyWithImpl(this._self, this._then);

  final _OnboardingFormData _self;
  final $Res Function(_OnboardingFormData) _then;

/// Create a copy of OnboardingFormData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? goalType = freezed,Object? goalName = freezed,Object? distanceMeters = freezed,Object? targetDate = freezed,Object? goalTimeSeconds = freezed,Object? prCurrentSeconds = freezed,Object? daysPerWeek = freezed,Object? preferredWeekdays = freezed,Object? coachStyle = freezed,Object? notes = freezed,Object? additionalNotes = freezed,}) {
  return _then(_OnboardingFormData(
goalType: freezed == goalType ? _self.goalType : goalType // ignore: cast_nullable_to_non_nullable
as OnboardingGoalType?,goalName: freezed == goalName ? _self.goalName : goalName // ignore: cast_nullable_to_non_nullable
as String?,distanceMeters: freezed == distanceMeters ? _self.distanceMeters : distanceMeters // ignore: cast_nullable_to_non_nullable
as int?,targetDate: freezed == targetDate ? _self.targetDate : targetDate // ignore: cast_nullable_to_non_nullable
as String?,goalTimeSeconds: freezed == goalTimeSeconds ? _self.goalTimeSeconds : goalTimeSeconds // ignore: cast_nullable_to_non_nullable
as int?,prCurrentSeconds: freezed == prCurrentSeconds ? _self.prCurrentSeconds : prCurrentSeconds // ignore: cast_nullable_to_non_nullable
as int?,daysPerWeek: freezed == daysPerWeek ? _self.daysPerWeek : daysPerWeek // ignore: cast_nullable_to_non_nullable
as int?,preferredWeekdays: freezed == preferredWeekdays ? _self._preferredWeekdays : preferredWeekdays // ignore: cast_nullable_to_non_nullable
as List<int>?,coachStyle: freezed == coachStyle ? _self.coachStyle : coachStyle // ignore: cast_nullable_to_non_nullable
as CoachStyleOption?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,additionalNotes: freezed == additionalNotes ? _self.additionalNotes : additionalNotes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
