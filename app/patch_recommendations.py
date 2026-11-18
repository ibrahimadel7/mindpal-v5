import sys

filepath = 'lib/features/recommendations/presentation/recommendations_screen.dart'
with open(filepath, 'r') as f:
    content = f.read()

# Add imports
imports = """import 'package:mindpal_app/features/insights/domain/models.dart';
import 'package:mindpal_app/features/insights/providers/insights_providers.dart';
"""
content = content.replace("import 'package:mindpal_app/features/recommendations/domain/models.dart';", imports + "import 'package:mindpal_app/features/recommendations/domain/models.dart';")

# Watch AI state
w_ai = """    final state = ref.watch(recommendationsProvider);
    final notifier = ref.read(recommendationsProvider.notifier);
    final aiState = ref.watch(aIOverviewNotifierProvider);"""
content = content.replace("    final state = ref.watch(recommendationsProvider);\n    final notifier = ref.read(recommendationsProvider.notifier);", w_ai)

# Add AI card
ai_card = """                  // AI Overview Card
                  const _AIOverviewCard(),
                  const SizedBox(height: 24),
                  
                  // Recommendation Carousel"""
content = content.replace("                  // Recommendation Carousel", ai_card)

# Define AI overview card class
card_code = """
class _AIOverviewCard extends ConsumerWidget {
  const _AIOverviewCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aiState = ref.watch(aIOverviewNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (aiState.loading) {
      return const ShimmerLoader(width: double.infinity, height: 160, radius: 24);
    }
    if (aiState.error != null) {
      return const SizedBox.shrink(); // Hide if error
    }
    final doc = aiState.overview;
    if (doc == null) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? MindPalColors.darkSurfaceHigh : MindPalColors.sand100,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : MindPalColors.ink900.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                size: 20,
                color: isDark ? MindPalColors.coral400 : MindPalColors.coral500,
              ),
              const SizedBox(width: 8),
              Text(
                'AI INSIGHT',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: isDark ? MindPalColors.coral400 : MindPalColors.coral500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            doc.greeting,
            style: GoogleFonts.newsreader(
              fontSize: 24,
              fontWeight: FontWeight.w500,
              color: isDark ? MindPalColors.darkTextPrimary : MindPalColors.ink900,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            doc.currentFeeling,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              height: 1.5,
              color: isDark ? MindPalColors.darkTextSecondary : MindPalColors.ink800,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? MindPalColors.darkSurface : Colors.white.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SummaryRow(icon: Icons.mood, text: doc.emotionSummary),
                const SizedBox(height: 8),
                _SummaryRow(icon: Icons.track_changes, text: doc.habitSummary),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            doc.encouragement,
            style: GoogleFonts.newsreader(
              fontSize: 16,
              fontStyle: FontStyle.italic,
              color: isDark ? MindPalColors.darkTextPrimary : MindPalColors.ink700,
            ),
          ),
        ],
      ),
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
            color: isDark ? MindPalColors.darkTextSecondary : MindPalColors.ink600,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              height: 1.4,
              color: isDark ? MindPalColors.darkTextSecondary : MindPalColors.ink800,
            ),
          ),
        ),
      ],
    );
  }
}
"""

content += card_code

with open(filepath, 'w') as f:
    f.write(content)
print("done")
