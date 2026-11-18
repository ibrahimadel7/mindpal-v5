import re

with open('lib/features/recommendations/presentation/recommendations_screen.dart', 'r') as f:
    text = f.read()

# Replace the build method of _RecommendationPageState
start_idx = text.find('  @override\n  Widget build(BuildContext context) {\n    return GestureDetector(')
end_idx = text.find('class _HabitsSection extends StatefulWidget', start_idx)

if start_idx != -1 and end_idx != -1:
    old_build = text[start_idx:end_idx]
    
    # We will just rewrite the _RecommendationPageState
    new_build = """  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _isExpanded = !_isExpanded),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(24),
            ),
            border: Border.all(
              color:
                  _isExpanded
                      ? MindPalColors.ink900.withValues(alpha: 0.3)
                      : MindPalColors.clay200.withValues(alpha: 0.8),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with title and expand icon - tappable
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          widget.item.title,
                          style: GoogleFonts.newsreader(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: MindPalColors.ink900,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Duration and kind tags
                        Wrap(
                          spacing: 8,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: MindPalColors.sand100,
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                widget.item.duration.toUpperCase(),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.8,
                                  color: MindPalColors.ink700,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: MindPalColors.clay100,
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                widget.item.kind
                                    .replaceAll('_', ' ')
                                    .toUpperCase(),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.8,
                                  color: MindPalColors.ink700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 48x48 touch target for expand icon
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: MindPalColors.ink700,
                      size: 24,
                    ),
                  ),
                ],
              ),
              // Expanded content with AnimatedSize for smooth transitioning height
              Flexible(
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.fastOutSlowIn,
                  alignment: Alignment.topCenter,
                  child: _isExpanded
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),
                            // Context label
                            Text(
                              'WHY THIS?',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5,
                                color: MindPalColors.ink700.withValues(alpha: 0.6),
                              ),
                            ),
                            const SizedBox(height: 6),
                            // Rationale
                            Flexible(
                              child: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.item.rationale,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        color: MindPalColors.ink700,
                                        height: 1.6,
                                      ),
                                    ),
                                    if (widget.item.followUp != null) ...[
                                      const SizedBox(height: 12),
                                      Text(
                                        widget.item.followUp!,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          fontStyle: FontStyle.italic,
                                          color: MindPalColors.ink700.withValues(alpha: 0.8),
                                          height: 1.5,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Action buttons
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: _handleComplete,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: MindPalColors.ink900,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  widget.item.kind == 'adopt_habit'
                                      ? 'Adopt habit'
                                      : 'Mark complete',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 48,
                                    child: OutlinedButton(
                                      onPressed: () => widget.onSkip(widget.item.id),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: MindPalColors.ink800,
                                        side: BorderSide(color: MindPalColors.clay300),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(100),
                                        ),
                                      ),
                                      child: Text(
                                        'Skip',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: SizedBox(
                                    height: 48,
                                    child: OutlinedButton(
                                      onPressed: widget.onNext,
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: MindPalColors.ink800,
                                        side: BorderSide(color: MindPalColors.clay300),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(100),
                                        ),
                                      ),
                                      child: Text(
                                        'Next',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      : Container(
                          width: double.infinity,
                          padding: const EdgeInsets.only(top: 24, bottom: 8),
                          child: Center(
                            child: Text(
                              'Tap to see details',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: MindPalColors.ink700.withValues(alpha: 0.65),
                              ),
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

"""
    text = text.replace(old_build, new_build)
    with open('lib/features/recommendations/presentation/recommendations_screen.dart', 'w') as f:
        f.write(text)
    print("Replaced successfully")
else:
    print("Could not find start or end index")

