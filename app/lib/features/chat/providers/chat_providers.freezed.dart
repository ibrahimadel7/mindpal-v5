// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_providers.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ChatState {

 String? get currentConversationId; Map<String, List<Message>> get messages; bool get isInitializing; bool get isSending; bool get showStreaming; bool get isThinking; String? get streamingMessageId; String? get error;
/// Create a copy of ChatState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatStateCopyWith<ChatState> get copyWith => _$ChatStateCopyWithImpl<ChatState>(this as ChatState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatState&&(identical(other.currentConversationId, currentConversationId) || other.currentConversationId == currentConversationId)&&const DeepCollectionEquality().equals(other.messages, messages)&&(identical(other.isInitializing, isInitializing) || other.isInitializing == isInitializing)&&(identical(other.isSending, isSending) || other.isSending == isSending)&&(identical(other.showStreaming, showStreaming) || other.showStreaming == showStreaming)&&(identical(other.isThinking, isThinking) || other.isThinking == isThinking)&&(identical(other.streamingMessageId, streamingMessageId) || other.streamingMessageId == streamingMessageId)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,currentConversationId,const DeepCollectionEquality().hash(messages),isInitializing,isSending,showStreaming,isThinking,streamingMessageId,error);

@override
String toString() {
  return 'ChatState(currentConversationId: $currentConversationId, messages: $messages, isInitializing: $isInitializing, isSending: $isSending, showStreaming: $showStreaming, isThinking: $isThinking, streamingMessageId: $streamingMessageId, error: $error)';
}


}

/// @nodoc
abstract mixin class $ChatStateCopyWith<$Res>  {
  factory $ChatStateCopyWith(ChatState value, $Res Function(ChatState) _then) = _$ChatStateCopyWithImpl;
@useResult
$Res call({
 String? currentConversationId, Map<String, List<Message>> messages, bool isInitializing, bool isSending, bool showStreaming, bool isThinking, String? streamingMessageId, String? error
});




}
/// @nodoc
class _$ChatStateCopyWithImpl<$Res>
    implements $ChatStateCopyWith<$Res> {
  _$ChatStateCopyWithImpl(this._self, this._then);

  final ChatState _self;
  final $Res Function(ChatState) _then;

/// Create a copy of ChatState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? currentConversationId = freezed,Object? messages = null,Object? isInitializing = null,Object? isSending = null,Object? showStreaming = null,Object? isThinking = null,Object? streamingMessageId = freezed,Object? error = freezed,}) {
  return _then(_self.copyWith(
currentConversationId: freezed == currentConversationId ? _self.currentConversationId : currentConversationId // ignore: cast_nullable_to_non_nullable
as String?,messages: null == messages ? _self.messages : messages // ignore: cast_nullable_to_non_nullable
as Map<String, List<Message>>,isInitializing: null == isInitializing ? _self.isInitializing : isInitializing // ignore: cast_nullable_to_non_nullable
as bool,isSending: null == isSending ? _self.isSending : isSending // ignore: cast_nullable_to_non_nullable
as bool,showStreaming: null == showStreaming ? _self.showStreaming : showStreaming // ignore: cast_nullable_to_non_nullable
as bool,isThinking: null == isThinking ? _self.isThinking : isThinking // ignore: cast_nullable_to_non_nullable
as bool,streamingMessageId: freezed == streamingMessageId ? _self.streamingMessageId : streamingMessageId // ignore: cast_nullable_to_non_nullable
as String?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatState].
extension ChatStatePatterns on ChatState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatState value)  $default,){
final _that = this;
switch (_that) {
case _ChatState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatState value)?  $default,){
final _that = this;
switch (_that) {
case _ChatState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? currentConversationId,  Map<String, List<Message>> messages,  bool isInitializing,  bool isSending,  bool showStreaming,  bool isThinking,  String? streamingMessageId,  String? error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatState() when $default != null:
return $default(_that.currentConversationId,_that.messages,_that.isInitializing,_that.isSending,_that.showStreaming,_that.isThinking,_that.streamingMessageId,_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? currentConversationId,  Map<String, List<Message>> messages,  bool isInitializing,  bool isSending,  bool showStreaming,  bool isThinking,  String? streamingMessageId,  String? error)  $default,) {final _that = this;
switch (_that) {
case _ChatState():
return $default(_that.currentConversationId,_that.messages,_that.isInitializing,_that.isSending,_that.showStreaming,_that.isThinking,_that.streamingMessageId,_that.error);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? currentConversationId,  Map<String, List<Message>> messages,  bool isInitializing,  bool isSending,  bool showStreaming,  bool isThinking,  String? streamingMessageId,  String? error)?  $default,) {final _that = this;
switch (_that) {
case _ChatState() when $default != null:
return $default(_that.currentConversationId,_that.messages,_that.isInitializing,_that.isSending,_that.showStreaming,_that.isThinking,_that.streamingMessageId,_that.error);case _:
  return null;

}
}

}

/// @nodoc


class _ChatState extends ChatState {
  const _ChatState({this.currentConversationId, final  Map<String, List<Message>> messages = const <String, List<Message>>{}, this.isInitializing = false, this.isSending = false, this.showStreaming = false, this.isThinking = false, this.streamingMessageId, this.error}): _messages = messages,super._();
  

@override final  String? currentConversationId;
 final  Map<String, List<Message>> _messages;
@override@JsonKey() Map<String, List<Message>> get messages {
  if (_messages is EqualUnmodifiableMapView) return _messages;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_messages);
}

@override@JsonKey() final  bool isInitializing;
@override@JsonKey() final  bool isSending;
@override@JsonKey() final  bool showStreaming;
@override@JsonKey() final  bool isThinking;
@override final  String? streamingMessageId;
@override final  String? error;

/// Create a copy of ChatState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatStateCopyWith<_ChatState> get copyWith => __$ChatStateCopyWithImpl<_ChatState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatState&&(identical(other.currentConversationId, currentConversationId) || other.currentConversationId == currentConversationId)&&const DeepCollectionEquality().equals(other._messages, _messages)&&(identical(other.isInitializing, isInitializing) || other.isInitializing == isInitializing)&&(identical(other.isSending, isSending) || other.isSending == isSending)&&(identical(other.showStreaming, showStreaming) || other.showStreaming == showStreaming)&&(identical(other.isThinking, isThinking) || other.isThinking == isThinking)&&(identical(other.streamingMessageId, streamingMessageId) || other.streamingMessageId == streamingMessageId)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,currentConversationId,const DeepCollectionEquality().hash(_messages),isInitializing,isSending,showStreaming,isThinking,streamingMessageId,error);

@override
String toString() {
  return 'ChatState(currentConversationId: $currentConversationId, messages: $messages, isInitializing: $isInitializing, isSending: $isSending, showStreaming: $showStreaming, isThinking: $isThinking, streamingMessageId: $streamingMessageId, error: $error)';
}


}

/// @nodoc
abstract mixin class _$ChatStateCopyWith<$Res> implements $ChatStateCopyWith<$Res> {
  factory _$ChatStateCopyWith(_ChatState value, $Res Function(_ChatState) _then) = __$ChatStateCopyWithImpl;
@override @useResult
$Res call({
 String? currentConversationId, Map<String, List<Message>> messages, bool isInitializing, bool isSending, bool showStreaming, bool isThinking, String? streamingMessageId, String? error
});




}
/// @nodoc
class __$ChatStateCopyWithImpl<$Res>
    implements _$ChatStateCopyWith<$Res> {
  __$ChatStateCopyWithImpl(this._self, this._then);

  final _ChatState _self;
  final $Res Function(_ChatState) _then;

/// Create a copy of ChatState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? currentConversationId = freezed,Object? messages = null,Object? isInitializing = null,Object? isSending = null,Object? showStreaming = null,Object? isThinking = null,Object? streamingMessageId = freezed,Object? error = freezed,}) {
  return _then(_ChatState(
currentConversationId: freezed == currentConversationId ? _self.currentConversationId : currentConversationId // ignore: cast_nullable_to_non_nullable
as String?,messages: null == messages ? _self._messages : messages // ignore: cast_nullable_to_non_nullable
as Map<String, List<Message>>,isInitializing: null == isInitializing ? _self.isInitializing : isInitializing // ignore: cast_nullable_to_non_nullable
as bool,isSending: null == isSending ? _self.isSending : isSending // ignore: cast_nullable_to_non_nullable
as bool,showStreaming: null == showStreaming ? _self.showStreaming : showStreaming // ignore: cast_nullable_to_non_nullable
as bool,isThinking: null == isThinking ? _self.isThinking : isThinking // ignore: cast_nullable_to_non_nullable
as bool,streamingMessageId: freezed == streamingMessageId ? _self.streamingMessageId : streamingMessageId // ignore: cast_nullable_to_non_nullable
as String?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
