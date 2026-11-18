// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'insights_local_cache.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(insightsLocalCache)
final insightsLocalCacheProvider = InsightsLocalCacheProvider._();

final class InsightsLocalCacheProvider
    extends
        $FunctionalProvider<
          InsightsLocalCache,
          InsightsLocalCache,
          InsightsLocalCache
        >
    with $Provider<InsightsLocalCache> {
  InsightsLocalCacheProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'insightsLocalCacheProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$insightsLocalCacheHash();

  @$internal
  @override
  $ProviderElement<InsightsLocalCache> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  InsightsLocalCache create(Ref ref) {
    return insightsLocalCache(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InsightsLocalCache value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InsightsLocalCache>(value),
    );
  }
}

String _$insightsLocalCacheHash() =>
    r'0d4045c1bdcf2cb5db20f4d8f69b36e4447b8649';
