import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Centralised type scale. Uses Inter — a clean, professional, recruiter-safe
/// grotesque that reads well on dense dashboards and long-form chat alike.
abstract class AppTypography {
  /// Pass the target brightness so text colors resolve to the correct
  /// light/dark neutral set. Weights, sizes, and letter-spacing stay
  /// identical across themes — only color changes.
  static TextTheme textTheme(TextTheme base, {required Brightness brightness}) {
    final inter = GoogleFonts.interTextTheme(base);
    final isDark = brightness == Brightness.dark;

    final textPrimary =
        isDark ? AppColorsDark.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColorsDark.textSecondary : AppColorsLight.textSecondary;
    final textTertiary =
        isDark ? AppColorsDark.textTertiary : AppColorsLight.textTertiary;

    return inter.copyWith(
      displaySmall: inter.displaySmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: textPrimary,
      ),
      headlineMedium: inter.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        color: textPrimary,
      ),
      headlineSmall: inter.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: textPrimary,
      ),
      titleLarge: inter.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: textPrimary,
      ),
      titleMedium: inter.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      bodyLarge: inter.bodyLarge?.copyWith(
        height: 1.55,
        color: textPrimary,
      ),
      bodyMedium: inter.bodyMedium?.copyWith(
        height: 1.55,
        color: textSecondary,
      ),
      bodySmall: inter.bodySmall?.copyWith(
        height: 1.5,
        color: textTertiary,
      ),
      labelLarge: inter.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        // no explicit color here originally, left as-is (inherits from theme)
      ),
    );
  }
}
