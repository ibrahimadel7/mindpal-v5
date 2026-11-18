import 'package:flutter_test/flutter_test.dart';
import 'package:mindpal_app/features/insights/domain/models.dart';

void main() {
  group('EmotionStat', () {
    test('fromJson parses correctly', () {
      final json = {'label': 'Joy', 'count': 15};

      final stat = EmotionStat.fromJson(json);

      expect(stat.label, equals('Joy'));
      expect(stat.count, equals(15));
    });

    test('fromJson uses default label when null', () {
      final json = {'label': null, 'count': 5};

      final stat = EmotionStat.fromJson(json);

      expect(stat.label, equals('Neutral'));
    });

    test('fromJson uses default count when null', () {
      final json = {'label': 'Sadness', 'count': null};

      final stat = EmotionStat.fromJson(json);

      expect(stat.count, equals(0));
    });

    test('copyWith creates new instance', () {
      const stat = EmotionStat(label: 'Joy', count: 10);

      final updated = stat.copyWith(count: 20);

      expect(updated.label, equals('Joy'));
      expect(updated.count, equals(20));
    });
  });

  group('HabitStat', () {
    test('fromJson parses correctly', () {
      final json = {'name': 'Exercise', 'count': 8};

      final stat = HabitStat.fromJson(json);

      expect(stat.name, equals('Exercise'));
      expect(stat.count, equals(8));
    });

    test('fromJson uses habit field as fallback', () {
      final json = {'habit': 'Meditation', 'count': 12};

      final stat = HabitStat.fromJson(json);

      expect(stat.name, equals('Meditation'));
    });

    test('fromJson uses default name when both null', () {
      final json = {'name': null, 'habit': null, 'count': 3};

      final stat = HabitStat.fromJson(json);

      expect(stat.name, equals('Habit'));
    });
  });

  group('InsightsSummary', () {
    test('fromJson parses correctly', () {
      final json = {
        'mood': 'Positive',
        'entries': 50,
        'streak': 7,
        'dominant_emotion': 'Joy',
      };

      final summary = InsightsSummary.fromJson(json);

      expect(summary.mood, equals('Positive'));
      expect(summary.entries, equals(50));
      expect(summary.streak, equals(7));
      expect(summary.dominantEmotion, equals('Joy'));
    });

    test('fromJson uses dominant_emotion as mood fallback', () {
      final json = {
        'mood': null,
        'entries': 10,
        'streak': 3,
        'dominant_emotion': 'Calm',
      };

      final summary = InsightsSummary.fromJson(json);

      expect(summary.mood, equals('Calm'));
    });

    test('fromJson uses total_messages as entries fallback', () {
      final json = {
        'mood': 'Good',
        'total_messages': 25,
        'streak': 5,
      };

      final summary = InsightsSummary.fromJson(json);

      expect(summary.entries, equals(25));
    });

    test('fromJson uses active_days as streak fallback', () {
      final json = {
        'mood': 'Good',
        'entries': 30,
        'active_days': 14,
      };

      final summary = InsightsSummary.fromJson(json);

      expect(summary.streak, equals(14));
    });

    test('fromJson uses defaults when all null', () {
      final json = <String, dynamic>{};

      final summary = InsightsSummary.fromJson(json);

      expect(summary.mood, equals('Balanced'));
      expect(summary.entries, equals(0));
      expect(summary.streak, equals(0));
      expect(summary.dominantEmotion, isNull);
    });
  });

  group('DayEmotion', () {
    test('fromJson parses correctly', () {
      final json = {'label': 'Anxiety', 'percent': 35.5};

      final emotion = DayEmotion.fromJson(json);

      expect(emotion.label, equals('Anxiety'));
      expect(emotion.percent, equals(35.5));
    });

    test('fromJson handles int percent', () {
      final json = {'label': 'Joy', 'percent': 50};

      final emotion = DayEmotion.fromJson(json);

      expect(emotion.percent, equals(50.0));
    });
  });

  group('TimeInsight', () {
    test('fromJson parses with emotions list', () {
      final json = {
        'date': '2024-03-15',
        'emotions': [
          {'label': 'Joy', 'percent': 60.0},
          {'label': 'Calm', 'percent': 40.0},
        ],
      };

      final insight = TimeInsight.fromJson(json);

      expect(insight.date.year, equals(2024));
      expect(insight.date.month, equals(3));
      expect(insight.date.day, equals(15));
      expect(insight.items.length, equals(2));
      expect(insight.items[0].label, equals('Joy'));
      expect(insight.items[1].label, equals('Calm'));
    });

    test('fromJson parses with hour_of_day format', () {
      final json = {
        'hour_of_day': 14,
        'message_count': 5.0,
        'top_emotion': 'Stress',
      };

      final insight = TimeInsight.fromJson(json);

      expect(insight.date.hour, equals(14));
      expect(insight.items.length, equals(1));
      expect(insight.items[0].label, equals('Stress'));
      expect(insight.items[0].percent, equals(5.0));
    });

    test('fromJson uses default emotion when none provided', () {
      final json = {
        'hour_of_day': 9,
        'message_count': 3.0,
      };

      final insight = TimeInsight.fromJson(json);

      expect(insight.items[0].label, equals('Neutral'));
    });
  });
}
