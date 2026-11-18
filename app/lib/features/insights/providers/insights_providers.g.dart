// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'insights_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(InsightsNotifier)
final insightsProvider = InsightsNotifierProvider._();

final class InsightsNotifierProvider
    extends $NotifierProvider<InsightsNotifier, InsightsState> {
  InsightsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'insightsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$insightsNotifierHash();

  @$internal
  @override
  InsightsNotifier create() => InsightsNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InsightsState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InsightsState>(value),
    );
  }
}

String _$insightsNotifierHash() => r'c1792877ff0f732c9a02bcaae6f73036abc13f9e';

abstract class _$InsightsNotifier extends $Notifier<InsightsState> {
  InsightsState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<InsightsState, InsightsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<InsightsState, InsightsState>,
              InsightsState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(AIOverviewNotifier)
final aIOverviewProvider = AIOverviewNotifierProvider._();

final class AIOverviewNotifierProvider
    extends $NotifierProvider<AIOverviewNotifier, AIOverviewState> {
  AIOverviewNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'aIOverviewProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$aIOverviewNotifierHash();

  @$internal
  @override
  AIOverviewNotifier create() => AIOverviewNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AIOverviewState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AIOverviewState>(value),
    );
  }
}

String _$aIOverviewNotifierHash() =>
    r'6c68b42d73caffb8eff2ab89e24f2d19416f011c';

abstract class _$AIOverviewNotifier extends $Notifier<AIOverviewState> {
  AIOverviewState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AIOverviewState, AIOverviewState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AIOverviewState, AIOverviewState>,
              AIOverviewState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
