import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';

class AutoScrollText extends StatefulWidget {
  final String? text;
  final TextStyle? style;
  final Widget? child;
  final Axis scrollDirection;

  const AutoScrollText({
    super.key,
    this.text,
    this.style,
    this.child,
    this.scrollDirection = Axis.horizontal,
  });

  @override
  State<AutoScrollText> createState() => _AutoScrollTextState();
}

class _AutoScrollTextState extends State<AutoScrollText> {
  late ScrollController _scrollController;
  bool _isScrolling = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    if (widget.scrollDirection == Axis.vertical) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkAndStartScrolling());
    }
  }

  @override
  void didUpdateWidget(covariant AutoScrollText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.scrollDirection == Axis.vertical) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkAndStartScrolling());
    }
  }

  @override
  void dispose() {
    _isScrolling = false;
    if (widget.scrollDirection == Axis.vertical) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  void _checkAndStartScrolling() async {
    if (!mounted) return;
    if (_scrollController.hasClients && _scrollController.position.maxScrollExtent > 0) {
      if (!_isScrolling) {
        _isScrolling = true;
        _scroll();
      }
    } else {
      _isScrolling = false;
    }
  }

  void _scroll() async {
    while (_isScrolling && mounted) {
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted || !_isScrolling || !_scrollController.hasClients) break;
      
      final maxScroll = _scrollController.position.maxScrollExtent;
      if (maxScroll <= 0) break;
      
      final duration = Duration(milliseconds: (maxScroll * 35).toInt().clamp(2000, 15000));
      
      if (_scrollController.offset <= 0.0) {
        await _scrollController.animateTo(maxScroll, duration: duration, curve: Curves.easeInOut);
      } else {
        await _scrollController.animateTo(0.0, duration: duration, curve: Curves.easeInOut);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.scrollDirection == Axis.vertical) {
      return ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.vertical,
          physics: const NeverScrollableScrollPhysics(),
          child: widget.child ?? Text(
            widget.text ?? '',
            style: widget.style,
          ),
        ),
      );
    } else {
      return LayoutBuilder(
        builder: (context, constraints) {
          final TextPainter textPainter = TextPainter(
            text: TextSpan(text: widget.text, style: widget.style),
            maxLines: 1,
            textDirection: TextDirection.ltr,
          )..layout(minWidth: 0, maxWidth: double.infinity);

          if (textPainter.size.width > constraints.maxWidth) {
            return SizedBox(
              width: constraints.maxWidth,
              height: textPainter.size.height,
              child: Marquee(
                text: widget.text ?? '',
                style: widget.style,
                scrollAxis: Axis.horizontal,
                crossAxisAlignment: CrossAxisAlignment.start,
                blankSpace: 20.0,
                velocity: 30.0,
                pauseAfterRound: const Duration(seconds: 2),
                showFadingOnlyWhenScrolling: true,
                fadingEdgeStartFraction: 0.1,
                fadingEdgeEndFraction: 0.1,
              ),
            );
          } else {
            return Text(
              widget.text ?? '',
              style: widget.style,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            );
          }
        },
      );
    }
  }
}
