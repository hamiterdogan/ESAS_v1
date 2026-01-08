import 'package:flutter/material.dart';

class AppColors {
  // Gradient colors
  static const Color gradientStart = Color(0xFF014B92);
  static const Color gradientEnd = Color(0xFF01325B);

  // Label & Title Colors
  static const Color inputLabelColor = Color(0xFF01396B);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [gradientStart, gradientEnd],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient primaryGradientLTR = LinearGradient(
    colors: [gradientStart, gradientEnd],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Bottom Navigation Bar için gradient (yukarıdan aşağıya - açık üstte, koyu altta)
  static const LinearGradient bottomNavGradient = LinearGradient(
    colors: [gradientStart, gradientEnd],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
