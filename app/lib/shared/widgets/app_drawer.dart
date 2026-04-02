import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:mindpal_app/features/chat/providers/chat_providers.dart';
import 'package:mindpal_app/theme.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key, this.currentRoute});

  final String? currentRoute;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatState = ref.watch(chatProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      backgroundColor: isDark ? MindPalColors.darkBg : const Color(0xFFF3EFE9),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with logo
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? MindPalColors.darkSurface
                      : Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isDark ? MindPalColors.darkSurfaceHigh : MindPalColors.clay200,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          'M',
                          style: GoogleFonts.fraunces(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: isDark ? MindPalColors.darkTextPrimary : MindPalColors.ink900,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MindPal',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: isDark ? MindPalColors.darkTextPrimary : MindPalColors.ink900,
                            ),
                          ),
                          Text(
                            'YOUR EMOTIONAL JOURNAL',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.5,
                              color: isDark
                                  ? MindPalColors.darkTextTertiary
                                  : MindPalColors.ink700.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Navigation grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isDark
                      ? MindPalColors.darkSurface
                      : Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isDark ? null : [
                    BoxShadow(
                      color: MindPalColors.ink900.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _NavItem(
                      icon: _ChatIcon(isActive: currentRoute == '/chat', isDark: isDark),
                      label: 'Chat',
                      isActive: currentRoute == '/chat',
                      isDark: isDark,
                      onTap: () {
                        Navigator.of(context).pop();
                        if (currentRoute != '/chat') context.go('/chat');
                      },
                    ),
                    _NavItem(
                      icon: _InsightsIcon(isActive: currentRoute == '/insights', isDark: isDark),
                      label: 'Insights',
                      isActive: currentRoute == '/insights',
                      isDark: isDark,
                      onTap: () {
                        Navigator.of(context).pop();
                        if (currentRoute != '/insights') context.go('/insights');
                      },
                    ),
                    _NavItem(
                      icon: _RecommendationsIcon(isActive: currentRoute == '/recommendations', isDark: isDark),
                      label: 'Plans',
                      isActive: currentRoute == '/recommendations',
                      isDark: isDark,
                      onTap: () {
                        Navigator.of(context).pop();
                        if (currentRoute != '/recommendations') context.go('/recommendations');
                      },
                    ),
                    _NavItem(
                      icon: Icon(
                        Icons.settings_outlined,
                        size: 20,
                        color: currentRoute == '/settings'
                            ? (isDark ? MindPalColors.darkTextPrimary : MindPalColors.ink900)
                            : (isDark ? MindPalColors.darkTextSecondary : MindPalColors.ink700),
                      ),
                      label: 'Settings',
                      isActive: currentRoute == '/settings',
                      isDark: isDark,
                      onTap: () {
                        Navigator.of(context).pop();
                        if (currentRoute != '/settings') context.go('/settings');
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Section header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'RECENT ENTRIES',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                  color: isDark
                      ? MindPalColors.darkTextTertiary
                      : MindPalColors.ink700.withValues(alpha: 0.65),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // New conversation button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Material(
                color: isDark ? MindPalColors.darkSurfaceHigh : MindPalColors.clay200,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: () {
                    ref.read(chatProvider.notifier).startNewConversation();
                    Navigator.of(context).pop();
                    if (currentRoute != '/chat') context.go('/chat');
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Icon(
                          Icons.add_rounded,
                          size: 20,
                          color: isDark ? MindPalColors.darkTextPrimary : MindPalColors.ink900,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'New Reflection',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? MindPalColors.darkTextPrimary : MindPalColors.ink900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Conversation list
            Expanded(
              child: ref.watch(conversationsProvider).when(
                data: (conversations) {
                  if (conversations.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? MindPalColors.darkSurface
                              : Colors.white.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? MindPalColors.darkBorder : MindPalColors.clay200,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Text(
                          'No reflections yet.\nStart your first reflection above.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            height: 1.5,
                            color: isDark ? MindPalColors.darkTextSecondary : MindPalColors.ink700,
                          ),
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: conversations.length,
                    separatorBuilder: (_, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final conv = conversations[index];
                      final isSelected = conv.id == chatState.currentConversationId;
                      return _ConversationCard(
                        title: conv.title != null && conv.title!.isNotEmpty
                            ? conv.title!
                            : 'Reflection ${conv.id.substring(0, min(6, conv.id.length))}',
                        date: conv.createdAt,
                        isSelected: isSelected,
                        isDark: isDark,
                        onTap: () {
                          Navigator.of(context).pop();
                          ref.read(chatProvider.notifier).switchConversation(conv.id);
                          if (currentRoute != '/chat') context.go('/chat');
                        },
                        onDelete: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              title: const Text('Delete Reflection'),
                              content: const Text(
                                'Are you sure? This cannot be undone.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(dialogContext).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(dialogContext).pop(true),
                                  style: TextButton.styleFrom(
                                    foregroundColor: MindPalColors.emotionAnger,
                                  ),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                          if (confirmed == true) {
                            await ref.read(chatProvider.notifier).deleteConversation(conv.id);
                          }
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (err, stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.cloud_off_outlined,
                          size: 40,
                          color: isDark ? MindPalColors.darkTextSecondary : MindPalColors.clay400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Unable to load history',
                          style: TextStyle(
                            color: isDark ? MindPalColors.darkTextSecondary : MindPalColors.ink700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Footer
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Text(
                'Your emotional journal',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: isDark
                      ? MindPalColors.darkTextTertiary
                      : MindPalColors.ink700.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.isDark,
    required this.onTap,
  });

  final Widget icon;
  final String label;
  final bool isActive;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive
                ? (isDark ? MindPalColors.darkSurfaceHigh : MindPalColors.clay200)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              icon,
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                  color: isActive
                      ? (isDark ? MindPalColors.darkTextPrimary : MindPalColors.ink900)
                      : (isDark ? MindPalColors.darkTextSecondary : MindPalColors.ink700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConversationCard extends StatelessWidget {
  const _ConversationCard({
    required this.title,
    required this.date,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
    required this.onDelete,
  });

  final String title;
  final DateTime date;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? (isDark ? MindPalColors.darkSurfaceMid : MindPalColors.clay100)
          : (isDark ? MindPalColors.darkSurface : Colors.white.withValues(alpha: 0.72)),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? (isDark ? MindPalColors.darkBorder : MindPalColors.clay300)
                  : Colors.transparent,
            ),
            boxShadow: isSelected && !isDark
                ? [
                    BoxShadow(
                      color: MindPalColors.ink900.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              // AI avatar
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isDark ? MindPalColors.darkSurfaceHigh : MindPalColors.sand100,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: _MindPalMiniIcon(isDark: isDark, size: 16),
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? MindPalColors.darkTextPrimary : MindPalColors.ink900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDate(date),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: isDark
                            ? MindPalColors.darkTextTertiary
                            : MindPalColors.ink700.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              // Delete button
              Material(
                color: isDark
                    ? MindPalColors.darkSurfaceHigh
                    : Colors.white,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: onDelete,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark
                            ? MindPalColors.darkBorder
                            : MindPalColors.clay200.withValues(alpha: 0.7),
                      ),
                    ),
                    child: Text(
                      'Delete',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? MindPalColors.darkTextSecondary : MindPalColors.ink700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return DateFormat('h:mm a').format(date);
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return DateFormat('EEEE').format(date);
    } else {
      return DateFormat('MMM d').format(date);
    }
  }
}

// Custom icons matching frontend SVGs
class _ChatIcon extends StatelessWidget {
  const _ChatIcon({required this.isActive, required this.isDark});
  final bool isActive;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final color = isActive
        ? (isDark ? MindPalColors.darkTextPrimary : MindPalColors.ink900)
        : (isDark ? MindPalColors.darkTextSecondary : MindPalColors.ink700);
    return CustomPaint(
      size: const Size(20, 20),
      painter: _ChatIconPainter(color: color),
    );
  }
}

class _ChatIconPainter extends CustomPainter {
  _ChatIconPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    // Chat bubble path: M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z
    final scale = size.width / 24;
    path.moveTo(21 * scale, 15 * scale);
    path.arcToPoint(
      Offset(19 * scale, 17 * scale),
      radius: Radius.circular(2 * scale),
    );
    path.lineTo(7 * scale, 17 * scale);
    path.lineTo(3 * scale, 21 * scale);
    path.lineTo(3 * scale, 5 * scale);
    path.arcToPoint(
      Offset(5 * scale, 3 * scale),
      radius: Radius.circular(2 * scale),
    );
    path.lineTo(19 * scale, 3 * scale);
    path.arcToPoint(
      Offset(21 * scale, 5 * scale),
      radius: Radius.circular(2 * scale),
    );
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ChatIconPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _InsightsIcon extends StatelessWidget {
  const _InsightsIcon({required this.isActive, required this.isDark});
  final bool isActive;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final color = isActive
        ? (isDark ? MindPalColors.darkTextPrimary : MindPalColors.ink900)
        : (isDark ? MindPalColors.darkTextSecondary : MindPalColors.ink700);
    return CustomPaint(
      size: const Size(20, 20),
      painter: _InsightsIconPainter(color: color),
    );
  }
}

class _InsightsIconPainter extends CustomPainter {
  _InsightsIconPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round;

    final scale = size.width / 24;
    // Three vertical bars
    canvas.drawLine(
      Offset(18 * scale, 20 * scale),
      Offset(18 * scale, 10 * scale),
      paint,
    );
    canvas.drawLine(
      Offset(12 * scale, 20 * scale),
      Offset(12 * scale, 4 * scale),
      paint,
    );
    canvas.drawLine(
      Offset(6 * scale, 20 * scale),
      Offset(6 * scale, 14 * scale),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _InsightsIconPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _RecommendationsIcon extends StatelessWidget {
  const _RecommendationsIcon({required this.isActive, required this.isDark});
  final bool isActive;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final color = isActive
        ? (isDark ? MindPalColors.darkTextPrimary : MindPalColors.ink900)
        : (isDark ? MindPalColors.darkTextSecondary : MindPalColors.ink700);
    return CustomPaint(
      size: const Size(20, 20),
      painter: _RecommendationsIconPainter(color: color),
    );
  }
}

class _RecommendationsIconPainter extends CustomPainter {
  _RecommendationsIconPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final scale = size.width / 24;

    // Lightbulb base line
    canvas.drawLine(
      Offset(9 * scale, 21 * scale),
      Offset(15 * scale, 21 * scale),
      paint,
    );

    // Bulb shape
    final bulbPath = Path();
    bulbPath.moveTo(12 * scale, 3 * scale);
    bulbPath.arcToPoint(
      Offset(18 * scale, 9 * scale),
      radius: Radius.circular(6 * scale),
      clockwise: true,
    );
    bulbPath.cubicTo(
      18 * scale, 11.2 * scale,
      16.8 * scale, 13.2 * scale,
      15 * scale, 14.4 * scale,
    );
    bulbPath.lineTo(15 * scale, 17 * scale);
    bulbPath.lineTo(9 * scale, 17 * scale);
    bulbPath.lineTo(9 * scale, 14.4 * scale);
    bulbPath.cubicTo(
      7.2 * scale, 13.2 * scale,
      6 * scale, 11.2 * scale,
      6 * scale, 9 * scale,
    );
    bulbPath.arcToPoint(
      Offset(12 * scale, 3 * scale),
      radius: Radius.circular(6 * scale),
      clockwise: true,
    );

    canvas.drawPath(bulbPath, paint);
  }

  @override
  bool shouldRepaint(covariant _RecommendationsIconPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _MindPalMiniIcon extends StatelessWidget {
  const _MindPalMiniIcon({required this.isDark, this.size = 14});
  final bool isDark;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Text(
      'M',
      style: GoogleFonts.fraunces(
        fontSize: size,
        fontWeight: FontWeight.w600,
        color: isDark ? MindPalColors.darkTextPrimary : MindPalColors.ink900,
      ),
    );
  }
}
