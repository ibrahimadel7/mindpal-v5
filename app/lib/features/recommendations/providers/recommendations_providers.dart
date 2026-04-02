import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:mindpal_app/features/recommendations/data/recommendations_repository.dart';
import 'package:mindpal_app/features/recommendations/domain/models.dart';

part 'recommendations_providers.g.dart';

class RecommendationsState {
  const RecommendationsState({
    required this.selectedCategory,
    required this.batch,
    required this.history,
    required this.checklist,
    required this.timers,
    required this.loading,
    this.error,
  });

  factory RecommendationsState.initial() => const RecommendationsState(
    selectedCategory: 'Balance',
    batch: <RecommendationItem>[],
    history: <RecommendationItem>[],
    checklist: <HabitChecklistItem>[],
    timers: <String, int>{},
    loading: true,
  );

  final String selectedCategory;
  final List<RecommendationItem> batch;
  final List<RecommendationItem> history;
  final List<HabitChecklistItem> checklist;
  final Map<String, int> timers;
  final bool loading;
  final String? error;

  double get completionPercent {
    if (checklist.isEmpty) {
      return 0;
    }
    final done = checklist.where((item) => item.completed).length;
    return done / checklist.length;
  }

  RecommendationsState copyWith({
    String? selectedCategory,
    List<RecommendationItem>? batch,
    List<RecommendationItem>? history,
    List<HabitChecklistItem>? checklist,
    Map<String, int>? timers,
    bool? loading,
    String? error,
  }) {
    return RecommendationsState(
      selectedCategory: selectedCategory ?? this.selectedCategory,
      batch: batch ?? this.batch,
      history: history ?? this.history,
      checklist: checklist ?? this.checklist,
      timers: timers ?? this.timers,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

@riverpod
class RecommendationsNotifier extends _$RecommendationsNotifier {
  Timer? _ticker;

  @override
  RecommendationsState build() {
    ref.onDispose(() {
      _ticker?.cancel();
      _ticker = null;
    });
    Future<void>.microtask(() async {
      await refreshBatch();
    });
    return RecommendationsState.initial();
  }

  Future<void> refreshBatch() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final repo = ref.read(recommendationsRepositoryProvider);
      final batch = await repo.today(category: state.selectedCategory);
      // Check if provider is still mounted after async operation
      if (!ref.mounted) return;
      final checklist = await repo.checklist();
      if (!ref.mounted) return;
      state = state.copyWith(
        batch: batch,
        checklist: checklist,
        loading: false,
        timers: _buildTimers(batch),
      );
      _startTicker();
    } catch (_) {
      if (!ref.mounted) return;
      state = state.copyWith(
        loading: false,
        error: 'Unable to load recommendations.',
      );
    }
  }

  Future<void> generateBatch() async {
    final repo = ref.read(recommendationsRepositoryProvider);
    final items = await repo.generate(category: state.selectedCategory);
    // Check if provider is still mounted after async operation
    if (!ref.mounted) return;
    state = state.copyWith(batch: items, timers: _buildTimers(items));
  }

  void selectCategory(String value) {
    state = state.copyWith(selectedCategory: value);
    unawaited(refreshBatch());
  }

  Future<void> toggleHabit(HabitChecklistItem item, bool checked) async {
    final repo = ref.read(recommendationsRepositoryProvider);
    await repo.setHabitChecked(id: item.id, completed: checked);
    // Check if provider is still mounted after async operation
    if (!ref.mounted) return;
    final next = state.checklist
        .map((e) => e.id == item.id ? e.copyWith(completed: checked) : e)
        .toList(growable: false);
    state = state.copyWith(checklist: next);
  }

  Future<void> addHabit(String name) async {
    final repo = ref.read(recommendationsRepositoryProvider);
    await repo.addHabit(name);
    // Check if provider is still mounted after async operation
    if (!ref.mounted) return;
    await refreshBatch();
  }

  Future<void> deleteHabit(String id) async {
    final repo = ref.read(recommendationsRepositoryProvider);
    await repo.deleteHabit(id);
    // Check if provider is still mounted after async operation
    if (!ref.mounted) return;
    state = state.copyWith(
      checklist: state.checklist.where((e) => e.id != id).toList(),
    );
  }

  Map<String, int> _buildTimers(List<RecommendationItem> items) {
    return {
      for (final item in items)
        if (item.duration.endsWith('m'))
          item.id: int.tryParse(item.duration.replaceAll('m', '')) ?? 0,
    };
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      // Check if provider is still mounted before updating state
      if (!ref.mounted) {
        _ticker?.cancel();
        _ticker = null;
        return;
      }
      if (state.timers.isEmpty) {
        _ticker?.cancel();
        return;
      }
      final updated = <String, int>{};
      state.timers.forEach((key, value) {
        final next = value - 1;
        if (next > 0) {
          updated[key] = next;
        }
      });
      state = state.copyWith(timers: updated);
    });
  }
}
