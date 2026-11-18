import 'package:flutter/material.dart';

import 'package:mindpal_app/features/insights/domain/models.dart';
import 'package:mindpal_app/theme.dart';

class DayEmotionWidget extends StatelessWidget {
  const DayEmotionWidget({required this.items, super.key});

  final List<DayEmotion> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Text('No day breakdown available');
    }

    return Column(
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(item.label)),
                      Text('${item.percent.toStringAsFixed(0)}%'),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      minHeight: 6,
                      value: (item.percent / 100).clamp(0, 1),
                      color:
                          Theme.of(context).brightness == Brightness.dark
                              ? MindPalColors.darkAccent
                              : MindPalColors.clay300,
                      backgroundColor:
                          Theme.of(context).brightness == Brightness.dark
                              ? MindPalColors.darkBorder
                              : MindPalColors.clay100,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}
