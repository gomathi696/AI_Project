import 'package:flutter/material.dart';

/// Central theme for the app.
///
/// Design choices are driven by the target user (visually impaired /
/// low-vision people), not aesthetics alone:
/// - High contrast (near-black background, near-white text/icons)
/// - Large default text sizes
/// - Large minimum touch targets (56dp+) for anyone with partial vision
/// - Avoids relying on color alone to convey state (icons + text always paired)
class AppTheme {
  AppTheme._();

  static const Color background = Color(0xFF0B0B0C);
  static const Color surface = Color(0xFF1B1B1D);
  static const Color primary = Color(0xFF4DA6FF);
  static const Color danger = Color(0xFFFF5C5C);
  static const Color success = Color(0xFF4CD97B);
  static const Color textPrimary = Color(0xFFF5F5F5);
  static const Color textSecondary = Color(0xFFB5B5B8);

  static ThemeData get theme {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: background,
      colorScheme: base.colorScheme.copyWith(
        primary: primary,
        error: danger,
        surface: surface,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ).copyWith(
        headlineMedium: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        titleLarge: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: const TextStyle(
          fontSize: 18,
          color: textSecondary,
          height: 1.4,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(72),
          textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      iconTheme: const IconThemeData(size: 32, color: textPrimary),
    );
  }
}
