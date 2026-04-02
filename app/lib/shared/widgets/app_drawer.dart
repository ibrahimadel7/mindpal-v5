import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Navigation icons row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _DrawerIcon(
                    icon: Icons.chat_bubble_outline,
                    label: 'Chat',
                    isActive: currentRoute == '/chat',
                    onTap: () {
                      Navigator.of(context).pop();
                      if (currentRoute != '/chat') {
                        context.go('/chat');
                      }
                    },
                  ),
                  _DrawerIcon(
                    icon: Icons.analytics_outlined,
                    label: 'Insights',
                    isActive: currentRoute == '/insights',
                    onTap: () {
                      Navigator.of(context).pop();
                      if (currentRoute != '/insights') {
                        context.go('/insights');
                      }
                    },
                  ),
                  _DrawerIcon(
                    icon: Icons.auto_awesome_outlined,
                    label: 'Today',
                    isActive: currentRoute == '/recommendations',
                    onTap: () {
                      Navigator.of(context).pop();
                      if (currentRoute != '/recommendations') {
                        context.go('/recommendations');
                      }
                    },
                  ),
                  _DrawerIcon(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    isActive: currentRoute == '/settings',
                    onTap: () {
                      Navigator.of(context).pop();
                      if (currentRoute != '/settings') {
                        context.go('/settings');
                      }
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 24,
              ),
              child: Text(
                'Chat History',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Expanded(
              child: ref.watch(conversationsProvider).when(
                data: (conversations) {
                  if (conversations.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 48,
                              color: isDark
                                  ? MindPalColors.darkTextSecondary
                                  : MindPalColors.clay400,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No past conversations yet.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isDark
                                    ? MindPalColors.darkTextSecondary
                                    : MindPalColors.clay400,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Start chatting to create your first reflection.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? MindPalColors.darkTextSecondary
                                    : MindPalColors.clay400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: conversations.length,
                    itemBuilder: (context, index) {
                      final conv = conversations[index];
                      final isSelected = conv.id == chatState.currentConversationId;
                      return Dismissible(
                        key: Key(conv.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: MindPalColors.emotionAnger,
                          child: const Icon(
                            Icons.delete_outline,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        confirmDismiss: (direction) async {
                          return await showDialog<bool>(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Delete Conversation'),
                                content: const Text(
                                  'Are you sure you want to delete this conversation? This action cannot be undone.',
                                ),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(true),
                                    style: TextButton.styleFrom(
                                      foregroundColor: MindPalColors.emotionAnger,
                                    ),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        onDismissed: (direction) {
                          ref.read(chatProvider.notifier).deleteConversation(conv.id);
                        },
                        child: ListTile(
                          selected: isSelected,
                          selectedTileColor: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.1),
                          selectedColor: Theme.of(context).colorScheme.primary,
                          leading: Icon(
                            Icons.chat_bubble_outline,
                            size: 20,
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : isDark
                                    ? MindPalColors.darkTextSecondary
                                    : MindPalColors.clay400,
                          ),
                          title: Text(
                            conv.title != null && conv.title!.isNotEmpty
                                ? conv.title!
                                : 'Chat ${conv.id.substring(0, min(8, conv.id.length))}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            _formatDate(conv.createdAt),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20),
                            color: isDark
                                ? MindPalColors.darkTextSecondary
                                : MindPalColors.clay400,
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text('Delete Conversation'),
                                    content: const Text(
                                      'Are you sure you want to delete this conversation? This action cannot be undone.',
                                    ),
                                    actions: <Widget>[
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(true),
                                        style: TextButton.styleFrom(
                                          foregroundColor: MindPalColors.emotionAnger,
                                        ),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  );
                                },
                              );
                              if (confirmed == true) {
                                ref.read(chatProvider.notifier).deleteConversation(conv.id);
                              }
                            },
                          ),
                          onTap: () {
                            Navigator.of(context).pop();
                            ref.read(chatProvider.notifier).switchConversation(conv.id);
                            if (currentRoute != '/chat') {
                              context.go('/chat');
                            }
                          },
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: MindPalColors.emotionAnger,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Error loading history',
                          style: TextStyle(
                            color: MindPalColors.emotionAnger,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton(
                onPressed: () {
                  ref.read(chatProvider.notifier).startNewConversation();
                  Navigator.of(context).pop();
                  if (currentRoute != '/chat') {
                    context.go('/chat');
                  }
                },
                child: const Center(child: Text('New Conversation')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }
}

class _DrawerIcon extends StatelessWidget {
  const _DrawerIcon({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeColor = theme.colorScheme.primary;

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
              color: isActive
                  ? activeColor.withValues(alpha: 0.15)
                  : isDark
                      ? const Color(0xFF2A2A2A)
                      : MindPalColors.surfaceHigh,
            ),
            child: Icon(
              icon,
              size: 24,
              color: isActive
                  ? activeColor
                  : isDark
                      ? const Color(0xFFEBEBEB)
                      : MindPalColors.ink900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
              color: isActive
                  ? activeColor
                  : isDark
                      ? const Color(0xFFEBEBEB)
                      : MindPalColors.ink900,
            ),
          ),
        ],
      ),
    );
  }
}
