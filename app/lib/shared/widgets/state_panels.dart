import 'package:flutter/material.dart';
import 'package:mindpal_app/shared/widgets/pill_button.dart';
import 'package:mindpal_app/theme.dart';

class MindPalErrorPanel extends StatelessWidget {
  const MindPalErrorPanel({
    required this.message,
    super.key,
    this.title = 'Something went off script',
    this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: MindPalColors.emotionAnger.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.priority_high_rounded,
                color: MindPalColors.emotionAnger,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              PillButton(label: 'Try again', onPressed: onRetry),
            ],
          ],
        ),
      ),
    );
  }
}

class MindPalEmptyPanel extends StatelessWidget {
  const MindPalEmptyPanel({
    required this.title,
    required this.subtitle,
    super.key,
    this.onAction,
    this.actionLabel = 'Refresh',
    this.icon = Icons.inbox_outlined,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final IconData icon;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 34,
              color: isDark ? MindPalColors.darkTextSecondary : MindPalColors.ink700,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (onAction != null) ...[
              const SizedBox(height: 16),
              PillButton(label: actionLabel, onPressed: onAction),
            ],
          ],
        ),
      ),
    );
  }
}
