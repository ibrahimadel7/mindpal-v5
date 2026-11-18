import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MindPalTextStyles {
  static TextStyle frauncesTitle({double size = 28, Color? color}) {
    return GoogleFonts.fraunces(
      fontSize: size,
      fontWeight: FontWeight.w600,
      color: color,
      height: 1.2,
    );
  }

  static TextStyle overline({Color? color}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 11,
      letterSpacing: 1.2,
      fontWeight: FontWeight.w600,
      color: color,
    );
  }
}
