import 'package:isar/isar.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mindpal_app/shared/data/cache/cached_conversation.dart';
import 'package:mindpal_app/shared/data/cache/cached_insights.dart';
import 'package:mindpal_app/shared/data/cache/cached_message.dart';
import 'package:mindpal_app/shared/data/cache/pending_message.dart';
import 'package:mindpal_app/shared/services/storage_interface.dart';
import 'package:mindpal_app/shared/services/storage_stub.dart'
    if (dart.library.html) 'package:mindpal_app/shared/services/storage_web.dart'
    if (dart.library.io) 'package:mindpal_app/shared/services/storage_mobile.dart';

/// Keys for SharedPreferences storage
class CacheKeys {
  static String conversations(int userId) => 'cache_conversations_$userId';
  static String messages(String conversationId) =>
      'cache_messages_$conversationId';
  static String insights(int userId) => 'cache_insights_$userId';
  static const String pendingMessages = 'cache_pending_messages';
}

class LocalCacheService {
  Isar? _isar;
  bool _disabled = false;
  StorageInterface? _storage;
  SharedPreferences? _prefs;

  /// Returns the platform-specific storage implementation.
  StorageInterface get storage => _storage ??= createStorage();

  /// Returns SharedPreferences instance for cache storage.
  Future<SharedPreferences> get prefs async =>
      _prefs ??= await SharedPreferences.getInstance();

  Future<Isar?> instance() async {
    // Web builds in this project use an in-memory chat cache only.
    if (kIsWeb || _disabled) {
      _disabled = true;
      return null;
    }

    if (_isar != null && _isar!.isOpen) {
      return _isar!;
    }

    try {
      final dirPath = await storage.getStorageDirectoryPath();
      _isar = await Isar.open(
        <CollectionSchema>[
          // Existing schemas only - new caches use SharedPreferences
        ],
        directory: dirPath,
        name: 'mindpal_cache',
      );
      return _isar!;
    } catch (_) {
      _disabled = true;
      return null;
    }
  }

  // ============ Conversations Cache ============

  Future<List<CachedConversation>> getConversations(int userId) async {
    final p = await prefs;
    final data = p.getString(CacheKeys.conversations(userId));
    if (data == null) return [];
    try {
      return CachedConversation.decodeList(data);
    } catch (_) {
      return [];
    }
  }

  Future<void> saveConversations(
      int userId, List<CachedConversation> conversations) async {
    final p = await prefs;
    await p.setString(
        CacheKeys.conversations(userId), CachedConversation.encodeList(conversations));
  }

  // ============ Messages Cache ============

  Future<List<CachedMessage>> getMessages(String conversationId) async {
    final p = await prefs;
    final data = p.getString(CacheKeys.messages(conversationId));
    if (data == null) return [];
    try {
      return CachedMessage.decodeList(data);
    } catch (_) {
      return [];
    }
  }

  Future<void> saveMessages(
      String conversationId, List<CachedMessage> messages) async {
    final p = await prefs;
    await p.setString(
        CacheKeys.messages(conversationId), CachedMessage.encodeList(messages));
  }

  // ============ Insights Cache ============

  Future<CachedInsights?> getInsights(int userId) async {
    final p = await prefs;
    final data = p.getString(CacheKeys.insights(userId));
    return CachedInsights.decode(data);
  }

  Future<void> saveInsights(CachedInsights insights) async {
    final p = await prefs;
    await p.setString(CacheKeys.insights(insights.userId), insights.encode());
  }

  Future<void> clearInsights(int userId) async {
    final p = await prefs;
    await p.remove(CacheKeys.insights(userId));
  }

  // ============ Pending Messages Queue ============

  Future<List<PendingMessage>> getPendingMessages() async {
    final p = await prefs;
    final data = p.getString(CacheKeys.pendingMessages);
    if (data == null) return [];
    try {
      return PendingMessage.decodeList(data);
    } catch (_) {
      return [];
    }
  }

  Future<void> savePendingMessages(List<PendingMessage> messages) async {
    final p = await prefs;
    await p.setString(
        CacheKeys.pendingMessages, PendingMessage.encodeList(messages));
  }

  Future<void> addPendingMessage(PendingMessage message) async {
    final messages = await getPendingMessages();
    messages.add(message);
    await savePendingMessages(messages);
  }

  Future<void> removePendingMessage(String localId) async {
    final messages = await getPendingMessages();
    messages.removeWhere((m) => m.localId == localId);
    await savePendingMessages(messages);
  }

  Future<void> updatePendingMessage(PendingMessage message) async {
    final messages = await getPendingMessages();
    final index = messages.indexWhere((m) => m.localId == message.localId);
    if (index >= 0) {
      messages[index] = message;
      await savePendingMessages(messages);
    }
  }

  // ============ Clear All ============

  Future<void> clearAll() async {
    final isar = await instance();
    if (isar != null) {
      await isar.close(deleteFromDisk: true);
      _isar = null;
    }

    final p = await prefs;
    final keys = p.getKeys().where((k) => k.startsWith('cache_'));
    for (final key in keys) {
      await p.remove(key);
    }
  }
}
