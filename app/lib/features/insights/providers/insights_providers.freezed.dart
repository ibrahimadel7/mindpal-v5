// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'insights_providers.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$InsightsState {

 List<EmotionStat> get emotions; List<HabitStat> get habits; InsightsSummary get summary; List<TimeInsight> get time; int get selectedDay; bool get loading; bool get isFromCache; bool get showingAllPatterns; String? get lastUpdated; String? get error;
/// Create a copy of InsightsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InsightsStateCopyWith<InsightsState> get copyWith => _$InsightsStateCopyWithImpl<InsightsState>(this as InsightsState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InsightsState&&const DeepCollectionEquality().equals(other.emotions, emotions)&&const DeepCollectionEquality().equals(other.habits, habits)&&(identical(other.summary, summary) || other.summary == summary)&&const DeepCollectionEquality().equals(other.time, time)&&(identical(other.selectedDay, selectedDay) || other.selectedDay == selectedDay)&&(identical(other.loading, loading) || other.loading == loading)&&(identical(other.isFromCache, isFromCache) || other.isFromCache == isFromCache)&&(identical(other.showingAllPatterns, showingAllPatterns) || other.showingAllPatterns == showingAllPatterns)&&(identical(other.lastUpdated, lastUpdated) || other.lastUpdated == lastUpdated)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(emotions),const DeepCollectionEquality().hash(habits),summary,const DeepCollectionEquality().hash(time),selectedDay,loading,isFromCache,showingAllPatterns,lastUpdated,error);

@override
String toString() {
  return 'InsightsState(emotions: $emotions, habits: $habits, summary: $summary, time: $time, selectedDay: $selectedDay, loading: $loading, isFromCache: $isFromCache, showingAllPatterns: $showingAllPatterns, lastUpdated: $lastUpdated, error: $error)';
}


}

/// @nodoc
abstract mixin class $InsightsStateCopyWith<$Res>  {
  factory $InsightsStateCopyWith(InsightsState value, $Res Function(InsightsState) _then) = _$InsightsStateCopyWithImpl;
@useResult
$Res call({
 List<EmotionStat> emotions, List<HabitStat> habits, InsightsSummary summary, List<TimeInsight> time, int selectedDay, bool loading, bool isFromCache, bool showingAllPatterns, String? lastUpdated, String? error
});


$InsightsSummaryCopyWith<$Res> get summary;

}
/// @nodoc
class _$InsightsStateCopyWithImpl<$Res>
    implements $InsightsStateCopyWith<$Res> {
  _$InsightsStateCopyWithImpl(this._self, this._then);

  final InsightsState _self;
  final $Res Function(InsightsState) _then;

/// Create a copy of InsightsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? emotions = null,Object? habits = null,Object? summary = null,Object? time = null,Object? selectedDay = null,Object? loading = null,Object? isFromCache = null,Object? showingAllPatterns = null,Object? lastUpdated = freezed,Object? error = freezed,}) {
  return _then(_self.copyWith(
emotions: null == emotions ? _self.emotions : emotions // ignore: cast_nullable_to_non_nullable
as List<EmotionStat>,habits: null == habits ? _self.habits : habits // ignore: cast_nullable_to_non_nullable
as List<HabitStat>,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as InsightsSummary,time: null == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as List<TimeInsight>,selectedDay: null == selectedDay ? _self.selectedDay : selectedDay // ignore: cast_nullable_to_non_nullable
as int,loading: null == loading ? _self.loading : loading // ignore: cast_nullable_to_non_nullable
as bool,isFromCache: null == isFromCache ? _self.isFromCache : isFromCache // ignore: cast_nullable_to_non_nullable
as bool,showingAllPatterns: null == showingAllPatterns ? _self.showingAllPatterns : showingAllPatterns // ignore: cast_nullable_to_non_nullable
as bool,lastUpdated: freezed == lastUpdated ? _self.lastUpdated : lastUpdated // ignore: cast_nullable_to_non_nullable
as String?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of InsightsState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InsightsSummaryCopyWith<$Res> get summary {
  
  return $InsightsSummaryCopyWith<$Res>(_self.summary, (value) {
    return _then(_self.copyWith(summary: value));
  });
}
}


/// Adds pattern-matching-related methods to [InsightsState].
extension InsightsStatePatterns on InsightsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InsightsState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InsightsState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InsightsState value)  $default,){
final _that = this;
switch (_that) {
case _InsightsState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InsightsState value)?  $default,){
final _that = this;
switch (_that) {
case _InsightsState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<EmotionStat> emotions,  List<HabitStat> habits,  InsightsSummary summary,  List<TimeInsight> time,  int selectedDay,  bool loading,  bool isFromCache,  bool showingAllPatterns,  String? lastUpdated,  String? error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InsightsState() when $default != null:
return $default(_that.emotions,_that.habits,_that.summary,_that.time,_that.selectedDay,_that.loading,_that.isFromCache,_that.showingAllPatterns,_that.lastUpdated,_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<EmotionStat> emotions,  List<HabitStat> habits,  InsightsSummary summary,  List<TimeInsight> time,  int selectedDay,  bool loading,  bool isFromCache,  bool showingAllPatterns,  String? lastUpdated,  String? error)  $default,) {final _that = this;
switch (_that) {
case _InsightsState():
return $default(_that.emotions,_that.habits,_that.summary,_that.time,_that.selectedDay,_that.loading,_that.isFromCache,_that.showingAllPatterns,_that.lastUpdated,_that.error);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<EmotionStat> emotions,  List<HabitStat> habits,  InsightsSummary summary,  List<TimeInsight> time,  int selectedDay,  bool loading,  bool isFromCache,  bool showingAllPatterns,  String? lastUpdated,  String? error)?  $default,) {final _that = this;
switch (_that) {
case _InsightsState() when $default != null:
return $default(_that.emotions,_that.habits,_that.summary,_that.time,_that.selectedDay,_that.loading,_that.isFromCache,_that.showingAllPatterns,_that.lastUpdated,_that.error);case _:
  return null;

}
}

}

/// @nodoc


class _InsightsState extends InsightsState {
  const _InsightsState({final  List<EmotionStat> emotions = const <EmotionStat>[], final  List<HabitStat> habits = const <HabitStat>[], this.summary = const InsightsSummary(mood: 'Balanced', entries: 0, streak: 0), final  List<TimeInsight> time = const <TimeInsight>[], this.selectedDay = 0, this.loading = true, this.isFromCache = false, this.showingAllPatterns = false, this.lastUpdated, this.error}): _emotions = emotions,_habits = habits,_time = time,super._();
  

 final  List<EmotionStat> _emotions;
@override@JsonKey() List<EmotionStat> get emotions {
  if (_emotions is EqualUnmodifiableListView) return _emotions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_emotions);
}

 final  List<HabitStat> _habits;
@override@JsonKey() List<HabitStat> get habits {
  if (_habits is EqualUnmodifiableListView) return _habits;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_habits);
}

@override@JsonKey() final  InsightsSummary summary;
 final  List<TimeInsight> _time;
@override@JsonKey() List<TimeInsight> get time {
  if (_time is EqualUnmodifiableListView) return _time;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_time);
}

@override@JsonKey() final  int selectedDay;
@override@JsonKey() final  bool loading;
@override@JsonKey() final  bool isFromCache;
@override@JsonKey() final  bool showingAllPatterns;
@override final  String? lastUpdated;
@override final  String? error;

/// Create a copy of InsightsState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InsightsStateCopyWith<_InsightsState> get copyWith => __$InsightsStateCopyWithImpl<_InsightsState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InsightsState&&const DeepCollectionEquality().equals(other._emotions, _emotions)&&const DeepCollectionEquality().equals(other._habits, _habits)&&(identical(other.summary, summary) || other.summary == summary)&&const DeepCollectionEquality().equals(other._time, _time)&&(identical(other.selectedDay, selectedDay) || other.selectedDay == selectedDay)&&(identical(other.loading, loading) || other.loading == loading)&&(identical(other.isFromCache, isFromCache) || other.isFromCache == isFromCache)&&(identical(other.showingAllPatterns, showingAllPatterns) || other.showingAllPatterns == showingAllPatterns)&&(identical(other.lastUpdated, lastUpdated) || other.lastUpdated == lastUpdated)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_emotions),const DeepCollectionEquality().hash(_habits),summary,const DeepCollectionEquality().hash(_time),selectedDay,loading,isFromCache,showingAllPatterns,lastUpdated,error);

@override
String toString() {
  return 'InsightsState(emotions: $emotions, habits: $habits, summary: $summary, time: $time, selectedDay: $selectedDay, loading: $loading, isFromCache: $isFromCache, showingAllPatterns: $showingAllPatterns, lastUpdated: $lastUpdated, error: $error)';
}


}

/// @nodoc
abstract mixin class _$InsightsStateCopyWith<$Res> implements $InsightsStateCopyWith<$Res> {
  factory _$InsightsStateCopyWith(_InsightsState value, $Res Function(_InsightsState) _then) = __$InsightsStateCopyWithImpl;
@override @useResult
$Res call({
 List<EmotionStat> emotions, List<HabitStat> habits, InsightsSummary summary, List<TimeInsight> time, int selectedDay, bool loading, bool isFromCache, bool showingAllPatterns, String? lastUpdated, String? error
});


@override $InsightsSummaryCopyWith<$Res> get summary;

}
/// @nodoc
class __$InsightsStateCopyWithImpl<$Res>
    implements _$InsightsStateCopyWith<$Res> {
  __$InsightsStateCopyWithImpl(this._self, this._then);

  final _InsightsState _self;
  final $Res Function(_InsightsState) _then;

/// Create a copy of InsightsState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? emotions = null,Object? habits = null,Object? summary = null,Object? time = null,Object? selectedDay = null,Object? loading = null,Object? isFromCache = null,Object? showingAllPatterns = null,Object? lastUpdated = freezed,Object? error = freezed,}) {
  return _then(_InsightsState(
emotions: null == emotions ? _self._emotions : emotions // ignore: cast_nullable_to_non_nullable
as List<EmotionStat>,habits: null == habits ? _self._habits : habits // ignore: cast_nullable_to_non_nullable
as List<HabitStat>,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as InsightsSummary,time: null == time ? _self._time : time // ignore: cast_nullable_to_non_nullable
as List<TimeInsight>,selectedDay: null == selectedDay ? _self.selectedDay : selectedDay // ignore: cast_nullable_to_non_nullable
as int,loading: null == loading ? _self.loading : loading // ignore: cast_nullable_to_non_nullable
as bool,isFromCache: null == isFromCache ? _self.isFromCache : isFromCache // ignore: cast_nullable_to_non_nullable
as bool,showingAllPatterns: null == showingAllPatterns ? _self.showingAllPatterns : showingAllPatterns // ignore: cast_nullable_to_non_nullable
as bool,lastUpdated: freezed == lastUpdated ? _self.lastUpdated : lastUpdated // ignore: cast_nullable_to_non_nullable
as String?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of InsightsState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InsightsSummaryCopyWith<$Res> get summary {
  
  return $InsightsSummaryCopyWith<$Res>(_self.summary, (value) {
    return _then(_self.copyWith(summary: value));
  });
}
}

/// @nodoc
mixin _$AIOverviewState {

 AIOverview? get overview; bool get loading; String? get error;
/// Create a copy of AIOverviewState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AIOverviewStateCopyWith<AIOverviewState> get copyWith => _$AIOverviewStateCopyWithImpl<AIOverviewState>(this as AIOverviewState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AIOverviewState&&(identical(other.overview, overview) || other.overview == overview)&&(identical(other.loading, loading) || other.loading == loading)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,overview,loading,error);

@override
String toString() {
  return 'AIOverviewState(overview: $overview, loading: $loading, error: $error)';
}


}

/// @nodoc
abstract mixin class $AIOverviewStateCopyWith<$Res>  {
  factory $AIOverviewStateCopyWith(AIOverviewState value, $Res Function(AIOverviewState) _then) = _$AIOverviewStateCopyWithImpl;
@useResult
$Res call({
 AIOverview? overview, bool loading, String? error
});


$AIOverviewCopyWith<$Res>? get overview;

}
/// @nodoc
class _$AIOverviewStateCopyWithImpl<$Res>
    implements $AIOverviewStateCopyWith<$Res> {
  _$AIOverviewStateCopyWithImpl(this._self, this._then);

  final AIOverviewState _self;
  final $Res Function(AIOverviewState) _then;

/// Create a copy of AIOverviewState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? overview = freezed,Object? loading = null,Object? error = freezed,}) {
  return _then(_self.copyWith(
overview: freezed == overview ? _self.overview : overview // ignore: cast_nullable_to_non_nullable
as AIOverview?,loading: null == loading ? _self.loading : loading // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of AIOverviewState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AIOverviewCopyWith<$Res>? get overview {
    if (_self.overview == null) {
    return null;
  }

  return $AIOverviewCopyWith<$Res>(_self.overview!, (value) {
    return _then(_self.copyWith(overview: value));
  });
}
}


/// Adds pattern-matching-related methods to [AIOverviewState].
extension AIOverviewStatePatterns on AIOverviewState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AIOverviewState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AIOverviewState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AIOverviewState value)  $default,){
final _that = this;
switch (_that) {
case _AIOverviewState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AIOverviewState value)?  $default,){
final _that = this;
switch (_that) {
case _AIOverviewState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AIOverview? overview,  bool loading,  String? error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AIOverviewState() when $default != null:
return $default(_that.overview,_that.loading,_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AIOverview? overview,  bool loading,  String? error)  $default,) {final _that = this;
switch (_that) {
case _AIOverviewState():
return $default(_that.overview,_that.loading,_that.error);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AIOverview? overview,  bool loading,  String? error)?  $default,) {final _that = this;
switch (_that) {
case _AIOverviewState() when $default != null:
return $default(_that.overview,_that.loading,_that.error);case _:
  return null;

}
}

}

/// @nodoc


class _AIOverviewState implements AIOverviewState {
  const _AIOverviewState({this.overview, this.loading = true, this.error});
  

@override final  AIOverview? overview;
@override@JsonKey() final  bool loading;
@override final  String? error;

/// Create a copy of AIOverviewState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AIOverviewStateCopyWith<_AIOverviewState> get copyWith => __$AIOverviewStateCopyWithImpl<_AIOverviewState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AIOverviewState&&(identical(other.overview, overview) || other.overview == overview)&&(identical(other.loading, loading) || other.loading == loading)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,overview,loading,error);

@override
String toString() {
  return 'AIOverviewState(overview: $overview, loading: $loading, error: $error)';
}


}

/// @nodoc
abstract mixin class _$AIOverviewStateCopyWith<$Res> implements $AIOverviewStateCopyWith<$Res> {
  factory _$AIOverviewStateCopyWith(_AIOverviewState value, $Res Function(_AIOverviewState) _then) = __$AIOverviewStateCopyWithImpl;
@override @useResult
$Res call({
 AIOverview? overview, bool loading, String? error
});


@override $AIOverviewCopyWith<$Res>? get overview;

}
/// @nodoc
class __$AIOverviewStateCopyWithImpl<$Res>
    implements _$AIOverviewStateCopyWith<$Res> {
  __$AIOverviewStateCopyWithImpl(this._self, this._then);

  final _AIOverviewState _self;
  final $Res Function(_AIOverviewState) _then;

/// Create a copy of AIOverviewState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? overview = freezed,Object? loading = null,Object? error = freezed,}) {
  return _then(_AIOverviewState(
overview: freezed == overview ? _self.overview : overview // ignore: cast_nullable_to_non_nullable
as AIOverview?,loading: null == loading ? _self.loading : loading // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of AIOverviewState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AIOverviewCopyWith<$Res>? get overview {
    if (_self.overview == null) {
    return null;
  }

  return $AIOverviewCopyWith<$Res>(_self.overview!, (value) {
    return _then(_self.copyWith(overview: value));
  });
}
}

// dart format on
