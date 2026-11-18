import 'dart:convert';

/// Cached message data for offline support.
class CachedMessage {
  final String id;
  final String conversationId;
  final String role;
  final String text;
  final DateTime createdAt;
  final String? thinking;
  final DateTime cachedAt;

  /// Status for offline queue: 'synced', 'pending', 'failed'
  final String syncStatus;

  CachedMessage({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.text,
    required this.createdAt,
    this.thinking,
    required this.cachedAt,
    this.syncStatus = 'synced',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'conversationId': conversationId,
        'role': role,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
        'thinking': thinking,
        'cachedAt': cachedAt.toIso8601String(),
        'syncStatus': syncStatus,
      };

  factory CachedMessage.fromJson(Map<String, dynamic> json) => CachedMessage(
        id: json['id'] as String,
        conversationId: json['conversationId'] as String,
        role: json['role'] as String,
        text: json['text'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        thinking: json['thinking'] as String?,
        cachedAt: DateTime.parse(json['cachedAt'] as String),
        syncStatus: json['syncStatus'] as String? ?? 'synced',
      );

  CachedMessage copyWith({String? syncStatus}) => CachedMessage(
        id: id,
        conversationId: conversationId,
        role: role,
        text: text,
        createdAt: createdAt,
        thinking: thinking,
        cachedAt: cachedAt,
        syncStatus: syncStatus ?? this.syncStatus,
      );

  static String encodeList(List<CachedMessage> list) =>
      jsonEncode(list.map((e) => e.toJson()).toList());

  static List<CachedMessage> decodeList(String data) =>
      (jsonDecode(data) as List)
          .map((e) => CachedMessage.fromJson(e as Map<String, dynamic>))
          .toList();
}
