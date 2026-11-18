import 'dart:convert';

/// Cached conversation data for offline support.
class CachedConversation {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime cachedAt;
  final int userId;

  CachedConversation({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.cachedAt,
    required this.userId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'createdAt': createdAt.toIso8601String(),
        'cachedAt': cachedAt.toIso8601String(),
        'userId': userId,
      };

  factory CachedConversation.fromJson(Map<String, dynamic> json) =>
      CachedConversation(
        id: json['id'] as String,
        title: json['title'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        cachedAt: DateTime.parse(json['cachedAt'] as String),
        userId: json['userId'] as int,
      );

  static String encodeList(List<CachedConversation> list) =>
      jsonEncode(list.map((e) => e.toJson()).toList());

  static List<CachedConversation> decodeList(String data) =>
      (jsonDecode(data) as List)
          .map((e) => CachedConversation.fromJson(e as Map<String, dynamic>))
          .toList();
}
