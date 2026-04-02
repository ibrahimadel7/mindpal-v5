import 'package:flutter/material.dart';

import 'package:mindpal_app/theme.dart';

class CategorySelector extends StatelessWidget {
  const CategorySelector({
    required this.selected,
    required this.onSelect,
    super.key,
  });

  final String selected;
  final ValueChanged<String> onSelect;

  static const categories = <String>[
    'Balance',
    'Calm',
    'Focus',
    'Energy',
    'Reflection',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(item),
                  selected: selected == item,
                  onSelected: (_) => onSelect(item),
                  selectedColor: MindPalColors.clay400,
                  labelStyle: TextStyle(
                    color: selected == item
                        ? Colors.white
                        : isDark
                            ? MindPalColors.darkTextPrimary
                            : MindPalColors.ink800,
                    fontWeight: FontWeight.w600,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  backgroundColor: isDark
                      ? MindPalColors.darkSurfaceHigh
                      : MindPalColors.surfaceHigh,
                  showCheckmark: false,
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}
