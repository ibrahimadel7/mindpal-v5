import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:mindpal_app/features/insights/domain/models.dart';
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
          : state.emotions.isEmpty && state.habits.isEmpty && state.time.isEmpty
          ? MindPalEmptyPanel(
              title: 'No insights yet',
              subtitle:
                  'Start a few chats and reflections to reveal your emotional landscape.',
              actionLabel: 'Refresh insights',
              icon: Icons.query_stats,
              onAction: ref.read(insightsProvider.notifier).fetchInsights,
            )
          : RefreshIndicator(
              onRefresh: () =>
                  ref.read(insightsProvider.notifier).fetchInsights(),
              child: CustomScrollView(
                slivers: [
                  // Subtitle sliver
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _selectedTab == 0
                              ? 'A curated view of your internal landscape'
                              : 'A curated view of your daily practices',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: isDark
                                ? MindPalColors.darkTextSecondary.withValues(alpha: 0.65)
                                : MindPalColors.ink700.withValues(alpha: 0.65),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Sticky tab bar
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _TabBarDelegate(
                      child: Container(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
                                  onTap: () => setState(() => _selectedTab = 0),
                                ),
                              ),
                              Expanded(
                                child: _TabButton(
                                  label: 'Habit Frequency',
                                  isSelected: _selectedTab == 1,
                                  onTap: () => setState(() => _selectedTab = 1),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      height: 68,
                    ),
                  ),
                  // Content
                  SliverPadding(
                    padding: const EdgeInsets.only(top: 8),
                    sliver: _selectedTab == 0
                        ? _EmotionalPatternsSliver(state: state)
                        : _HabitFrequencySliver(state: state),
                  ),
                ],
              ),
            ),
    );
  }
}

/// Delegate for the sticky tab bar header
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  const _TabBarDelegate({required this.child, required this.height});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => child;

  @override
  bool shouldRebuild(_TabBarDelegate old) => old.child != child || old.height != height;
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
          border: isSelected
              ? null
              : Border.all(
                  color: isDark
                      ? MindPalColors.darkBorder.withValues(alpha: 0.4)
                      : MindPalColors.clay200.withValues(alpha: 0.4),
                  width: 1,
                ),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected
                  ? (isDark
                        ? MindPalColors.darkTextPrimary
                        : MindPalColors.ink900)
                  : (isDark
                        ? MindPalColors.darkTextSecondary.withValues(alpha: 0.7)
                        : MindPalColors.ink700.withValues(alpha: 0.7)),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmotionalPatternsSliver extends ConsumerWidget {
  const _EmotionalPatternsSliver({required this.state});

  final InsightsState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isAllPatterns = state.showingAllPatterns;
    final timeInsight = state.selectedTimeInsight;

    // For "All patterns" view, use aggregated data
    final displayEmotions = isAllPatterns
        ? state.allPatternsEmotions
        : (timeInsight != null && timeInsight.items.isNotEmpty
              ? timeInsight.items
                    .map((e) => EmotionStat(label: e.label, count: e.count))
                    .toList()
              : state.emotions);

    final topEmotion = displayEmotions.isNotEmpty
        ? displayEmotions.reduce((a, b) => a.count > b.count ? a : b).label
        : state.summary.mood;

    final displaySummary = isAllPatterns
        ? state.summary.copyWith(
            mood: topEmotion,
            entries: state.allPatternsTotal,
          )
        : (timeInsight != null
              ? state.summary.copyWith(
                  mood: topEmotion,
                  entries: timeInsight.total,
                )
              : state.summary);

    // Determine display label for date selector
    String dateLabel;
    if (isAllPatterns) {
      dateLabel = 'All Patterns';
    } else if (timeInsight != null) {
      dateLabel = DateFormat('EEEE, MMMM d').format(timeInsight.date);
    } else {
      dateLabel = DateFormat('EEEE, MMMM d').format(DateTime.now());
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isAllPatterns)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Icon(
                              Icons.auto_awesome,
                              size: 16,
                              color: isDark
                                  ? MindPalColors.clay300
                                  : MindPalColors.clay400,
                            ),
                          ),
                        Text(
                          dateLabel,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? MindPalColors.darkTextPrimary
                                : MindPalColors.ink900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _DayButton(
                  icon: Icons.chevron_right,
                  onTap: isAllPatterns
                      ? null
                      : ref.read(insightsProvider.notifier).selectNextDay,
                  disabled: isAllPatterns,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Today's Resonance Card
          MoodSummaryCard(summary: displaySummary),
          const SizedBox(height: 16),

          // Emotion Frequency Card
          MindPalCard(
            radius: 24,
            color: isDark ? MindPalColors.darkSurface : MindPalColors.surfaceLow,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAllPatterns
                      ? 'Overall Emotion Frequency'
                      : 'Emotion Frequency',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? MindPalColors.darkTextPrimary
                        : MindPalColors.ink900,
                  ),
                ),
                const SizedBox(height: 20),
                EmotionBarChart(items: displayEmotions),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

class _HabitFrequencySliver extends StatelessWidget {
  const _HabitFrequencySliver({required this.state});

  final InsightsState state;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      sliver: SliverToBoxAdapter(
        child: HabitPieChart(habits: state.habits),
      ),
    );
  }
}

class _DayButton extends StatelessWidget {
  const _DayButton({required this.icon, this.onTap, this.disabled = false});

  final IconData icon;
  final VoidCallback? onTap;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: 36,
      height: 36,
      child: OutlinedButton(
        onPressed: disabled ? null : onTap,
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
          color: isDark
              ? MindPalColors.darkTextSecondary
              : MindPalColors.ink800,
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
