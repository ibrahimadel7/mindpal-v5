import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:mindpal_app/features/insights/data/insights_repository.dart';
import 'package:mindpal_app/features/insights/domain/models.dart';

part 'habit_providers.g.dart';

/// Time period for habit data filtering
enum HabitPeriod { week, month, allTime }

/// Provider for the selected habit time period
@riverpod
class HabitPeriodNotifier extends _$HabitPeriodNotifier {
  @override
  HabitPeriod build() => HabitPeriod.week;

  void set(HabitPeriod period) => state = period;
}

/// Provider for the currently selected/highlighted habit in the chart
@riverpod
class SelectedHabit extends _$SelectedHabit {
  @override
  String? build() => null; // null = all visible

  void toggle(String habitName) =>
      state = state == habitName ? null : habitName;

  void clear() => state = null;
}

/// Provider that fetches habits based on the selected period
@riverpod
Future<List<HabitStat>> periodFilteredHabits(Ref ref) async {
  final period = ref.watch(habitPeriodProvider);
  final repository = ref.watch(insightsRepositoryProvider);
  
  return repository.fetchHabits(period: period);
}
