import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:mindpal_app/features/recommendations/providers/recommendations_providers.dart';
import 'package:mindpal_app/features/recommendations/presentation/widgets/category_selector.dart';
import 'package:mindpal_app/features/recommendations/presentation/widgets/habit_checklist_card.dart';
import 'package:mindpal_app/features/recommendations/presentation/widgets/recommendation_card.dart';
import 'package:mindpal_app/shared/widgets/app_drawer.dart';
import 'package:mindpal_app/shared/widgets/pill_button.dart';
import 'package:mindpal_app/shared/widgets/shimmer_loader.dart';
import 'package:mindpal_app/shared/widgets/state_panels.dart';
import 'package:mindpal_app/theme.dart';

class RecommendationsScreen extends ConsumerWidget {
  const RecommendationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(recommendationsProvider);
    final notifier = ref.read(recommendationsProvider.notifier);

    return Scaffold(
      drawer: const AppDrawer(currentRoute: '/recommendations'),
      drawerEnableOpenDragGesture: true,
      appBar: AppBar(
        title: Text(
          'Today',
          style: GoogleFonts.newsreader(
            fontSize: 32,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body:
          state.loading
              ? const Padding(
                padding: EdgeInsets.all(16),
                child: ShimmerLoader(
                  width: double.infinity,
                  height: 220,
                  radius: 28,
                ),
              )
              : state.error != null
              ? MindPalErrorPanel(
                title: 'Unable to load recommendations',
                message: state.error!,
                onRetry: notifier.refreshBatch,
              )
              : state.batch.isEmpty && state.checklist.isEmpty
              ? MindPalEmptyPanel(
                title: 'No recommendations right now',
                subtitle:
                    'Pull to refresh or generate a new batch tuned to your current mood trend.',
                actionLabel: 'Generate batch',
                icon: Icons.self_improvement_outlined,
                onAction: notifier.generateBatch,
              )
              : RefreshIndicator(
                onRefresh: notifier.refreshBatch,
                child: Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _HeaderCard(
                        percent: (state.completionPercent * 100).round(),
                      ),
                      const SizedBox(height: 16),
                      HabitChecklistCard(
                        items: state.checklist,
                        onToggle: notifier.toggleHabit,
                        onAdd: notifier.addHabit,
                        onDelete: notifier.deleteHabit,
                      ),
                      const SizedBox(height: 16),
                      CategorySelector(
                        selected: state.selectedCategory,
                        onSelect: notifier.selectCategory,
                      ),
                      const SizedBox(height: 14),
                      ...state.batch.map((item) {
                        final timer = state.timers[item.id];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            children: [
                              if (timer != null) _TimerCard(seconds: timer),
                              if (timer != null) const SizedBox(height: 8),
                              RecommendationCard(item: item),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 12),
                      PillButton(
                        label: 'Refresh batch',
                        expanded: true,
                        onPressed: notifier.generateBatch,
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? MindPalColors.darkSurfaceMid : null,
        gradient:
            isDark
                ? null
                : const LinearGradient(
                  colors: [
                    MindPalColors.recommendationGradientStart,
                    MindPalColors.recommendationGradientEnd,
                  ],
                ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark ? MindPalColors.darkBorder : MindPalColors.clay200,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RECOMMENDATIONS',
                  style: TextStyle(
                    fontSize: 11,
                    color:
                        isDark
                            ? MindPalColors.darkTextSecondary
                            : MindPalColors.ink700,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Breathe into gentle action',
                  style: GoogleFonts.newsreader(
                    fontSize: 34,
                    fontWeight: FontWeight.w600,
                    color:
                        isDark
                            ? MindPalColors.darkTextPrimary
                            : MindPalColors.ink900,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Small rituals shaped by your recent emotional patterns.',
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 110,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:
                  isDark
                      ? MindPalColors.darkSurfaceHigh
                      : Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Text(
                  '$percent%',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: percent / 100,
                    minHeight: 4,
                    backgroundColor:
                        isDark
                            ? MindPalColors.darkBorder
                            : MindPalColors.clay100,
                    color:
                        isDark
                            ? MindPalColors.darkTextPrimary
                            : MindPalColors.ink900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimerCard extends StatelessWidget {
  const _TimerCard({required this.seconds});

  final int seconds;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            isDark ? MindPalColors.darkSurfaceHigh : MindPalColors.timerCardBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$seconds s',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: isDark ? MindPalColors.darkTextPrimary : MindPalColors.ink900,
        ),
      ),
    );
  }
}
