import sys

filepath = '/home/yami/Desktop/Projects/mindpal-app/app/lib/features/insights/presentation/insights_screen.dart'
with open(filepath, 'r') as f:
    content = f.read()

# Replace _DayButton definition
old_day_button = """class _DayButton extends StatelessWidget {
  const _DayButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: 36,
      height: 36,
      child: OutlinedButton(
        onPressed: onTap,"""

new_day_button = """class _DayButton extends StatelessWidget {
  const _DayButton({required this.icon, this.onTap, this.disabled = false});

  final IconData icon;
  final VoidCallback? onTap;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: 36,
      height: 36,
      child: OutlinedButton(
        onPressed: disabled ? null : onTap,"""

content = content.replace(old_day_button, new_day_button)

with open(filepath, 'w') as f:
    f.write(content)
print("patch_insights done")
