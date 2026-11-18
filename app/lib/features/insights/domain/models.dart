import 'package:freezed_annotation/freezed_annotation.dart';

part 'models.freezed.dart';
part 'models.g.dart';

@freezed
sealed class EmotionStat with _$EmotionStat {
  const factory EmotionStat({required String label, required int count}) =
      _EmotionStat;

  factory EmotionStat.fromJson(Map<String, dynamic> json) =>
      _$EmotionStatFromJson(_normalizeEmotionStatJson(json));
}

Map<String, dynamic> _normalizeEmotionStatJson(Map<String, dynamic> json) {
  return {
    'label': json['label']?.toString() ?? 'Neutral',
    'count': (json['count'] as num?)?.toInt() ?? 0,
  };
}

@freezed
sealed class HabitStat with _$HabitStat {
  const factory HabitStat({required String name, required int count}) =
      _HabitStat;

  factory HabitStat.fromJson(Map<String, dynamic> json) =>
      _$HabitStatFromJson(_normalizeHabitStatJson(json));
}

Map<String, dynamic> _normalizeHabitStatJson(Map<String, dynamic> json) {
  return {
    'name': json['name']?.toString() ?? json['habit']?.toString() ?? 'Habit',
    'count': (json['count'] as num?)?.toInt() ?? 0,
  };
}

@freezed
sealed class InsightsSummary with _$InsightsSummary {
  const factory InsightsSummary({
    required String mood,
    required int entries,
    required int streak,
    String? dominantEmotion,
  }) = _InsightsSummary;

  factory InsightsSummary.fromJson(Map<String, dynamic> json) =>
      _$InsightsSummaryFromJson(_normalizeInsightsSummaryJson(json));
}

Map<String, dynamic> _normalizeInsightsSummaryJson(Map<String, dynamic> json) {
  final dominantEmotion = json['dominant_emotion']?.toString();
  return {
    'mood': json['mood']?.toString() ?? dominantEmotion ?? 'Balanced',
    'entries':
        (json['entries'] as num?)?.toInt() ??
        (json['total_messages'] as num?)?.toInt() ??
        0,
    'streak':
        (json['streak'] as num?)?.toInt() ??
        (json['active_days'] as num?)?.toInt() ??
        0,
    'dominantEmotion': dominantEmotion,
  };
}

@freezed
sealed class DayEmotion with _$DayEmotion {
  const factory DayEmotion({
    required String label,
    required double percent,
    @Default(0) int count,
  }) = _DayEmotion;

  factory DayEmotion.fromJson(Map<String, dynamic> json) =>
      _$DayEmotionFromJson(_normalizeDayEmotionJson(json));
}

Map<String, dynamic> _normalizeDayEmotionJson(Map<String, dynamic> json) {
  return {
    'label': json['label']?.toString() ?? 'Neutral',
    'percent':
        (json['percent'] as num?)?.toDouble() ??
        (json['count'] as num?)?.toDouble() ??
        0.0,
    'count':
        (json['count_raw'] as num?)?.toInt() ??
        (json['count'] as num?)?.toInt() ??
        0,
  };
}

@freezed
sealed class TimeInsight with _$TimeInsight {
  const factory TimeInsight({
    required DateTime date,
    required List<DayEmotion> items,
    @Default(0) int total,
  }) = _TimeInsight;

  factory TimeInsight.fromJson(Map<String, dynamic> json) {
    final date = DateTime.tryParse(json['date']?.toString() ?? '');
    final total = (json['total'] as num?)?.toInt() ?? 0;
    final raw = (json['emotions'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(DayEmotion.fromJson)
        .toList(growable: false);

    if (raw.isNotEmpty) {
      return TimeInsight(
        date: date ?? DateTime.now(),
        items: raw,
        total: total,
      );
    }

    final hour = (json['hour_of_day'] as num?)?.toInt();
    final count = (json['message_count'] as num?)?.toDouble() ?? 0;
    final label = json['top_emotion']?.toString() ?? 'Neutral';

    return TimeInsight(
      date: hour == null
          ? (date ?? DateTime.now())
          : DateTime.now().copyWith(
              hour: hour,
              minute: 0,
              second: 0,
              millisecond: 0,
              microsecond: 0,
            ),
      items: <DayEmotion>[
        DayEmotion(label: label, percent: count, count: count.toInt()),
      ],
      total: count.toInt(),
    );
  }
}

/// AI-generated personalized insight overview.
@freezed
sealed class AIOverview with _$AIOverview {
  const factory AIOverview({
    required String greeting,
    required String currentFeeling,
    required String emotionSummary,
    required String habitSummary,
    required String encouragement,
  }) = _AIOverview;

  factory AIOverview.fromJson(Map<String, dynamic> json) =>
      _$AIOverviewFromJson(_normalizeAIOverviewJson(json));
}

Map<String, dynamic> _normalizeAIOverviewJson(Map<String, dynamic> json) {
  return {
    'greeting': json['greeting']?.toString() ?? 'Welcome back!',
    'currentFeeling':
        json['current_feeling']?.toString() ?? 'You seem to be doing well.',
    'emotionSummary':
        json['emotion_summary']?.toString() ??
        'Your emotional journey continues.',
    'habitSummary':
        json['habit_summary']?.toString() ??
        'Keep up with your healthy habits.',
    'encouragement':
        json['encouragement']?.toString() ?? 'Every step forward matters.',
  };
}
