// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'habit_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for the selected habit time period

@ProviderFor(HabitPeriodNotifier)
final habitPeriodProvider = HabitPeriodNotifierProvider._();

/// Provider for the selected habit time period
final class HabitPeriodNotifierProvider
    extends $NotifierProvider<HabitPeriodNotifier, HabitPeriod> {
  /// Provider for the selected habit time period
  HabitPeriodNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'habitPeriodProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$habitPeriodNotifierHash();

  @$internal
  @override
  HabitPeriodNotifier create() => HabitPeriodNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HabitPeriod value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HabitPeriod>(value),
    );
  }
}

String _$habitPeriodNotifierHash() =>
    r'98ee34dc08e134cc7c9fc76c540454380c95b889';

/// Provider for the selected habit time period

abstract class _$HabitPeriodNotifier extends $Notifier<HabitPeriod> {
  HabitPeriod build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<HabitPeriod, HabitPeriod>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<HabitPeriod, HabitPeriod>,
              HabitPeriod,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Provider for the currently selected/highlighted habit in the chart

@ProviderFor(SelectedHabit)
final selectedHabitProvider = SelectedHabitProvider._();

/// Provider for the currently selected/highlighted habit in the chart
final class SelectedHabitProvider
    extends $NotifierProvider<SelectedHabit, String?> {
  /// Provider for the currently selected/highlighted habit in the chart
  SelectedHabitProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedHabitProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedHabitHash();

  @$internal
  @override
  SelectedHabit create() => SelectedHabit();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$selectedHabitHash() => r'63f844b77e2a25347303936ebaabe58935844321';

/// Provider for the currently selected/highlighted habit in the chart

abstract class _$SelectedHabit extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Provider that fetches habits based on the selected period

@ProviderFor(periodFilteredHabits)
final periodFilteredHabitsProvider = PeriodFilteredHabitsProvider._();

/// Provider that fetches habits based on the selected period

final class PeriodFilteredHabitsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<HabitStat>>,
          List<HabitStat>,
          FutureOr<List<HabitStat>>
        >
    with $FutureModifier<List<HabitStat>>, $FutureProvider<List<HabitStat>> {
  /// Provider that fetches habits based on the selected period
  PeriodFilteredHabitsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'periodFilteredHabitsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$periodFilteredHabitsHash();

  @$internal
  @override
  $FutureProviderElement<List<HabitStat>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<HabitStat>> create(Ref ref) {
    return periodFilteredHabits(ref);
  }
}

String _$periodFilteredHabitsHash() =>
    r'0f9e3bc8cc6b5dcf10d8e01509e17b3a674108fd';
