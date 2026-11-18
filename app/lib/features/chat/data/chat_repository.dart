import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:mindpal_app/constants.dart';
import 'package:mindpal_app/features/chat/domain/models.dart';
import 'package:mindpal_app/shared/providers/core_providers.dart';

part 'chat_repository.g.dart';

/// Callback types for streaming chat events
typedef OnThinkingToken = void Function(String token);
typedef OnResponseToken = void Function(String token);
typedef OnStreamComplete = void Function(String fullResponse, String? thinking);
typedef OnStreamError = void Function(String error);

class ChatRepository {
  ChatRepository(this._dio);

  final Dio _dio;

  Future<List<Conversation>> fetchConversations() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/conversations',
      queryParameters: <String, Object?>{'user_id': kUserId},
    );
    final raw =
        response.data?['conversations'] as List<dynamic>? ?? const <dynamic>[];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(Conversation.fromJson)
        .toList(growable: false);
  }

  Future<Conversation> createConversation() async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/conversations',
      data: <String, Object?>{'user_id': kUserId},
    );
    return Conversation.fromJson(response.data ?? <String, dynamic>{});
  }

  Future<void> deleteConversation(String conversationId) async {
    await _dio.delete<void>(
      '/conversations/$conversationId',
      queryParameters: <String, Object?>{'user_id': kUserId},
    );
  }

  Future<List<Message>> fetchMessages(String conversationId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/conversations/$conversationId/messages',
      queryParameters: <String, Object?>{'user_id': kUserId},
    );
    final raw =
        response.data?['messages'] as List<dynamic>? ?? const <dynamic>[];
    return raw
        .whereType<Map<String, dynamic>>()
        .map((json) => Message.fromJson(json, conversationId: conversationId))
        .toList(growable: false);
  }

  Future<String> sendMessage({
    required String conversationId,
    required String message,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/chat',
      data: <String, Object?>{
        'user_id': kUserId,
        'conversation_id': conversationId,
        'message': message,
      },
    );

    final data = response.data ?? const <String, dynamic>{};
    return data['response']?.toString() ?? data['message']?.toString() ?? '';
  }

  /// Stream chat response with thinking tokens via SSE
  Future<void> streamMessage({
    required String conversationId,
    required String message,
    OnThinkingToken? onThinkingToken,
    OnResponseToken? onResponseToken,
    OnStreamComplete? onComplete,
    OnStreamError? onError,
  }) async {
    try {
      final response = await _dio.post<ResponseBody>(
        '/chat/stream',
        data: <String, Object?>{
          'user_id': kUserId,
          'conversation_id': conversationId,
          'message': message,
        },
        options: Options(
          responseType: ResponseType.stream,
          headers: {
            'Accept': 'text/event-stream',
          },
        ),
      );

      final stream = response.data?.stream;
      if (stream == null) {
        onError?.call('No stream available');
        return;
      }

      final thinkingBuffer = StringBuffer();
      final responseBuffer = StringBuffer();
      String eventBuffer = '';

      await for (final chunk in stream) {
        final text = utf8.decode(chunk);
        eventBuffer += text;

        // Process complete SSE events (separated by double newline)
        while (eventBuffer.contains('\n\n')) {
          final eventEnd = eventBuffer.indexOf('\n\n');
          final eventBlock = eventBuffer.substring(0, eventEnd);
          eventBuffer = eventBuffer.substring(eventEnd + 2);

          _processSSEEvent(
            eventBlock,
            onThinkingToken: (token) {
              thinkingBuffer.write(token);
              onThinkingToken?.call(token);
            },
            onResponseToken: (token) {
              responseBuffer.write(token);
              onResponseToken?.call(token);
            },
            onComplete: () {
              onComplete?.call(
                responseBuffer.toString(),
                thinkingBuffer.isEmpty ? null : thinkingBuffer.toString(),
              );
            },
            onError: onError,
          );
        }
      }

      // Handle any remaining buffer
      if (eventBuffer.trim().isNotEmpty) {
        _processSSEEvent(
          eventBuffer,
          onThinkingToken: (token) {
            thinkingBuffer.write(token);
            onThinkingToken?.call(token);
          },
          onResponseToken: (token) {
            responseBuffer.write(token);
            onResponseToken?.call(token);
          },
          onComplete: () {
            onComplete?.call(
              responseBuffer.toString(),
              thinkingBuffer.isEmpty ? null : thinkingBuffer.toString(),
            );
          },
          onError: onError,
        );
      }
    } catch (e) {
      onError?.call(e.toString());
    }
  }

  void _processSSEEvent(
    String eventBlock, {
    required OnThinkingToken onThinkingToken,
    required OnResponseToken onResponseToken,
    required VoidCallback onComplete,
    OnStreamError? onError,
  }) {
    final lines = eventBlock.split('\n');
    String? eventType;
    final dataLines = <String>[];

    for (final line in lines) {
      if (line.startsWith('event:')) {
        eventType = line.substring(6).trim();
      } else if (line.startsWith('data:')) {
        dataLines.add(line.substring(5).trim());
      }
    }

    if (dataLines.isEmpty) return;

    final dataStr = dataLines.join('\n');
    Map<String, dynamic>? data;
    try {
      data = json.decode(dataStr) as Map<String, dynamic>?;
    } catch (_) {
      return;
    }

    if (data == null) return;

    switch (eventType) {
      case 'thinking_token':
        final token = data['token']?.toString() ?? '';
        if (token.isNotEmpty) {
          onThinkingToken(token);
        }
      case 'token':
        final token = data['token']?.toString() ?? '';
        if (token.isNotEmpty) {
          onResponseToken(token);
        }
      case 'message_end':
        onComplete();
      case 'error':
        onError?.call(data['message']?.toString() ?? 'Stream error');
    }
  }
}

typedef VoidCallback = void Function();

@riverpod
ChatRepository chatRepository(Ref ref) {
  final dio = ref.watch(dioProvider);
  return ChatRepository(dio);
}
