import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mindpal_app/features/chat/domain/models.dart';
import 'package:mindpal_app/features/chat/providers/chat_providers.dart';
import 'package:mindpal_app/features/chat/presentation/widgets/chat_input.dart';
import 'package:mindpal_app/features/chat/presentation/widgets/message_bubble.dart';
import 'package:mindpal_app/features/chat/presentation/widgets/suggestion_chips.dart';
import 'package:mindpal_app/shared/widgets/app_drawer.dart';
import 'package:mindpal_app/shared/widgets/state_panels.dart';
import 'package:mindpal_app/theme.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _controller;
  late final AnimationController _streamingController;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _streamingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatProvider.notifier).ensureConversation();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _streamingController.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    _controller.clear();
    await ref.read(chatProvider.notifier).send(text);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatProvider);
    final messages = state.currentMessages;
    final streamingMessage = Message(
      id: 'streaming',
      conversationId: state.currentConversationId ?? '',
      role: 'assistant',
      text:
          _streamingController.value > 0.5
              ? 'MindPal is reflecting...|'
              : 'MindPal is reflecting...',
      createdAt: DateTime.now(),
    );
    final display = <Message>[
      if (state.showStreaming) streamingMessage,
      ...messages.reversed,
    ];

    return Scaffold(
      drawerEnableOpenDragGesture: true,
      drawer: const AppDrawer(currentRoute: '/chat'),
      appBar: AppBar(
        title: const Text('MindPal'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              'YOUR EMOTIONAL JOURNAL',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                letterSpacing: 1.4,
                fontSize: 11,
              ),
            ),
          ),
        ),
      ),
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Column(
          children: [
            Expanded(
              child: switch ((
                state.isInitializing,
                messages.isEmpty,
                state.error != null,
              )) {
                (true, true, _) => const _InitializingState(),
                (false, true, true) => MindPalErrorPanel(
                  message: state.error!,
                  title: 'MindPal is unavailable right now',
                  onRetry: ref.read(chatProvider.notifier).ensureConversation,
                ),
                (_, true, false) => _EmptyState(
                  onSuggestion: (text) {
                    _controller.text = text;
                    _handleSend();
                  },
                ),
                _ => ListView.separated(
                  reverse: true,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                  itemBuilder: (context, index) {
                    final message = display[index];
                    return MessageBubble(message: message);
                  },
                  separatorBuilder:
                      (context, index) => const SizedBox(height: 10),
                  itemCount: display.length,
                ),
              },
            ),
            if (state.error != null && messages.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(
                  state.error!,
                  style: const TextStyle(color: MindPalColors.emotionAnger),
                ),
              ),
            Container(
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                MediaQuery.of(context).padding.bottom + 12,
              ),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surface.withValues(alpha: 0.92),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: ChatInput(
                controller: _controller,
                docked: true,
                enabled: !state.isSending,
                onSend: _handleSend,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onSuggestion});

  final ValueChanged<String> onSuggestion;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Good morning. Take a moment to check in with yourself. How are you feeling as you start your day?',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontSize: 36, // Reduced from 46 for better fit
              ),
            ),
            const SizedBox(height: 32),
            SuggestionChips(onSelect: onSuggestion),
          ],
        ),
      ),
    );
  }
}

class _InitializingState extends StatelessWidget {
  const _InitializingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(strokeWidth: 2),
          SizedBox(height: 12),
          Text('Preparing your reflection space...'),
        ],
      ),
    );
  }
}
