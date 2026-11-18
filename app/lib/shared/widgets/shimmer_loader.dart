import 'package:flutter/material.dart';
import 'package:mindpal_app/theme.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerLoader extends StatelessWidget {
  const ShimmerLoader({
    required this.width,
    required this.height,
    super.key,
    this.radius = 16,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? MindPalColors.darkSurfaceMid : MindPalColors.clay100,
      highlightColor:
          isDark ? MindPalColors.darkSurfaceHigh : MindPalColors.sand50,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: isDark ? MindPalColors.darkSurfaceMid : MindPalColors.clay100,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}
