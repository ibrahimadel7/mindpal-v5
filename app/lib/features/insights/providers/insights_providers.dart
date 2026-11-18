import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:mindpal_app/constants.dart';
import 'package:mindpal_app/features/insights/data/insights_local_cache.dart';
import 'package:mindpal_app/features/insights/data/insights_repository.dart';
import 'package:mindpal_app/features/insights/domain/models.dart';
import 'package:mindpal_app/shared/utils/connectivity_service.dart';

part 'insights_providers.g.dart';
part 'insights_providers.freezed.dart';

@freezed
sealed class InsightsState with _$InsightsState {
  const InsightsState._();

  const factory InsightsState({
    @Default(<EmotionStat>[]) List<EmotionStat> emotions,
    @Default(<HabitStat>[]) List<HabitStat> habits,
    @Default(InsightsSummary(mood: 'Balanced', entries: 0, streak: 0))
    InsightsSummary summary,
    @Default(<TimeInsight>[]) List<TimeInsight> time,
    @Default(0) int selectedDay,
    @Default(true) bool loading,
    @Default(false) bool isFromCache,
    @Default(false) bool showingAllPatterns,
    String? lastUpdated,
    String? error,
  }) = _InsightsState;

  TimeInsight? get selectedTimeInsight {
    if (showingAllPatterns || time.isEmpty) return null;
    return time[selectedDay.clamp(0, time.length - 1)];
  }

  /// Aggregate all emotions across all days for "All patterns" view.
  List<EmotionStat> get allPatternsEmotions {
    if (!showingAllPatterns) return emotions;

    final Map<String, int> totals = {};
    for (final day in time) {
      for (final item in day.items) {
        totals[item.label] = (totals[item.label] ?? 0) + item.count;
      }
    }

    final result =
        totals.entries
            .map((e) => EmotionStat(label: e.key, count: e.value))
            .toList()
          ..sort((a, b) => b.count.compareTo(a.count));

    return result.isEmpty ? emotions : result;
  }

  /// Total entries across all days.
  int get allPatternsTotal {
    int total = 0;
    for (final day in time) {
      total += day.total;
    }
    return total;
  }
}

@riverpod
class InsightsNotifier extends _$InsightsNotifier {
  @override
  InsightsState build() {
    Future<void>.microtask(fetchInsights);
    return const InsightsState();
  }

  Future<void> fetchInsights() async {
    state = state.copyWith(loading: true, error: null);

    final connectivity = ref.read(connectivityServiceProvider);
    final localCache = ref.read(insightsLocalCacheProvider);
    final isOnline =
        await connectivity.checkConnectivity() == ConnectivityStatus.online;

    // If offline, try to load from cache first
    if (!isOnline) {
      final cached = await localCache.read(kUserId);
      if (cached != null) {
        state = state.copyWith(
          emotions: cached.emotions,
          habits: cached.habits,
          summary: cached.summary,
          time: cached.time,
          selectedDay: cached.time.isEmpty ? 0 : cached.time.length - 1,
          loading: false,
          isFromCache: true,
          lastUpdated: cached.lastUpdatedText,
        );
        return;
      }
    }

    try {
      final bundle = await ref.read(insightsRepositoryProvider).fetchAll();
      state = state.copyWith(
        emotions: bundle.emotions,
        habits: bundle.habits,
        summary: bundle.summary,
        time: bundle.time,
        selectedDay: bundle.time.isEmpty ? 0 : bundle.time.length - 1,
        loading: false,
        isFromCache: false,
        lastUpdated: null,
        showingAllPatterns: false,
      );

      // Cache the fresh data
      await localCache.write(
        userId: kUserId,
        emotions: bundle.emotions,
        habits: bundle.habits,
        summary: bundle.summary,
        time: bundle.time,
      );
    } catch (_) {
      // On error, try to show cached data
      final cached = await localCache.read(kUserId);
      if (cached != null) {
        state = state.copyWith(
          emotions: cached.emotions,
          habits: cached.habits,
          summary: cached.summary,
          time: cached.time,
          selectedDay: cached.time.isEmpty ? 0 : cached.time.length - 1,
          loading: false,
          isFromCache: true,
          lastUpdated: cached.lastUpdatedText,
          error: 'Showing cached data. Pull to refresh.',
        );
      } else {
        state = state.copyWith(
          loading: false,
          error: 'Could not load insights right now.',
        );
      }
    }
  }

  void selectPrevDay() {
    if (state.showingAllPatterns) {
      // Go back to last day
      final max = state.time.isEmpty ? 0 : state.time.length - 1;
      state = state.copyWith(showingAllPatterns: false, selectedDay: max);
    } else {
      state = state.copyWith(
        selectedDay: (state.selectedDay - 1).clamp(0, 999),
      );
    }
  }

  void selectNextDay() {
    final max = state.time.isEmpty ? 0 : state.time.length - 1;
    if (state.selectedDay >= max && !state.showingAllPatterns) {
      // At the end, go to "All patterns" view
      state = state.copyWith(showingAllPatterns: true);
    } else if (!state.showingAllPatterns) {
      state = state.copyWith(
        selectedDay: (state.selectedDay + 1).clamp(0, max),
      );
    }
    // If already showing all patterns, do nothing on forward
  }

  void showAllPatterns() {
    state = state.copyWith(showingAllPatterns: true);
  }

  void showDay(int day) {
    final max = state.time.isEmpty ? 0 : state.time.length - 1;
    state = state.copyWith(
      showingAllPatterns: false,
      selectedDay: day.clamp(0, max),
    );
  }
}

/// Provider for AI-generated overview.
@freezed
sealed class AIOverviewState with _$AIOverviewState {
  const factory AIOverviewState({
    AIOverview? overview,
    @Default(true) bool loading,
    String? error,
  }) = _AIOverviewState;
}

@riverpod
class AIOverviewNotifier extends _$AIOverviewNotifier {
  @override
  AIOverviewState build() {
    Future<void>.microtask(fetchOverview);
    return const AIOverviewState();
  }

  Future<void> fetchOverview() async {
    state = state.copyWith(loading: true, error: null);

    try {
      final overview = await ref
          .read(insightsRepositoryProvider)
          .fetchAIOverview();
      state = state.copyWith(overview: overview, loading: false);
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: 'Could not generate overview.',
      );
    }
  }

  void refresh() {
    fetchOverview();
  }
}
