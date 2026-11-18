import 'package:flutter/material.dart';

import 'package:mindpal_app/shared/widgets/pill_button.dart';

class SuggestionChips extends StatelessWidget {
  const SuggestionChips({required this.onSelect, super.key});

  final ValueChanged<String> onSelect;

  static const suggestions = <String>[
    'Reflect on my day',
    'Explore a difficult emotion',
    'Share a moment of gratitude',
    'Help me ground for 5 minutes',
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final text = suggestions[index];
          return PillButton(
            label: text,
            variant: PillButtonVariant.secondary,
            onPressed: () => onSelect(text),
          );
        },
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemCount: suggestions.length,
      ),
    );
  }
}
