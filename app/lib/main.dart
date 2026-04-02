import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mindpal_app/features/settings/providers/settings_provider.dart';
import 'package:mindpal_app/router.dart';
import 'package:mindpal_app/theme.dart';

void main() {
  // Only enable device preview on web in debug mode
  final enableDevicePreview = kIsWeb && !kReleaseMode;
  
  runApp(
    DevicePreview(
      enabled: enableDevicePreview,
      builder: (context) => const ProviderScope(child: MindPalApp()),
    ),
  );
}

class MindPalApp extends ConsumerWidget {
  const MindPalApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final useDevicePreview = kIsWeb && !kReleaseMode;
    
    return MaterialApp.router(
      title: 'MindPal',
      debugShowCheckedModeBanner: false,
      // Only use DevicePreview features on web
      locale: useDevicePreview ? DevicePreview.locale(context) : null,
      builder: useDevicePreview ? DevicePreview.appBuilder : null,
      theme: mindpalTheme,
      darkTheme: mindpalDarkTheme,
      themeMode: settings.darkMode ? ThemeMode.dark : ThemeMode.light,
      routerConfig: router,
    );
  }
}
