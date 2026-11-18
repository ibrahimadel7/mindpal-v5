import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mindpal_app/theme.dart';
import 'package:google_fonts/google_fonts.dart';

class DrawerNavRow extends StatelessWidget {
  const DrawerNavRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _DrawerIcon(
            icon: Icons.chat_bubble_outline,
            label: 'Chat',
            onTap: () {
              Navigator.of(context).pop();
              context.push('/chat');
            },
          ),
          _DrawerIcon(
            icon: Icons.analytics_outlined,
            label: 'Insights',
            onTap: () {
              Navigator.of(context).pop();
              context.push('/insights');
            },
          ),
          _DrawerIcon(
            icon: Icons.auto_awesome_outlined,
            label: 'Today',
            onTap: () {
              Navigator.of(context).pop();
              context.push('/recommendations');
            },
          ),
          _DrawerIcon(
            icon: Icons.settings_outlined,
            label: 'Settings',
            onTap: () {
              Navigator.of(context).pop();
              context.push('/settings');
            },
          ),
        ],
      ),
    );
  }
}

class _DrawerIcon extends StatelessWidget {
  const _DrawerIcon({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? const Color(0xFF2A2A2A) : MindPalColors.surfaceHigh,
            ),
            child: Icon(
              icon,
              size: 24,
              color: isDark ? const Color(0xFFEBEBEB) : MindPalColors.ink900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFEBEBEB) : MindPalColors.ink900,
            ),
          ),
        ],
      ),
    );
  }
}
