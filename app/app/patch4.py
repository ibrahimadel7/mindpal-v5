import re

with open('lib/features/recommendations/presentation/recommendations_screen.dart', 'r') as f:
    text = f.read()

# Replace StatelessWidget -> StatefulWidget for _RecommendationCarousel
text = re.sub(r'class _RecommendationCarousel extends StatelessWidget \{([^}]*?)\}',
r'''class _RecommendationCarousel extends StatefulWidget {\1}

class _RecommendationCarouselState extends State<_RecommendationCarousel> {
  final Map<String, bool> _expandedState = {};

  bool _isItemExpanded(String id) => _expandedState[id] ?? true;

  void _toggleExpanded(String id) {
    setState(() {
      _expandedState[id] = !_isItemExpanded(id);
    });
  }''', text, count=1)

# Replace build method signature
text = re.sub(r'  @override\n  Widget build\(BuildContext context\) \{',
r'''  @override
  State<_RecommendationCarousel> createState() => _RecommendationCarouselState();

  @override
  Widget build(BuildContext context) {''', text, count=1)
# Wait, this would put `build` inside StatefulWidget, which is wrong.
