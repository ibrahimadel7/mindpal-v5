import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:mindpal_app/features/insights/domain/models.dart';
import 'package:mindpal_app/shared/data/cache/cached_insights.dart';
import 'package:mindpal_app/shared/providers/local_cache_provider.dart';
import 'package:mindpal_app/shared/services/local_cache_service.dart';

part 'insights_local_cache.g.dart';

/// Cached insights bundle with metadata.
class CachedInsightsBundle {
  const CachedInsightsBundle({
    required this.emotions,
    required this.habits,
    required this.summary,
    required this.time,
    required this.cachedAt,
  });

  final List<EmotionStat> emotions;
  final List<HabitStat> habits;
  final InsightsSummary summary;
  final List<TimeInsight> time;
  final DateTime cachedAt;

  /// Check if cache is stale (older than 1 hour).
  bool get isStale => DateTime.now().difference(cachedAt).inHours >= 1;

  /// Human-readable last updated string.
  String get lastUpdatedText {
    final diff = DateTime.now().difference(cachedAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class InsightsLocalCache {
  InsightsLocalCache(this._localCacheService);

  final LocalCacheService _localCacheService;

  /// Read cached insights for a user.
  Future<CachedInsightsBundle?> read(int userId) async {
    final cached = await _localCacheService.getInsights(userId);
    if (cached == null) return null;

    try {
      final emotionsList = (jsonDecode(cached.emotionsJson) as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(EmotionStat.fromJson)
          .toList();

      final habitsList = (jsonDecode(cached.habitsJson) as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(HabitStat.fromJson)
          .toList();

      final summaryMap = jsonDecode(cached.summaryJson) as Map<String, dynamic>;
      final summary = InsightsSummary.fromJson(summaryMap);

      final timeList = (jsonDecode(cached.timeJson) as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(TimeInsight.fromJson)
          .toList();

      return CachedInsightsBundle(
        emotions: emotionsList,
        habits: habitsList,
        summary: summary,
        time: timeList,
        cachedAt: cached.cachedAt,
      );
    } catch (_) {
      // Invalid cached data, clear it
      await clear(userId);
      return null;
    }
  }

  /// Write insights to cache.
  Future<void> write({
    required int userId,
    required List<EmotionStat> emotions,
    required List<HabitStat> habits,
    required InsightsSummary summary,
    required List<TimeInsight> time,
  }) async {
    final cached = CachedInsights(
      userId: userId,
      emotionsJson: jsonEncode(emotions.map(_emotionToJson).toList()),
      habitsJson: jsonEncode(habits.map(_habitToJson).toList()),
      summaryJson: jsonEncode(_summaryToJson(summary)),
      timeJson: jsonEncode(time.map(_timeInsightToJson).toList()),
      cachedAt: DateTime.now(),
    );

    await _localCacheService.saveInsights(cached);
  }

  /// Clear cached insights for a user.
  Future<void> clear(int userId) async {
    await _localCacheService.clearInsights(userId);
  }

  Map<String, dynamic> _emotionToJson(EmotionStat stat) => {
        'label': stat.label,
        'count': stat.count,
      };

  Map<String, dynamic> _habitToJson(HabitStat stat) => {
        'name': stat.name,
        'count': stat.count,
      };

  Map<String, dynamic> _summaryToJson(InsightsSummary summary) => {
        'mood': summary.mood,
        'entries': summary.entries,
        'streak': summary.streak,
        'dominant_emotion': summary.dominantEmotion,
      };

  Map<String, dynamic> _timeInsightToJson(TimeInsight insight) => {
        'date': insight.date.toIso8601String(),
        'emotions': insight.items
            .map((e) => {'label': e.label, 'percent': e.percent})
            .toList(),
      };
}

@riverpod
InsightsLocalCache insightsLocalCache(Ref ref) {
  final service = ref.watch(localCacheServiceProvider);
  return InsightsLocalCache(service);
}
