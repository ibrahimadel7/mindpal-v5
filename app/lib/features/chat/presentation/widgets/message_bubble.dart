import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:mindpal_app/features/chat/domain/models.dart';
import 'package:mindpal_app/theme.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    required this.message,
    this.isStreaming = false,
    this.isThinking = false,
    super.key,
  });

  final Message message;
  final bool isStreaming;
  final bool isThinking;

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
          // Thinking section (collapsible)
          if (!isUser && (message.thinking != null || isThinking))
            _ThinkingSection(
              thinking: message.thinking ?? '',
              isThinking: isThinking,
              isStreaming: isStreaming,
            ),
          // Main message content
          if (message.text.isNotEmpty || (!isThinking && isStreaming))
            Text(
              message.text.isEmpty && isStreaming
                  ? 'Preparing response...'
                  : message.text,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontSize: 15,
                height: 1.4,
                fontStyle: message.text.isEmpty && isStreaming
                    ? FontStyle.italic
                    : FontStyle.normal,
                color: message.text.isEmpty && isStreaming
                    ? (isDark ? MindPalColors.darkTextSecondary : MindPalColors.ink700)
                    : null,
              ),
            )
          else if (isThinking && message.text.isEmpty)
            const SizedBox.shrink(),
          // Streaming cursor for response
          if (isStreaming && !isThinking && message.text.isNotEmpty)
            Text(
              '|',
              style: TextStyle(
                color: isDark ? MindPalColors.darkTextPrimary : MindPalColors.ink900,
                fontWeight: FontWeight.bold,
              ),
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
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                'assets/logo.png',
                width: 32,
                height: 32,
                fit: BoxFit.cover,
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

class _ThinkingSection extends StatefulWidget {
  const _ThinkingSection({
    required this.thinking,
    required this.isThinking,
    required this.isStreaming,
  });

  final String thinking;
  final bool isThinking;
  final bool isStreaming;

  @override
  State<_ThinkingSection> createState() => _ThinkingSectionState();
}

class _ThinkingSectionState extends State<_ThinkingSection> {
  bool _isExpanded = true;

  @override
  void didUpdateWidget(_ThinkingSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Auto-collapse when thinking ends and response starts
    if (oldWidget.isThinking && !widget.isThinking && widget.thinking.isNotEmpty) {
      setState(() => _isExpanded = false);
    }
    // Auto-expand when thinking starts
    if (!oldWidget.isThinking && widget.isThinking) {
      setState(() => _isExpanded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (widget.thinking.isEmpty && !widget.isThinking) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Thinking header (tap to expand/collapse)
        GestureDetector(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 16,
                  color: isDark ? MindPalColors.darkTextSecondary : MindPalColors.ink700,
                ),
                const SizedBox(width: 4),
                if (widget.isThinking)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: MindPalColors.emotionJoy,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Thinking...',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark ? MindPalColors.darkTextSecondary : MindPalColors.ink700,
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    'View reasoning',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? MindPalColors.darkTextSecondary : MindPalColors.ink700,
                    ),
                  ),
              ],
            ),
          ),
        ),
        // Thinking content
        if (_isExpanded)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? MindPalColors.darkSurfaceHigh.withValues(alpha: 0.5)
                  : MindPalColors.sand50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark
                    ? MindPalColors.darkBorder.withValues(alpha: 0.3)
                    : MindPalColors.clay200.withValues(alpha: 0.5),
              ),
            ),
            child: Text(
              widget.thinking.isEmpty
                  ? 'Processing your message...'
                  : widget.thinking + (widget.isThinking ? '|' : ''),
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: isDark ? MindPalColors.darkTextSecondary : MindPalColors.ink700,
                fontStyle: widget.thinking.isEmpty ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
        // Divider
        if (widget.thinking.isNotEmpty || widget.isThinking)
          Container(
            height: 1,
            margin: const EdgeInsets.only(bottom: 10),
            color: isDark
                ? MindPalColors.darkBorder.withValues(alpha: 0.3)
                : MindPalColors.clay200.withValues(alpha: 0.5),
          ),
      ],
    );
  }
}
