// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'plan_evaluation.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PlanEvaluation {

 int get id;@JsonKey(name: 'user_id') int get userId;@JsonKey(name: 'goal_id') int get goalId;@JsonKey(name: 'training_week_id') int? get trainingWeekId;@JsonKey(name: 'scheduled_for') String get scheduledFor;/// One of: pending, processing, ready, no_change_needed, accepted, dismissed.
 String get status;@JsonKey(name: 'report_markdown') String? get reportMarkdown;@JsonKey(name: 'proposal_id') int? get proposalId;@JsonKey(name: 'notification_id') int? get notificationId;@JsonKey(name: 'triggered_at') String? get triggeredAt;@JsonKey(name: 'completed_at') String? get completedAt;/// Eager-loaded by the detail endpoint — carries the `EditActivePlan`
/// CoachProposal (with `payload`) when `proposalId` is non-null.
 Map<String, dynamic>? get proposal;
/// Create a copy of PlanEvaluation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlanEvaluationCopyWith<PlanEvaluation> get copyWith => _$PlanEvaluationCopyWithImpl<PlanEvaluation>(this as PlanEvaluation, _$identity);

  /// Serializes this PlanEvaluation to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlanEvaluation&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.goalId, goalId) || other.goalId == goalId)&&(identical(other.trainingWeekId, trainingWeekId) || other.trainingWeekId == trainingWeekId)&&(identical(other.scheduledFor, scheduledFor) || other.scheduledFor == scheduledFor)&&(identical(other.status, status) || other.status == status)&&(identical(other.reportMarkdown, reportMarkdown) || other.reportMarkdown == reportMarkdown)&&(identical(other.proposalId, proposalId) || other.proposalId == proposalId)&&(identical(other.notificationId, notificationId) || other.notificationId == notificationId)&&(identical(other.triggeredAt, triggeredAt) || other.triggeredAt == triggeredAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&const DeepCollectionEquality().equals(other.proposal, proposal));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,goalId,trainingWeekId,scheduledFor,status,reportMarkdown,proposalId,notificationId,triggeredAt,completedAt,const DeepCollectionEquality().hash(proposal));

@override
String toString() {
  return 'PlanEvaluation(id: $id, userId: $userId, goalId: $goalId, trainingWeekId: $trainingWeekId, scheduledFor: $scheduledFor, status: $status, reportMarkdown: $reportMarkdown, proposalId: $proposalId, notificationId: $notificationId, triggeredAt: $triggeredAt, completedAt: $completedAt, proposal: $proposal)';
}


}

/// @nodoc
abstract mixin class $PlanEvaluationCopyWith<$Res>  {
  factory $PlanEvaluationCopyWith(PlanEvaluation value, $Res Function(PlanEvaluation) _then) = _$PlanEvaluationCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'user_id') int userId,@JsonKey(name: 'goal_id') int goalId,@JsonKey(name: 'training_week_id') int? trainingWeekId,@JsonKey(name: 'scheduled_for') String scheduledFor, String status,@JsonKey(name: 'report_markdown') String? reportMarkdown,@JsonKey(name: 'proposal_id') int? proposalId,@JsonKey(name: 'notification_id') int? notificationId,@JsonKey(name: 'triggered_at') String? triggeredAt,@JsonKey(name: 'completed_at') String? completedAt, Map<String, dynamic>? proposal
});




}
/// @nodoc
class _$PlanEvaluationCopyWithImpl<$Res>
    implements $PlanEvaluationCopyWith<$Res> {
  _$PlanEvaluationCopyWithImpl(this._self, this._then);

  final PlanEvaluation _self;
  final $Res Function(PlanEvaluation) _then;

/// Create a copy of PlanEvaluation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? goalId = null,Object? trainingWeekId = freezed,Object? scheduledFor = null,Object? status = null,Object? reportMarkdown = freezed,Object? proposalId = freezed,Object? notificationId = freezed,Object? triggeredAt = freezed,Object? completedAt = freezed,Object? proposal = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as int,goalId: null == goalId ? _self.goalId : goalId // ignore: cast_nullable_to_non_nullable
as int,trainingWeekId: freezed == trainingWeekId ? _self.trainingWeekId : trainingWeekId // ignore: cast_nullable_to_non_nullable
as int?,scheduledFor: null == scheduledFor ? _self.scheduledFor : scheduledFor // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,reportMarkdown: freezed == reportMarkdown ? _self.reportMarkdown : reportMarkdown // ignore: cast_nullable_to_non_nullable
as String?,proposalId: freezed == proposalId ? _self.proposalId : proposalId // ignore: cast_nullable_to_non_nullable
as int?,notificationId: freezed == notificationId ? _self.notificationId : notificationId // ignore: cast_nullable_to_non_nullable
as int?,triggeredAt: freezed == triggeredAt ? _self.triggeredAt : triggeredAt // ignore: cast_nullable_to_non_nullable
as String?,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as String?,proposal: freezed == proposal ? _self.proposal : proposal // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}

}


/// Adds pattern-matching-related methods to [PlanEvaluation].
extension PlanEvaluationPatterns on PlanEvaluation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlanEvaluation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlanEvaluation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlanEvaluation value)  $default,){
final _that = this;
switch (_that) {
case _PlanEvaluation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlanEvaluation value)?  $default,){
final _that = this;
switch (_that) {
case _PlanEvaluation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'user_id')  int userId, @JsonKey(name: 'goal_id')  int goalId, @JsonKey(name: 'training_week_id')  int? trainingWeekId, @JsonKey(name: 'scheduled_for')  String scheduledFor,  String status, @JsonKey(name: 'report_markdown')  String? reportMarkdown, @JsonKey(name: 'proposal_id')  int? proposalId, @JsonKey(name: 'notification_id')  int? notificationId, @JsonKey(name: 'triggered_at')  String? triggeredAt, @JsonKey(name: 'completed_at')  String? completedAt,  Map<String, dynamic>? proposal)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlanEvaluation() when $default != null:
return $default(_that.id,_that.userId,_that.goalId,_that.trainingWeekId,_that.scheduledFor,_that.status,_that.reportMarkdown,_that.proposalId,_that.notificationId,_that.triggeredAt,_that.completedAt,_that.proposal);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'user_id')  int userId, @JsonKey(name: 'goal_id')  int goalId, @JsonKey(name: 'training_week_id')  int? trainingWeekId, @JsonKey(name: 'scheduled_for')  String scheduledFor,  String status, @JsonKey(name: 'report_markdown')  String? reportMarkdown, @JsonKey(name: 'proposal_id')  int? proposalId, @JsonKey(name: 'notification_id')  int? notificationId, @JsonKey(name: 'triggered_at')  String? triggeredAt, @JsonKey(name: 'completed_at')  String? completedAt,  Map<String, dynamic>? proposal)  $default,) {final _that = this;
switch (_that) {
case _PlanEvaluation():
return $default(_that.id,_that.userId,_that.goalId,_that.trainingWeekId,_that.scheduledFor,_that.status,_that.reportMarkdown,_that.proposalId,_that.notificationId,_that.triggeredAt,_that.completedAt,_that.proposal);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(name: 'user_id')  int userId, @JsonKey(name: 'goal_id')  int goalId, @JsonKey(name: 'training_week_id')  int? trainingWeekId, @JsonKey(name: 'scheduled_for')  String scheduledFor,  String status, @JsonKey(name: 'report_markdown')  String? reportMarkdown, @JsonKey(name: 'proposal_id')  int? proposalId, @JsonKey(name: 'notification_id')  int? notificationId, @JsonKey(name: 'triggered_at')  String? triggeredAt, @JsonKey(name: 'completed_at')  String? completedAt,  Map<String, dynamic>? proposal)?  $default,) {final _that = this;
switch (_that) {
case _PlanEvaluation() when $default != null:
return $default(_that.id,_that.userId,_that.goalId,_that.trainingWeekId,_that.scheduledFor,_that.status,_that.reportMarkdown,_that.proposalId,_that.notificationId,_that.triggeredAt,_that.completedAt,_that.proposal);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlanEvaluation implements PlanEvaluation {
  const _PlanEvaluation({required this.id, @JsonKey(name: 'user_id') required this.userId, @JsonKey(name: 'goal_id') required this.goalId, @JsonKey(name: 'training_week_id') this.trainingWeekId, @JsonKey(name: 'scheduled_for') required this.scheduledFor, required this.status, @JsonKey(name: 'report_markdown') this.reportMarkdown, @JsonKey(name: 'proposal_id') this.proposalId, @JsonKey(name: 'notification_id') this.notificationId, @JsonKey(name: 'triggered_at') this.triggeredAt, @JsonKey(name: 'completed_at') this.completedAt, final  Map<String, dynamic>? proposal}): _proposal = proposal;
  factory _PlanEvaluation.fromJson(Map<String, dynamic> json) => _$PlanEvaluationFromJson(json);

@override final  int id;
@override@JsonKey(name: 'user_id') final  int userId;
@override@JsonKey(name: 'goal_id') final  int goalId;
@override@JsonKey(name: 'training_week_id') final  int? trainingWeekId;
@override@JsonKey(name: 'scheduled_for') final  String scheduledFor;
/// One of: pending, processing, ready, no_change_needed, accepted, dismissed.
@override final  String status;
@override@JsonKey(name: 'report_markdown') final  String? reportMarkdown;
@override@JsonKey(name: 'proposal_id') final  int? proposalId;
@override@JsonKey(name: 'notification_id') final  int? notificationId;
@override@JsonKey(name: 'triggered_at') final  String? triggeredAt;
@override@JsonKey(name: 'completed_at') final  String? completedAt;
/// Eager-loaded by the detail endpoint — carries the `EditActivePlan`
/// CoachProposal (with `payload`) when `proposalId` is non-null.
 final  Map<String, dynamic>? _proposal;
/// Eager-loaded by the detail endpoint — carries the `EditActivePlan`
/// CoachProposal (with `payload`) when `proposalId` is non-null.
@override Map<String, dynamic>? get proposal {
  final value = _proposal;
  if (value == null) return null;
  if (_proposal is EqualUnmodifiableMapView) return _proposal;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of PlanEvaluation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlanEvaluationCopyWith<_PlanEvaluation> get copyWith => __$PlanEvaluationCopyWithImpl<_PlanEvaluation>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlanEvaluationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlanEvaluation&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.goalId, goalId) || other.goalId == goalId)&&(identical(other.trainingWeekId, trainingWeekId) || other.trainingWeekId == trainingWeekId)&&(identical(other.scheduledFor, scheduledFor) || other.scheduledFor == scheduledFor)&&(identical(other.status, status) || other.status == status)&&(identical(other.reportMarkdown, reportMarkdown) || other.reportMarkdown == reportMarkdown)&&(identical(other.proposalId, proposalId) || other.proposalId == proposalId)&&(identical(other.notificationId, notificationId) || other.notificationId == notificationId)&&(identical(other.triggeredAt, triggeredAt) || other.triggeredAt == triggeredAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&const DeepCollectionEquality().equals(other._proposal, _proposal));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,goalId,trainingWeekId,scheduledFor,status,reportMarkdown,proposalId,notificationId,triggeredAt,completedAt,const DeepCollectionEquality().hash(_proposal));

@override
String toString() {
  return 'PlanEvaluation(id: $id, userId: $userId, goalId: $goalId, trainingWeekId: $trainingWeekId, scheduledFor: $scheduledFor, status: $status, reportMarkdown: $reportMarkdown, proposalId: $proposalId, notificationId: $notificationId, triggeredAt: $triggeredAt, completedAt: $completedAt, proposal: $proposal)';
}


}

/// @nodoc
abstract mixin class _$PlanEvaluationCopyWith<$Res> implements $PlanEvaluationCopyWith<$Res> {
  factory _$PlanEvaluationCopyWith(_PlanEvaluation value, $Res Function(_PlanEvaluation) _then) = __$PlanEvaluationCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'user_id') int userId,@JsonKey(name: 'goal_id') int goalId,@JsonKey(name: 'training_week_id') int? trainingWeekId,@JsonKey(name: 'scheduled_for') String scheduledFor, String status,@JsonKey(name: 'report_markdown') String? reportMarkdown,@JsonKey(name: 'proposal_id') int? proposalId,@JsonKey(name: 'notification_id') int? notificationId,@JsonKey(name: 'triggered_at') String? triggeredAt,@JsonKey(name: 'completed_at') String? completedAt, Map<String, dynamic>? proposal
});




}
/// @nodoc
class __$PlanEvaluationCopyWithImpl<$Res>
    implements _$PlanEvaluationCopyWith<$Res> {
  __$PlanEvaluationCopyWithImpl(this._self, this._then);

  final _PlanEvaluation _self;
  final $Res Function(_PlanEvaluation) _then;

/// Create a copy of PlanEvaluation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? goalId = null,Object? trainingWeekId = freezed,Object? scheduledFor = null,Object? status = null,Object? reportMarkdown = freezed,Object? proposalId = freezed,Object? notificationId = freezed,Object? triggeredAt = freezed,Object? completedAt = freezed,Object? proposal = freezed,}) {
  return _then(_PlanEvaluation(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as int,goalId: null == goalId ? _self.goalId : goalId // ignore: cast_nullable_to_non_nullable
as int,trainingWeekId: freezed == trainingWeekId ? _self.trainingWeekId : trainingWeekId // ignore: cast_nullable_to_non_nullable
as int?,scheduledFor: null == scheduledFor ? _self.scheduledFor : scheduledFor // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,reportMarkdown: freezed == reportMarkdown ? _self.reportMarkdown : reportMarkdown // ignore: cast_nullable_to_non_nullable
as String?,proposalId: freezed == proposalId ? _self.proposalId : proposalId // ignore: cast_nullable_to_non_nullable
as int?,notificationId: freezed == notificationId ? _self.notificationId : notificationId // ignore: cast_nullable_to_non_nullable
as int?,triggeredAt: freezed == triggeredAt ? _self.triggeredAt : triggeredAt // ignore: cast_nullable_to_non_nullable
as String?,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as String?,proposal: freezed == proposal ? _self._proposal : proposal // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}


}

// dart format on
