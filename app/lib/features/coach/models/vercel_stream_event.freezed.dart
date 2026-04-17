// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'vercel_stream_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$VercelStreamEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VercelStreamEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'VercelStreamEvent()';
}


}

/// @nodoc
class $VercelStreamEventCopyWith<$Res>  {
$VercelStreamEventCopyWith(VercelStreamEvent _, $Res Function(VercelStreamEvent) __);
}


/// Adds pattern-matching-related methods to [VercelStreamEvent].
extension VercelStreamEventPatterns on VercelStreamEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( TextDeltaEvent value)?  textDelta,TResult Function( TextEndEvent value)?  textEnd,TResult Function( ToolStartEvent value)?  toolStart,TResult Function( ToolEndEvent value)?  toolEnd,TResult Function( ProposalEvent value)?  proposal,TResult Function( StatsEvent value)?  stats,TResult Function( ChipsEvent value)?  chips,TResult Function( ErrorEvent value)?  error,TResult Function( DoneEvent value)?  done,required TResult orElse(),}){
final _that = this;
switch (_that) {
case TextDeltaEvent() when textDelta != null:
return textDelta(_that);case TextEndEvent() when textEnd != null:
return textEnd(_that);case ToolStartEvent() when toolStart != null:
return toolStart(_that);case ToolEndEvent() when toolEnd != null:
return toolEnd(_that);case ProposalEvent() when proposal != null:
return proposal(_that);case StatsEvent() when stats != null:
return stats(_that);case ChipsEvent() when chips != null:
return chips(_that);case ErrorEvent() when error != null:
return error(_that);case DoneEvent() when done != null:
return done(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( TextDeltaEvent value)  textDelta,required TResult Function( TextEndEvent value)  textEnd,required TResult Function( ToolStartEvent value)  toolStart,required TResult Function( ToolEndEvent value)  toolEnd,required TResult Function( ProposalEvent value)  proposal,required TResult Function( StatsEvent value)  stats,required TResult Function( ChipsEvent value)  chips,required TResult Function( ErrorEvent value)  error,required TResult Function( DoneEvent value)  done,}){
final _that = this;
switch (_that) {
case TextDeltaEvent():
return textDelta(_that);case TextEndEvent():
return textEnd(_that);case ToolStartEvent():
return toolStart(_that);case ToolEndEvent():
return toolEnd(_that);case ProposalEvent():
return proposal(_that);case StatsEvent():
return stats(_that);case ChipsEvent():
return chips(_that);case ErrorEvent():
return error(_that);case DoneEvent():
return done(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( TextDeltaEvent value)?  textDelta,TResult? Function( TextEndEvent value)?  textEnd,TResult? Function( ToolStartEvent value)?  toolStart,TResult? Function( ToolEndEvent value)?  toolEnd,TResult? Function( ProposalEvent value)?  proposal,TResult? Function( StatsEvent value)?  stats,TResult? Function( ChipsEvent value)?  chips,TResult? Function( ErrorEvent value)?  error,TResult? Function( DoneEvent value)?  done,}){
final _that = this;
switch (_that) {
case TextDeltaEvent() when textDelta != null:
return textDelta(_that);case TextEndEvent() when textEnd != null:
return textEnd(_that);case ToolStartEvent() when toolStart != null:
return toolStart(_that);case ToolEndEvent() when toolEnd != null:
return toolEnd(_that);case ProposalEvent() when proposal != null:
return proposal(_that);case StatsEvent() when stats != null:
return stats(_that);case ChipsEvent() when chips != null:
return chips(_that);case ErrorEvent() when error != null:
return error(_that);case DoneEvent() when done != null:
return done(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String delta)?  textDelta,TResult Function()?  textEnd,TResult Function( String toolName)?  toolStart,TResult Function()?  toolEnd,TResult Function( CoachProposal proposal)?  proposal,TResult Function( CoachStatsCard stats)?  stats,TResult Function( List<CoachChip> chips)?  chips,TResult Function( String message)?  error,TResult Function()?  done,required TResult orElse(),}) {final _that = this;
switch (_that) {
case TextDeltaEvent() when textDelta != null:
return textDelta(_that.delta);case TextEndEvent() when textEnd != null:
return textEnd();case ToolStartEvent() when toolStart != null:
return toolStart(_that.toolName);case ToolEndEvent() when toolEnd != null:
return toolEnd();case ProposalEvent() when proposal != null:
return proposal(_that.proposal);case StatsEvent() when stats != null:
return stats(_that.stats);case ChipsEvent() when chips != null:
return chips(_that.chips);case ErrorEvent() when error != null:
return error(_that.message);case DoneEvent() when done != null:
return done();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String delta)  textDelta,required TResult Function()  textEnd,required TResult Function( String toolName)  toolStart,required TResult Function()  toolEnd,required TResult Function( CoachProposal proposal)  proposal,required TResult Function( CoachStatsCard stats)  stats,required TResult Function( List<CoachChip> chips)  chips,required TResult Function( String message)  error,required TResult Function()  done,}) {final _that = this;
switch (_that) {
case TextDeltaEvent():
return textDelta(_that.delta);case TextEndEvent():
return textEnd();case ToolStartEvent():
return toolStart(_that.toolName);case ToolEndEvent():
return toolEnd();case ProposalEvent():
return proposal(_that.proposal);case StatsEvent():
return stats(_that.stats);case ChipsEvent():
return chips(_that.chips);case ErrorEvent():
return error(_that.message);case DoneEvent():
return done();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String delta)?  textDelta,TResult? Function()?  textEnd,TResult? Function( String toolName)?  toolStart,TResult? Function()?  toolEnd,TResult? Function( CoachProposal proposal)?  proposal,TResult? Function( CoachStatsCard stats)?  stats,TResult? Function( List<CoachChip> chips)?  chips,TResult? Function( String message)?  error,TResult? Function()?  done,}) {final _that = this;
switch (_that) {
case TextDeltaEvent() when textDelta != null:
return textDelta(_that.delta);case TextEndEvent() when textEnd != null:
return textEnd();case ToolStartEvent() when toolStart != null:
return toolStart(_that.toolName);case ToolEndEvent() when toolEnd != null:
return toolEnd();case ProposalEvent() when proposal != null:
return proposal(_that.proposal);case StatsEvent() when stats != null:
return stats(_that.stats);case ChipsEvent() when chips != null:
return chips(_that.chips);case ErrorEvent() when error != null:
return error(_that.message);case DoneEvent() when done != null:
return done();case _:
  return null;

}
}

}

/// @nodoc


class TextDeltaEvent implements VercelStreamEvent {
  const TextDeltaEvent(this.delta);
  

 final  String delta;

/// Create a copy of VercelStreamEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TextDeltaEventCopyWith<TextDeltaEvent> get copyWith => _$TextDeltaEventCopyWithImpl<TextDeltaEvent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TextDeltaEvent&&(identical(other.delta, delta) || other.delta == delta));
}


@override
int get hashCode => Object.hash(runtimeType,delta);

@override
String toString() {
  return 'VercelStreamEvent.textDelta(delta: $delta)';
}


}

/// @nodoc
abstract mixin class $TextDeltaEventCopyWith<$Res> implements $VercelStreamEventCopyWith<$Res> {
  factory $TextDeltaEventCopyWith(TextDeltaEvent value, $Res Function(TextDeltaEvent) _then) = _$TextDeltaEventCopyWithImpl;
@useResult
$Res call({
 String delta
});




}
/// @nodoc
class _$TextDeltaEventCopyWithImpl<$Res>
    implements $TextDeltaEventCopyWith<$Res> {
  _$TextDeltaEventCopyWithImpl(this._self, this._then);

  final TextDeltaEvent _self;
  final $Res Function(TextDeltaEvent) _then;

/// Create a copy of VercelStreamEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? delta = null,}) {
  return _then(TextDeltaEvent(
null == delta ? _self.delta : delta // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class TextEndEvent implements VercelStreamEvent {
  const TextEndEvent();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TextEndEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'VercelStreamEvent.textEnd()';
}


}




/// @nodoc


class ToolStartEvent implements VercelStreamEvent {
  const ToolStartEvent(this.toolName);
  

 final  String toolName;

/// Create a copy of VercelStreamEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ToolStartEventCopyWith<ToolStartEvent> get copyWith => _$ToolStartEventCopyWithImpl<ToolStartEvent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ToolStartEvent&&(identical(other.toolName, toolName) || other.toolName == toolName));
}


@override
int get hashCode => Object.hash(runtimeType,toolName);

@override
String toString() {
  return 'VercelStreamEvent.toolStart(toolName: $toolName)';
}


}

/// @nodoc
abstract mixin class $ToolStartEventCopyWith<$Res> implements $VercelStreamEventCopyWith<$Res> {
  factory $ToolStartEventCopyWith(ToolStartEvent value, $Res Function(ToolStartEvent) _then) = _$ToolStartEventCopyWithImpl;
@useResult
$Res call({
 String toolName
});




}
/// @nodoc
class _$ToolStartEventCopyWithImpl<$Res>
    implements $ToolStartEventCopyWith<$Res> {
  _$ToolStartEventCopyWithImpl(this._self, this._then);

  final ToolStartEvent _self;
  final $Res Function(ToolStartEvent) _then;

/// Create a copy of VercelStreamEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? toolName = null,}) {
  return _then(ToolStartEvent(
null == toolName ? _self.toolName : toolName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ToolEndEvent implements VercelStreamEvent {
  const ToolEndEvent();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ToolEndEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'VercelStreamEvent.toolEnd()';
}


}




/// @nodoc


class ProposalEvent implements VercelStreamEvent {
  const ProposalEvent(this.proposal);
  

 final  CoachProposal proposal;

/// Create a copy of VercelStreamEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProposalEventCopyWith<ProposalEvent> get copyWith => _$ProposalEventCopyWithImpl<ProposalEvent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProposalEvent&&(identical(other.proposal, proposal) || other.proposal == proposal));
}


@override
int get hashCode => Object.hash(runtimeType,proposal);

@override
String toString() {
  return 'VercelStreamEvent.proposal(proposal: $proposal)';
}


}

/// @nodoc
abstract mixin class $ProposalEventCopyWith<$Res> implements $VercelStreamEventCopyWith<$Res> {
  factory $ProposalEventCopyWith(ProposalEvent value, $Res Function(ProposalEvent) _then) = _$ProposalEventCopyWithImpl;
@useResult
$Res call({
 CoachProposal proposal
});


$CoachProposalCopyWith<$Res> get proposal;

}
/// @nodoc
class _$ProposalEventCopyWithImpl<$Res>
    implements $ProposalEventCopyWith<$Res> {
  _$ProposalEventCopyWithImpl(this._self, this._then);

  final ProposalEvent _self;
  final $Res Function(ProposalEvent) _then;

/// Create a copy of VercelStreamEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? proposal = null,}) {
  return _then(ProposalEvent(
null == proposal ? _self.proposal : proposal // ignore: cast_nullable_to_non_nullable
as CoachProposal,
  ));
}

/// Create a copy of VercelStreamEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CoachProposalCopyWith<$Res> get proposal {
  
  return $CoachProposalCopyWith<$Res>(_self.proposal, (value) {
    return _then(_self.copyWith(proposal: value));
  });
}
}

/// @nodoc


class StatsEvent implements VercelStreamEvent {
  const StatsEvent(this.stats);
  

 final  CoachStatsCard stats;

/// Create a copy of VercelStreamEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StatsEventCopyWith<StatsEvent> get copyWith => _$StatsEventCopyWithImpl<StatsEvent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StatsEvent&&(identical(other.stats, stats) || other.stats == stats));
}


@override
int get hashCode => Object.hash(runtimeType,stats);

@override
String toString() {
  return 'VercelStreamEvent.stats(stats: $stats)';
}


}

/// @nodoc
abstract mixin class $StatsEventCopyWith<$Res> implements $VercelStreamEventCopyWith<$Res> {
  factory $StatsEventCopyWith(StatsEvent value, $Res Function(StatsEvent) _then) = _$StatsEventCopyWithImpl;
@useResult
$Res call({
 CoachStatsCard stats
});


$CoachStatsCardCopyWith<$Res> get stats;

}
/// @nodoc
class _$StatsEventCopyWithImpl<$Res>
    implements $StatsEventCopyWith<$Res> {
  _$StatsEventCopyWithImpl(this._self, this._then);

  final StatsEvent _self;
  final $Res Function(StatsEvent) _then;

/// Create a copy of VercelStreamEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? stats = null,}) {
  return _then(StatsEvent(
null == stats ? _self.stats : stats // ignore: cast_nullable_to_non_nullable
as CoachStatsCard,
  ));
}

/// Create a copy of VercelStreamEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CoachStatsCardCopyWith<$Res> get stats {
  
  return $CoachStatsCardCopyWith<$Res>(_self.stats, (value) {
    return _then(_self.copyWith(stats: value));
  });
}
}

/// @nodoc


class ChipsEvent implements VercelStreamEvent {
  const ChipsEvent(final  List<CoachChip> chips): _chips = chips;
  

 final  List<CoachChip> _chips;
 List<CoachChip> get chips {
  if (_chips is EqualUnmodifiableListView) return _chips;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_chips);
}


/// Create a copy of VercelStreamEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChipsEventCopyWith<ChipsEvent> get copyWith => _$ChipsEventCopyWithImpl<ChipsEvent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChipsEvent&&const DeepCollectionEquality().equals(other._chips, _chips));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_chips));

@override
String toString() {
  return 'VercelStreamEvent.chips(chips: $chips)';
}


}

/// @nodoc
abstract mixin class $ChipsEventCopyWith<$Res> implements $VercelStreamEventCopyWith<$Res> {
  factory $ChipsEventCopyWith(ChipsEvent value, $Res Function(ChipsEvent) _then) = _$ChipsEventCopyWithImpl;
@useResult
$Res call({
 List<CoachChip> chips
});




}
/// @nodoc
class _$ChipsEventCopyWithImpl<$Res>
    implements $ChipsEventCopyWith<$Res> {
  _$ChipsEventCopyWithImpl(this._self, this._then);

  final ChipsEvent _self;
  final $Res Function(ChipsEvent) _then;

/// Create a copy of VercelStreamEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? chips = null,}) {
  return _then(ChipsEvent(
null == chips ? _self._chips : chips // ignore: cast_nullable_to_non_nullable
as List<CoachChip>,
  ));
}


}

/// @nodoc


class ErrorEvent implements VercelStreamEvent {
  const ErrorEvent(this.message);
  

 final  String message;

/// Create a copy of VercelStreamEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ErrorEventCopyWith<ErrorEvent> get copyWith => _$ErrorEventCopyWithImpl<ErrorEvent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ErrorEvent&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'VercelStreamEvent.error(message: $message)';
}


}

/// @nodoc
abstract mixin class $ErrorEventCopyWith<$Res> implements $VercelStreamEventCopyWith<$Res> {
  factory $ErrorEventCopyWith(ErrorEvent value, $Res Function(ErrorEvent) _then) = _$ErrorEventCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$ErrorEventCopyWithImpl<$Res>
    implements $ErrorEventCopyWith<$Res> {
  _$ErrorEventCopyWithImpl(this._self, this._then);

  final ErrorEvent _self;
  final $Res Function(ErrorEvent) _then;

/// Create a copy of VercelStreamEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(ErrorEvent(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class DoneEvent implements VercelStreamEvent {
  const DoneEvent();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DoneEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'VercelStreamEvent.done()';
}


}




// dart format on
