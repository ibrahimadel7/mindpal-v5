// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recommendations_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(RecommendationsNotifier)
final recommendationsProvider = RecommendationsNotifierProvider._();

final class RecommendationsNotifierProvider
    extends $NotifierProvider<RecommendationsNotifier, RecommendationsState> {
  RecommendationsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recommendationsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recommendationsNotifierHash();

  @$internal
  @override
  RecommendationsNotifier create() => RecommendationsNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RecommendationsState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RecommendationsState>(value),
    );
  }
}

String _$recommendationsNotifierHash() =>
    r'538917e089a98f8c13af346cb88050895989b2fc';

abstract class _$RecommendationsNotifier
    extends $Notifier<RecommendationsState> {
  RecommendationsState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<RecommendationsState, RecommendationsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<RecommendationsState, RecommendationsState>,
              RecommendationsState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
