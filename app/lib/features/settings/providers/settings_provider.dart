import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings_provider.g.dart';

class SettingsState {
  const SettingsState({
    required this.dailyReflectionPrompt,
    required this.eveningWindDown,
  });

  final bool dailyReflectionPrompt;
  final bool eveningWindDown;

  SettingsState copyWith({
    bool? dailyReflectionPrompt,
    bool? eveningWindDown,
  }) {
    return SettingsState(
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
      dailyReflectionPrompt: true,
      eveningWindDown: false,
    );
  }

  void toggleDailyPrompt(bool value) {
    state = state.copyWith(dailyReflectionPrompt: value);
  }

  void toggleEveningWindDown(bool value) {
    state = state.copyWith(eveningWindDown: value);
  }
}
