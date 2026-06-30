
import 'package:flutter/material.dart';

/// Aestimo palette.
///
/// The spec mandates exactly two primary colors. Every other shade in the app
/// is *derived* from these two (tints/shades/opacity), so the product stays
/// visually coherent and on-brand.
///
///   Primary   #2563EB  Professional Blue
///   Secondary #F8FAFC  Soft White
abstract class AppColors {
  // --- The two source-of-truth colors -------------------------------------
  static const Color primary = Color(0xFF2563EB);
  static const Color secondary = Color(0xFFF8FAFC);

  // --- Primary derivatives (tints & shades of #2563EB) --------------------
  static const Color primaryDark = Color(0xFF1D4FD7);
  static const Color primaryDarker = Color(0xFF1E40AF);
  static const Color primaryLight = Color(0xFF60A5FA);
  static const Color primarySoft = Color(0xFFEFF4FF); // very light blue wash
  static const Color primarySurface = Color(0xFFDCE7FF); // chips / highlights

  // --- Neutrals derived from the soft-white secondary ---------------------
  static const Color background = secondary; // #F8FAFC
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF1F5F9);
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderStrong = Color(0xFFCBD5E1);

  // --- Text (cool slate neutrals, in-family with the blue) ----------------
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // --- Semantic (kept minimal & desaturated to respect the palette) -------
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFD97706);
  static const Color danger = Color(0xFFDC2626);

  // --- Effects ------------------------------------------------------------
  static const Color shadow = Color(0x142563EB); // soft blue-tinted shadow
  static const Color scrim = Color(0x66000000);

  /// Soft brand gradient used on splash + hero surfaces.
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDarker],
  );
}
