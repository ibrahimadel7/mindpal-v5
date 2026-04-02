import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:mindpal_app/shared/providers/local_cache_provider.dart';
import 'package:mindpal_app/shared/widgets/app_drawer.dart';
import 'package:mindpal_app/shared/widgets/mindpal_card.dart';
import 'package:mindpal_app/shared/widgets/pill_button.dart';
import 'package:mindpal_app/theme.dart';
import 'package:mindpal_app/features/settings/providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _clearCache(BuildContext context, WidgetRef ref) async {
    await ref.read(localCacheServiceProvider).clearAll();
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Local cache cleared.')));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      drawer: const AppDrawer(currentRoute: '/settings'),
      drawerEnableOpenDragGesture: true,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.newsreader(
            fontSize: 32,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'SETTINGS',
              style: textTheme.labelSmall?.copyWith(
                color: isDark ? MindPalColors.darkTextTertiary : MindPalColors.clay400,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tune your quiet space',
              style: GoogleFonts.newsreader(fontSize: 40, height: 1.05),
            ),
            const SizedBox(height: 18),
            MindPalCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Profile', style: textTheme.titleLarge),
                  const SizedBox(height: 10),
                  const _SettingsRow(
                    icon: Icons.person_outline,
                    label: 'Name',
                    trailing: 'MindPal User',
                  ),
                  const Divider(height: 20),
                  const _SettingsRow(
                    icon: Icons.favorite_border,
                    label: 'Wellness goal',
                    trailing: 'Emotional balance',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            MindPalCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Appearance', style: textTheme.titleLarge),
                  const SizedBox(height: 10),
                  _SwitchRow(
                    icon: Icons.dark_mode_outlined,
                    label: 'Dark mode',
                    value: settings.darkMode,
                    onChanged: (val) => settingsNotifier.toggleDarkMode(val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            MindPalCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Reminders', style: textTheme.titleLarge),
                  const SizedBox(height: 10),
                  _SwitchRow(
                    icon: Icons.notifications_none,
                    label: 'Daily reflection prompt',
                    value: settings.dailyReflectionPrompt,
                    onChanged: (val) => settingsNotifier.toggleDailyPrompt(val),
                  ),
                  const Divider(height: 20),
                  _SwitchRow(
                    icon: Icons.nights_stay_outlined,
                    label: 'Evening wind-down reminder',
                    value: settings.eveningWindDown,
                    onChanged:
                        (val) => settingsNotifier.toggleEveningWindDown(val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            MindPalCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Storage & privacy', style: textTheme.titleLarge),
                  const SizedBox(height: 8),
                  const Text(
                    'Clear local cache if you want to reset offline context and local snapshots.',
                  ),
                  const SizedBox(height: 14),
                  PillButton(
                    label: 'Clear cache',
                    variant: PillButtonVariant.ghost,
                    onPressed: () => _clearCache(context, ref),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            MindPalCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('About MindPal', style: textTheme.titleLarge),
                  const SizedBox(height: 8),
                  const Text('Version 1.0.0'),
                  const SizedBox(height: 8),
                  const Text(
                    'MindPal is a reflective AI companion for emotional wellness and gentle daily rituals.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.trailing,
  });

  final IconData icon;
  final String label;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).textTheme.bodyMedium?.color),
        const SizedBox(width: 10),
        Expanded(child: Text(label)),
        Text(
          trailing,
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
      ],
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).textTheme.bodyMedium?.color),
        const SizedBox(width: 10),
        Expanded(child: Text(label)),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeThumbColor: Theme.of(context).colorScheme.primary,
        ),
      ],
    );
  }
}
