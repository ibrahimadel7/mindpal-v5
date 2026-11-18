import re

with open('lib/features/recommendations/presentation/recommendations_screen.dart', 'r') as f:
    text = f.read()

# Replace _RecommendationPage signature
old_page_sig = """class _RecommendationPage extends StatefulWidget {
  const _RecommendationPage({
    required this.item,
    required this.onComplete,
    required this.onAdopt,
    required this.onSkip,
    required this.onNext,
  });

  final RecommendationItem item;
  final Future<void> Function(String itemId) onComplete;
  final Future<void> Function(String itemId) onAdopt;
  final Future<void> Function(String itemId) onSkip;
  final VoidCallback onNext;

  @override
  State<_RecommendationPage> createState() => _RecommendationPageState();
}

class _RecommendationPageState extends State<_RecommendationPage> {
  bool _isExpanded = true;

  void _handleComplete() async {"""

new_page_sig = """class _RecommendationPage extends StatefulWidget {
  const _RecommendationPage({
    required this.item,
    required this.isExpanded,
    required this.onToggleExpanded,
    required this.onComplete,
    required this.onAdopt,
    required this.onSkip,
    required this.onNext,
  });

  final RecommendationItem item;
  final bool isExpanded;
  final VoidCallback onToggleExpanded;
  final Future<void> Function(String itemId) onComplete;
  final Future<void> Function(String itemId) onAdopt;
  final Future<void> Function(String itemId) onSkip;
  final VoidCallback onNext;

  @override
  State<_RecommendationPage> createState() => _RecommendationPageState();
}

class _RecommendationPageState extends State<_RecommendationPage> {
  void _handleComplete() async {"""

text = text.replace(old_page_sig, new_page_sig)

# Replace `_isExpanded` with `widget.isExpanded` in `_RecommendationPageState`
# Replace `setState(() => _isExpanded = !_isExpanded)` with `widget.onToggleExpanded()`
text = text.replace("onTap: () => setState(() => _isExpanded = !_isExpanded),", "onTap: widget.onToggleExpanded,")
# Actually, wait, replacing `_isExpanded` to `widget.isExpanded` everywhere in that block
# we can just use re.sub or replace if we do it carefully.
# In `_RecommendationPageState`, replace `_isExpanded` with `widget.isExpanded`
text = re.sub(r'(?<!\w)_isExpanded(?!\w)', 'widget.isExpanded', text)

with open('lib/features/recommendations/presentation/recommendations_screen.dart', 'w') as f:
    f.write(text)

