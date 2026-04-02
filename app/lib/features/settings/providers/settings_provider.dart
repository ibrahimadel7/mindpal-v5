import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings_provider.g.dart';

class SettingsState {
  const SettingsState({
    required this.darkMode,
    required this.dailyReflectionPrompt,
    required this.eveningWindDown,
  });

  final bool darkMode;
  final bool dailyReflectionPrompt;
  final bool eveningWindDown;

  SettingsState copyWith({
    bool? darkMode,
    bool? dailyReflectionPrompt,
    bool? eveningWindDown,
  }) {
    return SettingsState(
      darkMode: darkMode ?? this.darkMode,
      dailyReflectionPrompt:
          dailyReflectionPrompt ?? this.dailyReflectionPrompt,
      eveningWindDown: eveningWindDown ?? this.eveningWindDown,
    );
  }
}

@riverpod
class SettingsNotifier extends _$SettingsNotifier {
  @override
  SettingsState build() {
    return const SettingsState(
      darkMode: false,
      dailyReflectionPrompt: true,
      eveningWindDown: false,
    );
  }

  void toggleDarkMode(bool value) {
    state = state.copyWith(darkMode: value);
  }

  void toggleDailyPrompt(bool value) {
    state = state.copyWith(dailyReflectionPrompt: value);
  }

  void toggleEveningWindDown(bool value) {
    state = state.copyWith(eveningWindDown: value);
  }
}
