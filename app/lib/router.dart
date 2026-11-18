import 'package:go_router/go_router.dart';

import 'package:mindpal_app/features/chat/presentation/chat_screen.dart';
import 'package:mindpal_app/features/insights/presentation/insights_screen.dart';
import 'package:mindpal_app/features/recommendations/presentation/recommendations_screen.dart';
import 'package:mindpal_app/features/settings/presentation/settings_screen.dart';

final router = GoRouter(
  initialLocation: '/chat',
  routes: [
    GoRoute(path: '/chat', builder: (c, s) => const ChatScreen()),
    GoRoute(path: '/insights', builder: (c, s) => const InsightsScreen()),
    GoRoute(
      path: '/recommendations',
      builder: (c, s) => const RecommendationsScreen(),
    ),
    GoRoute(path: '/settings', builder: (c, s) => const SettingsScreen()),
  ],
);
