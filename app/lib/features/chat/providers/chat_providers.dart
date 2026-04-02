import 'dart:async';
import 'dart:math';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:mindpal_app/features/chat/data/chat_local_cache.dart';
import 'package:mindpal_app/features/chat/data/chat_repository.dart';
import 'package:mindpal_app/features/chat/domain/models.dart';

part 'chat_providers.g.dart';

class ChatState {
  const ChatState({
    required this.currentConversationId,
    required this.messages,
    required this.isInitializing,
    required this.isSending,
    required this.showStreaming,
    this.error,
  });

  factory ChatState.initial() => const ChatState(
    currentConversationId: null,
    messages: <String, List<Message>>{},
    isInitializing: false,
    isSending: false,
    showStreaming: false,
  );

  final String? currentConversationId;
  final Map<String, List<Message>> messages;
  final bool isInitializing;
  final bool isSending;
  final bool showStreaming;
  final String? error;

  List<Message> get currentMessages {
    final id = currentConversationId;
    if (id == null) {
      return const <Message>[];
    }
    return messages[id] ?? const <Message>[];
  }

  ChatState copyWith({
    String? currentConversationId,
    Map<String, List<Message>>? messages,
    bool? isInitializing,
    bool? isSending,
    bool? showStreaming,
    String? error,
  }) {
    return ChatState(
      currentConversationId:
          currentConversationId ?? this.currentConversationId,
      messages: messages ?? this.messages,
      isInitializing: isInitializing ?? this.isInitializing,
      isSending: isSending ?? this.isSending,
      showStreaming: showStreaming ?? this.showStreaming,
      error: error,
    );
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
    return ChatState.initial();
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

    final list = <Message>[...state.currentMessages, userMessage];
    state = state.copyWith(
      messages: <String, List<Message>>{
        ...state.messages,
        conversationId: list,
      },
      isSending: true,
      showStreaming: true,
      error: null,
    );

    try {
      final response = await repo.sendMessage(
        conversationId: conversationId,
        message: text.trim(),
      );
      // Check if provider is still mounted after async operation
      if (!ref.mounted) return;

      final assistantMessage = Message(
        id: '${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(999)}',
        conversationId: conversationId,
        role: 'assistant',
        text: response,
        createdAt: DateTime.now(),
      );
      state = state.copyWith(
        messages: <String, List<Message>>{
          ...state.messages,
          conversationId: <Message>[...list, assistantMessage],
        },
        isSending: false,
        showStreaming: false,
      );
      ref.invalidate(conversationsProvider);
      await ref
          .read(chatLocalCacheProvider)
          .writeMessages(
            conversationId,
            state.messages[conversationId] ?? const <Message>[],
          );
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        isSending: false,
        showStreaming: false,
        error: 'Unable to send message. Please try again.',
      );
    }
  }
}
