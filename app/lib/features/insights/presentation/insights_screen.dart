import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:mindpal_app/features/insights/providers/insights_providers.dart';
import 'package:mindpal_app/features/insights/presentation/widgets/emotion_bar_chart.dart';
import 'package:mindpal_app/features/insights/presentation/widgets/habit_pie_chart.dart';
import 'package:mindpal_app/features/insights/presentation/widgets/mood_summary_card.dart';
import 'package:mindpal_app/shared/widgets/app_drawer.dart';
import 'package:mindpal_app/shared/widgets/mindpal_card.dart';
import 'package:mindpal_app/shared/widgets/shimmer_loader.dart';
import 'package:mindpal_app/shared/widgets/state_panels.dart';
import 'package:mindpal_app/theme.dart';

class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(insightsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      drawer: const AppDrawer(currentRoute: '/insights'),
      drawerEnableOpenDragGesture: true,
      appBar: AppBar(
        title: Text(
          _selectedTab == 0 ? 'Emotional Patterns' : 'Habit Frequency',
          style: GoogleFonts.newsreader(
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: state.loading
          ? const _LoadingBody()
          : state.error != null
              ? _ErrorBody(
                  message: state.error!,
                  onRetry: ref.read(insightsProvider.notifier).fetchInsights,
                )
              : state.emotions.isEmpty &&
                      state.habits.isEmpty &&
                      state.time.isEmpty
                  ? MindPalEmptyPanel(
                      title: 'No insights yet',
                      subtitle:
                          'Start a few chats and reflections to reveal your emotional landscape.',
                      actionLabel: 'Refresh insights',
                      icon: Icons.query_stats,
                      onAction:
                          ref.read(insightsProvider.notifier).fetchInsights,
                    )
                  : RefreshIndicator(
                      onRefresh: () =>
                          ref.read(insightsProvider.notifier).fetchInsights(),
                      child: Column(
                        children: [
                          // Subtitle
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                _selectedTab == 0
                                    ? 'A curated view of your internal landscape'
                                    : 'A curated view of your daily practices',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ),
                          // Tab selector
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? MindPalColors.darkSurface
                                    : MindPalColors.sand100,
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _TabButton(
                                      label: 'Emotional Patterns',
                                      isSelected: _selectedTab == 0,
                                      onTap: () =>
                                          setState(() => _selectedTab = 0),
                                    ),
                                  ),
                                  Expanded(
                                    child: _TabButton(
                                      label: 'Habit Frequency',
                                      isSelected: _selectedTab == 1,
                                      onTap: () =>
                                          setState(() => _selectedTab = 1),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Content
                          Expanded(
                            child: _selectedTab == 0
                                ? _EmotionalPatternsTab(state: state)
                                : _HabitFrequencyTab(state: state),
                          ),
                        ],
                      ),
                    ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 44,
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? MindPalColors.darkSurfaceHigh : MindPalColors.clay200)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected
                  ? (isDark
                      ? MindPalColors.darkTextPrimary
                      : MindPalColors.ink900)
                  : (isDark
                      ? MindPalColors.darkTextSecondary
                      : MindPalColors.ink700),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmotionalPatternsTab extends ConsumerWidget {
  const _EmotionalPatternsTab({required this.state});

  final InsightsState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        // Date selector
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: isDark
                ? MindPalColors.darkSurface
                : Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isDark ? MindPalColors.darkBorder : MindPalColors.clay100,
            ),
          ),
          child: Row(
            children: [
              _DayButton(
                icon: Icons.chevron_left,
                onTap: ref.read(insightsProvider.notifier).selectPrevDay,
              ),
              Expanded(
                child: Center(
                  child: Text(
                    DateFormat('EEEE, MMMM d').format(
                      state.selectedTimeInsight?.date ?? DateTime.now(),
                    ),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? MindPalColors.darkTextPrimary
                          : MindPalColors.ink900,
                    ),
                  ),
                ),
              ),
              _DayButton(
                icon: Icons.chevron_right,
                onTap: ref.read(insightsProvider.notifier).selectNextDay,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Today's Resonance Card
        MoodSummaryCard(summary: state.summary),
        const SizedBox(height: 16),

        // Emotion Frequency Card
        MindPalCard(
          radius: 24,
          color: isDark ? MindPalColors.darkSurface : MindPalColors.surfaceLow,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Emotion Frequency',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? MindPalColors.darkTextPrimary
                      : MindPalColors.ink900,
                ),
              ),
              const SizedBox(height: 20),
              EmotionBarChart(items: state.emotions),
            ],
          ),
        ),
      ],
    );
  }
}

class _HabitFrequencyTab extends StatelessWidget {
  const _HabitFrequencyTab({required this.state});

  final InsightsState state;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      child: HabitPieChart(habits: state.habits),
    );
  }
}

class _DayButton extends StatelessWidget {
  const _DayButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: 36,
      height: 36,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          side: BorderSide(
            color: isDark ? MindPalColors.darkBorder : MindPalColors.clay200,
          ),
          shape: const CircleBorder(),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isDark ? MindPalColors.darkTextSecondary : MindPalColors.ink800,
        ),
      ),
    );
  }
}

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: const [
              ShimmerLoader(width: double.infinity, height: 48, radius: 30),
              SizedBox(height: 20),
              ShimmerLoader(width: double.infinity, height: 250, radius: 24),
              SizedBox(height: 16),
              ShimmerLoader(width: double.infinity, height: 150, radius: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return MindPalErrorPanel(
      message: message,
      title: 'Could not load insights',
      onRetry: onRetry,
    );
  }
}
