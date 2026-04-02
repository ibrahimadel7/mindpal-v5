import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:mindpal_app/features/insights/domain/models.dart';
import 'package:mindpal_app/theme.dart';

class MoodSummaryCard extends StatelessWidget {
  const MoodSummaryCard({required this.summary, super.key});

  final InsightsSummary summary;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
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
          Text(
            "TODAY'S RESONANCE",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: isDark
                  ? MindPalColors.darkTextSecondary
                  : MindPalColors.ink700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Your heart feels ${summary.mood.toLowerCase()} today.',
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
            'Based on ${summary.entries} insight ${summary.entries == 1 ? 'entry' : 'entries'}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: isDark
                  ? MindPalColors.darkTextSecondary
                  : MindPalColors.ink700,
            ),
          ),
        ],
      ),
    );
  }
}
