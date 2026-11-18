import 'package:freezed_annotation/freezed_annotation.dart';

part 'models.freezed.dart';
part 'models.g.dart';

@freezed
sealed class Conversation with _$Conversation {
  const factory Conversation({
    required String id,
    required DateTime createdAt,
    String? title,
  }) = _Conversation;

  factory Conversation.fromJson(Map<String, dynamic> json) =>
      _$ConversationFromJson(_normalizeConversationJson(json));
}

Map<String, dynamic> _normalizeConversationJson(Map<String, dynamic> json) {
  return {
    'id': json['id']?.toString() ?? '',
    'title': json['title']?.toString(),
    'createdAt': json['created_at']?.toString() ?? DateTime.now().toIso8601String(),
  };
}

@freezed
sealed class Message with _$Message {
  const factory Message({
    required String id,
    required String conversationId,
    required String role,
    required String text,
    required DateTime createdAt,
    String? thinking,
  }) = _Message;

  factory Message.fromJson(
    Map<String, dynamic> json, {
    required String conversationId,
  }) =>
      _$MessageFromJson(_normalizeMessageJson(json, conversationId));
}

Map<String, dynamic> _normalizeMessageJson(
    Map<String, dynamic> json, String conversationId) {
  return {
    'id': json['id']?.toString() ?? '${DateTime.now().millisecondsSinceEpoch}',
    'conversationId': json['conversation_id']?.toString() ?? conversationId,
    'role': json['role']?.toString() ?? 'assistant',
    'text': json['text']?.toString() ??
        json['content']?.toString() ??
        json['message']?.toString() ??
        '',
    'createdAt':
        json['created_at']?.toString() ?? DateTime.now().toIso8601String(),
    'thinking': json['thinking']?.toString(),
  };
}

extension MessageExtension on Message {
  bool get isUser => role.toLowerCase() == 'user';
}
