import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/section_header.dart';
import '../models/insights.dart';
import '../providers/insights_provider.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(insightsProvider);

    return Scaffold(
      body: ResponsiveContainer(
        padding:
            EdgeInsets.all(context.responsive(mobile: 16.0, desktop: 32.0)),
        child: async.when(
          loading: () => const LoadingView(
            message: 'Analyzing your resume…',
          ),
          error: (err, _) {
            if (isNoResume(err)) {
              return EmptyState(
                icon: Icons.insights_rounded,
                title: 'No resume to analyze yet',
                message: 'Upload your resume and we’ll break down your skills, '
                    'experience, strengths, and gaps.',
                actionLabel: 'Upload resume',
                onAction: () => context.go(AppRoutes.upload),
              );
            }
            return ErrorView(
              message: 'We couldn’t generate insights. Please try again.',
              onRetry: () => ref.invalidate(insightsProvider),
            );
          },
          data: (insights) => _InsightsBody(insights: insights),
        ),
      ),
    );
  }
}

class _InsightsBody extends StatelessWidget {
  const _InsightsBody({required this.insights});
  final ResumeInsights insights;

  @override
  Widget build(BuildContext context) {
    final twoCol = context.isDesktop;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primarySoft =
        isDark ? AppColorsDark.primarySoft : AppColorsLight.primarySoft;
    final primary = theme.colorScheme.primary;

    final skills = _SkillsCard(insights: insights);
    final experience = _ExperienceCard(insights: insights);
    final strengths = _StrengthsCard(insights: insights);
    final improvements = _ImprovementsCard(insights: insights);

    return ListView(
      children: [
        const SizedBox(height: 8),
        SectionHeader(
          title: 'Resume Insights',
          subtitle:
              'A recruiter’s-eye view of your profile, generated from your '
              'resume.',
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: primarySoft,
              borderRadius: BorderRadius.circular(AppRadii.pill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome_rounded, size: 15, color: primary),
                const SizedBox(width: 6),
                Text(
                  'AI generated',
                  style: TextStyle(
                    color: primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (twoCol)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: skills),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: experience),
              ],
            ),
          )
        else ...[
          skills,
          const SizedBox(height: AppSpacing.md),
          experience,
        ],
        const SizedBox(height: AppSpacing.md),
        if (twoCol)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: strengths),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: improvements),
              ],
            ),
          )
        else ...[
          strengths,
          const SizedBox(height: AppSpacing.md),
          improvements,
        ],
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

class _CardTitle extends StatelessWidget {
  const _CardTitle({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primarySoft =
        isDark ? AppColorsDark.primarySoft : AppColorsLight.primarySoft;
    final primary = theme.colorScheme.primary;

    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: primarySoft,
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          child: Icon(icon, color: primary, size: 19),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(label, style: theme.textTheme.titleMedium),
      ],
    );
  }
}

/// Chip row. Pass [foreground]/[background] to override the default
/// primary-tinted style (e.g. for soft skills or "worth adding" chips).
/// Defaults resolve to the current theme's primary tokens when omitted —
/// they can't be compile-time constants anymore since Light/Dark tokens
/// aren't const-equal, so resolution happens in [build] instead of in the
/// constructor signature.
class _ChipWrap extends StatelessWidget {
  const _ChipWrap({
    required this.items,
    this.foreground,
    this.background,
  });

  final List<String> items;
  final Color? foreground;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final primarySurface =
        isDark ? AppColorsDark.primarySurface : AppColorsLight.primarySurface;

    final fg = foreground ?? primary;
    final bg = background ?? primarySurface;

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final item in items)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(AppRadii.pill),
            ),
            child: Text(
              item,
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
      ],
    );
  }
}

class _MiniLabel extends StatelessWidget {
  const _MiniLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTertiary =
        isDark ? AppColorsDark.textTertiary : AppColorsLight.textTertiary;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: textTertiary,
          fontWeight: FontWeight.w700,
          fontSize: 11,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _SkillsCard extends StatelessWidget {
  const _SkillsCard({required this.insights});
  final ResumeInsights insights;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColorsDark.textSecondary : AppColorsLight.textSecondary;
    final surfaceMuted =
        isDark ? AppColorsDark.surfaceMuted : AppColorsLight.surfaceMuted;
    final warning = isDark ? AppColors.warningDark : AppColors.warning;
    // "Worth adding" chip background: light amber tint. Resolved for dark
    // mode so it doesn't read as a stray bright patch on a dark card.
    final warningBg = isDark
        ? AppColors.warningDark.withValues(alpha: 0.16)
        : const Color(0xFFFEF3E2);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle(icon: Icons.code_rounded, label: 'Skills Analysis'),
          const SizedBox(height: AppSpacing.lg),
          const _MiniLabel('Technical'),
          _ChipWrap(items: insights.technicalSkills),
          const SizedBox(height: AppSpacing.lg),
          const _MiniLabel('Soft skills'),
          _ChipWrap(
            items: insights.softSkills,
            foreground: textSecondary,
            background: surfaceMuted,
          ),
          const SizedBox(height: AppSpacing.lg),
          const _MiniLabel('Worth adding'),
          _ChipWrap(
            items: insights.missingSkills,
            foreground: warning,
            background: warningBg,
          ),
        ],
      ),
    );
  }
}

class _ExperienceCard extends StatelessWidget {
  const _ExperienceCard({required this.insights});
  final ResumeInsights insights;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;
    final primarySoft =
        isDark ? AppColorsDark.primarySoft : AppColorsLight.primarySoft;
    final primary = theme.colorScheme.primary;

    final years = insights.yearsExperience;
    final yearsLabel =
        years == years.roundToDouble() ? years.toInt().toString() : '$years';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle(
            icon: Icons.work_history_rounded,
            label: 'Experience Summary',
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: primarySoft,
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Row(
              children: [
                Text(
                  yearsLabel,
                  style: t.headlineMedium?.copyWith(
                    color: primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('years of\nexperience',
                      style: t.bodySmall?.copyWith(height: 1.15)),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const _MiniLabel('Main expertise areas'),
          _ChipWrap(items: insights.expertiseAreas),
        ],
      ),
    );
  }
}

class _StrengthsCard extends StatelessWidget {
  const _StrengthsCard({required this.insights});
  final ResumeInsights insights;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle(
            icon: Icons.emoji_events_rounded,
            label: 'Career Strengths',
          ),
          const SizedBox(height: AppSpacing.lg),
          const _MiniLabel('Top strengths'),
          for (final s in insights.strengths) _Bullet(text: s),
          const SizedBox(height: AppSpacing.md),
          const _MiniLabel('Competitive advantages'),
          for (final a in insights.advantages)
            _Bullet(text: a, icon: Icons.bolt_rounded),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.text, this.icon = Icons.check_circle_rounded});
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _ImprovementsCard extends StatelessWidget {
  const _ImprovementsCard({required this.insights});
  final ResumeInsights insights;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;
    final surfaceMuted =
        isDark ? AppColorsDark.surfaceMuted : AppColorsLight.surfaceMuted;
    final primary = theme.colorScheme.primary;
    final onPrimary =
        isDark ? AppColorsDark.textOnPrimary : AppColorsLight.textOnPrimary;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle(
            icon: Icons.trending_up_rounded,
            label: 'Improvement Suggestions',
          ),
          const SizedBox(height: AppSpacing.lg),
          for (var i = 0; i < insights.improvements.length; i++) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: surfaceMuted,
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: primary,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            color: onPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(insights.improvements[i].title,
                            style: t.titleSmall),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(insights.improvements[i].detail, style: t.bodyMedium),
                ],
              ),
            ),
            if (i != insights.improvements.length - 1)
              const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}
