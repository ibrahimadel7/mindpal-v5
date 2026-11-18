import 'dart:convert';

/// Cached insights data for offline support.
class CachedInsights {
  final int userId;

  /// JSON-encoded list of emotion stats
  final String emotionsJson;

  /// JSON-encoded list of habit stats
  final String habitsJson;

  /// JSON-encoded summary object
  final String summaryJson;

  /// JSON-encoded list of time insights
  final String timeJson;

  final DateTime cachedAt;

  CachedInsights({
    required this.userId,
    required this.emotionsJson,
    required this.habitsJson,
    required this.summaryJson,
    required this.timeJson,
    required this.cachedAt,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'emotionsJson': emotionsJson,
        'habitsJson': habitsJson,
        'summaryJson': summaryJson,
        'timeJson': timeJson,
        'cachedAt': cachedAt.toIso8601String(),
      };

  factory CachedInsights.fromJson(Map<String, dynamic> json) => CachedInsights(
        userId: json['userId'] as int,
        emotionsJson: json['emotionsJson'] as String,
        habitsJson: json['habitsJson'] as String,
        summaryJson: json['summaryJson'] as String,
        timeJson: json['timeJson'] as String,
        cachedAt: DateTime.parse(json['cachedAt'] as String),
      );

  String encode() => jsonEncode(toJson());

  static CachedInsights? decode(String? data) {
    if (data == null) return null;
    return CachedInsights.fromJson(jsonDecode(data) as Map<String, dynamic>);
  }
}
