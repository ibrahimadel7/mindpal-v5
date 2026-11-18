import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:mindpal_app/features/chat/domain/models.dart';
import 'package:mindpal_app/shared/providers/local_cache_provider.dart';
import 'package:mindpal_app/shared/services/local_cache_service.dart';

part 'chat_local_cache.g.dart';

class ChatLocalCache {
  ChatLocalCache(this._localCacheService);

  final LocalCacheService _localCacheService;
  final Map<String, List<Message>> _memoryCache = <String, List<Message>>{};

  Future<void> warmup() async {
    try {
      await _localCacheService.instance();
    } catch (_) {
      // Local cache is optional; keep chat available even if cache init fails.
    }
  }

  List<Message> readMessages(String conversationId) {
    return List<Message>.from(
      _memoryCache[conversationId] ?? const <Message>[],
    );
  }

  Future<void> writeMessages(
    String conversationId,
    List<Message> messages,
  ) async {
    _memoryCache[conversationId] = List<Message>.from(messages);
    await _localCacheService.instance();
  }

  Future<void> clearConversation(String conversationId) async {
    _memoryCache.remove(conversationId);
  }

  Future<void> clear() async {
    _memoryCache.clear();
    await _localCacheService.clearAll();
  }
}

@riverpod
ChatLocalCache chatLocalCache(Ref ref) {
  final service = ref.watch(localCacheServiceProvider);
  return ChatLocalCache(service);
}
