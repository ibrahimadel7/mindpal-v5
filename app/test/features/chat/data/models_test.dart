import 'package:flutter_test/flutter_test.dart';
import 'package:mindpal_app/features/chat/domain/models.dart';

void main() {
  group('Conversation', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 123,
        'title': 'Test Conversation',
        'created_at': '2024-01-15T10:30:00.000Z',
      };

      final conversation = Conversation.fromJson(json);

      expect(conversation.id, equals('123'));
      expect(conversation.title, equals('Test Conversation'));
      expect(conversation.createdAt.year, equals(2024));
      expect(conversation.createdAt.month, equals(1));
      expect(conversation.createdAt.day, equals(15));
    });

    test('fromJson handles null title', () {
      final json = {
        'id': 456,
        'title': null,
        'created_at': '2024-02-20T14:00:00.000Z',
      };

      final conversation = Conversation.fromJson(json);

      expect(conversation.id, equals('456'));
      expect(conversation.title, isNull);
    });

    test('fromJson handles missing created_at', () {
      final json = {
        'id': 789,
        'title': 'No Date',
      };

      final conversation = Conversation.fromJson(json);

      expect(conversation.id, equals('789'));
      expect(conversation.createdAt, isNotNull);
    });

    test('copyWith creates new instance with updated values', () {
      final original = Conversation(
        id: '1',
        createdAt: DateTime(2024, 1, 1),
        title: 'Original',
      );

      final updated = original.copyWith(title: 'Updated');

      expect(updated.title, equals('Updated'));
      expect(updated.id, equals('1'));
    });
  });

  group('Message', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 42,
        'conversation_id': '100',
        'role': 'user',
        'text': 'Hello world',
        'created_at': '2024-03-10T09:15:00.000Z',
        'thinking': 'Processing...',
      };

      final message = Message.fromJson(json, conversationId: '100');

      expect(message.id, equals('42'));
      expect(message.conversationId, equals('100'));
      expect(message.role, equals('user'));
      expect(message.text, equals('Hello world'));
      expect(message.thinking, equals('Processing...'));
      expect(message.isUser, isTrue);
    });

    test('fromJson uses content field as fallback for text', () {
      final json = {
        'id': 43,
        'role': 'assistant',
        'content': 'Response content',
      };

      final message = Message.fromJson(json, conversationId: '101');

      expect(message.text, equals('Response content'));
    });

    test('fromJson uses message field as fallback for text', () {
      final json = {
        'id': 44,
        'role': 'assistant',
        'message': 'Message fallback',
      };

      final message = Message.fromJson(json, conversationId: '102');

      expect(message.text, equals('Message fallback'));
    });

    test('isUser returns true for user role', () {
      final message = Message(
        id: '1',
        conversationId: '1',
        role: 'user',
        text: 'Test',
        createdAt: DateTime.now(),
      );

      expect(message.isUser, isTrue);
    });

    test('isUser returns false for assistant role', () {
      final message = Message(
        id: '1',
        conversationId: '1',
        role: 'assistant',
        text: 'Test',
        createdAt: DateTime.now(),
      );

      expect(message.isUser, isFalse);
    });

    test('isUser handles case insensitively', () {
      final message = Message(
        id: '1',
        conversationId: '1',
        role: 'USER',
        text: 'Test',
        createdAt: DateTime.now(),
      );

      expect(message.isUser, isTrue);
    });

    test('copyWith creates new instance with updated values', () {
      final original = Message(
        id: '1',
        conversationId: '1',
        role: 'user',
        text: 'Original',
        createdAt: DateTime.now(),
      );

      final updated = original.copyWith(text: 'Updated', thinking: 'New thinking');

      expect(updated.text, equals('Updated'));
      expect(updated.thinking, equals('New thinking'));
      expect(updated.id, equals('1'));
      expect(updated.role, equals('user'));
    });
  });
}
