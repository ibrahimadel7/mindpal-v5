// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_EmotionStat _$EmotionStatFromJson(Map<String, dynamic> json) => _EmotionStat(
  label: json['label'] as String,
  count: (json['count'] as num).toInt(),
);

Map<String, dynamic> _$EmotionStatToJson(_EmotionStat instance) =>
    <String, dynamic>{'label': instance.label, 'count': instance.count};

_HabitStat _$HabitStatFromJson(Map<String, dynamic> json) => _HabitStat(
  name: json['name'] as String,
  count: (json['count'] as num).toInt(),
);

Map<String, dynamic> _$HabitStatToJson(_HabitStat instance) =>
    <String, dynamic>{'name': instance.name, 'count': instance.count};

_InsightsSummary _$InsightsSummaryFromJson(Map<String, dynamic> json) =>
    _InsightsSummary(
      mood: json['mood'] as String,
      entries: (json['entries'] as num).toInt(),
      streak: (json['streak'] as num).toInt(),
      dominantEmotion: json['dominantEmotion'] as String?,
    );

Map<String, dynamic> _$InsightsSummaryToJson(_InsightsSummary instance) =>
    <String, dynamic>{
      'mood': instance.mood,
      'entries': instance.entries,
      'streak': instance.streak,
      'dominantEmotion': instance.dominantEmotion,
    };

_DayEmotion _$DayEmotionFromJson(Map<String, dynamic> json) => _DayEmotion(
  label: json['label'] as String,
  percent: (json['percent'] as num).toDouble(),
  count: (json['count'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$DayEmotionToJson(_DayEmotion instance) =>
    <String, dynamic>{
      'label': instance.label,
      'percent': instance.percent,
      'count': instance.count,
    };

_AIOverview _$AIOverviewFromJson(Map<String, dynamic> json) => _AIOverview(
  greeting: json['greeting'] as String,
  currentFeeling: json['currentFeeling'] as String,
  emotionSummary: json['emotionSummary'] as String,
  habitSummary: json['habitSummary'] as String,
  encouragement: json['encouragement'] as String,
);

Map<String, dynamic> _$AIOverviewToJson(_AIOverview instance) =>
    <String, dynamic>{
      'greeting': instance.greeting,
      'currentFeeling': instance.currentFeeling,
      'emotionSummary': instance.emotionSummary,
      'habitSummary': instance.habitSummary,
      'encouragement': instance.encouragement,
    };
