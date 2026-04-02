import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:mindpal_app/features/insights/domain/models.dart';
import 'package:mindpal_app/theme.dart';

class HabitPieChart extends StatelessWidget {
  const HabitPieChart({required this.habits, super.key});

  final List<HabitStat> habits;

  static const List<Color> _palette = [
    MindPalColors.clay300,
    MindPalColors.emotionJoy,
    MindPalColors.emotionCalm,
    MindPalColors.emotionExcitement,
    MindPalColors.emotionGratitude,
    MindPalColors.emotionNeutral,
    MindPalColors.emotionSadness,
    MindPalColors.emotionFrustration,
    MindPalColors.clay400,
    MindPalColors.emotionAnxiety,
  ];

  @override
  Widget build(BuildContext context) {
    if (habits.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No habit data available yet')),
      );
    }

    final total = habits.fold<int>(0, (value, item) => value + item.count);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Donut Chart
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 16, bottom: 16),
            child: SizedBox(
              width: 180,
              height: 180,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 55,
                  sections: habits.asMap().entries.map((entry) {
                    final i = entry.key;
                    final item = entry.value;
                    final value = total == 0 ? 0.0 : item.count / total * 100;
                    return PieChartSectionData(
                      color: _palette[i % _palette.length],
                      value: value,
                      title: value >= 6 ? '${value.round()}%' : '',
                      radius: 45,
                      titleStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      titlePositionPercentageOffset: 0.6,
                    );
                  }).toList(growable: false),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Legend - scrollable
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(right: 8, top: 4, bottom: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: habits.asMap().entries.map((entry) {
                  final i = entry.key;
                  final item = entry.value;
                  final pct = total == 0 ? 0 : (item.count / total * 100).round();
                  return _LegendItem(
                    color: _palette[i % _palette.length],
                    label: _capitalize(item.name),
                    percentage: pct,
                    isDark: isDark,
                  );
                }).toList(growable: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    required this.percentage,
    required this.isDark,
  });

  final Color color;
  final String label;
  final int percentage;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? MindPalColors.darkSurfaceMid
            : Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? MindPalColors.darkBorder : MindPalColors.clay100,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? MindPalColors.darkTextPrimary
                    : MindPalColors.ink900,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$percentage%',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? MindPalColors.darkTextPrimary
                  : MindPalColors.ink800,
            ),
          ),
        ],
      ),
    );
  }
}
