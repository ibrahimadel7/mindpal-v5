class Conversation {
  const Conversation({required this.id, required this.createdAt, this.title});

  final String id;
  final DateTime createdAt;
  final String? title;

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'].toString(),
      title: json['title']?.toString(),
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class Message {
  const Message({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String conversationId;
  final String role;
  final String text;
  final DateTime createdAt;

  bool get isUser => role.toLowerCase() == 'user';

  factory Message.fromJson(
    Map<String, dynamic> json, {
    required String conversationId,
  }) {
    return Message(
      id: json['id']?.toString() ?? '${DateTime.now().millisecondsSinceEpoch}',
      conversationId: json['conversation_id']?.toString() ?? conversationId,
      role: json['role']?.toString() ?? 'assistant',
      text:
          json['text']?.toString() ??
          json['content']?.toString() ??
          json['message']?.toString() ??
          '',
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
