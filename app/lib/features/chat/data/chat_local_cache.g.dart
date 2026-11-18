// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_local_cache.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(chatLocalCache)
final chatLocalCacheProvider = ChatLocalCacheProvider._();

final class ChatLocalCacheProvider
    extends $FunctionalProvider<ChatLocalCache, ChatLocalCache, ChatLocalCache>
    with $Provider<ChatLocalCache> {
  ChatLocalCacheProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatLocalCacheProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatLocalCacheHash();

  @$internal
  @override
  $ProviderElement<ChatLocalCache> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ChatLocalCache create(Ref ref) {
    return chatLocalCache(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChatLocalCache value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChatLocalCache>(value),
    );
  }
}

String _$chatLocalCacheHash() => r'37d41c41143083d802c7db7d527c39f2a47d154b';
