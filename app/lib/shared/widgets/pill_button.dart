import 'package:flutter/material.dart';
import 'package:mindpal_app/theme.dart';

enum PillButtonVariant { primary, secondary, ghost }

class PillButton extends StatelessWidget {
  const PillButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.variant = PillButtonVariant.primary,
    this.expanded = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final PillButtonVariant variant;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final style = _style(context);
    final child = FilledButton(
      onPressed: onPressed,
      style: style,
      child: Text(label),
    );

    if (!expanded) {
      return child;
    }
    return SizedBox(width: double.infinity, child: child);
  }

  ButtonStyle _style(BuildContext context) {
    switch (variant) {
      case PillButtonVariant.primary:
        return FilledButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        );
      case PillButtonVariant.secondary:
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return FilledButton.styleFrom(
          backgroundColor: Theme.of(context).cardColor,
          foregroundColor:
              Theme.of(context).textTheme.bodyLarge?.color ??
              MindPalColors.ink800,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
            side: BorderSide(
              color: isDark ? MindPalColors.darkBorder : MindPalColors.clay200,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        );
      case PillButtonVariant.ghost:
        return FilledButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor:
              Theme.of(context).textTheme.bodySmall?.color ??
              MindPalColors.ink700,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        );
    }
  }
}
