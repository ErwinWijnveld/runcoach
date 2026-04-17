// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'dashboard_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DashboardData {

@JsonKey(name: 'weekly_summary') WeeklySummary? get weeklySummary;@JsonKey(name: 'next_training') TrainingDay? get nextTraining;@JsonKey(name: 'active_goal') ActiveGoalSummary? get activeGoal;@JsonKey(name: 'coach_insight') String? get coachInsight;
/// Create a copy of DashboardData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DashboardDataCopyWith<DashboardData> get copyWith => _$DashboardDataCopyWithImpl<DashboardData>(this as DashboardData, _$identity);

  /// Serializes this DashboardData to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DashboardData&&(identical(other.weeklySummary, weeklySummary) || other.weeklySummary == weeklySummary)&&(identical(other.nextTraining, nextTraining) || other.nextTraining == nextTraining)&&(identical(other.activeGoal, activeGoal) || other.activeGoal == activeGoal)&&(identical(other.coachInsight, coachInsight) || other.coachInsight == coachInsight));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,weeklySummary,nextTraining,activeGoal,coachInsight);

@override
String toString() {
  return 'DashboardData(weeklySummary: $weeklySummary, nextTraining: $nextTraining, activeGoal: $activeGoal, coachInsight: $coachInsight)';
}


}

/// @nodoc
abstract mixin class $DashboardDataCopyWith<$Res>  {
  factory $DashboardDataCopyWith(DashboardData value, $Res Function(DashboardData) _then) = _$DashboardDataCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'weekly_summary') WeeklySummary? weeklySummary,@JsonKey(name: 'next_training') TrainingDay? nextTraining,@JsonKey(name: 'active_goal') ActiveGoalSummary? activeGoal,@JsonKey(name: 'coach_insight') String? coachInsight
});


$WeeklySummaryCopyWith<$Res>? get weeklySummary;$TrainingDayCopyWith<$Res>? get nextTraining;$ActiveGoalSummaryCopyWith<$Res>? get activeGoal;

}
/// @nodoc
class _$DashboardDataCopyWithImpl<$Res>
    implements $DashboardDataCopyWith<$Res> {
  _$DashboardDataCopyWithImpl(this._self, this._then);

  final DashboardData _self;
  final $Res Function(DashboardData) _then;

/// Create a copy of DashboardData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? weeklySummary = freezed,Object? nextTraining = freezed,Object? activeGoal = freezed,Object? coachInsight = freezed,}) {
  return _then(_self.copyWith(
weeklySummary: freezed == weeklySummary ? _self.weeklySummary : weeklySummary // ignore: cast_nullable_to_non_nullable
as WeeklySummary?,nextTraining: freezed == nextTraining ? _self.nextTraining : nextTraining // ignore: cast_nullable_to_non_nullable
as TrainingDay?,activeGoal: freezed == activeGoal ? _self.activeGoal : activeGoal // ignore: cast_nullable_to_non_nullable
as ActiveGoalSummary?,coachInsight: freezed == coachInsight ? _self.coachInsight : coachInsight // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of DashboardData
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WeeklySummaryCopyWith<$Res>? get weeklySummary {
    if (_self.weeklySummary == null) {
    return null;
  }

  return $WeeklySummaryCopyWith<$Res>(_self.weeklySummary!, (value) {
    return _then(_self.copyWith(weeklySummary: value));
  });
}/// Create a copy of DashboardData
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TrainingDayCopyWith<$Res>? get nextTraining {
    if (_self.nextTraining == null) {
    return null;
  }

  return $TrainingDayCopyWith<$Res>(_self.nextTraining!, (value) {
    return _then(_self.copyWith(nextTraining: value));
  });
}/// Create a copy of DashboardData
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ActiveGoalSummaryCopyWith<$Res>? get activeGoal {
    if (_self.activeGoal == null) {
    return null;
  }

  return $ActiveGoalSummaryCopyWith<$Res>(_self.activeGoal!, (value) {
    return _then(_self.copyWith(activeGoal: value));
  });
}
}


/// Adds pattern-matching-related methods to [DashboardData].
extension DashboardDataPatterns on DashboardData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DashboardData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DashboardData() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DashboardData value)  $default,){
final _that = this;
switch (_that) {
case _DashboardData():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DashboardData value)?  $default,){
final _that = this;
switch (_that) {
case _DashboardData() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'weekly_summary')  WeeklySummary? weeklySummary, @JsonKey(name: 'next_training')  TrainingDay? nextTraining, @JsonKey(name: 'active_goal')  ActiveGoalSummary? activeGoal, @JsonKey(name: 'coach_insight')  String? coachInsight)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DashboardData() when $default != null:
return $default(_that.weeklySummary,_that.nextTraining,_that.activeGoal,_that.coachInsight);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'weekly_summary')  WeeklySummary? weeklySummary, @JsonKey(name: 'next_training')  TrainingDay? nextTraining, @JsonKey(name: 'active_goal')  ActiveGoalSummary? activeGoal, @JsonKey(name: 'coach_insight')  String? coachInsight)  $default,) {final _that = this;
switch (_that) {
case _DashboardData():
return $default(_that.weeklySummary,_that.nextTraining,_that.activeGoal,_that.coachInsight);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'weekly_summary')  WeeklySummary? weeklySummary, @JsonKey(name: 'next_training')  TrainingDay? nextTraining, @JsonKey(name: 'active_goal')  ActiveGoalSummary? activeGoal, @JsonKey(name: 'coach_insight')  String? coachInsight)?  $default,) {final _that = this;
switch (_that) {
case _DashboardData() when $default != null:
return $default(_that.weeklySummary,_that.nextTraining,_that.activeGoal,_that.coachInsight);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DashboardData implements DashboardData {
  const _DashboardData({@JsonKey(name: 'weekly_summary') this.weeklySummary, @JsonKey(name: 'next_training') this.nextTraining, @JsonKey(name: 'active_goal') this.activeGoal, @JsonKey(name: 'coach_insight') this.coachInsight});
  factory _DashboardData.fromJson(Map<String, dynamic> json) => _$DashboardDataFromJson(json);

@override@JsonKey(name: 'weekly_summary') final  WeeklySummary? weeklySummary;
@override@JsonKey(name: 'next_training') final  TrainingDay? nextTraining;
@override@JsonKey(name: 'active_goal') final  ActiveGoalSummary? activeGoal;
@override@JsonKey(name: 'coach_insight') final  String? coachInsight;

/// Create a copy of DashboardData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DashboardDataCopyWith<_DashboardData> get copyWith => __$DashboardDataCopyWithImpl<_DashboardData>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DashboardDataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DashboardData&&(identical(other.weeklySummary, weeklySummary) || other.weeklySummary == weeklySummary)&&(identical(other.nextTraining, nextTraining) || other.nextTraining == nextTraining)&&(identical(other.activeGoal, activeGoal) || other.activeGoal == activeGoal)&&(identical(other.coachInsight, coachInsight) || other.coachInsight == coachInsight));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,weeklySummary,nextTraining,activeGoal,coachInsight);

@override
String toString() {
  return 'DashboardData(weeklySummary: $weeklySummary, nextTraining: $nextTraining, activeGoal: $activeGoal, coachInsight: $coachInsight)';
}


}

/// @nodoc
abstract mixin class _$DashboardDataCopyWith<$Res> implements $DashboardDataCopyWith<$Res> {
  factory _$DashboardDataCopyWith(_DashboardData value, $Res Function(_DashboardData) _then) = __$DashboardDataCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'weekly_summary') WeeklySummary? weeklySummary,@JsonKey(name: 'next_training') TrainingDay? nextTraining,@JsonKey(name: 'active_goal') ActiveGoalSummary? activeGoal,@JsonKey(name: 'coach_insight') String? coachInsight
});


@override $WeeklySummaryCopyWith<$Res>? get weeklySummary;@override $TrainingDayCopyWith<$Res>? get nextTraining;@override $ActiveGoalSummaryCopyWith<$Res>? get activeGoal;

}
/// @nodoc
class __$DashboardDataCopyWithImpl<$Res>
    implements _$DashboardDataCopyWith<$Res> {
  __$DashboardDataCopyWithImpl(this._self, this._then);

  final _DashboardData _self;
  final $Res Function(_DashboardData) _then;

/// Create a copy of DashboardData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? weeklySummary = freezed,Object? nextTraining = freezed,Object? activeGoal = freezed,Object? coachInsight = freezed,}) {
  return _then(_DashboardData(
weeklySummary: freezed == weeklySummary ? _self.weeklySummary : weeklySummary // ignore: cast_nullable_to_non_nullable
as WeeklySummary?,nextTraining: freezed == nextTraining ? _self.nextTraining : nextTraining // ignore: cast_nullable_to_non_nullable
as TrainingDay?,activeGoal: freezed == activeGoal ? _self.activeGoal : activeGoal // ignore: cast_nullable_to_non_nullable
as ActiveGoalSummary?,coachInsight: freezed == coachInsight ? _self.coachInsight : coachInsight // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of DashboardData
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WeeklySummaryCopyWith<$Res>? get weeklySummary {
    if (_self.weeklySummary == null) {
    return null;
  }

  return $WeeklySummaryCopyWith<$Res>(_self.weeklySummary!, (value) {
    return _then(_self.copyWith(weeklySummary: value));
  });
}/// Create a copy of DashboardData
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TrainingDayCopyWith<$Res>? get nextTraining {
    if (_self.nextTraining == null) {
    return null;
  }

  return $TrainingDayCopyWith<$Res>(_self.nextTraining!, (value) {
    return _then(_self.copyWith(nextTraining: value));
  });
}/// Create a copy of DashboardData
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ActiveGoalSummaryCopyWith<$Res>? get activeGoal {
    if (_self.activeGoal == null) {
    return null;
  }

  return $ActiveGoalSummaryCopyWith<$Res>(_self.activeGoal!, (value) {
    return _then(_self.copyWith(activeGoal: value));
  });
}
}


/// @nodoc
mixin _$WeeklySummary {

@JsonKey(name: 'total_km_planned', fromJson: toDouble) double get totalKmPlanned;@JsonKey(name: 'total_km_completed', fromJson: toDouble) double get totalKmCompleted;@JsonKey(name: 'sessions_completed', fromJson: toInt) int get sessionsCompleted;@JsonKey(name: 'sessions_total', fromJson: toInt) int get sessionsTotal;@JsonKey(name: 'compliance_avg', fromJson: toDoubleOrNull) double? get complianceAvg;
/// Create a copy of WeeklySummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WeeklySummaryCopyWith<WeeklySummary> get copyWith => _$WeeklySummaryCopyWithImpl<WeeklySummary>(this as WeeklySummary, _$identity);

  /// Serializes this WeeklySummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WeeklySummary&&(identical(other.totalKmPlanned, totalKmPlanned) || other.totalKmPlanned == totalKmPlanned)&&(identical(other.totalKmCompleted, totalKmCompleted) || other.totalKmCompleted == totalKmCompleted)&&(identical(other.sessionsCompleted, sessionsCompleted) || other.sessionsCompleted == sessionsCompleted)&&(identical(other.sessionsTotal, sessionsTotal) || other.sessionsTotal == sessionsTotal)&&(identical(other.complianceAvg, complianceAvg) || other.complianceAvg == complianceAvg));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,totalKmPlanned,totalKmCompleted,sessionsCompleted,sessionsTotal,complianceAvg);

@override
String toString() {
  return 'WeeklySummary(totalKmPlanned: $totalKmPlanned, totalKmCompleted: $totalKmCompleted, sessionsCompleted: $sessionsCompleted, sessionsTotal: $sessionsTotal, complianceAvg: $complianceAvg)';
}


}

/// @nodoc
abstract mixin class $WeeklySummaryCopyWith<$Res>  {
  factory $WeeklySummaryCopyWith(WeeklySummary value, $Res Function(WeeklySummary) _then) = _$WeeklySummaryCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'total_km_planned', fromJson: toDouble) double totalKmPlanned,@JsonKey(name: 'total_km_completed', fromJson: toDouble) double totalKmCompleted,@JsonKey(name: 'sessions_completed', fromJson: toInt) int sessionsCompleted,@JsonKey(name: 'sessions_total', fromJson: toInt) int sessionsTotal,@JsonKey(name: 'compliance_avg', fromJson: toDoubleOrNull) double? complianceAvg
});




}
/// @nodoc
class _$WeeklySummaryCopyWithImpl<$Res>
    implements $WeeklySummaryCopyWith<$Res> {
  _$WeeklySummaryCopyWithImpl(this._self, this._then);

  final WeeklySummary _self;
  final $Res Function(WeeklySummary) _then;

/// Create a copy of WeeklySummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? totalKmPlanned = null,Object? totalKmCompleted = null,Object? sessionsCompleted = null,Object? sessionsTotal = null,Object? complianceAvg = freezed,}) {
  return _then(_self.copyWith(
totalKmPlanned: null == totalKmPlanned ? _self.totalKmPlanned : totalKmPlanned // ignore: cast_nullable_to_non_nullable
as double,totalKmCompleted: null == totalKmCompleted ? _self.totalKmCompleted : totalKmCompleted // ignore: cast_nullable_to_non_nullable
as double,sessionsCompleted: null == sessionsCompleted ? _self.sessionsCompleted : sessionsCompleted // ignore: cast_nullable_to_non_nullable
as int,sessionsTotal: null == sessionsTotal ? _self.sessionsTotal : sessionsTotal // ignore: cast_nullable_to_non_nullable
as int,complianceAvg: freezed == complianceAvg ? _self.complianceAvg : complianceAvg // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [WeeklySummary].
extension WeeklySummaryPatterns on WeeklySummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WeeklySummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WeeklySummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WeeklySummary value)  $default,){
final _that = this;
switch (_that) {
case _WeeklySummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WeeklySummary value)?  $default,){
final _that = this;
switch (_that) {
case _WeeklySummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'total_km_planned', fromJson: toDouble)  double totalKmPlanned, @JsonKey(name: 'total_km_completed', fromJson: toDouble)  double totalKmCompleted, @JsonKey(name: 'sessions_completed', fromJson: toInt)  int sessionsCompleted, @JsonKey(name: 'sessions_total', fromJson: toInt)  int sessionsTotal, @JsonKey(name: 'compliance_avg', fromJson: toDoubleOrNull)  double? complianceAvg)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WeeklySummary() when $default != null:
return $default(_that.totalKmPlanned,_that.totalKmCompleted,_that.sessionsCompleted,_that.sessionsTotal,_that.complianceAvg);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'total_km_planned', fromJson: toDouble)  double totalKmPlanned, @JsonKey(name: 'total_km_completed', fromJson: toDouble)  double totalKmCompleted, @JsonKey(name: 'sessions_completed', fromJson: toInt)  int sessionsCompleted, @JsonKey(name: 'sessions_total', fromJson: toInt)  int sessionsTotal, @JsonKey(name: 'compliance_avg', fromJson: toDoubleOrNull)  double? complianceAvg)  $default,) {final _that = this;
switch (_that) {
case _WeeklySummary():
return $default(_that.totalKmPlanned,_that.totalKmCompleted,_that.sessionsCompleted,_that.sessionsTotal,_that.complianceAvg);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'total_km_planned', fromJson: toDouble)  double totalKmPlanned, @JsonKey(name: 'total_km_completed', fromJson: toDouble)  double totalKmCompleted, @JsonKey(name: 'sessions_completed', fromJson: toInt)  int sessionsCompleted, @JsonKey(name: 'sessions_total', fromJson: toInt)  int sessionsTotal, @JsonKey(name: 'compliance_avg', fromJson: toDoubleOrNull)  double? complianceAvg)?  $default,) {final _that = this;
switch (_that) {
case _WeeklySummary() when $default != null:
return $default(_that.totalKmPlanned,_that.totalKmCompleted,_that.sessionsCompleted,_that.sessionsTotal,_that.complianceAvg);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WeeklySummary implements WeeklySummary {
  const _WeeklySummary({@JsonKey(name: 'total_km_planned', fromJson: toDouble) required this.totalKmPlanned, @JsonKey(name: 'total_km_completed', fromJson: toDouble) required this.totalKmCompleted, @JsonKey(name: 'sessions_completed', fromJson: toInt) required this.sessionsCompleted, @JsonKey(name: 'sessions_total', fromJson: toInt) required this.sessionsTotal, @JsonKey(name: 'compliance_avg', fromJson: toDoubleOrNull) this.complianceAvg});
  factory _WeeklySummary.fromJson(Map<String, dynamic> json) => _$WeeklySummaryFromJson(json);

@override@JsonKey(name: 'total_km_planned', fromJson: toDouble) final  double totalKmPlanned;
@override@JsonKey(name: 'total_km_completed', fromJson: toDouble) final  double totalKmCompleted;
@override@JsonKey(name: 'sessions_completed', fromJson: toInt) final  int sessionsCompleted;
@override@JsonKey(name: 'sessions_total', fromJson: toInt) final  int sessionsTotal;
@override@JsonKey(name: 'compliance_avg', fromJson: toDoubleOrNull) final  double? complianceAvg;

/// Create a copy of WeeklySummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WeeklySummaryCopyWith<_WeeklySummary> get copyWith => __$WeeklySummaryCopyWithImpl<_WeeklySummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WeeklySummaryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WeeklySummary&&(identical(other.totalKmPlanned, totalKmPlanned) || other.totalKmPlanned == totalKmPlanned)&&(identical(other.totalKmCompleted, totalKmCompleted) || other.totalKmCompleted == totalKmCompleted)&&(identical(other.sessionsCompleted, sessionsCompleted) || other.sessionsCompleted == sessionsCompleted)&&(identical(other.sessionsTotal, sessionsTotal) || other.sessionsTotal == sessionsTotal)&&(identical(other.complianceAvg, complianceAvg) || other.complianceAvg == complianceAvg));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,totalKmPlanned,totalKmCompleted,sessionsCompleted,sessionsTotal,complianceAvg);

@override
String toString() {
  return 'WeeklySummary(totalKmPlanned: $totalKmPlanned, totalKmCompleted: $totalKmCompleted, sessionsCompleted: $sessionsCompleted, sessionsTotal: $sessionsTotal, complianceAvg: $complianceAvg)';
}


}

/// @nodoc
abstract mixin class _$WeeklySummaryCopyWith<$Res> implements $WeeklySummaryCopyWith<$Res> {
  factory _$WeeklySummaryCopyWith(_WeeklySummary value, $Res Function(_WeeklySummary) _then) = __$WeeklySummaryCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'total_km_planned', fromJson: toDouble) double totalKmPlanned,@JsonKey(name: 'total_km_completed', fromJson: toDouble) double totalKmCompleted,@JsonKey(name: 'sessions_completed', fromJson: toInt) int sessionsCompleted,@JsonKey(name: 'sessions_total', fromJson: toInt) int sessionsTotal,@JsonKey(name: 'compliance_avg', fromJson: toDoubleOrNull) double? complianceAvg
});




}
/// @nodoc
class __$WeeklySummaryCopyWithImpl<$Res>
    implements _$WeeklySummaryCopyWith<$Res> {
  __$WeeklySummaryCopyWithImpl(this._self, this._then);

  final _WeeklySummary _self;
  final $Res Function(_WeeklySummary) _then;

/// Create a copy of WeeklySummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? totalKmPlanned = null,Object? totalKmCompleted = null,Object? sessionsCompleted = null,Object? sessionsTotal = null,Object? complianceAvg = freezed,}) {
  return _then(_WeeklySummary(
totalKmPlanned: null == totalKmPlanned ? _self.totalKmPlanned : totalKmPlanned // ignore: cast_nullable_to_non_nullable
as double,totalKmCompleted: null == totalKmCompleted ? _self.totalKmCompleted : totalKmCompleted // ignore: cast_nullable_to_non_nullable
as double,sessionsCompleted: null == sessionsCompleted ? _self.sessionsCompleted : sessionsCompleted // ignore: cast_nullable_to_non_nullable
as int,sessionsTotal: null == sessionsTotal ? _self.sessionsTotal : sessionsTotal // ignore: cast_nullable_to_non_nullable
as int,complianceAvg: freezed == complianceAvg ? _self.complianceAvg : complianceAvg // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}


/// @nodoc
mixin _$ActiveGoalSummary {

 int get id; String get type; String get name; String? get distance;@JsonKey(name: 'target_date') String? get targetDate;@JsonKey(name: 'weeks_until_target_date', fromJson: toIntOrNull) int? get weeksUntilTargetDate;
/// Create a copy of ActiveGoalSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ActiveGoalSummaryCopyWith<ActiveGoalSummary> get copyWith => _$ActiveGoalSummaryCopyWithImpl<ActiveGoalSummary>(this as ActiveGoalSummary, _$identity);

  /// Serializes this ActiveGoalSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ActiveGoalSummary&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.name, name) || other.name == name)&&(identical(other.distance, distance) || other.distance == distance)&&(identical(other.targetDate, targetDate) || other.targetDate == targetDate)&&(identical(other.weeksUntilTargetDate, weeksUntilTargetDate) || other.weeksUntilTargetDate == weeksUntilTargetDate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,type,name,distance,targetDate,weeksUntilTargetDate);

@override
String toString() {
  return 'ActiveGoalSummary(id: $id, type: $type, name: $name, distance: $distance, targetDate: $targetDate, weeksUntilTargetDate: $weeksUntilTargetDate)';
}


}

/// @nodoc
abstract mixin class $ActiveGoalSummaryCopyWith<$Res>  {
  factory $ActiveGoalSummaryCopyWith(ActiveGoalSummary value, $Res Function(ActiveGoalSummary) _then) = _$ActiveGoalSummaryCopyWithImpl;
@useResult
$Res call({
 int id, String type, String name, String? distance,@JsonKey(name: 'target_date') String? targetDate,@JsonKey(name: 'weeks_until_target_date', fromJson: toIntOrNull) int? weeksUntilTargetDate
});




}
/// @nodoc
class _$ActiveGoalSummaryCopyWithImpl<$Res>
    implements $ActiveGoalSummaryCopyWith<$Res> {
  _$ActiveGoalSummaryCopyWithImpl(this._self, this._then);

  final ActiveGoalSummary _self;
  final $Res Function(ActiveGoalSummary) _then;

/// Create a copy of ActiveGoalSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? type = null,Object? name = null,Object? distance = freezed,Object? targetDate = freezed,Object? weeksUntilTargetDate = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,distance: freezed == distance ? _self.distance : distance // ignore: cast_nullable_to_non_nullable
as String?,targetDate: freezed == targetDate ? _self.targetDate : targetDate // ignore: cast_nullable_to_non_nullable
as String?,weeksUntilTargetDate: freezed == weeksUntilTargetDate ? _self.weeksUntilTargetDate : weeksUntilTargetDate // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [ActiveGoalSummary].
extension ActiveGoalSummaryPatterns on ActiveGoalSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ActiveGoalSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ActiveGoalSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ActiveGoalSummary value)  $default,){
final _that = this;
switch (_that) {
case _ActiveGoalSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ActiveGoalSummary value)?  $default,){
final _that = this;
switch (_that) {
case _ActiveGoalSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String type,  String name,  String? distance, @JsonKey(name: 'target_date')  String? targetDate, @JsonKey(name: 'weeks_until_target_date', fromJson: toIntOrNull)  int? weeksUntilTargetDate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ActiveGoalSummary() when $default != null:
return $default(_that.id,_that.type,_that.name,_that.distance,_that.targetDate,_that.weeksUntilTargetDate);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String type,  String name,  String? distance, @JsonKey(name: 'target_date')  String? targetDate, @JsonKey(name: 'weeks_until_target_date', fromJson: toIntOrNull)  int? weeksUntilTargetDate)  $default,) {final _that = this;
switch (_that) {
case _ActiveGoalSummary():
return $default(_that.id,_that.type,_that.name,_that.distance,_that.targetDate,_that.weeksUntilTargetDate);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String type,  String name,  String? distance, @JsonKey(name: 'target_date')  String? targetDate, @JsonKey(name: 'weeks_until_target_date', fromJson: toIntOrNull)  int? weeksUntilTargetDate)?  $default,) {final _that = this;
switch (_that) {
case _ActiveGoalSummary() when $default != null:
return $default(_that.id,_that.type,_that.name,_that.distance,_that.targetDate,_that.weeksUntilTargetDate);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ActiveGoalSummary implements ActiveGoalSummary {
  const _ActiveGoalSummary({required this.id, required this.type, required this.name, this.distance, @JsonKey(name: 'target_date') this.targetDate, @JsonKey(name: 'weeks_until_target_date', fromJson: toIntOrNull) this.weeksUntilTargetDate});
  factory _ActiveGoalSummary.fromJson(Map<String, dynamic> json) => _$ActiveGoalSummaryFromJson(json);

@override final  int id;
@override final  String type;
@override final  String name;
@override final  String? distance;
@override@JsonKey(name: 'target_date') final  String? targetDate;
@override@JsonKey(name: 'weeks_until_target_date', fromJson: toIntOrNull) final  int? weeksUntilTargetDate;

/// Create a copy of ActiveGoalSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ActiveGoalSummaryCopyWith<_ActiveGoalSummary> get copyWith => __$ActiveGoalSummaryCopyWithImpl<_ActiveGoalSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ActiveGoalSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ActiveGoalSummary&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.name, name) || other.name == name)&&(identical(other.distance, distance) || other.distance == distance)&&(identical(other.targetDate, targetDate) || other.targetDate == targetDate)&&(identical(other.weeksUntilTargetDate, weeksUntilTargetDate) || other.weeksUntilTargetDate == weeksUntilTargetDate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,type,name,distance,targetDate,weeksUntilTargetDate);

@override
String toString() {
  return 'ActiveGoalSummary(id: $id, type: $type, name: $name, distance: $distance, targetDate: $targetDate, weeksUntilTargetDate: $weeksUntilTargetDate)';
}


}

/// @nodoc
abstract mixin class _$ActiveGoalSummaryCopyWith<$Res> implements $ActiveGoalSummaryCopyWith<$Res> {
  factory _$ActiveGoalSummaryCopyWith(_ActiveGoalSummary value, $Res Function(_ActiveGoalSummary) _then) = __$ActiveGoalSummaryCopyWithImpl;
@override @useResult
$Res call({
 int id, String type, String name, String? distance,@JsonKey(name: 'target_date') String? targetDate,@JsonKey(name: 'weeks_until_target_date', fromJson: toIntOrNull) int? weeksUntilTargetDate
});




}
/// @nodoc
class __$ActiveGoalSummaryCopyWithImpl<$Res>
    implements _$ActiveGoalSummaryCopyWith<$Res> {
  __$ActiveGoalSummaryCopyWithImpl(this._self, this._then);

  final _ActiveGoalSummary _self;
  final $Res Function(_ActiveGoalSummary) _then;

/// Create a copy of ActiveGoalSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? type = null,Object? name = null,Object? distance = freezed,Object? targetDate = freezed,Object? weeksUntilTargetDate = freezed,}) {
  return _then(_ActiveGoalSummary(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,distance: freezed == distance ? _self.distance : distance // ignore: cast_nullable_to_non_nullable
as String?,targetDate: freezed == targetDate ? _self.targetDate : targetDate // ignore: cast_nullable_to_non_nullable
as String?,weeksUntilTargetDate: freezed == weeksUntilTargetDate ? _self.weeksUntilTargetDate : weeksUntilTargetDate // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
