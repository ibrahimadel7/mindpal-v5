import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:mindpal_app/constants.dart';
import 'package:mindpal_app/features/insights/domain/models.dart';
import 'package:mindpal_app/features/insights/providers/habit_providers.dart';
import 'package:mindpal_app/shared/providers/core_providers.dart';

part 'insights_repository.g.dart';

class InsightsBundle {
  const InsightsBundle({
    required this.emotions,
    required this.habits,
    required this.summary,
    required this.time,
  });

  final List<EmotionStat> emotions;
  final List<HabitStat> habits;
  final InsightsSummary summary;
  final List<TimeInsight> time;
}

class InsightsRepository {
  InsightsRepository(this._dio);

  final Dio _dio;

  Future<InsightsBundle> fetchAll() async {
    final query = <String, Object?>{'user_id': kUserId};
    final responses = await Future.wait([
      _dio.get<List<dynamic>>('/insights/emotions', queryParameters: query),
      _dio.get<List<dynamic>>('/insights/habits', queryParameters: query),
      _dio.get<Map<String, dynamic>>(
        '/insights/summary',
        queryParameters: query,
      ),
      _dio.get<List<dynamic>>(
        '/insights/trends/emotions',
        queryParameters: query,
      ),
    ]);

    final emotionsData =
        responses[0].data as List<dynamic>? ?? const <dynamic>[];
    final habitsData = responses[1].data as List<dynamic>? ?? const <dynamic>[];
    final summaryData =
        responses[2].data as Map<String, dynamic>? ?? const <String, dynamic>{};
    final timeData = responses[3].data as List<dynamic>? ?? const <dynamic>[];

    return InsightsBundle(
      emotions: emotionsData
          .whereType<Map<String, dynamic>>()
          .map(EmotionStat.fromJson)
          .toList(growable: false),
      habits: habitsData
          .whereType<Map<String, dynamic>>()
          .map(HabitStat.fromJson)
          .toList(growable: false),
      summary: InsightsSummary.fromJson(summaryData),
      time: timeData
          .whereType<Map<String, dynamic>>()
          .map((item) {
            final next = Map<String, dynamic>.from(item);
            final total = (item['total'] as num?)?.toDouble() ?? 0;

            if (item.containsKey('emotions') && item['emotions'] is List) {
              final List<dynamic> emotionsList =
                  item['emotions'] as List<dynamic>;
              final List<Map<String, dynamic>> normalizedEmotions = [];

              for (final e in emotionsList.whereType<Map<String, dynamic>>()) {
                final count = (e['count'] as num?)?.toDouble() ?? 0.0;
                final label = e['label'] as String? ?? 'Neutral';
                final normalized = total == 0 ? 0.0 : (count / total) * 100;
                normalizedEmotions.add({
                  'label': label,
                  'percent': normalized,
                  'count_raw': count.toInt(),
                });
              }
              next['emotions'] = normalizedEmotions;
            }

            return TimeInsight.fromJson(next);
          })
          .toList(growable: false),
    );
  }

  /// Fetch habits filtered by time period
  Future<List<HabitStat>> fetchHabits({HabitPeriod? period}) async {
    final query = <String, Object?>{
      'user_id': kUserId,
      if (period != null) 'period': period.toApiValue(),
    };
    
    final response = await _dio.get<List<dynamic>>(
      '/insights/habits',
      queryParameters: query,
    );
    
    final habitsData = response.data ?? const <dynamic>[];
    return habitsData
        .whereType<Map<String, dynamic>>()
        .map(HabitStat.fromJson)
        .toList(growable: false);
  }

  /// Fetch AI-generated personalized overview.
  Future<AIOverview> fetchAIOverview() async {
    final query = <String, Object?>{'user_id': kUserId};
    final response = await _dio.get<Map<String, dynamic>>(
      '/insights/ai-overview',
      queryParameters: query,
    );
    final data = response.data ?? const <String, dynamic>{};
    return AIOverview.fromJson(data);
  }
}

@riverpod
InsightsRepository insightsRepository(Ref ref) {
  return InsightsRepository(ref.watch(dioProvider));
}

/// Extension to convert HabitPeriod to API query value
extension HabitPeriodApi on HabitPeriod {
  String toApiValue() {
    switch (this) {
      case HabitPeriod.week:
        return 'week';
      case HabitPeriod.month:
        return 'month';
      case HabitPeriod.allTime:
        return 'all';
    }
  }
}
