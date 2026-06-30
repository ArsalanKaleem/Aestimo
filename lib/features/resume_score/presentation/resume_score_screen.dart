import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/section_header.dart';
import '../../upload_resume/providers/resume_provider.dart';
import '../models/resume_score.dart';
import '../providers/resume_score_provider.dart';

class ResumeScoreScreen extends ConsumerWidget {
  const ResumeScoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resume = ref.watch(resumeProvider);
    final scoreState = ref.watch(resumeScoreProvider);

    if (!resume.hasResume) {
      return const Scaffold(
        body: EmptyState(
          icon: Icons.score_rounded,
          title: 'No Resume Yet',
          message:'Upload your PDF resume first to get an ATS score.',
        ),
      );
    }

    return Scaffold(
      body: ResponsiveContainer(
        padding: EdgeInsets.all(
          context.responsive(mobile: 16.0, desktop: 32.0),
        ),
        child: ListView(
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Resume Score',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'AI-powered ATS compatibility analysis',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                if (scoreState.hasScore)
                  OutlinedButton.icon(
                    onPressed: () => ref
                        .read(resumeScoreProvider.notifier)
                        .analyse(),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Re-analyse'),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Idle state ──────────────────────────────────────────────────
            if (scoreState.status == ScoreStatus.idle) ...[
              _AnalyseCta(
                onTap: () =>
                    ref.read(resumeScoreProvider.notifier).analyse(),
              ),
            ],

            // ── Loading ─────────────────────────────────────────────────────
            if (scoreState.isLoading) ...[
              const _LoadingCard(),
            ],

            // ── Error ───────────────────────────────────────────────────────
            if (scoreState.status == ScoreStatus.error) ...[
              _ErrorCard(
                message: scoreState.error ?? 'Something went wrong.',
                onRetry: () =>
                    ref.read(resumeScoreProvider.notifier).analyse(),
              ),
            ],

            // ── Results ──────────────────────────────────────────────────────
            if (scoreState.hasScore) ...[
              _ResultsView(score: scoreState.score!),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CTA card
// ─────────────────────────────────────────────────────────────────────────────

class _AnalyseCta extends StatelessWidget {
  const _AnalyseCta({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.md),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.analytics_rounded,
              size: 36,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Get Your ATS Score',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'We will ll analyse your resume across 6 key categories and give you an ATS compatibility score with actionable feedback.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: 'Analyse My Resume',
            icon: Icons.bar_chart_rounded,
            onPressed: onTap,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Loading card
// ─────────────────────────────────────────────────────────────────────────────

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Analysing your resume…',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Our AI is scoring your resume across 6 categories.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error card
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: AppColors.danger),
            const SizedBox(height: AppSpacing.sm),
            Text(message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Full results view
// ─────────────────────────────────────────────────────────────────────────────

class _ResultsView extends StatelessWidget {
  const _ResultsView({required this.score});

  final ResumeScore score;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Overall score hero
        _OverallScoreCard(score: score),
        const SizedBox(height: AppSpacing.lg),

        // Category breakdown
        const SectionHeader(title: 'Category Breakdown'),
        const SizedBox(height: AppSpacing.sm),
        ...score.categories.map((c) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _CategoryRow(category: c),
            )),
        const SizedBox(height: AppSpacing.md),

        // Two-column strengths + fixes
        _TwoColSection(
          leftTitle: '✅ Top Strengths',
          leftItems: score.topStrengths,
          leftColor: AppColors.success,
          rightTitle: '🔧 Critical Fixes',
          rightItems: score.criticalFixes,
          rightColor: AppColors.danger,
        ),
        const SizedBox(height: AppSpacing.lg),

        // Keywords
        const SectionHeader(title: 'ATS Keywords'),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _KeywordChips(
                  label: 'Found in Resume',
                  keywords: score.atsKeywords,
                  color: AppColors.success,
                  bgColor: const Color(0xFFDCFCE7),
                ),
                if (score.missingKeywords.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  _KeywordChips(
                    label: 'Missing Keywords',
                    keywords: score.missingKeywords,
                    color: AppColors.danger,
                    bgColor: const Color(0xFFFFEBEE),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Overall score hero card with circular gauge
// ─────────────────────────────────────────────────────────────────────────────

class _OverallScoreCard extends StatelessWidget {
  const _OverallScoreCard({required this.score});

  final ResumeScore score;

  Color get _gaugeColor {
    if (score.overallScore >= 80) return AppColors.success;
    if (score.overallScore >= 60) return AppColors.warning;
    return AppColors.danger;
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            _CircularGauge(value: score.overallScore / 100, color: _gaugeColor,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${score.overallScore}',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: _gaugeColor,
                          ),
                    ),
                    Text(
                      '/100',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                )),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _gaugeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppRadii.pill),
                        ),
                        child: Text(
                          '${score.grade} · ${score.gradeLabel}',
                          style: TextStyle(
                            color: _gaugeColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'ATS Compatibility Score',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Based on 6 categories including keywords, formatting, '
                    'experience, and achievements.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircularGauge extends StatelessWidget {
  const _CircularGauge({
    required this.value,
    required this.color,
    required this.child,
  });

  final double value;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      height: 110,
      child: CustomPaint(
        painter: _GaugePainter(value: value, color: color),
        child: Center(child: child),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({required this.value, required this.color});

  final double value;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const strokeWidth = 10.0;

    // Track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = AppColors.border
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    // Arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * value,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.value != value || old.color != color;
}

// ─────────────────────────────────────────────────────────────────────────────
// Category row with bar
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.category});

  final ScoreCategory category;

  Color get _barColor {
    if (category.fraction >= 0.8) return AppColors.success;
    if (category.fraction >= 0.6) return AppColors.warning;
    return AppColors.danger;
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    category.name,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  '${category.score}/${category.maxScore}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: _barColor,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.pill),
              child: LinearProgressIndicator(
                value: category.fraction,
                minHeight: 8,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation<Color>(_barColor),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              category.feedback,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Two-column strengths / fixes
// ─────────────────────────────────────────────────────────────────────────────

class _TwoColSection extends StatelessWidget {
  const _TwoColSection({
    required this.leftTitle,
    required this.leftItems,
    required this.leftColor,
    required this.rightTitle,
    required this.rightItems,
    required this.rightColor,
  });

  final String leftTitle;
  final List<String> leftItems;
  final Color leftColor;
  final String rightTitle;
  final List<String> rightItems;
  final Color rightColor;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth > 520;
      final children = [
        Expanded(
          child: _ListCard(
            title: leftTitle,
            items: leftItems,
            dotColor: leftColor,
          ),
        ),
        SizedBox(width: isWide ? AppSpacing.md : 0,
            height: isWide ? 0 : AppSpacing.sm),
        Expanded(
          child: _ListCard(
            title: rightTitle,
            items: rightItems,
            dotColor: rightColor,
          ),
        ),
      ];
      return isWide
          ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: children)
          : Column(children: [
              _ListCard(
                  title: leftTitle, items: leftItems, dotColor: leftColor),
              const SizedBox(height: AppSpacing.sm),
              _ListCard(
                  title: rightTitle, items: rightItems, dotColor: rightColor),
            ]);
    });
  }
}

class _ListCard extends StatelessWidget {
  const _ListCard(
      {required this.title, required this.items, required this.dotColor});

  final String title;
  final List<String> items;
  final Color dotColor;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: AppSpacing.sm),
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 6, right: 8),
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: dotColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          item,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Keyword chips
// ─────────────────────────────────────────────────────────────────────────────

class _KeywordChips extends StatelessWidget {
  const _KeywordChips({
    required this.label,
    required this.keywords,
    required this.color,
    required this.bgColor,
  });

  final String label;
  final List<String> keywords;
  final Color color;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: keywords
              .map((k) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                      border: Border.all(color: color.withOpacity(0.3)),
                    ),
                    child: Text(k,
                        style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.w500)),
                  ))
              .toList(),
        ),
      ],
    );
  }
}
