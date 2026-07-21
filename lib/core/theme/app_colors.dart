import 'package:flutter/material.dart';

/// Aestimo palette.
///
/// The spec mandates exactly two primary colors. Every other shade in the app
/// is *derived* from these two (tints/shades/opacity), so the product stays
/// visually coherent and on-brand — across both light and dark modes.
///
///   Primary   #2563EB  Professional Blue
///   Secondary #F8FAFC  Soft White
abstract class AppColors {
  // --- The two source-of-truth colors (brand-fixed, same in both modes) ---
  static const Color primary = Color(0xFF2563EB);
  static const Color secondary = Color(0xFFF8FAFC);

  // --- Primary derivatives (tints & shades of #2563EB) --------------------
  // These stay the same across themes; only surfaces/text/neutrals flip.
  static const Color primaryDark = Color(0xFF1D4FD7);
  static const Color primaryDarker = Color(0xFF1E40AF);
  static const Color primaryLight = Color(0xFF60A5FA);

  // --- Semantic (kept minimal & desaturated to respect the palette) -------
  // Slightly brighter variants used on dark surfaces for better contrast.
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFD97706);
  static const Color danger = Color(0xFFDC2626);

  static const Color successDark = Color(0xFF22C55E);
  static const Color warningDark = Color(0xFFF59E0B);
  static const Color dangerDark = Color(0xFFEF4444);

  /// Soft brand gradient used on splash + hero surfaces (same both modes).
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDarker],
  );
}

/// Light-mode derived colors.
abstract class AppColorsLight {
  static const Color primarySoft = Color(0xFFEFF4FF); // very light blue wash
  static const Color primarySurface = Color(0xFFDCE7FF); // chips / highlights

  static const Color background = AppColors.secondary; // #F8FAFC
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF1F5F9);
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderStrong = Color(0xFFCBD5E1);

  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  static const Color shadow = Color(0x142563EB); // soft blue-tinted shadow
  static const Color scrim = Color(0x66000000);
}

/// Dark-mode derived colors.
abstract class AppColorsDark {
  static const Color primarySoft = Color(0xFF16213E); // deep blue wash
  static const Color primarySurface = Color(0xFF1E2A4A); // chips / highlights

  static const Color background = Color(0xFF0B1120); // near-black slate
  static const Color surface = Color(0xFF111827);
  static const Color surfaceMuted = Color(0xFF1A2333);
  static const Color border = Color(0xFF27324A);
  static const Color borderStrong = Color(0xFF3B4A6B);

  static const Color textPrimary = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFFB6C2D9);
  static const Color textTertiary = Color(0xFF7C8AA5);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  static const Color shadow = Color(0x66000000); // stronger shadow on dark
  static const Color scrim = Color(0x99000000);
}
