import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// A soft, bordered surface with optional tap behaviour and hover lift.
class AppCard extends StatefulWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.color,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? color;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final interactive = widget.onTap != null;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark ? AppColorsDark.surface : AppColorsLight.surface;
    final border = isDark ? AppColorsDark.border : AppColorsLight.border;

    return MouseRegion(
      cursor: interactive ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: interactive ? (_) => setState(() => _hovering = true) : null,
      onExit: interactive ? (_) => setState(() => _hovering = false) : null,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppDurations.fast,
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, _hovering ? -3 : 0, 0),
          padding: widget.padding,
          decoration: BoxDecoration(
            color: widget.color ?? surface,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(
              color: _hovering ? AppColors.primaryLight : border,
            ),
            boxShadow: _hovering
                ? AppShadows.raised(context)
                : AppShadows.card(context),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// A dashboard feature tile: icon chip + title + subtitle, fully tappable.
class FeatureCard extends StatelessWidget {
  const FeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;

    final primary = theme.colorScheme.primary;
    final primarySoft =
        isDark ? AppColorsDark.primarySoft : AppColorsLight.primarySoft;
    final primarySurface =
        isDark ? AppColorsDark.primarySurface : AppColorsLight.primarySurface;
    final textTertiary =
        isDark ? AppColorsDark.textTertiary : AppColorsLight.textTertiary;

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: primarySoft,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Icon(icon, color: primary, size: 22),
              ),
              const Spacer(),
              if (badge != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: primarySurface,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                  child: Text(
                    badge!,
                    style: t.bodySmall?.copyWith(
                      color: primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else
                Icon(Icons.arrow_outward_rounded,
                    color: textTertiary, size: 20),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(title, style: t.titleMedium),
          const SizedBox(height: 4),
          Text(subtitle, style: t.bodyMedium),
        ],
      ),
    );
  }
}
