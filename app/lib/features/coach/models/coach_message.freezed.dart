// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'coach_message.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CoachMessage {

 String get id; String get role; String get content;@JsonKey(name: 'created_at') String get createdAt; CoachProposal? get proposal;@JsonKey(includeFromJson: false, includeToJson: false) CoachStatsCard? get statsCard;@JsonKey(includeFromJson: false, includeToJson: false) List<CoachChip>? get chips;@JsonKey(includeFromJson: false, includeToJson: false) String? get errorDetail;@JsonKey(includeFromJson: false, includeToJson: false) bool get streaming;@JsonKey(includeFromJson: false, includeToJson: false) String? get toolIndicator;// Set when the workout-scoped agent calls EscalateToCoach. The UI
// renders a tile under this message that opens a fresh coach chat
// pre-seeded with this prompt. Not persisted server-side — the SDK
// stores it in tool_results, but reload doesn't re-display it (the
// hand-off was a one-shot decision; reopening the workout chat
// shouldn't keep nagging).
@JsonKey(includeFromJson: false, includeToJson: false) String? get handoffPrompt;
/// Create a copy of CoachMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CoachMessageCopyWith<CoachMessage> get copyWith => _$CoachMessageCopyWithImpl<CoachMessage>(this as CoachMessage, _$identity);

  /// Serializes this CoachMessage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CoachMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.role, role) || other.role == role)&&(identical(other.content, content) || other.content == content)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.proposal, proposal) || other.proposal == proposal)&&(identical(other.statsCard, statsCard) || other.statsCard == statsCard)&&const DeepCollectionEquality().equals(other.chips, chips)&&(identical(other.errorDetail, errorDetail) || other.errorDetail == errorDetail)&&(identical(other.streaming, streaming) || other.streaming == streaming)&&(identical(other.toolIndicator, toolIndicator) || other.toolIndicator == toolIndicator)&&(identical(other.handoffPrompt, handoffPrompt) || other.handoffPrompt == handoffPrompt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,role,content,createdAt,proposal,statsCard,const DeepCollectionEquality().hash(chips),errorDetail,streaming,toolIndicator,handoffPrompt);

@override
String toString() {
  return 'CoachMessage(id: $id, role: $role, content: $content, createdAt: $createdAt, proposal: $proposal, statsCard: $statsCard, chips: $chips, errorDetail: $errorDetail, streaming: $streaming, toolIndicator: $toolIndicator, handoffPrompt: $handoffPrompt)';
}


}

/// @nodoc
abstract mixin class $CoachMessageCopyWith<$Res>  {
  factory $CoachMessageCopyWith(CoachMessage value, $Res Function(CoachMessage) _then) = _$CoachMessageCopyWithImpl;
@useResult
$Res call({
 String id, String role, String content,@JsonKey(name: 'created_at') String createdAt, CoachProposal? proposal,@JsonKey(includeFromJson: false, includeToJson: false) CoachStatsCard? statsCard,@JsonKey(includeFromJson: false, includeToJson: false) List<CoachChip>? chips,@JsonKey(includeFromJson: false, includeToJson: false) String? errorDetail,@JsonKey(includeFromJson: false, includeToJson: false) bool streaming,@JsonKey(includeFromJson: false, includeToJson: false) String? toolIndicator,@JsonKey(includeFromJson: false, includeToJson: false) String? handoffPrompt
});


$CoachProposalCopyWith<$Res>? get proposal;$CoachStatsCardCopyWith<$Res>? get statsCard;

}
/// @nodoc
class _$CoachMessageCopyWithImpl<$Res>
    implements $CoachMessageCopyWith<$Res> {
  _$CoachMessageCopyWithImpl(this._self, this._then);

  final CoachMessage _self;
  final $Res Function(CoachMessage) _then;

/// Create a copy of CoachMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? role = null,Object? content = null,Object? createdAt = null,Object? proposal = freezed,Object? statsCard = freezed,Object? chips = freezed,Object? errorDetail = freezed,Object? streaming = null,Object? toolIndicator = freezed,Object? handoffPrompt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,proposal: freezed == proposal ? _self.proposal : proposal // ignore: cast_nullable_to_non_nullable
as CoachProposal?,statsCard: freezed == statsCard ? _self.statsCard : statsCard // ignore: cast_nullable_to_non_nullable
as CoachStatsCard?,chips: freezed == chips ? _self.chips : chips // ignore: cast_nullable_to_non_nullable
as List<CoachChip>?,errorDetail: freezed == errorDetail ? _self.errorDetail : errorDetail // ignore: cast_nullable_to_non_nullable
as String?,streaming: null == streaming ? _self.streaming : streaming // ignore: cast_nullable_to_non_nullable
as bool,toolIndicator: freezed == toolIndicator ? _self.toolIndicator : toolIndicator // ignore: cast_nullable_to_non_nullable
as String?,handoffPrompt: freezed == handoffPrompt ? _self.handoffPrompt : handoffPrompt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of CoachMessage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CoachProposalCopyWith<$Res>? get proposal {
    if (_self.proposal == null) {
    return null;
  }

  return $CoachProposalCopyWith<$Res>(_self.proposal!, (value) {
    return _then(_self.copyWith(proposal: value));
  });
}/// Create a copy of CoachMessage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CoachStatsCardCopyWith<$Res>? get statsCard {
    if (_self.statsCard == null) {
    return null;
  }

  return $CoachStatsCardCopyWith<$Res>(_self.statsCard!, (value) {
    return _then(_self.copyWith(statsCard: value));
  });
}
}


/// Adds pattern-matching-related methods to [CoachMessage].
extension CoachMessagePatterns on CoachMessage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CoachMessage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CoachMessage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CoachMessage value)  $default,){
final _that = this;
switch (_that) {
case _CoachMessage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CoachMessage value)?  $default,){
final _that = this;
switch (_that) {
case _CoachMessage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String role,  String content, @JsonKey(name: 'created_at')  String createdAt,  CoachProposal? proposal, @JsonKey(includeFromJson: false, includeToJson: false)  CoachStatsCard? statsCard, @JsonKey(includeFromJson: false, includeToJson: false)  List<CoachChip>? chips, @JsonKey(includeFromJson: false, includeToJson: false)  String? errorDetail, @JsonKey(includeFromJson: false, includeToJson: false)  bool streaming, @JsonKey(includeFromJson: false, includeToJson: false)  String? toolIndicator, @JsonKey(includeFromJson: false, includeToJson: false)  String? handoffPrompt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CoachMessage() when $default != null:
return $default(_that.id,_that.role,_that.content,_that.createdAt,_that.proposal,_that.statsCard,_that.chips,_that.errorDetail,_that.streaming,_that.toolIndicator,_that.handoffPrompt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String role,  String content, @JsonKey(name: 'created_at')  String createdAt,  CoachProposal? proposal, @JsonKey(includeFromJson: false, includeToJson: false)  CoachStatsCard? statsCard, @JsonKey(includeFromJson: false, includeToJson: false)  List<CoachChip>? chips, @JsonKey(includeFromJson: false, includeToJson: false)  String? errorDetail, @JsonKey(includeFromJson: false, includeToJson: false)  bool streaming, @JsonKey(includeFromJson: false, includeToJson: false)  String? toolIndicator, @JsonKey(includeFromJson: false, includeToJson: false)  String? handoffPrompt)  $default,) {final _that = this;
switch (_that) {
case _CoachMessage():
return $default(_that.id,_that.role,_that.content,_that.createdAt,_that.proposal,_that.statsCard,_that.chips,_that.errorDetail,_that.streaming,_that.toolIndicator,_that.handoffPrompt);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String role,  String content, @JsonKey(name: 'created_at')  String createdAt,  CoachProposal? proposal, @JsonKey(includeFromJson: false, includeToJson: false)  CoachStatsCard? statsCard, @JsonKey(includeFromJson: false, includeToJson: false)  List<CoachChip>? chips, @JsonKey(includeFromJson: false, includeToJson: false)  String? errorDetail, @JsonKey(includeFromJson: false, includeToJson: false)  bool streaming, @JsonKey(includeFromJson: false, includeToJson: false)  String? toolIndicator, @JsonKey(includeFromJson: false, includeToJson: false)  String? handoffPrompt)?  $default,) {final _that = this;
switch (_that) {
case _CoachMessage() when $default != null:
return $default(_that.id,_that.role,_that.content,_that.createdAt,_that.proposal,_that.statsCard,_that.chips,_that.errorDetail,_that.streaming,_that.toolIndicator,_that.handoffPrompt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CoachMessage implements CoachMessage {
  const _CoachMessage({required this.id, required this.role, required this.content, @JsonKey(name: 'created_at') required this.createdAt, this.proposal, @JsonKey(includeFromJson: false, includeToJson: false) this.statsCard, @JsonKey(includeFromJson: false, includeToJson: false) final  List<CoachChip>? chips, @JsonKey(includeFromJson: false, includeToJson: false) this.errorDetail, @JsonKey(includeFromJson: false, includeToJson: false) this.streaming = false, @JsonKey(includeFromJson: false, includeToJson: false) this.toolIndicator, @JsonKey(includeFromJson: false, includeToJson: false) this.handoffPrompt}): _chips = chips;
  factory _CoachMessage.fromJson(Map<String, dynamic> json) => _$CoachMessageFromJson(json);

@override final  String id;
@override final  String role;
@override final  String content;
@override@JsonKey(name: 'created_at') final  String createdAt;
@override final  CoachProposal? proposal;
@override@JsonKey(includeFromJson: false, includeToJson: false) final  CoachStatsCard? statsCard;
 final  List<CoachChip>? _chips;
@override@JsonKey(includeFromJson: false, includeToJson: false) List<CoachChip>? get chips {
  final value = _chips;
  if (value == null) return null;
  if (_chips is EqualUnmodifiableListView) return _chips;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override@JsonKey(includeFromJson: false, includeToJson: false) final  String? errorDetail;
@override@JsonKey(includeFromJson: false, includeToJson: false) final  bool streaming;
@override@JsonKey(includeFromJson: false, includeToJson: false) final  String? toolIndicator;
// Set when the workout-scoped agent calls EscalateToCoach. The UI
// renders a tile under this message that opens a fresh coach chat
// pre-seeded with this prompt. Not persisted server-side — the SDK
// stores it in tool_results, but reload doesn't re-display it (the
// hand-off was a one-shot decision; reopening the workout chat
// shouldn't keep nagging).
@override@JsonKey(includeFromJson: false, includeToJson: false) final  String? handoffPrompt;

/// Create a copy of CoachMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CoachMessageCopyWith<_CoachMessage> get copyWith => __$CoachMessageCopyWithImpl<_CoachMessage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CoachMessageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CoachMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.role, role) || other.role == role)&&(identical(other.content, content) || other.content == content)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.proposal, proposal) || other.proposal == proposal)&&(identical(other.statsCard, statsCard) || other.statsCard == statsCard)&&const DeepCollectionEquality().equals(other._chips, _chips)&&(identical(other.errorDetail, errorDetail) || other.errorDetail == errorDetail)&&(identical(other.streaming, streaming) || other.streaming == streaming)&&(identical(other.toolIndicator, toolIndicator) || other.toolIndicator == toolIndicator)&&(identical(other.handoffPrompt, handoffPrompt) || other.handoffPrompt == handoffPrompt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,role,content,createdAt,proposal,statsCard,const DeepCollectionEquality().hash(_chips),errorDetail,streaming,toolIndicator,handoffPrompt);

@override
String toString() {
  return 'CoachMessage(id: $id, role: $role, content: $content, createdAt: $createdAt, proposal: $proposal, statsCard: $statsCard, chips: $chips, errorDetail: $errorDetail, streaming: $streaming, toolIndicator: $toolIndicator, handoffPrompt: $handoffPrompt)';
}


}

/// @nodoc
abstract mixin class _$CoachMessageCopyWith<$Res> implements $CoachMessageCopyWith<$Res> {
  factory _$CoachMessageCopyWith(_CoachMessage value, $Res Function(_CoachMessage) _then) = __$CoachMessageCopyWithImpl;
@override @useResult
$Res call({
 String id, String role, String content,@JsonKey(name: 'created_at') String createdAt, CoachProposal? proposal,@JsonKey(includeFromJson: false, includeToJson: false) CoachStatsCard? statsCard,@JsonKey(includeFromJson: false, includeToJson: false) List<CoachChip>? chips,@JsonKey(includeFromJson: false, includeToJson: false) String? errorDetail,@JsonKey(includeFromJson: false, includeToJson: false) bool streaming,@JsonKey(includeFromJson: false, includeToJson: false) String? toolIndicator,@JsonKey(includeFromJson: false, includeToJson: false) String? handoffPrompt
});


@override $CoachProposalCopyWith<$Res>? get proposal;@override $CoachStatsCardCopyWith<$Res>? get statsCard;

}
/// @nodoc
class __$CoachMessageCopyWithImpl<$Res>
    implements _$CoachMessageCopyWith<$Res> {
  __$CoachMessageCopyWithImpl(this._self, this._then);

  final _CoachMessage _self;
  final $Res Function(_CoachMessage) _then;

/// Create a copy of CoachMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? role = null,Object? content = null,Object? createdAt = null,Object? proposal = freezed,Object? statsCard = freezed,Object? chips = freezed,Object? errorDetail = freezed,Object? streaming = null,Object? toolIndicator = freezed,Object? handoffPrompt = freezed,}) {
  return _then(_CoachMessage(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,proposal: freezed == proposal ? _self.proposal : proposal // ignore: cast_nullable_to_non_nullable
as CoachProposal?,statsCard: freezed == statsCard ? _self.statsCard : statsCard // ignore: cast_nullable_to_non_nullable
as CoachStatsCard?,chips: freezed == chips ? _self._chips : chips // ignore: cast_nullable_to_non_nullable
as List<CoachChip>?,errorDetail: freezed == errorDetail ? _self.errorDetail : errorDetail // ignore: cast_nullable_to_non_nullable
as String?,streaming: null == streaming ? _self.streaming : streaming // ignore: cast_nullable_to_non_nullable
as bool,toolIndicator: freezed == toolIndicator ? _self.toolIndicator : toolIndicator // ignore: cast_nullable_to_non_nullable
as String?,handoffPrompt: freezed == handoffPrompt ? _self.handoffPrompt : handoffPrompt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of CoachMessage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CoachProposalCopyWith<$Res>? get proposal {
    if (_self.proposal == null) {
    return null;
  }

  return $CoachProposalCopyWith<$Res>(_self.proposal!, (value) {
    return _then(_self.copyWith(proposal: value));
  });
}/// Create a copy of CoachMessage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CoachStatsCardCopyWith<$Res>? get statsCard {
    if (_self.statsCard == null) {
    return null;
  }

  return $CoachStatsCardCopyWith<$Res>(_self.statsCard!, (value) {
    return _then(_self.copyWith(statsCard: value));
  });
}
}

// dart format on
