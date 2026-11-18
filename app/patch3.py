import re

with open('lib/features/recommendations/presentation/recommendations_screen.dart', 'r') as f:
    text = f.read()

old_carousel = """class _RecommendationCarousel extends StatelessWidget {
  const _RecommendationCarousel({
    required this.items,
    required this.currentPage,
    required this.pageController,
    required this.onPageChanged,
    required this.onComplete,
    required this.onAdopt,
    required this.onSkip,
    required this.onNext,
  });

  final List<RecommendationItem> items;
  final int currentPage;
  final PageController pageController;
  final ValueChanged<int> onPageChanged;
  final Future<void> Function(String itemId) onComplete;
  final Future<void> Function(String itemId) onAdopt;
  final Future<void> Function(String itemId) onSkip;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {"""

new_carousel = """class _RecommendationCarousel extends StatefulWidget {
  const _RecommendationCarousel({
    required this.items,
    required this.currentPage,
    required this.pageController,
    required this.onPageChanged,
    required this.onComplete,
    required this.onAdopt,
    required this.onSkip,
    required this.onNext,
  });

  final List<RecommendationItem> items;
  final int currentPage;
  final PageController pageController;
  final ValueChanged<int> onPageChanged;
  final Future<void> Function(String itemId) onComplete;
  final Future<void> Function(String itemId) onAdopt;
  final Future<void> Function(String itemId) onSkip;
  final VoidCallback onNext;

  @override
  State<_RecommendationCarousel> createState() => _RecommendationCarouselState();
}

class _RecommendationCarouselState extends State<_RecommendationCarousel> {
  final Map<String, bool> _expandedState = {};

  bool _isItemExpanded(String id) => _expandedState[id] ?? true;

  void _toggleExpanded(String id) {
    setState(() {
      _expandedState[id] = !_isItemExpanded(id);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {"""

text = text.replace(old_carousel, new_carousel)

def replace_props(match):
    return "widget." + match.group(1)

# Now we need to replace all usages of these properties inside build.
# Instead of doing it naively, let's just make sure we capture the right block.
# Start of block is around 180, end is the end of the class.
parts = text.split("class _RecommendationCarouselState extends State<_RecommendationCarousel> {")
# parts[0] is everything before, parts[1] is everything after.
start_idx = parts[1].find("Widget build(BuildContext context) {")
end_idx = parts[1].find("class _RecommendationPage")
build_body = parts[1][start_idx:end_idx]

for field in ['items', 'currentPage', 'pageController', 'onPageChanged', 'onComplete', 'onAdopt', 'onSkip', 'onNext']:
    build_body = re.sub(r'\\b' + field + r'\\b', f'widget.{field}', build_body)

# Additionally, we change `height: 340,` to dynamic height
build_body = re.sub(r'SizedBox\(\n\s*height: 340,\n\s*child: PageView\.builder\(',
r'''AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.fastOutSlowIn,
          height: _isItemExpanded(widget.items[safeCurrentPage].id) ? 340 : 132,
          child: PageView.builder(''', build_body)

build_body = re.sub(r'_RecommendationPage\(\s*item: widget\.items\[index\],',
r'''_RecommendationPage(
                item: widget.items[index],
                isExpanded: _isItemExpanded(widget.items[index].id),
                onToggleExpanded: () => _toggleExpanded(widget.items[index].id),''', build_body)

text = parts[0] + "class _RecommendationCarouselState extends State<_RecommendationCarousel> {" + parts[1][:start_idx] + build_body + parts[1][end_idx:]

with open('lib/features/recommendations/presentation/recommendations_screen.dart', 'w') as f:
    f.write(text)
