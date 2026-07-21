import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// The Aestimo wordmark: a rounded gradient glyph + the product name.
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 28,
    this.showWordmark = true,
    this.onLight = false,
  });

  final double size;
  final bool showWordmark;

  /// When placed on a colored/gradient surface, render the wordmark in white.
  final bool onLight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColorsDark.textPrimary : AppColorsLight.textPrimary;

    final markColor = onLight ? AppColors.secondary : textPrimary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: AppColors.brandGradient,
            borderRadius: BorderRadius.circular(size * 0.3),
            boxShadow: AppShadows.card(context),
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.auto_awesome,
            size: size * 0.72,
            color: AppColors.secondary,
          ),
        ),
        if (showWordmark) ...[
          const SizedBox(width: AppSpacing.sm),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'AESTI',
                  style: TextStyle(
                    fontSize: size * 1,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                    color: markColor,
                  ),
                ),
                TextSpan(
                  text: 'MO',
                  style: TextStyle(
                    fontSize: size * 1,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                    color: onLight ? AppColors.secondary : AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
