import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/section_header.dart';
import '../data/job.dart';
import '../providers/job_match_provider.dart';

const _quickChips = ['Internship', 'Junior', 'Remote', 'Flutter', 'Backend'];

class JobMatchScreen extends ConsumerStatefulWidget {
  const JobMatchScreen({super.key});

  @override
  ConsumerState<JobMatchScreen> createState() => _JobMatchScreenState();
}

class _JobMatchScreenState extends ConsumerState<JobMatchScreen> {
  late final TextEditingController _search;

  @override
  void initState() {
    super.initState();
    _search = TextEditingController(text: ref.read(jobQueryProvider));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _runSearch(String q) {
    ref.read(jobQueryProvider.notifier).state = q.trim();
    ref.invalidate(jobMatchProvider);
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(jobMatchProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final surfaceMuted =
        isDark ? AppColorsDark.surfaceMuted : AppColorsLight.surfaceMuted;
    final border = isDark ? AppColorsDark.border : AppColorsLight.border;
    final textSecondary =
        isDark ? AppColorsDark.textSecondary : AppColorsLight.textSecondary;

    return Scaffold(
      body: ResponsiveContainer(
        padding:
            EdgeInsets.all(context.responsive(mobile: 16.0, desktop: 32.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            const SectionHeader(
              title: 'Job Match',
              subtitle:
                  'Live roles and internships, ranked against your resume.',
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              hint: 'Search a role, e.g. “flutter developer”, “ML intern”',
              controller: _search,
              prefixIcon: Icons.search_rounded,
              textInputAction: TextInputAction.search,
              onSubmitted: _runSearch,
              suffix: IconButton(
                icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                color: primary,
                onPressed: () => _runSearch(_search.text),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (final chip in _quickChips)
                  ActionChip(
                    label: Text(chip),
                    backgroundColor: surfaceMuted,
                    side: BorderSide(color: border),
                    labelStyle: TextStyle(
                      color: textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    onPressed: () {
                      _search.text = chip;
                      _runSearch(chip);
                    },
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: async.when(
                loading: () => const LoadingView(
                  message: 'Finding jobs that fit you…',
                ),
                error: (err, _) {
                  if (isNoResumeForJobs(err)) {
                    return EmptyState(
                      icon: Icons.work_outline_rounded,
                      title: 'Upload a resume to match jobs',
                      message: 'We rank live job listings against your resume. '
                          'Upload one to get personalized matches.',
                      actionLabel: 'Upload resume',
                      onAction: () => context.go(AppRoutes.upload),
                    );
                  }
                  return ErrorView(
                    message:
                        'We couldn’t load jobs right now. Please try again.',
                    onRetry: () => ref.invalidate(jobMatchProvider),
                  );
                },
                data: (matches) {
                  if (matches.isEmpty) {
                    return EmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'No matches found',
                      message:
                          'Try a different search term or one of the chips '
                          'above.',
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async => ref.invalidate(jobMatchProvider),
                    child: ListView.separated(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                      itemCount: matches.length,
                      itemBuilder: (_, i) => _JobCard(match: matches[i]),
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.md),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  const _JobCard({required this.match});
  final JobMatch match;

  Future<void> _open(BuildContext context) async {
    final uri = Uri.tryParse(match.job.url);
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the listing')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;
    final primarySoft =
        isDark ? AppColorsDark.primarySoft : AppColorsLight.primarySoft;
    final primary = theme.colorScheme.primary;
    final job = match.job;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Logo(url: job.companyLogo, company: job.company),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(job.title,
                        style: t.titleMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text('${job.company} · ${job.location}',
                        style: t.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              if (match.isRanked) _ScoreBadge(score: match.score),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (job.isInternship)
                const _Tag(text: 'Internship', highlight: true),
              for (final s in match.matchedSkills) _Tag(text: s),
            ],
          ),
          if (match.reason.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: primarySoft,
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.auto_awesome_rounded, size: 15, color: primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(match.reason,
                        style: t.bodySmall?.copyWith(color: primary)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _open(context),
              icon: const Icon(Icons.open_in_new_rounded, size: 17),
              label: const Text('View & Apply'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo({required this.url, required this.company});
  final String? url;
  final String company;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primarySoft =
        isDark ? AppColorsDark.primarySoft : AppColorsLight.primarySoft;
    final primary = theme.colorScheme.primary;
    final initial =
        company.trim().isNotEmpty ? company.trim()[0].toUpperCase() : '?';

    Widget fallback() => Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: primarySoft,
            borderRadius: BorderRadius.circular(AppRadii.sm),
          ),
          child: Text(initial,
              style: TextStyle(
                color: primary,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              )),
        );

    if (url == null) return fallback();
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: Image.network(
        url!,
        width: 44,
        height: 44,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback(),
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({required this.score});
  final int score;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final success = isDark ? AppColors.successDark : AppColors.success;
    final warning = isDark ? AppColors.warningDark : AppColors.warning;
    final primary = theme.colorScheme.primary;

    final Color c = score >= 75
        ? success
        : score >= 50
            ? primary
            : warning;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Column(
        children: [
          Text('$score%',
              style: TextStyle(
                color: c,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              )),
          Text('match',
              style: TextStyle(
                color: c,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              )),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text, this.highlight = false});
  final String text;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primarySurface =
        isDark ? AppColorsDark.primarySurface : AppColorsLight.primarySurface;
    final surfaceMuted =
        isDark ? AppColorsDark.surfaceMuted : AppColorsLight.surfaceMuted;
    final primary = theme.colorScheme.primary;
    final textSecondary =
        isDark ? AppColorsDark.textSecondary : AppColorsLight.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: highlight ? primarySurface : surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: highlight ? primary : textSecondary,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }
}
