// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$EmotionStat {

 String get label; int get count;
/// Create a copy of EmotionStat
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EmotionStatCopyWith<EmotionStat> get copyWith => _$EmotionStatCopyWithImpl<EmotionStat>(this as EmotionStat, _$identity);

  /// Serializes this EmotionStat to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EmotionStat&&(identical(other.label, label) || other.label == label)&&(identical(other.count, count) || other.count == count));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,label,count);

@override
String toString() {
  return 'EmotionStat(label: $label, count: $count)';
}


}

/// @nodoc
abstract mixin class $EmotionStatCopyWith<$Res>  {
  factory $EmotionStatCopyWith(EmotionStat value, $Res Function(EmotionStat) _then) = _$EmotionStatCopyWithImpl;
@useResult
$Res call({
 String label, int count
});




}
/// @nodoc
class _$EmotionStatCopyWithImpl<$Res>
    implements $EmotionStatCopyWith<$Res> {
  _$EmotionStatCopyWithImpl(this._self, this._then);

  final EmotionStat _self;
  final $Res Function(EmotionStat) _then;

/// Create a copy of EmotionStat
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? label = null,Object? count = null,}) {
  return _then(_self.copyWith(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [EmotionStat].
extension EmotionStatPatterns on EmotionStat {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EmotionStat value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EmotionStat() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EmotionStat value)  $default,){
final _that = this;
switch (_that) {
case _EmotionStat():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EmotionStat value)?  $default,){
final _that = this;
switch (_that) {
case _EmotionStat() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String label,  int count)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EmotionStat() when $default != null:
return $default(_that.label,_that.count);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String label,  int count)  $default,) {final _that = this;
switch (_that) {
case _EmotionStat():
return $default(_that.label,_that.count);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String label,  int count)?  $default,) {final _that = this;
switch (_that) {
case _EmotionStat() when $default != null:
return $default(_that.label,_that.count);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EmotionStat implements EmotionStat {
  const _EmotionStat({required this.label, required this.count});
  factory _EmotionStat.fromJson(Map<String, dynamic> json) => _$EmotionStatFromJson(json);

@override final  String label;
@override final  int count;

/// Create a copy of EmotionStat
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EmotionStatCopyWith<_EmotionStat> get copyWith => __$EmotionStatCopyWithImpl<_EmotionStat>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EmotionStatToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EmotionStat&&(identical(other.label, label) || other.label == label)&&(identical(other.count, count) || other.count == count));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,label,count);

@override
String toString() {
  return 'EmotionStat(label: $label, count: $count)';
}


}

/// @nodoc
abstract mixin class _$EmotionStatCopyWith<$Res> implements $EmotionStatCopyWith<$Res> {
  factory _$EmotionStatCopyWith(_EmotionStat value, $Res Function(_EmotionStat) _then) = __$EmotionStatCopyWithImpl;
@override @useResult
$Res call({
 String label, int count
});




}
/// @nodoc
class __$EmotionStatCopyWithImpl<$Res>
    implements _$EmotionStatCopyWith<$Res> {
  __$EmotionStatCopyWithImpl(this._self, this._then);

  final _EmotionStat _self;
  final $Res Function(_EmotionStat) _then;

/// Create a copy of EmotionStat
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? label = null,Object? count = null,}) {
  return _then(_EmotionStat(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$HabitStat {

 String get name; int get count;
/// Create a copy of HabitStat
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HabitStatCopyWith<HabitStat> get copyWith => _$HabitStatCopyWithImpl<HabitStat>(this as HabitStat, _$identity);

  /// Serializes this HabitStat to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HabitStat&&(identical(other.name, name) || other.name == name)&&(identical(other.count, count) || other.count == count));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,count);

@override
String toString() {
  return 'HabitStat(name: $name, count: $count)';
}


}

/// @nodoc
abstract mixin class $HabitStatCopyWith<$Res>  {
  factory $HabitStatCopyWith(HabitStat value, $Res Function(HabitStat) _then) = _$HabitStatCopyWithImpl;
@useResult
$Res call({
 String name, int count
});




}
/// @nodoc
class _$HabitStatCopyWithImpl<$Res>
    implements $HabitStatCopyWith<$Res> {
  _$HabitStatCopyWithImpl(this._self, this._then);

  final HabitStat _self;
  final $Res Function(HabitStat) _then;

/// Create a copy of HabitStat
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? count = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [HabitStat].
extension HabitStatPatterns on HabitStat {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HabitStat value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HabitStat() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HabitStat value)  $default,){
final _that = this;
switch (_that) {
case _HabitStat():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HabitStat value)?  $default,){
final _that = this;
switch (_that) {
case _HabitStat() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  int count)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HabitStat() when $default != null:
return $default(_that.name,_that.count);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  int count)  $default,) {final _that = this;
switch (_that) {
case _HabitStat():
return $default(_that.name,_that.count);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  int count)?  $default,) {final _that = this;
switch (_that) {
case _HabitStat() when $default != null:
return $default(_that.name,_that.count);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HabitStat implements HabitStat {
  const _HabitStat({required this.name, required this.count});
  factory _HabitStat.fromJson(Map<String, dynamic> json) => _$HabitStatFromJson(json);

@override final  String name;
@override final  int count;

/// Create a copy of HabitStat
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HabitStatCopyWith<_HabitStat> get copyWith => __$HabitStatCopyWithImpl<_HabitStat>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HabitStatToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HabitStat&&(identical(other.name, name) || other.name == name)&&(identical(other.count, count) || other.count == count));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,count);

@override
String toString() {
  return 'HabitStat(name: $name, count: $count)';
}


}

/// @nodoc
abstract mixin class _$HabitStatCopyWith<$Res> implements $HabitStatCopyWith<$Res> {
  factory _$HabitStatCopyWith(_HabitStat value, $Res Function(_HabitStat) _then) = __$HabitStatCopyWithImpl;
@override @useResult
$Res call({
 String name, int count
});




}
/// @nodoc
class __$HabitStatCopyWithImpl<$Res>
    implements _$HabitStatCopyWith<$Res> {
  __$HabitStatCopyWithImpl(this._self, this._then);

  final _HabitStat _self;
  final $Res Function(_HabitStat) _then;

/// Create a copy of HabitStat
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? count = null,}) {
  return _then(_HabitStat(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$InsightsSummary {

 String get mood; int get entries; int get streak; String? get dominantEmotion;
/// Create a copy of InsightsSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InsightsSummaryCopyWith<InsightsSummary> get copyWith => _$InsightsSummaryCopyWithImpl<InsightsSummary>(this as InsightsSummary, _$identity);

  /// Serializes this InsightsSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InsightsSummary&&(identical(other.mood, mood) || other.mood == mood)&&(identical(other.entries, entries) || other.entries == entries)&&(identical(other.streak, streak) || other.streak == streak)&&(identical(other.dominantEmotion, dominantEmotion) || other.dominantEmotion == dominantEmotion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,mood,entries,streak,dominantEmotion);

@override
String toString() {
  return 'InsightsSummary(mood: $mood, entries: $entries, streak: $streak, dominantEmotion: $dominantEmotion)';
}


}

/// @nodoc
abstract mixin class $InsightsSummaryCopyWith<$Res>  {
  factory $InsightsSummaryCopyWith(InsightsSummary value, $Res Function(InsightsSummary) _then) = _$InsightsSummaryCopyWithImpl;
@useResult
$Res call({
 String mood, int entries, int streak, String? dominantEmotion
});




}
/// @nodoc
class _$InsightsSummaryCopyWithImpl<$Res>
    implements $InsightsSummaryCopyWith<$Res> {
  _$InsightsSummaryCopyWithImpl(this._self, this._then);

  final InsightsSummary _self;
  final $Res Function(InsightsSummary) _then;

/// Create a copy of InsightsSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? mood = null,Object? entries = null,Object? streak = null,Object? dominantEmotion = freezed,}) {
  return _then(_self.copyWith(
mood: null == mood ? _self.mood : mood // ignore: cast_nullable_to_non_nullable
as String,entries: null == entries ? _self.entries : entries // ignore: cast_nullable_to_non_nullable
as int,streak: null == streak ? _self.streak : streak // ignore: cast_nullable_to_non_nullable
as int,dominantEmotion: freezed == dominantEmotion ? _self.dominantEmotion : dominantEmotion // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [InsightsSummary].
extension InsightsSummaryPatterns on InsightsSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InsightsSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InsightsSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InsightsSummary value)  $default,){
final _that = this;
switch (_that) {
case _InsightsSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InsightsSummary value)?  $default,){
final _that = this;
switch (_that) {
case _InsightsSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String mood,  int entries,  int streak,  String? dominantEmotion)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InsightsSummary() when $default != null:
return $default(_that.mood,_that.entries,_that.streak,_that.dominantEmotion);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String mood,  int entries,  int streak,  String? dominantEmotion)  $default,) {final _that = this;
switch (_that) {
case _InsightsSummary():
return $default(_that.mood,_that.entries,_that.streak,_that.dominantEmotion);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String mood,  int entries,  int streak,  String? dominantEmotion)?  $default,) {final _that = this;
switch (_that) {
case _InsightsSummary() when $default != null:
return $default(_that.mood,_that.entries,_that.streak,_that.dominantEmotion);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InsightsSummary implements InsightsSummary {
  const _InsightsSummary({required this.mood, required this.entries, required this.streak, this.dominantEmotion});
  factory _InsightsSummary.fromJson(Map<String, dynamic> json) => _$InsightsSummaryFromJson(json);

@override final  String mood;
@override final  int entries;
@override final  int streak;
@override final  String? dominantEmotion;

/// Create a copy of InsightsSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InsightsSummaryCopyWith<_InsightsSummary> get copyWith => __$InsightsSummaryCopyWithImpl<_InsightsSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InsightsSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InsightsSummary&&(identical(other.mood, mood) || other.mood == mood)&&(identical(other.entries, entries) || other.entries == entries)&&(identical(other.streak, streak) || other.streak == streak)&&(identical(other.dominantEmotion, dominantEmotion) || other.dominantEmotion == dominantEmotion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,mood,entries,streak,dominantEmotion);

@override
String toString() {
  return 'InsightsSummary(mood: $mood, entries: $entries, streak: $streak, dominantEmotion: $dominantEmotion)';
}


}

/// @nodoc
abstract mixin class _$InsightsSummaryCopyWith<$Res> implements $InsightsSummaryCopyWith<$Res> {
  factory _$InsightsSummaryCopyWith(_InsightsSummary value, $Res Function(_InsightsSummary) _then) = __$InsightsSummaryCopyWithImpl;
@override @useResult
$Res call({
 String mood, int entries, int streak, String? dominantEmotion
});




}
/// @nodoc
class __$InsightsSummaryCopyWithImpl<$Res>
    implements _$InsightsSummaryCopyWith<$Res> {
  __$InsightsSummaryCopyWithImpl(this._self, this._then);

  final _InsightsSummary _self;
  final $Res Function(_InsightsSummary) _then;

/// Create a copy of InsightsSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? mood = null,Object? entries = null,Object? streak = null,Object? dominantEmotion = freezed,}) {
  return _then(_InsightsSummary(
mood: null == mood ? _self.mood : mood // ignore: cast_nullable_to_non_nullable
as String,entries: null == entries ? _self.entries : entries // ignore: cast_nullable_to_non_nullable
as int,streak: null == streak ? _self.streak : streak // ignore: cast_nullable_to_non_nullable
as int,dominantEmotion: freezed == dominantEmotion ? _self.dominantEmotion : dominantEmotion // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$DayEmotion {

 String get label; double get percent; int get count;
/// Create a copy of DayEmotion
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DayEmotionCopyWith<DayEmotion> get copyWith => _$DayEmotionCopyWithImpl<DayEmotion>(this as DayEmotion, _$identity);

  /// Serializes this DayEmotion to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DayEmotion&&(identical(other.label, label) || other.label == label)&&(identical(other.percent, percent) || other.percent == percent)&&(identical(other.count, count) || other.count == count));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,label,percent,count);

@override
String toString() {
  return 'DayEmotion(label: $label, percent: $percent, count: $count)';
}


}

/// @nodoc
abstract mixin class $DayEmotionCopyWith<$Res>  {
  factory $DayEmotionCopyWith(DayEmotion value, $Res Function(DayEmotion) _then) = _$DayEmotionCopyWithImpl;
@useResult
$Res call({
 String label, double percent, int count
});




}
/// @nodoc
class _$DayEmotionCopyWithImpl<$Res>
    implements $DayEmotionCopyWith<$Res> {
  _$DayEmotionCopyWithImpl(this._self, this._then);

  final DayEmotion _self;
  final $Res Function(DayEmotion) _then;

/// Create a copy of DayEmotion
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? label = null,Object? percent = null,Object? count = null,}) {
  return _then(_self.copyWith(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,percent: null == percent ? _self.percent : percent // ignore: cast_nullable_to_non_nullable
as double,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [DayEmotion].
extension DayEmotionPatterns on DayEmotion {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DayEmotion value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DayEmotion() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DayEmotion value)  $default,){
final _that = this;
switch (_that) {
case _DayEmotion():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DayEmotion value)?  $default,){
final _that = this;
switch (_that) {
case _DayEmotion() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String label,  double percent,  int count)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DayEmotion() when $default != null:
return $default(_that.label,_that.percent,_that.count);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String label,  double percent,  int count)  $default,) {final _that = this;
switch (_that) {
case _DayEmotion():
return $default(_that.label,_that.percent,_that.count);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String label,  double percent,  int count)?  $default,) {final _that = this;
switch (_that) {
case _DayEmotion() when $default != null:
return $default(_that.label,_that.percent,_that.count);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DayEmotion implements DayEmotion {
  const _DayEmotion({required this.label, required this.percent, this.count = 0});
  factory _DayEmotion.fromJson(Map<String, dynamic> json) => _$DayEmotionFromJson(json);

@override final  String label;
@override final  double percent;
@override@JsonKey() final  int count;

/// Create a copy of DayEmotion
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DayEmotionCopyWith<_DayEmotion> get copyWith => __$DayEmotionCopyWithImpl<_DayEmotion>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DayEmotionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DayEmotion&&(identical(other.label, label) || other.label == label)&&(identical(other.percent, percent) || other.percent == percent)&&(identical(other.count, count) || other.count == count));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,label,percent,count);

@override
String toString() {
  return 'DayEmotion(label: $label, percent: $percent, count: $count)';
}


}

/// @nodoc
abstract mixin class _$DayEmotionCopyWith<$Res> implements $DayEmotionCopyWith<$Res> {
  factory _$DayEmotionCopyWith(_DayEmotion value, $Res Function(_DayEmotion) _then) = __$DayEmotionCopyWithImpl;
@override @useResult
$Res call({
 String label, double percent, int count
});




}
/// @nodoc
class __$DayEmotionCopyWithImpl<$Res>
    implements _$DayEmotionCopyWith<$Res> {
  __$DayEmotionCopyWithImpl(this._self, this._then);

  final _DayEmotion _self;
  final $Res Function(_DayEmotion) _then;

/// Create a copy of DayEmotion
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? label = null,Object? percent = null,Object? count = null,}) {
  return _then(_DayEmotion(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,percent: null == percent ? _self.percent : percent // ignore: cast_nullable_to_non_nullable
as double,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$TimeInsight {

 DateTime get date; List<DayEmotion> get items; int get total;
/// Create a copy of TimeInsight
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TimeInsightCopyWith<TimeInsight> get copyWith => _$TimeInsightCopyWithImpl<TimeInsight>(this as TimeInsight, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TimeInsight&&(identical(other.date, date) || other.date == date)&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.total, total) || other.total == total));
}


@override
int get hashCode => Object.hash(runtimeType,date,const DeepCollectionEquality().hash(items),total);

@override
String toString() {
  return 'TimeInsight(date: $date, items: $items, total: $total)';
}


}

/// @nodoc
abstract mixin class $TimeInsightCopyWith<$Res>  {
  factory $TimeInsightCopyWith(TimeInsight value, $Res Function(TimeInsight) _then) = _$TimeInsightCopyWithImpl;
@useResult
$Res call({
 DateTime date, List<DayEmotion> items, int total
});




}
/// @nodoc
class _$TimeInsightCopyWithImpl<$Res>
    implements $TimeInsightCopyWith<$Res> {
  _$TimeInsightCopyWithImpl(this._self, this._then);

  final TimeInsight _self;
  final $Res Function(TimeInsight) _then;

/// Create a copy of TimeInsight
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? date = null,Object? items = null,Object? total = null,}) {
  return _then(_self.copyWith(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<DayEmotion>,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [TimeInsight].
extension TimeInsightPatterns on TimeInsight {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TimeInsight value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TimeInsight() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TimeInsight value)  $default,){
final _that = this;
switch (_that) {
case _TimeInsight():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TimeInsight value)?  $default,){
final _that = this;
switch (_that) {
case _TimeInsight() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime date,  List<DayEmotion> items,  int total)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TimeInsight() when $default != null:
return $default(_that.date,_that.items,_that.total);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime date,  List<DayEmotion> items,  int total)  $default,) {final _that = this;
switch (_that) {
case _TimeInsight():
return $default(_that.date,_that.items,_that.total);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime date,  List<DayEmotion> items,  int total)?  $default,) {final _that = this;
switch (_that) {
case _TimeInsight() when $default != null:
return $default(_that.date,_that.items,_that.total);case _:
  return null;

}
}

}

/// @nodoc


class _TimeInsight implements TimeInsight {
  const _TimeInsight({required this.date, required final  List<DayEmotion> items, this.total = 0}): _items = items;
  

@override final  DateTime date;
 final  List<DayEmotion> _items;
@override List<DayEmotion> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override@JsonKey() final  int total;

/// Create a copy of TimeInsight
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TimeInsightCopyWith<_TimeInsight> get copyWith => __$TimeInsightCopyWithImpl<_TimeInsight>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TimeInsight&&(identical(other.date, date) || other.date == date)&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.total, total) || other.total == total));
}


@override
int get hashCode => Object.hash(runtimeType,date,const DeepCollectionEquality().hash(_items),total);

@override
String toString() {
  return 'TimeInsight(date: $date, items: $items, total: $total)';
}


}

/// @nodoc
abstract mixin class _$TimeInsightCopyWith<$Res> implements $TimeInsightCopyWith<$Res> {
  factory _$TimeInsightCopyWith(_TimeInsight value, $Res Function(_TimeInsight) _then) = __$TimeInsightCopyWithImpl;
@override @useResult
$Res call({
 DateTime date, List<DayEmotion> items, int total
});




}
/// @nodoc
class __$TimeInsightCopyWithImpl<$Res>
    implements _$TimeInsightCopyWith<$Res> {
  __$TimeInsightCopyWithImpl(this._self, this._then);

  final _TimeInsight _self;
  final $Res Function(_TimeInsight) _then;

/// Create a copy of TimeInsight
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? date = null,Object? items = null,Object? total = null,}) {
  return _then(_TimeInsight(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<DayEmotion>,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$AIOverview {

 String get greeting; String get currentFeeling; String get emotionSummary; String get habitSummary; String get encouragement;
/// Create a copy of AIOverview
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AIOverviewCopyWith<AIOverview> get copyWith => _$AIOverviewCopyWithImpl<AIOverview>(this as AIOverview, _$identity);

  /// Serializes this AIOverview to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AIOverview&&(identical(other.greeting, greeting) || other.greeting == greeting)&&(identical(other.currentFeeling, currentFeeling) || other.currentFeeling == currentFeeling)&&(identical(other.emotionSummary, emotionSummary) || other.emotionSummary == emotionSummary)&&(identical(other.habitSummary, habitSummary) || other.habitSummary == habitSummary)&&(identical(other.encouragement, encouragement) || other.encouragement == encouragement));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,greeting,currentFeeling,emotionSummary,habitSummary,encouragement);

@override
String toString() {
  return 'AIOverview(greeting: $greeting, currentFeeling: $currentFeeling, emotionSummary: $emotionSummary, habitSummary: $habitSummary, encouragement: $encouragement)';
}


}

/// @nodoc
abstract mixin class $AIOverviewCopyWith<$Res>  {
  factory $AIOverviewCopyWith(AIOverview value, $Res Function(AIOverview) _then) = _$AIOverviewCopyWithImpl;
@useResult
$Res call({
 String greeting, String currentFeeling, String emotionSummary, String habitSummary, String encouragement
});




}
/// @nodoc
class _$AIOverviewCopyWithImpl<$Res>
    implements $AIOverviewCopyWith<$Res> {
  _$AIOverviewCopyWithImpl(this._self, this._then);

  final AIOverview _self;
  final $Res Function(AIOverview) _then;

/// Create a copy of AIOverview
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? greeting = null,Object? currentFeeling = null,Object? emotionSummary = null,Object? habitSummary = null,Object? encouragement = null,}) {
  return _then(_self.copyWith(
greeting: null == greeting ? _self.greeting : greeting // ignore: cast_nullable_to_non_nullable
as String,currentFeeling: null == currentFeeling ? _self.currentFeeling : currentFeeling // ignore: cast_nullable_to_non_nullable
as String,emotionSummary: null == emotionSummary ? _self.emotionSummary : emotionSummary // ignore: cast_nullable_to_non_nullable
as String,habitSummary: null == habitSummary ? _self.habitSummary : habitSummary // ignore: cast_nullable_to_non_nullable
as String,encouragement: null == encouragement ? _self.encouragement : encouragement // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [AIOverview].
extension AIOverviewPatterns on AIOverview {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AIOverview value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AIOverview() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AIOverview value)  $default,){
final _that = this;
switch (_that) {
case _AIOverview():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AIOverview value)?  $default,){
final _that = this;
switch (_that) {
case _AIOverview() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String greeting,  String currentFeeling,  String emotionSummary,  String habitSummary,  String encouragement)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AIOverview() when $default != null:
return $default(_that.greeting,_that.currentFeeling,_that.emotionSummary,_that.habitSummary,_that.encouragement);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String greeting,  String currentFeeling,  String emotionSummary,  String habitSummary,  String encouragement)  $default,) {final _that = this;
switch (_that) {
case _AIOverview():
return $default(_that.greeting,_that.currentFeeling,_that.emotionSummary,_that.habitSummary,_that.encouragement);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String greeting,  String currentFeeling,  String emotionSummary,  String habitSummary,  String encouragement)?  $default,) {final _that = this;
switch (_that) {
case _AIOverview() when $default != null:
return $default(_that.greeting,_that.currentFeeling,_that.emotionSummary,_that.habitSummary,_that.encouragement);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AIOverview implements AIOverview {
  const _AIOverview({required this.greeting, required this.currentFeeling, required this.emotionSummary, required this.habitSummary, required this.encouragement});
  factory _AIOverview.fromJson(Map<String, dynamic> json) => _$AIOverviewFromJson(json);

@override final  String greeting;
@override final  String currentFeeling;
@override final  String emotionSummary;
@override final  String habitSummary;
@override final  String encouragement;

/// Create a copy of AIOverview
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AIOverviewCopyWith<_AIOverview> get copyWith => __$AIOverviewCopyWithImpl<_AIOverview>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AIOverviewToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AIOverview&&(identical(other.greeting, greeting) || other.greeting == greeting)&&(identical(other.currentFeeling, currentFeeling) || other.currentFeeling == currentFeeling)&&(identical(other.emotionSummary, emotionSummary) || other.emotionSummary == emotionSummary)&&(identical(other.habitSummary, habitSummary) || other.habitSummary == habitSummary)&&(identical(other.encouragement, encouragement) || other.encouragement == encouragement));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,greeting,currentFeeling,emotionSummary,habitSummary,encouragement);

@override
String toString() {
  return 'AIOverview(greeting: $greeting, currentFeeling: $currentFeeling, emotionSummary: $emotionSummary, habitSummary: $habitSummary, encouragement: $encouragement)';
}


}

/// @nodoc
abstract mixin class _$AIOverviewCopyWith<$Res> implements $AIOverviewCopyWith<$Res> {
  factory _$AIOverviewCopyWith(_AIOverview value, $Res Function(_AIOverview) _then) = __$AIOverviewCopyWithImpl;
@override @useResult
$Res call({
 String greeting, String currentFeeling, String emotionSummary, String habitSummary, String encouragement
});




}
/// @nodoc
class __$AIOverviewCopyWithImpl<$Res>
    implements _$AIOverviewCopyWith<$Res> {
  __$AIOverviewCopyWithImpl(this._self, this._then);

  final _AIOverview _self;
  final $Res Function(_AIOverview) _then;

/// Create a copy of AIOverview
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? greeting = null,Object? currentFeeling = null,Object? emotionSummary = null,Object? habitSummary = null,Object? encouragement = null,}) {
  return _then(_AIOverview(
greeting: null == greeting ? _self.greeting : greeting // ignore: cast_nullable_to_non_nullable
as String,currentFeeling: null == currentFeeling ? _self.currentFeeling : currentFeeling // ignore: cast_nullable_to_non_nullable
as String,emotionSummary: null == emotionSummary ? _self.emotionSummary : emotionSummary // ignore: cast_nullable_to_non_nullable
as String,habitSummary: null == habitSummary ? _self.habitSummary : habitSummary // ignore: cast_nullable_to_non_nullable
as String,encouragement: null == encouragement ? _self.encouragement : encouragement // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
