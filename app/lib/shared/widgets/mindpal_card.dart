import 'package:flutter/material.dart';
import 'package:mindpal_app/theme.dart';

class MindPalCard extends StatelessWidget {
  const MindPalCard({
    required this.child,
    super.key,
    this.radius = 20,
    this.padding = const EdgeInsets.all(16),
    this.color,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: isDark
              ? MindPalColors.darkBorder.withValues(alpha: 0.6)
              : MindPalColors.clay200.withValues(alpha: 0.5),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: MindPalColors.ink900.withValues(alpha: 0.09),
                  blurRadius: 40,
                  spreadRadius: -32,
                  offset: const Offset(0, 18),
                ),
              ],
      ),
      padding: padding,
      child: child,
    );
  }
}
