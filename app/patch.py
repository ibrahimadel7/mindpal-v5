import re

with open('lib/features/insights/providers/insights_providers.dart', 'r') as f:
    text = f.read()

# Swap the logic!

old_methods = """  void selectPrevDay() {
    state = state.copyWith(selectedDay: (state.selectedDay - 1).clamp(0, 999));
  }

  void selectNextDay() {
    final max = state.time.isEmpty ? 0 : state.time.length - 1;
    state = state.copyWith(selectedDay: (state.selectedDay + 1).clamp(0, max));
  }"""

new_methods = """  void selectPrevDay() {
    final max = state.time.isEmpty ? 0 : state.time.length - 1;
    state = state.copyWith(selectedDay: (state.selectedDay + 1).clamp(0, max));
  }

  void selectNextDay() {
    state = state.copyWith(selectedDay: (state.selectedDay - 1).clamp(0, 999));
  }"""

text = text.replace(old_methods, new_methods)

with open('lib/features/insights/providers/insights_providers.dart', 'w') as f:
    f.write(text)

