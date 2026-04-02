import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:mindpal_app/features/insights/domain/models.dart';
import 'package:mindpal_app/theme.dart';

class EmotionBarChart extends StatelessWidget {
  const EmotionBarChart({required this.items, super.key});

  final List<EmotionStat> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(child: Text('No emotion data available yet')),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final maxCount = items.map((e) => e.count).fold<int>(1, (a, b) => a > b ? a : b);

    return SizedBox(
      height: 200,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: items.map((item) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Count label above bar
                  Text(
                    '${item.count}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? MindPalColors.darkTextPrimary
                          : MindPalColors.ink900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Bar with background
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark
                            ? MindPalColors.darkSurfaceHigh
                            : MindPalColors.sand100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.bottomCenter,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final heightPercent = item.count / maxCount;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOutCubic,
                            width: double.infinity,
                            height: constraints.maxHeight * heightPercent,
                            decoration: BoxDecoration(
                              color: MindPalColors.emotionColor(item.label, isDark: isDark),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Label below bar
                  Text(
                    item.label.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: isDark
                          ? MindPalColors.darkTextSecondary
                          : MindPalColors.ink700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        }).toList(growable: false),
      ),
    );
  }
}
