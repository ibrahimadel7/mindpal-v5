import 'package:flutter/material.dart';

import 'package:mindpal_app/theme.dart';

class StreakCard extends StatelessWidget {
  const StreakCard({required this.streak, super.key});

  final int streak;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            Theme.of(context).brightness == Brightness.dark
                ? MindPalColors.darkSurfaceHigh
                : MindPalColors.inkDeep,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.local_fire_department_outlined,
            color: Colors.white70,
          ),
          const SizedBox(height: 12),
          Text(
            '$streak',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 52,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Text(
            'Day Streak',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            "You're doing great",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
