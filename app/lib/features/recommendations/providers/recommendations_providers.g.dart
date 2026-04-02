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
    r'f409a2149c4c17bec3e10700eb1c23a4b2b908e9';

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
