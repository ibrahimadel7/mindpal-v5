import 'package:flutter/material.dart';

import 'package:mindpal_app/features/recommendations/domain/models.dart';
import 'package:mindpal_app/shared/widgets/pill_button.dart';
import 'package:mindpal_app/theme.dart';

class HabitChecklistCard extends StatefulWidget {
  const HabitChecklistCard({
    required this.items,
    required this.onToggle,
    required this.onAdd,
    required this.onDelete,
    super.key,
  });

  final List<HabitChecklistItem> items;
  final Future<void> Function(HabitChecklistItem item, bool checked) onToggle;
  final Future<void> Function(String name) onAdd;
  final Future<void> Function(String id) onDelete;

  @override
  State<HabitChecklistCard> createState() => _HabitChecklistCardState();
}

class _HabitChecklistCardState extends State<HabitChecklistCard> {
  bool _showAdd = false;
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            isDark
                ? MindPalColors.darkSurface
                : MindPalColors.surfaceLow,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CHECKLIST',
            style: TextStyle(
              fontSize: 11,
              color: isDark ? MindPalColors.darkTextSecondary : MindPalColors.ink700,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Today's habits",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: isDark ? MindPalColors.darkTextPrimary : MindPalColors.ink900,
            ),
          ),
          const SizedBox(height: 10),
          if (widget.items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'No habits yet. Add one to start tracking!',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? MindPalColors.darkTextTertiary : MindPalColors.ink700,
                  ),
                ),
              ),
            )
          else
            ...widget.items.map((item) {
              return Row(
                children: [
                  Checkbox(
                    value: item.completed,
                    activeColor: MindPalColors.clay300,
                    onChanged: (value) {
                      widget.onToggle(item, value ?? false);
                    },
                  ),
                  Expanded(
                    child: Text(
                      item.name,
                      style: TextStyle(
                        color: isDark ? MindPalColors.darkTextPrimary : MindPalColors.ink900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => widget.onDelete(item.id),
                    icon: Icon(
                      Icons.delete_outline,
                      color: isDark ? MindPalColors.darkTextSecondary : MindPalColors.ink700,
                    ),
                  ),
                ],
              );
            }),
          const SizedBox(height: 8),
          if (_showAdd)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(hintText: 'Add habit'),
                  ),
                ),
                const SizedBox(width: 8),
                PillButton(
                  label: 'Add',
                  onPressed: () async {
                    final text = _controller.text.trim();
                    if (text.isEmpty) return;
                    await widget.onAdd(text);
                    if (mounted) {
                      _controller.clear();
                      setState(() => _showAdd = false);
                    }
                  },
                ),
                PillButton(
                  label: 'Cancel',
                  variant: PillButtonVariant.ghost,
                  onPressed: () => setState(() => _showAdd = false),
                ),
              ],
            )
          else
            PillButton(
              label: 'Add habit',
              variant: PillButtonVariant.secondary,
              onPressed: () => setState(() => _showAdd = true),
            ),
        ],
      ),
    );
  }
}
