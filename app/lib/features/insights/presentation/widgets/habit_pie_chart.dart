import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:mindpal_app/features/insights/domain/models.dart';
import 'package:mindpal_app/features/insights/providers/habit_providers.dart';
import 'package:mindpal_app/theme.dart';

class HabitPieChart extends ConsumerStatefulWidget {
  const HabitPieChart({required this.habits, super.key});

  /// Initial/fallback habits data (used while loading period-filtered data)
  final List<HabitStat> habits;

  @override
  ConsumerState<HabitPieChart> createState() => _HabitPieChartState();
}

class _HabitPieChartState extends ConsumerState<HabitPieChart> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  // Earthy color palette matching the mockup
  static const List<Color> _palette = [
    Color(0xFF8B7355), // Brown/Tan (Meditation)
    Color(0xFFB86E4B), // Terracotta/Orange (Journaling)
    Color(0xFF6B8E6B), // Sage Green (Exercise)
    Color(0xFFCCAA55), // Mustard/Gold (Reading)
    Color(0xFF9B8B7A), // Taupe
    Color(0xFFA67B5B), // Camel
    Color(0xFF7A9E7A), // Moss Green
    Color(0xFFD4A574), // Sand
  ];

  @override
  Widget build(BuildContext context) {
    // Watch the period-filtered habits provider
    final periodHabitsAsync = ref.watch(periodFilteredHabitsProvider);
    
    // Use period-filtered data if available, otherwise fall back to initial data
    final habits = periodHabitsAsync.when(
      data: (data) => data,
      loading: () => widget.habits,
      error: (e, st) => widget.habits,
    );
    
    final isLoading = periodHabitsAsync.isLoading;

    if (habits.isEmpty && !isLoading) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No habit data available yet')),
      );
    }

    final total = habits.fold<int>(0, (value, item) => value + item.count);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedHabit = ref.watch(selectedHabitProvider);

    // Find dominant habit (largest slice)
    int dominantIndex = 0;
    int maxCount = 0;
    for (int i = 0; i < habits.length; i++) {
      if (habits[i].count > maxCount) {
        maxCount = habits[i].count;
        dominantIndex = i;
      }
    }
    final dominantPct = total == 0 ? 0 : (habits[dominantIndex].count / total * 100).round();

    final cardBorder = Border.all(
      color: isDark
          ? MindPalColors.darkBorder
          : MindPalColors.clay200.withValues(alpha: 0.7),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Habit Distribution Card - Expandable
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? MindPalColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: cardBorder,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with expand indicator
              GestureDetector(
                onTap: _toggleExpand,
                behavior: HitTestBehavior.opaque,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Habit Distribution',
                            style: GoogleFonts.fraunces(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: isDark ? MindPalColors.darkTextPrimary : MindPalColors.ink900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Your practice breakdown this period',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: isDark 
                                  ? MindPalColors.darkTextSecondary.withValues(alpha: 0.65) 
                                  : MindPalColors.ink700.withValues(alpha: 0.65),
                            ),
                          ),
                        ],
                      ),
                    ),
                    RotationTransition(
                      turns: Tween(begin: 0.0, end: 0.5).animate(_expandAnimation),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: isDark ? MindPalColors.darkTextSecondary : MindPalColors.ink700,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Period selector
              const _PeriodSelector(),
              const SizedBox(height: 20),
              // Chart centered with loading overlay
              Center(
                child: SizedBox(
                  width: 160,
                  height: 160,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: isLoading ? 0.4 : 1.0,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 160 * 0.29,
                            sections: habits.asMap().entries.map((entry) {
                              final i = entry.key;
                              final item = entry.value;
                              final value = total == 0 ? 0.0 : item.count / total * 100;
                              final habitName = _capitalize(item.name);
                              final isSelected = selectedHabit == null || selectedHabit == habitName;
                              final baseColor = _palette[i % _palette.length];
                              return PieChartSectionData(
                                color: isSelected 
                                    ? baseColor 
                                    : baseColor.withValues(alpha: 0.25),
                                value: value,
                                title: '',
                                radius: selectedHabit == habitName ? 36 : 160 * 0.21,
                                showTitle: false,
                              );
                            }).toList(growable: false),
                          ),
                        ),
                      ),
                      if (isLoading)
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: isDark ? MindPalColors.clay300 : MindPalColors.clay400,
                          ),
                        )
                      else
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$dominantPct%',
                              style: GoogleFonts.fraunces(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                color: isDark ? MindPalColors.darkTextPrimary : MindPalColors.ink900,
                              ),
                            ),
                            Text(
                              'DOMINANT',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                                color: isDark ? MindPalColors.darkTextSecondary : MindPalColors.ink700,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              // Animated legend section
              SizeTransition(
                sizeFactor: _expandAnimation,
                axisAlignment: -1.0,
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // Divider
                    Container(
                      height: 1,
                      color: isDark
                          ? MindPalColors.darkBorder.withValues(alpha: 0.5)
                          : MindPalColors.clay200.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    // Legend items
                    _buildLegendGrid(context, habits, total, isDark, selectedHabit),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Weekly Trend Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? MindPalColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: cardBorder,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Weekly Trend',
                style: GoogleFonts.fraunces(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: isDark ? MindPalColors.darkTextPrimary : MindPalColors.ink900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Your habit consistency over the week',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: isDark 
                      ? MindPalColors.darkTextSecondary.withValues(alpha: 0.65) 
                      : MindPalColors.ink700.withValues(alpha: 0.65),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: _WeeklyTrendChart(isDark: isDark),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendGrid(BuildContext context, List<HabitStat> habits, int total, bool isDark, String? selectedHabit) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: habits.asMap().entries.map((entry) {
        final i = entry.key;
        final item = entry.value;
        final pct = total == 0 ? 0 : (item.count / total * 100).round();
        final label = _capitalize(item.name);
        return SizedBox(
          width: (MediaQuery.of(context).size.width - 80) / 2,
          child: _LegendGridItem(
            color: _palette[i % _palette.length],
            label: label,
            percentage: pct,
            isDark: isDark,
            isSelected: selectedHabit == label,
            isActive: selectedHabit == null || selectedHabit == label,
            onTap: () => ref.read(selectedHabitProvider.notifier).toggle(label),
          ),
        );
      }).toList(),
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }
}

class _LegendGridItem extends StatelessWidget {
  const _LegendGridItem({
    required this.color,
    required this.label,
    required this.percentage,
    required this.isDark,
    required this.isSelected,
    required this.isActive,
    required this.onTap,
  });

  final Color color;
  final String label;
  final int percentage;
  final bool isDark;
  final bool isSelected;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isActive ? 1.0 : 0.3,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isSelected ? 12 : 10,
                height: isSelected ? 12 : 10,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isDark
                            ? MindPalColors.darkTextPrimary
                            : MindPalColors.ink900,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    Text(
                      '$percentage%',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? MindPalColors.darkTextSecondary.withValues(alpha: 0.55)
                            : MindPalColors.ink700.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeeklyTrendChart extends StatelessWidget {
  const _WeeklyTrendChart({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final lineColor = isDark ? MindPalColors.clay300 : MindPalColors.clay400;
    final gridColor = isDark ? MindPalColors.darkBorder : MindPalColors.clay100;
    final textColor = isDark ? MindPalColors.darkTextSecondary : MindPalColors.ink700;
    final tooltipBgColor = isDark ? MindPalColors.darkSurfaceHigh : MindPalColors.clay200;
    final tooltipTextColor = isDark ? MindPalColors.darkTextPrimary : MindPalColors.ink900;
    final inactiveDotColor = isDark ? MindPalColors.darkBorder : MindPalColors.clay300;

    // Sample data - this would come from actual habit tracking
    final spots = [
      const FlSpot(0, 25),  // Mon
      const FlSpot(1, 38),  // Tue
      const FlSpot(2, 45),  // Wed
      const FlSpot(3, 50),  // Thu
      const FlSpot(4, 68),  // Fri
      const FlSpot(5, 75),  // Sat
      const FlSpot(6, 92),  // Sun
    ];

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 25,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: gridColor,
              strokeWidth: 0.5,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 1,
              getTitlesWidget: (value, meta) {
                const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                final index = value.toInt();
                if (index >= 0 && index < days.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      days[index],
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: 25,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}%',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: 6,
        minY: 0,
        maxY: 100,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => tooltipBgColor,
            tooltipPadding: const EdgeInsets.all(8),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  '${spot.y.toInt()}%',
                  GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: tooltipTextColor,
                  ),
                );
              }).toList();
            },
          ),
          handleBuiltInTouches: true,
          getTouchedSpotIndicator: (barData, spotIndexes) {
            return spotIndexes.map((index) {
              return TouchedSpotIndicatorData(
                const FlLine(color: Colors.transparent), // No vertical line
                FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, bar, idx) {
                    return FlDotCirclePainter(
                      radius: 5,
                      color: lineColor,
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    );
                  },
                ),
              );
            }).toList();
          },
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: false,
            color: lineColor,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 3,
                  color: inactiveDotColor,
                  strokeWidth: 0,
                );
              },
            ),
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
    );
  }
}

/// Period selector widget for habit time filtering
class _PeriodSelector extends ConsumerWidget {
  const _PeriodSelector();

  static const _labels = {
    HabitPeriod.week: 'This week',
    HabitPeriod.month: 'Month',
    HabitPeriod.allTime: 'All time',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(habitPeriodProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark 
            ? MindPalColors.darkSurfaceHigh 
            : MindPalColors.sand100,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: HabitPeriod.values.map((period) {
          final isSelected = period == selected;
          return GestureDetector(
            onTap: () => ref.read(habitPeriodProvider.notifier).set(period),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark ? MindPalColors.darkSurface : Colors.white)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _labels[period]!,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? (isDark ? MindPalColors.darkTextPrimary : MindPalColors.ink900)
                      : (isDark 
                          ? MindPalColors.darkTextSecondary.withValues(alpha: 0.6) 
                          : MindPalColors.ink700.withValues(alpha: 0.6)),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
