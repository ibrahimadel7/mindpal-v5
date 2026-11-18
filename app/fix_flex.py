import re

with open('lib/features/recommendations/presentation/recommendations_screen.dart', 'r') as f:
    text = f.read()

# Replace the AnimatedSize block
old_block = r"              // Expanded content with AnimatedSize for smooth transitioning height\n              Flexible\(\n                child: AnimatedSize\(\n                  duration: const Duration\(milliseconds: 250\),\n                  curve: Curves\.fastOutSlowIn,\n                  alignment: Alignment\.topCenter,\n                  child: widget\.isExpanded\n                      \? Column\("

new_block = """              // Expanded content
              if (widget.isExpanded)
                Flexible(
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: SizedBox(
                      height: 204, // 340 - 136
                      child: Column("""

text = re.sub(old_block, new_block, text)

# Now, we need to strip the false branch of the ternary operator!
# Find the end of the expanded Column:
# It's at `                      : Container(` up to `                ),`
# Let's replace the whole false branch with nothing, since we used `if (widget.isExpanded)`
false_branch = r"                      : Container\(\n                          width: double\.infinity,\n                          padding: const EdgeInsets\.only\(top: 24, bottom: 8\),\n                          child: Center\(\n                            child: Text\(\n                              'Tap to see details',\n                              style: GoogleFonts\.plusJakartaSans\(\n                                fontSize: 12,\n                                color: MindPalColors\.ink700\.withValues\(\n                                  alpha: 0\.65,\n                                \),\n                              \),\n                            \),\n                          \),\n                        \),\n                \),"

if not re.search(false_branch, text):
    # Try looking for SizedBox.shrink()
    false_branch = r"                      : const SizedBox\.shrink\(\),\n                \),"

new_false = """                        ),
                    ),
                  ),
                ),"""

text = re.sub(false_branch, new_false, text)

with open('lib/features/recommendations/presentation/recommendations_screen.dart', 'w') as f:
    f.write(text)

