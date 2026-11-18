import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:mindpal_app/features/insights/domain/models.dart';
import 'package:mindpal_app/features/insights/providers/insights_providers.dart';
import 'package:mindpal_app/theme.dart';

/// A calendar widget that displays mood/emotion indicators for each day.
class MoodCalendar extends ConsumerStatefulWidget {
  const MoodCalendar({super.key});

  @override
  ConsumerState<MoodCalendar> createState() => _MoodCalendarState();
}

class _MoodCalendarState extends ConsumerState<MoodCalendar> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(insightsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Build a map of date -> dominant emotion
    final emotionsByDate = _buildEmotionsByDate(state.time);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
          child: Text(
            'Mood Calendar',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? MindPalColors.darkTextPrimary
                  : MindPalColors.ink900,
            ),
          ),
        ),

        // Calendar
        Container(
          decoration: BoxDecoration(
            color: isDark ? MindPalColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? MindPalColors.darkBorder : MindPalColors.clay200,
            ),
          ),
          child: TableCalendar<String>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: _calendarFormat,
            startingDayOfWeek: StartingDayOfWeek.monday,
            headerStyle: HeaderStyle(
              titleCentered: true,
              formatButtonVisible: true,
              formatButtonShowsNext: false,
              formatButtonDecoration: BoxDecoration(
                border: Border.all(
                  color: isDark
                      ? MindPalColors.darkBorder
                      : MindPalColors.clay200,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              formatButtonTextStyle: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? MindPalColors.darkTextSecondary
                    : MindPalColors.ink700,
              ),
              titleTextStyle: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? MindPalColors.darkTextPrimary
                    : MindPalColors.ink900,
              ),
              leftChevronIcon: Icon(
                Icons.chevron_left,
                color: isDark
                    ? MindPalColors.darkTextSecondary
                    : MindPalColors.ink700,
              ),
              rightChevronIcon: Icon(
                Icons.chevron_right,
                color: isDark
                    ? MindPalColors.darkTextSecondary
                    : MindPalColors.ink700,
              ),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? MindPalColors.darkTextTertiary
                    : MindPalColors.ink700,
              ),
              weekendStyle: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? MindPalColors.darkTextTertiary
                    : MindPalColors.ink700,
              ),
            ),
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              defaultTextStyle: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: isDark
                    ? MindPalColors.darkTextPrimary
                    : MindPalColors.ink900,
              ),
              weekendTextStyle: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: isDark
                    ? MindPalColors.darkTextPrimary
                    : MindPalColors.ink900,
              ),
              todayDecoration: BoxDecoration(
                color: (isDark ? MindPalColors.clay300 : MindPalColors.clay200)
                    .withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              todayTextStyle: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? MindPalColors.darkTextPrimary
                    : MindPalColors.ink900,
              ),
              selectedDecoration: BoxDecoration(
                color: isDark ? MindPalColors.clay400 : MindPalColors.clay300,
                shape: BoxShape.circle,
              ),
              selectedTextStyle: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              markerDecoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                final dateKey = _dateKey(date);
                final emotion = emotionsByDate[dateKey];
                if (emotion == null) return const SizedBox.shrink();

                return Positioned(
                  bottom: 4,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: MindPalColors.emotionColor(emotion),
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
              defaultBuilder: (context, date, focusedDay) {
                final dateKey = _dateKey(date);
                final emotion = emotionsByDate[dateKey];

                if (emotion != null) {
                  return Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: MindPalColors.emotionColor(emotion)
                          .withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${date.day}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: isDark
                              ? MindPalColors.darkTextPrimary
                              : MindPalColors.ink900,
                        ),
                      ),
                    ),
                  );
                }

                return null;
              },
            ),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              _showDayDetails(context, selectedDay, emotionsByDate);
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
          ),
        ),

        // Legend
        const SizedBox(height: 16),
        _buildLegend(isDark),

        // Selected day details
        if (_selectedDay != null) ...[
          const SizedBox(height: 16),
          _buildSelectedDayDetails(emotionsByDate, isDark),
        ],
      ],
    );
  }

  Map<String, String> _buildEmotionsByDate(List<TimeInsight> timeInsights) {
    final map = <String, String>{};
    for (final insight in timeInsights) {
      if (insight.items.isNotEmpty) {
        // Find the dominant emotion (highest percent)
        final dominant = insight.items.reduce((a, b) =>
            a.percent > b.percent ? a : b);
        map[_dateKey(insight.date)] = dominant.label;
      }
    }
    return map;
  }

  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Widget _buildLegend(bool isDark) {
    final emotions = [
      'Joy',
      'Calm',
      'Neutral',
      'Anxiety',
      'Sadness',
      'Stress',
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: emotions.map((emotion) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: MindPalColors.emotionColor(emotion),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              emotion,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: isDark
                    ? MindPalColors.darkTextSecondary
                    : MindPalColors.ink700,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildSelectedDayDetails(
      Map<String, String> emotionsByDate, bool isDark) {
    final dateKey = _dateKey(_selectedDay!);
    final emotion = emotionsByDate[dateKey];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? MindPalColors.darkSurface : MindPalColors.sand100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? MindPalColors.darkBorder : MindPalColors.clay200,
        ),
      ),
      child: Row(
        children: [
          if (emotion != null) ...[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: MindPalColors.emotionColor(emotion).withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _emotionEmoji(emotion),
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE, MMMM d').format(_selectedDay!),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? MindPalColors.darkTextPrimary
                        : MindPalColors.ink900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  emotion != null
                      ? 'Dominant mood: $emotion'
                      : 'No data recorded',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: isDark
                        ? MindPalColors.darkTextSecondary
                        : MindPalColors.ink700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _emotionEmoji(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'joy':
        return '😊';
      case 'excitement':
        return '🎉';
      case 'gratitude':
        return '🙏';
      case 'calm':
        return '😌';
      case 'neutral':
        return '😐';
      case 'anxiety':
        return '😰';
      case 'fear':
        return '😨';
      case 'sadness':
        return '😢';
      case 'frustration':
        return '😤';
      case 'anger':
        return '😠';
      case 'stress':
        return '😫';
      default:
        return '🙂';
    }
  }

  void _showDayDetails(
    BuildContext context,
    DateTime day,
    Map<String, String> emotionsByDate,
  ) {
    // Just update selected day - details shown inline
  }
}
