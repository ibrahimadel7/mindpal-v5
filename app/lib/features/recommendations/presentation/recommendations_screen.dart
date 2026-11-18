import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:mindpal_app/features/insights/providers/insights_providers.dart';
import 'package:mindpal_app/features/recommendations/domain/models.dart';
import 'package:mindpal_app/features/recommendations/providers/recommendations_providers.dart';
import 'package:mindpal_app/features/recommendations/presentation/widgets/category_selector.dart';
import 'package:mindpal_app/shared/widgets/app_drawer.dart';
import 'package:mindpal_app/shared/widgets/auto_scroll_text.dart';
import 'package:mindpal_app/shared/widgets/mindpal_card.dart';
import 'package:mindpal_app/shared/widgets/shimmer_loader.dart';
import 'package:mindpal_app/shared/widgets/state_panels.dart';
import 'package:mindpal_app/theme.dart';

class RecommendationsScreen extends ConsumerStatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  ConsumerState<RecommendationsScreen> createState() =>
      _RecommendationsScreenState();
}

class _RecommendationsScreenState extends ConsumerState<RecommendationsScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _habitsExpanded = true;
  int _selectedTab = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _clampCurrentPage(int batchLength) {
    if (batchLength == 0) {
      _currentPage = 0;
    } else if (_currentPage >= batchLength) {
      _currentPage = batchLength - 1;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(_currentPage);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recommendationsProvider);
    final notifier = ref.read(recommendationsProvider.notifier);

    // Clamp page index when batch shrinks
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _clampCurrentPage(state.batch.length);
    });

    return Scaffold(
      drawer: const AppDrawer(currentRoute: '/recommendations'),
      drawerEnableOpenDragGesture: true,
      appBar: AppBar(
        title: Text(
          'Plans & Recommendations',
          style: GoogleFonts.newsreader(
            fontSize: 28,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: state.loading ? null : notifier.generateBatch,
            child: Text(
              'Refresh',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: MindPalColors.ink700,
              ),
            ),
          ),
        ],
      ),
      body: state.loading
          ? const Padding(
              padding: EdgeInsets.all(20),
              child: ShimmerLoader(
                width: double.infinity,
                height: 280,
                radius: 24,
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
              child: Column(
                children: [
                  // Tab selector
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? MindPalColors.darkSurface
                            : MindPalColors.sand100,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _TabButton(
                              label: 'Action Plan',
                              isSelected: _selectedTab == 0,
                              onTap: () => setState(() => _selectedTab = 0),
                            ),
                          ),
                          Expanded(
                            child: _TabButton(
                              label: 'AI Insights',
                              isSelected: _selectedTab == 1,
                              onTap: () => setState(() => _selectedTab = 1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      children: _selectedTab == 1
                          ? [const _AIOverviewCard()]
                          : [
                              // Recommendation Carousel
                              if (state.batch.isNotEmpty) ...[
                                _RecommendationCarousel(
                                  items: state.batch,
                                  currentPage: _currentPage,
                                  pageController: _pageController,
                                  onPageChanged: (index) {
                                    setState(() => _currentPage = index);
                                  },
                                  onComplete: notifier.completeItem,
                                  onAdopt: notifier.adoptHabit,
                                  onSkip: notifier.skipItem,
                                  onNext: () {
                                    if (_currentPage < state.batch.length - 1) {
                                      _pageController.nextPage(
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        curve: Curves.easeInOut,
                                      );
                                    }
                                  },
                                ),
                                const SizedBox(height: 20),
                              ],
                              // Today's Habits Section
                              _HabitsSection(
                                items: state.checklist,
                                isExpanded: _habitsExpanded,
                                onToggleExpanded: () {
                                  setState(
                                    () => _habitsExpanded = !_habitsExpanded,
                                  );
                                },
                                onToggle: notifier.toggleHabit,
                                onAdd: notifier.addHabit,
                                onDelete: notifier.deleteHabit,
                                onReorder: notifier.reorderHabits,
                              ),
                              const SizedBox(height: 20),
                              // Category Selector
                              _DirectionCard(
                                selectedCategory: state.selectedCategory,
                                onSelect: notifier.selectCategory,
                                onRefresh: notifier.generateBatch,
                              ),
                            ],
                    ),
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
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? MindPalColors.darkSurfaceMid : MindPalColors.clay300)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? (isDark ? Colors.white : MindPalColors.ink900)
                  : (isDark ? Colors.white60 : MindPalColors.ink700),
            ),
          ),
        ),
      ),
    );
  }
}

class _RecommendationCarousel extends StatefulWidget {
  const _RecommendationCarousel({
    required this.items,
    required this.currentPage,
    required this.pageController,
    required this.onPageChanged,
    required this.onComplete,
    required this.onAdopt,
    required this.onSkip,
    required this.onNext,
  });

  final List<RecommendationItem> items;
  final int currentPage;
  final PageController pageController;
  final ValueChanged<int> onPageChanged;
  final Future<void> Function(String itemId) onComplete;
  final Future<void> Function(String itemId) onAdopt;
  final Future<void> Function(String itemId) onSkip;
  final VoidCallback onNext;

  @override
  State<_RecommendationCarousel> createState() =>
      _RecommendationCarouselState();
}

class _RecommendationCarouselState extends State<_RecommendationCarousel> {
  final Map<String, bool> _expandedState = {};

  bool _isItemExpanded(String id) => _expandedState[id] ?? true;

  void _toggleExpanded(String id) {
    setState(() {
      _expandedState[id] = !_isItemExpanded(id);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return const SizedBox.shrink();
    }
    final safeCurrentPage = widget.currentPage.clamp(
      0,
      widget.items.length - 1,
    );
    final currentItem = widget.items[safeCurrentPage];

    return Column(
      children: [
        // Card Header with pagination
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: MindPalColors.clay200.withValues(alpha: 0.8),
            ),
            boxShadow: [
              BoxShadow(
                color: MindPalColors.ink900.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Item counter
              Text(
                'ITEM ${safeCurrentPage + 1} OF ${widget.items.length}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  color: MindPalColors.ink700,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '•',
                style: TextStyle(
                  color: MindPalColors.ink700.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(width: 8),
              // Kind label
              Text(
                _formatKind(currentItem.kind).toUpperCase(),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  color: MindPalColors.ink700,
                ),
              ),
              const Spacer(),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: MindPalColors.sand100,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  currentItem.status.toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: MindPalColors.ink700,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Progress dots
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              left: BorderSide(
                color: MindPalColors.clay200.withValues(alpha: 0.8),
              ),
              right: BorderSide(
                color: MindPalColors.clay200.withValues(alpha: 0.8),
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.items.length,
              (index) => Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: index == safeCurrentPage
                      ? MindPalColors.ink900
                      : MindPalColors.clay200,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
        // Page View
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.fastOutSlowIn,
          height: _isItemExpanded(widget.items[safeCurrentPage].id) ? 340 : 136,
          child: PageView.builder(
            controller: widget.pageController,
            onPageChanged: widget.onPageChanged,
            itemCount: widget.items.length,
            itemBuilder: (context, index) {
              return _RecommendationPage(
                item: widget.items[index],
                isExpanded: _isItemExpanded(widget.items[index].id),
                onToggleExpanded: () => _toggleExpanded(widget.items[index].id),
                onComplete: widget.onComplete,
                onAdopt: widget.onAdopt,
                onSkip: widget.onSkip,
                onNext: widget.onNext,
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatKind(String kind) {
    return kind.replaceAll('_', ' ');
  }
}

class _RecommendationPage extends StatefulWidget {
  const _RecommendationPage({
    required this.item,
    required this.isExpanded,
    required this.onToggleExpanded,
    required this.onComplete,
    required this.onAdopt,
    required this.onSkip,
    required this.onNext,
  });

  final RecommendationItem item;
  final bool isExpanded;
  final VoidCallback onToggleExpanded;
  final Future<void> Function(String itemId) onComplete;
  final Future<void> Function(String itemId) onAdopt;
  final Future<void> Function(String itemId) onSkip;
  final VoidCallback onNext;

  @override
  State<_RecommendationPage> createState() => _RecommendationPageState();
}

class _RecommendationPageState extends State<_RecommendationPage> {
  void _handleComplete() async {
    HapticFeedback.mediumImpact();
    final isAdopt = widget.item.kind == 'adopt_habit';

    if (isAdopt) {
      await widget.onAdopt(widget.item.id);
    } else {
      await widget.onComplete(widget.item.id);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Text(
                isAdopt ? 'Habit adopted!' : 'Completed!',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          backgroundColor: MindPalColors.sage300,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onToggleExpanded,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(24),
            ),
            border: Border.all(
              color: widget.isExpanded
                  ? MindPalColors.ink900.withValues(alpha: 0.3)
                  : MindPalColors.clay200.withValues(alpha: 0.8),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with title and expand icon - tappable
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        SizedBox(
                          height: 60,
                          child: AutoScrollText(
                            text: widget.item.title,
                            scrollDirection: Axis.vertical,
                            style: GoogleFonts.newsreader(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: MindPalColors.ink900,
                              height: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Duration and kind tags
                        Wrap(
                          spacing: 8,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: MindPalColors.sand100,
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                widget.item.duration.toUpperCase(),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.8,
                                  color: MindPalColors.ink700,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: MindPalColors.clay100,
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                widget.item.kind
                                    .replaceAll('_', ' ')
                                    .toUpperCase(),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.8,
                                  color: MindPalColors.ink700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 48x48 touch target for expand icon
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: Icon(
                      widget.isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: MindPalColors.ink700,
                      size: 24,
                    ),
                  ),
                ],
              ),
              // Expanded content
              if (widget.isExpanded)
                Flexible(
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: SizedBox(
                      height: 204, // 340 - 136
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          // Context label
                          Text(
                            'WHY THIS?',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                              color: MindPalColors.ink700.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          // Rationale
                          Flexible(
                            child: AutoScrollText(
                              scrollDirection: Axis.vertical,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.item.rationale,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      color: MindPalColors.ink700,
                                      height: 1.6,
                                    ),
                                  ),
                                  if (widget.item.followUp != null) ...[
                                    const SizedBox(height: 12),
                                    Text(
                                      widget.item.followUp!,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontStyle: FontStyle.italic,
                                        color: MindPalColors.ink700.withValues(
                                          alpha: 0.8,
                                        ),
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Action buttons
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _handleComplete,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: MindPalColors.ink900,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                widget.item.kind == 'adopt_habit'
                                    ? 'Adopt habit'
                                    : 'Mark complete',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 48,
                                  child: OutlinedButton(
                                    onPressed: () =>
                                        widget.onSkip(widget.item.id),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: MindPalColors.ink800,
                                      side: BorderSide(
                                        color: MindPalColors.clay300,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          100,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      'Skip',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: SizedBox(
                                  height: 48,
                                  child: OutlinedButton(
                                    onPressed: widget.onNext,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: MindPalColors.ink800,
                                      side: BorderSide(
                                        color: MindPalColors.clay300,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          100,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      'Next',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HabitsSection extends StatefulWidget {
  const _HabitsSection({
    required this.items,
    required this.isExpanded,
    required this.onToggleExpanded,
    required this.onToggle,
    required this.onAdd,
    required this.onDelete,
    required this.onReorder,
  });

  final List<HabitChecklistItem> items;
  final bool isExpanded;
  final VoidCallback onToggleExpanded;
  final Future<void> Function(HabitChecklistItem item, bool checked) onToggle;
  final Future<void> Function(String name) onAdd;
  final Future<void> Function(String id) onDelete;
  final void Function(int oldIndex, int newIndex) onReorder;

  @override
  State<_HabitsSection> createState() => _HabitsSectionState();
}

class _HabitsSectionState extends State<_HabitsSection> {
  bool _showAddForm = false;
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final completedCount = widget.items.where((i) => i.completed).length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: MindPalColors.clay200.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: MindPalColors.ink900.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "TODAY'S HABITS",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                          color: MindPalColors.ink700.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$completedCount of ${widget.items.length} completed',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: MindPalColors.ink900,
                        ),
                      ),
                    ],
                  ),
                ),
                // 48x48 touch target for show/hide button
                SizedBox(
                  height: 48,
                  child: TextButton(
                    onPressed: widget.onToggleExpanded,
                    style: TextButton.styleFrom(
                      minimumSize: const Size(64, 48),
                    ),
                    child: Text(
                      widget.isExpanded ? 'HIDE' : 'SHOW',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                        color: MindPalColors.ink700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Habits list
          if (widget.isExpanded) ...[
            const Divider(height: 1, color: MindPalColors.clay100),
            if (widget.items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 32,
                ),
                child: Column(
                  children: [
                    // Friendly empty state illustration (plant icon)
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: MindPalColors.sage100.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.eco_outlined,
                        size: 32,
                        color: MindPalColors.sage300,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Start growing your habits',
                      style: GoogleFonts.newsreader(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: MindPalColors.ink900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add a habit below or adopt one from your recommendations.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: MindPalColors.ink700.withValues(alpha: 0.7),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              )
            else
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                itemCount: widget.items.length,
                onReorder: widget.onReorder,
                proxyDecorator: (child, index, animation) {
                  return AnimatedBuilder(
                    animation: animation,
                    builder: (context, child) {
                      final scale = Tween<double>(begin: 1.0, end: 1.02)
                          .animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeInOut,
                            ),
                          )
                          .value;
                      return Transform.scale(
                        scale: scale,
                        child: Material(
                          elevation: 4,
                          borderRadius: BorderRadius.circular(16),
                          child: child,
                        ),
                      );
                    },
                    child: child,
                  );
                },
                itemBuilder: (context, index) {
                  final item = widget.items[index];
                  return _HabitRow(
                    key: ValueKey(item.id),
                    item: item,
                    index: index,
                    onToggle: widget.onToggle,
                    onDelete: widget.onDelete,
                  );
                },
              ),
            // Add habit form or button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: _showAddForm
                  ? Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            autofocus: true,
                            decoration: InputDecoration(
                              hintText: 'e.g. Morning Walk',
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(100),
                                borderSide: BorderSide(
                                  color: MindPalColors.clay300,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(100),
                                borderSide: BorderSide(
                                  color: MindPalColors.clay300,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(100),
                                borderSide: BorderSide(
                                  color: MindPalColors.clay400,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async {
                            final text = _controller.text.trim();
                            if (text.isEmpty) return;
                            await widget.onAdd(text);
                            if (mounted) {
                              _controller.clear();
                              setState(() => _showAddForm = false);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: MindPalColors.ink900,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            elevation: 0,
                          ),
                          child: const Text('Add'),
                        ),
                        const SizedBox(width: 4),
                        TextButton(
                          onPressed: () {
                            _controller.clear();
                            setState(() => _showAddForm = false);
                          },
                          child: Text(
                            'Cancel',
                            style: TextStyle(color: MindPalColors.ink700),
                          ),
                        ),
                      ],
                    )
                  : GestureDetector(
                      onTap: () => setState(() => _showAddForm = true),
                      child: Row(
                        children: [
                          Text(
                            '+',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: MindPalColors.ink700,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Add habit',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: MindPalColors.ink700,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HabitRow extends StatefulWidget {
  const _HabitRow({
    super.key,
    required this.item,
    required this.index,
    required this.onToggle,
    required this.onDelete,
  });

  final HabitChecklistItem item;
  final int index;
  final Future<void> Function(HabitChecklistItem item, bool checked) onToggle;
  final Future<void> Function(String id) onDelete;

  @override
  State<_HabitRow> createState() => _HabitRowState();
}

class _HabitRowState extends State<_HabitRow>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _strikeController;
  late Animation<double> _strikeAnimation;

  bool get _hasDetails =>
      (widget.item.category != null && widget.item.category!.isNotEmpty) ||
      (widget.item.cueText != null && widget.item.cueText!.isNotEmpty) ||
      (widget.item.reasonText != null && widget.item.reasonText!.isNotEmpty);

  @override
  void initState() {
    super.initState();
    _strikeController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _strikeAnimation = CurvedAnimation(
      parent: _strikeController,
      curve: Curves.easeOut,
    );
    if (widget.item.completed) {
      _strikeController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant _HabitRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.item.completed != oldWidget.item.completed) {
      if (widget.item.completed) {
        _strikeController.forward();
      } else {
        _strikeController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _strikeController.dispose();
    super.dispose();
  }

  void _handleToggle(bool? value) {
    HapticFeedback.lightImpact();
    widget.onToggle(widget.item, value ?? false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _hasDetails
          ? () => setState(() => _isExpanded = !_isExpanded)
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.only(left: 8, right: 16, top: 14, bottom: 14),
        decoration: BoxDecoration(
          color: MindPalColors.sand50.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isExpanded
                ? MindPalColors.ink900.withValues(alpha: 0.3)
                : MindPalColors.clay200.withValues(alpha: 0.7),
          ),
          boxShadow: [
            BoxShadow(
              color: MindPalColors.ink900.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Drag handle for reordering
                ReorderableDragStartListener(
                  index: widget.index,
                  child: SizedBox(
                    width: 32,
                    height: 48,
                    child: Icon(
                      Icons.drag_indicator,
                      color: MindPalColors.clay300,
                      size: 20,
                    ),
                  ),
                ),
                // 48x48 touch target for checkbox
                SizedBox(
                  width: 48,
                  height: 48,
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: Checkbox(
                        value: widget.item.completed,
                        activeColor: MindPalColors.ink900,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        side: BorderSide(
                          color: MindPalColors.clay300,
                          width: 1.5,
                        ),
                        onChanged: _handleToggle,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: AnimatedBuilder(
                    animation: _strikeAnimation,
                    builder: (context, child) {
                      return Stack(
                        children: [
                          AutoScrollText(
                            text: widget.item.name,
                            scrollDirection: Axis.horizontal,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color.lerp(
                                MindPalColors.ink900,
                                MindPalColors.ink700,
                                _strikeAnimation.value,
                              ),
                            ),
                          ),
                          // Animated strikethrough line
                          if (_strikeAnimation.value > 0)
                            Positioned.fill(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    return Container(
                                      width:
                                          constraints.maxWidth *
                                          _strikeAnimation.value,
                                      height: 1.5,
                                      color: MindPalColors.ink700.withValues(
                                        alpha: 0.5,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
                if (_hasDetails)
                  // 48x48 touch target for expand icon
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: MindPalColors.ink700,
                      size: 20,
                    ),
                  ),
                // 48x48 touch target for remove button
                SizedBox(
                  width: 72,
                  height: 48,
                  child: TextButton(
                    onPressed: () => widget.onDelete(widget.item.id),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(72, 48),
                    ),
                    child: Text(
                      'Remove',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: MindPalColors.ink700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_isExpanded && _hasDetails) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.item.category != null &&
                        widget.item.category!.isNotEmpty) ...[
                      _DetailRow(
                        label: 'Category',
                        value: widget.item.category!,
                      ),
                    ],
                    if (widget.item.cueText != null &&
                        widget.item.cueText!.isNotEmpty) ...[
                      if (widget.item.category != null)
                        const SizedBox(height: 8),
                      _DetailRow(label: 'Cue', value: widget.item.cueText!),
                    ],
                    if (widget.item.reasonText != null &&
                        widget.item.reasonText!.isNotEmpty) ...[
                      if (widget.item.category != null ||
                          widget.item.cueText != null)
                        const SizedBox(height: 8),
                      _DetailRow(label: 'Why', value: widget.item.reasonText!),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: MindPalColors.ink700.withValues(alpha: 0.6),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: MindPalColors.ink900,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _DirectionCard extends StatelessWidget {
  const _DirectionCard({
    required this.selectedCategory,
    required this.onSelect,
    required this.onRefresh,
  });

  final String selectedCategory;
  final ValueChanged<String> onSelect;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: MindPalColors.clay200.withValues(alpha: 0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pick your direction',
            style: GoogleFonts.newsreader(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: MindPalColors.ink900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Keep one category active and focus on one recommendation at a time.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: MindPalColors.ink700,
            ),
          ),
          const SizedBox(height: 16),
          CategorySelector(selected: selectedCategory, onSelect: onSelect),
        ],
      ),
    );
  }
}

class _AIOverviewCard extends ConsumerWidget {
  const _AIOverviewCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aiState = ref.watch(aIOverviewProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (aiState.loading) {
      return const ShimmerLoader(
        width: double.infinity,
        height: 160,
        radius: 24,
      );
    }
    if (aiState.error != null) {
      return const SizedBox.shrink(); // Hide if error
    }
    final doc = aiState.overview;
    if (doc == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top Card (Like MoodSummaryCard)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark
                ? MindPalColors.darkSurfaceMid
                : MindPalColors.clay100.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 16,
                    color: isDark
                        ? MindPalColors.darkTextSecondary
                        : MindPalColors.ink700,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'AI INSIGHT',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: isDark
                          ? MindPalColors.darkTextSecondary
                          : MindPalColors.ink700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                doc.greeting,
                style: GoogleFonts.newsreader(
                  fontSize: 28,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? MindPalColors.darkTextPrimary
                      : MindPalColors.ink900,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                doc.currentFeeling,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  height: 1.5,
                  color: isDark
                      ? MindPalColors.darkTextSecondary
                      : MindPalColors.ink700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Bottom Card (Like EmotionFrequency Card)
        MindPalCard(
          radius: 24,
          color: isDark ? MindPalColors.darkSurface : MindPalColors.surfaceLow,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recent Observations',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? MindPalColors.darkTextPrimary
                      : MindPalColors.ink900,
                ),
              ),
              const SizedBox(height: 16),
              _SummaryRow(icon: Icons.mood, text: doc.emotionSummary),
              const SizedBox(height: 12),
              _SummaryRow(icon: Icons.track_changes, text: doc.habitSummary),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Encouragement Text
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            doc.encouragement,
            style: GoogleFonts.newsreader(
              fontSize: 16,
              fontStyle: FontStyle.italic,
              color: isDark
                  ? MindPalColors.darkTextPrimary
                  : MindPalColors.ink700,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            icon,
            size: 16,
            color: isDark
                ? MindPalColors.darkTextSecondary
                : MindPalColors.ink700,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              height: 1.4,
              color: isDark
                  ? MindPalColors.darkTextSecondary
                  : MindPalColors.ink800,
            ),
          ),
        ),
      ],
    );
  }
}
