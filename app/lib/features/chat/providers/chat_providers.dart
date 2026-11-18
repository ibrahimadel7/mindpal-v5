import 'dart:async';
import 'dart:math';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:mindpal_app/features/chat/data/chat_local_cache.dart';
import 'package:mindpal_app/features/chat/data/chat_repository.dart';
import 'package:mindpal_app/features/chat/domain/models.dart';

part 'chat_providers.g.dart';
part 'chat_providers.freezed.dart';

@freezed
sealed class ChatState with _$ChatState {
  const ChatState._();

  const factory ChatState({
    String? currentConversationId,
    @Default(<String, List<Message>>{}) Map<String, List<Message>> messages,
    @Default(false) bool isInitializing,
    @Default(false) bool isSending,
    @Default(false) bool showStreaming,
    @Default(false) bool isThinking,
    String? streamingMessageId,
    String? error,
  }) = _ChatState;

  List<Message> get currentMessages {
    final id = currentConversationId;
    if (id == null) return const <Message>[];
    return messages[id] ?? const <Message>[];
  }
}

@Riverpod(keepAlive: true)
Future<List<Conversation>> conversations(Ref ref) async {
  final repo = ref.watch(chatRepositoryProvider);
  return repo.fetchConversations();
}

@Riverpod(keepAlive: true)
class ChatNotifier extends _$ChatNotifier {
  @override
  ChatState build() {
    ref.onDispose(() {
      // Cancel any in-flight operations when disposed
    });
    ref.read(chatLocalCacheProvider).warmup();
    return const ChatState();
  }

  Future<void> ensureConversation() async {
    if (state.currentConversationId != null) {
      return;
    }
    state = state.copyWith(isInitializing: true, error: null);

    try {
      // Always start with a fresh empty conversation
      final repo = ref.read(chatRepositoryProvider);
      final created = await repo.createConversation();
      
      // Check if provider is still mounted after async operation
      if (!ref.mounted) return;

      state = state.copyWith(
        currentConversationId: created.id,
        isInitializing: false,
      );
      ref.invalidate(conversationsProvider);
    } catch (_) {
      if (!ref.mounted) return;
      state = state.copyWith(
        isInitializing: false,
        error: 'Unable to start your conversation right now.',
      );
    }
  }

  Future<void> switchConversation(String conversationId) async {
    state = state.copyWith(
      currentConversationId: conversationId,
      isInitializing: true,
    );

    // First check local cache
    final cached = ref
        .read(chatLocalCacheProvider)
        .readMessages(conversationId);
    
    if (cached.isNotEmpty) {
      state = state.copyWith(
        messages: <String, List<Message>>{
          ...state.messages,
          conversationId: cached,
        },
        isInitializing: false,
      );
      return;
    }

    // If cache is empty, fetch from backend
    try {
      final repo = ref.read(chatRepositoryProvider);
      final messages = await repo.fetchMessages(conversationId);
      if (!ref.mounted) return;

      state = state.copyWith(
        messages: <String, List<Message>>{
          ...state.messages,
          conversationId: messages,
        },
        isInitializing: false,
      );

      // Update local cache
      await ref
          .read(chatLocalCacheProvider)
          .writeMessages(conversationId, messages);
    } catch (_) {
      if (!ref.mounted) return;
      state = state.copyWith(
        isInitializing: false,
        error: 'Unable to load conversation messages.',
      );
    }
  }

  Future<void> startNewConversation() async {
    // Check if current conversation has any messages
    final currentMessages = state.currentMessages;
    if (currentMessages.isEmpty && state.currentConversationId != null) {
      // Current conversation is empty, don't create a new one
      return;
    }

    state = state.copyWith(isInitializing: true, error: null);
    try {
      final repo = ref.read(chatRepositoryProvider);
      final created = await repo.createConversation();
      if (!ref.mounted) return;

      state = state.copyWith(
        currentConversationId: created.id,
        messages: <String, List<Message>>{
          ...state.messages,
          created.id: <Message>[],
        },
        isInitializing: false,
      );
      ref.invalidate(conversationsProvider);
    } catch (_) {
      if (!ref.mounted) return;
      state = state.copyWith(
        isInitializing: false,
        error: 'Unable to start a new conversation right now.',
      );
    }
  }

  Future<void> deleteConversation(String conversationId) async {
    try {
      final repo = ref.read(chatRepositoryProvider);
      await repo.deleteConversation(conversationId);
      
      if (!ref.mounted) return;

      // Remove from local state
      final updatedMessages = Map<String, List<Message>>.from(state.messages);
      updatedMessages.remove(conversationId);

      // If we deleted the current conversation, create a new one
      if (state.currentConversationId == conversationId) {
        final created = await repo.createConversation();
        if (!ref.mounted) return;

        state = state.copyWith(
          currentConversationId: created.id,
          messages: updatedMessages,
        );
      } else {
        state = state.copyWith(messages: updatedMessages);
      }

      // Clear from cache
      await ref.read(chatLocalCacheProvider).clearConversation(conversationId);

      // Refresh conversations list
      ref.invalidate(conversationsProvider);
    } catch (_) {
      // Silently fail or show error
    }
  }

  Future<void> send(String text) async {
    if (text.trim().isEmpty) {
      return;
    }

    await ensureConversation();
    // Check if provider is still mounted after async operation
    if (!ref.mounted) return;

    final conversationId = state.currentConversationId;
    if (conversationId == null) {
      return;
    }

    final repo = ref.read(chatRepositoryProvider);
    final userMessage = Message(
      id: '${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(999)}',
      conversationId: conversationId,
      role: 'user',
      text: text.trim(),
      createdAt: DateTime.now(),
    );

    // Create placeholder assistant message for streaming
    final assistantMessageId = '${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(999)}';
    final assistantPlaceholder = Message(
      id: assistantMessageId,
      conversationId: conversationId,
      role: 'assistant',
      text: '',
      createdAt: DateTime.now(),
    );

    // Haptic feedback on send
    HapticFeedback.lightImpact();

    final list = <Message>[...state.currentMessages, userMessage, assistantPlaceholder];
    state = state.copyWith(
      messages: <String, List<Message>>{
        ...state.messages,
        conversationId: list,
      },
      isSending: true,
      showStreaming: true,
      isThinking: true,
      streamingMessageId: assistantMessageId,
      error: null,
    );

    final completer = Completer<void>();

    repo.streamMessage(
      conversationId: conversationId,
      message: text.trim(),
      onThinkingToken: (token) {
        if (!ref.mounted) return;
        _updateStreamingMessage(conversationId, assistantMessageId, thinkingToken: token);
      },
      onResponseToken: (token) {
        if (!ref.mounted) return;
        // When first response token arrives, stop thinking phase
        if (state.isThinking) {
          state = state.copyWith(isThinking: false);
        }
        _updateStreamingMessage(conversationId, assistantMessageId, responseToken: token);
      },
      onComplete: (fullResponse, thinking) async {
        if (!ref.mounted) {
          completer.complete();
          return;
        }
        
        // Haptic feedback on message receive complete
        HapticFeedback.selectionClick();
        
        // Update final message
        final currentList = state.messages[conversationId] ?? <Message>[];
        final updatedList = currentList.map((m) {
          if (m.id == assistantMessageId) {
            return m.copyWith(
              text: fullResponse.isNotEmpty ? fullResponse : m.text,
              thinking: thinking ?? m.thinking,
            );
          }
          return m;
        }).toList();

        state = state.copyWith(
          messages: <String, List<Message>>{
            ...state.messages,
            conversationId: updatedList,
          },
          isSending: false,
          showStreaming: false,
          isThinking: false,
          streamingMessageId: null,
        );

        ref.invalidate(conversationsProvider);
        await ref.read(chatLocalCacheProvider).writeMessages(
          conversationId,
          updatedList,
        );
        completer.complete();
      },
      onError: (error) {
        if (!ref.mounted) {
          completer.complete();
          return;
        }
        // Haptic feedback on error
        HapticFeedback.heavyImpact();
        
        state = state.copyWith(
          isSending: false,
          showStreaming: false,
          isThinking: false,
          streamingMessageId: null,
          error: 'Unable to send message. Please try again.',
        );
        completer.complete();
      },
    );

    await completer.future;
  }

  void _updateStreamingMessage(
    String conversationId,
    String messageId, {
    String? thinkingToken,
    String? responseToken,
  }) {
    final currentList = state.messages[conversationId] ?? <Message>[];
    final updatedList = currentList.map((m) {
      if (m.id == messageId) {
        return m.copyWith(
          thinking: thinkingToken != null 
              ? '${m.thinking ?? ''}$thinkingToken' 
              : m.thinking,
          text: responseToken != null 
              ? '${m.text}$responseToken' 
              : m.text,
        );
      }
      return m;
    }).toList();

    state = state.copyWith(
      messages: <String, List<Message>>{
        ...state.messages,
        conversationId: updatedList,
      },
    );
  }
}
