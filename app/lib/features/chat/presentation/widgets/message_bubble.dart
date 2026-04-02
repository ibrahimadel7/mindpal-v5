import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:mindpal_app/features/chat/domain/models.dart';
import 'package:mindpal_app/theme.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({required this.message, super.key});

  final Message message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final screenWidth = MediaQuery.of(context).size.width;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bubble = Container(
      constraints: BoxConstraints(
        maxWidth: screenWidth * 0.75, // Responsive width
      ),
      decoration: BoxDecoration(
        color:
            isDark
                ? (isUser
                    ? MindPalColors.darkClay
                    : MindPalColors.darkSurface)
                : (isUser ? MindPalColors.clay200 : Colors.white),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(20),
          topRight: const Radius.circular(20),
          bottomLeft: Radius.circular(isUser ? 20 : 6),
          bottomRight: Radius.circular(isUser ? 6 : 20),
        ),
        border:
            isUser
                ? (isDark ? Border.all(color: MindPalColors.darkBorderAccent.withValues(alpha: 0.4)) : null)
                : Border.all(
                  color:
                      isDark ? MindPalColors.darkBorder : MindPalColors.clay200,
                ),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message.text,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontSize: 15, height: 1.4),
          ),
          const SizedBox(height: 6),
          Text(
            DateFormat('h:mm a').format(message.createdAt),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontSize: 10),
          ),
        ],
      ),
    );

    if (isUser) {
      return Padding(
        padding: const EdgeInsets.only(
          left: 40,
        ), // Space for MP avatar on other side
        child: Align(alignment: Alignment.centerRight, child: bubble),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(right: 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(top: 4),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color:
                    isDark
                        ? MindPalColors.darkSurfaceHigh
                        : MindPalColors.sand100,
                shape: BoxShape.circle,
                border:
                    isDark ? Border.all(color: MindPalColors.darkBorder) : null,
              ),
              child: Text(
                'MP',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color:
                      isDark
                          ? MindPalColors.darkTextPrimary
                          : MindPalColors.ink900,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(child: bubble),
          ],
        ),
      ),
    );
  }
}
