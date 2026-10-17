import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color magenta = Color(0xFFFF007A);
  static const Color orange = Color(0xFFFF7A00);

  static const Color canvas = Color(0xFFFAFAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceFill = Color(0xFFF3F4F6);
  static const Color border = Color(0xFFE5E7EB);

  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF4B5563);
  static const Color textMuted = Color(0xFF9CA3AF);

  /// Degradado para botones principales, anillos y badges.
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [magenta, orange],
  );

  /// Resplandor del botón principal.
  static const List<BoxShadow> brandGlow = [
    BoxShadow(
      color: Color(0x47FF007A),
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
  ];
}
