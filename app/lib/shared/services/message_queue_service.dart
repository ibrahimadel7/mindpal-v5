import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:mindpal_app/features/chat/data/chat_repository.dart';
import 'package:mindpal_app/shared/data/cache/pending_message.dart';
import 'package:mindpal_app/shared/providers/local_cache_provider.dart';
import 'package:mindpal_app/shared/services/local_cache_service.dart';
import 'package:mindpal_app/shared/utils/connectivity_service.dart';
import 'package:mindpal_app/shared/utils/retry_helper.dart';

part 'message_queue_service.g.dart';

/// Service for queuing messages when offline and syncing when back online.
class MessageQueueService {
  MessageQueueService({
    required this.localCacheService,
    required this.chatRepository,
    required this.connectivityService,
  });

  final LocalCacheService localCacheService;
  final ChatRepository chatRepository;
  final ConnectivityService connectivityService;

  StreamSubscription<ConnectivityStatus>? _connectivitySubscription;
  bool _isSyncing = false;

  final _pendingCountController = StreamController<int>.broadcast();
  Stream<int> get pendingCountStream => _pendingCountController.stream;

  /// Initialize the service and start listening for connectivity changes.
  void initialize() {
    _connectivitySubscription = connectivityService.statusStream.listen((status) {
      if (status == ConnectivityStatus.online) {
        syncPendingMessages();
      }
    });
  }

  /// Queue a message for sending when offline.
  Future<PendingMessage?> queueMessage({
    required String localId,
    required String conversationId,
    required String text,
  }) async {
    final pending = PendingMessage(
      localId: localId,
      conversationId: conversationId,
      text: text,
      createdAt: DateTime.now(),
      retryCount: 0,
      status: 'pending',
    );

    await localCacheService.addPendingMessage(pending);
    _emitPendingCount();
    return pending;
  }

  /// Get all pending messages for a conversation.
  Future<List<PendingMessage>> getPendingMessages(String conversationId) async {
    final all = await localCacheService.getPendingMessages();
    return all
        .where((m) => m.conversationId == conversationId)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  /// Get count of all pending messages.
  Future<int> getPendingCount() async {
    final all = await localCacheService.getPendingMessages();
    return all.where((m) => m.status == 'pending' || m.status == 'failed').length;
  }

  /// Sync all pending messages to the server.
  Future<void> syncPendingMessages() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final all = await localCacheService.getPendingMessages();
      final pendingMessages = all
          .where((m) => m.status == 'pending' || m.status == 'failed')
          .toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

      for (final message in pendingMessages) {
        await _syncSingleMessage(message);
      }
    } finally {
      _isSyncing = false;
      _emitPendingCount();
    }
  }

  Future<void> _syncSingleMessage(PendingMessage message) async {
    // Mark as sending
    await localCacheService.updatePendingMessage(
      message.copyWith(status: 'sending'),
    );

    try {
      final retryHelper = RetryHelper(RetryConfig.critical);
      await retryHelper.executeOrThrow(() async {
        await chatRepository.sendMessage(
          conversationId: message.conversationId,
          message: message.text,
        );
      });

      // Success - remove from queue
      await localCacheService.removePendingMessage(message.localId);
    } catch (e) {
      // Failed - mark as failed and increment retry count
      await localCacheService.updatePendingMessage(
        message.copyWith(
          status: 'failed',
          retryCount: message.retryCount + 1,
          lastError: e.toString(),
        ),
      );
    }
  }

  /// Remove a pending message from the queue.
  Future<void> removePendingMessage(String localId) async {
    await localCacheService.removePendingMessage(localId);
    _emitPendingCount();
  }

  /// Clear all pending messages.
  Future<void> clearAll() async {
    await localCacheService.savePendingMessages([]);
    _emitPendingCount();
  }

  void _emitPendingCount() {
    getPendingCount().then(_pendingCountController.add);
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _pendingCountController.close();
  }
}

@Riverpod(keepAlive: true)
MessageQueueService messageQueueService(Ref ref) {
  final localCache = ref.watch(localCacheServiceProvider);
  final chatRepo = ref.watch(chatRepositoryProvider);
  final connectivity = ref.watch(connectivityServiceProvider);

  final service = MessageQueueService(
    localCacheService: localCache,
    chatRepository: chatRepo,
    connectivityService: connectivity,
  );

  service.initialize();
  ref.onDispose(service.dispose);

  return service;
}

@riverpod
Stream<int> pendingMessageCount(Ref ref) {
  final service = ref.watch(messageQueueServiceProvider);
  return service.pendingCountStream;
}
