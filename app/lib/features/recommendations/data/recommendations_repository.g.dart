// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recommendations_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(recommendationsRepository)
final recommendationsRepositoryProvider = RecommendationsRepositoryProvider._();

final class RecommendationsRepositoryProvider
    extends
        $FunctionalProvider<
          RecommendationsRepository,
          RecommendationsRepository,
          RecommendationsRepository
        >
    with $Provider<RecommendationsRepository> {
  RecommendationsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recommendationsRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recommendationsRepositoryHash();

  @$internal
  @override
  $ProviderElement<RecommendationsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  RecommendationsRepository create(Ref ref) {
    return recommendationsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RecommendationsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RecommendationsRepository>(value),
    );
  }
}

String _$recommendationsRepositoryHash() =>
    r'8b95b7ddd77556074b2f9113a4791a05c98510ab';
