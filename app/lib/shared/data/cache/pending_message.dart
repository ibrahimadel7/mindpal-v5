import 'dart:convert';

/// Message queued for sending when offline.
class PendingMessage {
  /// Local temporary ID for optimistic UI
  final String localId;
  final String conversationId;
  final String text;
  final DateTime createdAt;

  /// Number of send attempts
  final int retryCount;

  /// Last error message if send failed
  final String? lastError;

  /// Status: 'pending', 'sending', 'failed'
  final String status;

  PendingMessage({
    required this.localId,
    required this.conversationId,
    required this.text,
    required this.createdAt,
    this.retryCount = 0,
    this.lastError,
    this.status = 'pending',
  });

  Map<String, dynamic> toJson() => {
        'localId': localId,
        'conversationId': conversationId,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
        'retryCount': retryCount,
        'lastError': lastError,
        'status': status,
      };

  factory PendingMessage.fromJson(Map<String, dynamic> json) => PendingMessage(
        localId: json['localId'] as String,
        conversationId: json['conversationId'] as String,
        text: json['text'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        retryCount: json['retryCount'] as int? ?? 0,
        lastError: json['lastError'] as String?,
        status: json['status'] as String? ?? 'pending',
      );

  PendingMessage copyWith({
    int? retryCount,
    String? lastError,
    String? status,
  }) =>
      PendingMessage(
        localId: localId,
        conversationId: conversationId,
        text: text,
        createdAt: createdAt,
        retryCount: retryCount ?? this.retryCount,
        lastError: lastError ?? this.lastError,
        status: status ?? this.status,
      );

  static String encodeList(List<PendingMessage> list) =>
      jsonEncode(list.map((e) => e.toJson()).toList());

  static List<PendingMessage> decodeList(String data) =>
      (jsonDecode(data) as List)
          .map((e) => PendingMessage.fromJson(e as Map<String, dynamic>))
          .toList();
}
