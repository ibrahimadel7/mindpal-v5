import 'package:flutter/material.dart';

import 'package:mindpal_app/theme.dart';

class ChatInput extends StatelessWidget {
  const ChatInput({
    required this.controller,
    required this.onSend,
    super.key,
    this.docked = false,
    this.enabled = true,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final bool docked;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (docked)
              Container(
                margin: const EdgeInsets.only(right: 8, bottom: 4),
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isDark ? MindPalColors.darkSurfaceHigh : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color:
                        isDark
                            ? MindPalColors.darkBorder
                            : MindPalColors.clay200,
                  ),
                ),
                child: IconButton(
                  onPressed: enabled ? () {} : null,
                  icon: Icon(
                    Icons.today_outlined,
                    size: 18,
                    color:
                        enabled
                            ? (isDark
                                ? MindPalColors.darkTextPrimary
                                : MindPalColors.ink900)
                            : (isDark
                                ? MindPalColors.darkTextTertiary
                                : MindPalColors.clay300),
                  ),
                ),
              ),
            Expanded(
              child: TextField(
                controller: controller,
                enabled: enabled,
                minLines: 1,
                maxLines: 6,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  hintText: 'Speak your heart...',
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color:
                    enabled
                        ? Theme.of(context).colorScheme.primary
                        : (isDark
                            ? MindPalColors.darkSurfaceHigh
                            : MindPalColors.sand100),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: enabled ? onSend : null,
                color:
                    enabled
                        ? Theme.of(context).colorScheme.onPrimary
                        : (isDark
                            ? MindPalColors.darkTextTertiary
                            : MindPalColors.clay300),
                icon: const Icon(Icons.arrow_upward_rounded),
              ),
            ),
          ],
        ),
        if (docked)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 2, 0),
            child: Row(
              children: [
                Icon(
                  Icons.mic_none_rounded,
                  size: 18,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
                const SizedBox(width: 10),
                Icon(
                  Icons.image_outlined,
                  size: 18,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
                const Spacer(),
                Text(
                  'MINDPAL AI',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 0.8,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
