import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/app_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../../upload_resume/models/resume.dart';
import '../../upload_resume/providers/resume_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final resume = ref.watch(resumeProvider);

    final greeting = _greeting();
    final name = user?.displayName?.split(' ').first ?? 'there';

    final columns = context.responsive(mobile: 1, tablet: 2, desktop: 3);

    return Scaffold(
      body: ResponsiveContainer(
        padding:
            EdgeInsets.all(context.responsive(mobile: 16.0, desktop: 32.0)),
        child: ListView(
          children: [
            const SizedBox(height: 8),
            _TopBar(user: user),
            const SizedBox(height: AppSpacing.lg),
            Text('$greeting, $name 👋',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 6),
            Text(
              'Your AI career copilot is ready. Here’s what you can do.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            _ResumeStatusBanner(resume: resume),
            const SizedBox(height: AppSpacing.lg),
            GridView.count(
              crossAxisCount: columns,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
              childAspectRatio:
                  context.responsive(mobile: 1.7, tablet: 1.5, desktop: 1.45),
              children: [
                FeatureCard(
                  icon: Icons.upload_file_rounded,
                  title: 'Upload Resume',
                  subtitle: 'Add or replace your PDF to power everything.',
                  onTap: () => context.go(AppRoutes.upload),
                ),
                FeatureCard(
                  icon: Icons.insights_rounded,
                  title: 'Resume Insights',
                  subtitle: 'Skills, experience, strengths & gaps.',
                  onTap: () => context.go(AppRoutes.insights),
                ),
                FeatureCard(
                  icon: Icons.forum_rounded,
                  title: 'AI Chat',
                  subtitle: 'Ask anything about your career, with sources.',
                  onTap: () => context.go(AppRoutes.chat),
                ),
                FeatureCard(
                  icon: Icons.psychology_rounded,
                  title: 'Interview Prep',
                  subtitle: 'Personalized questions & mock interviews.',
                  onTap: () => context.go(AppRoutes.interview),
                ),
                FeatureCard(
                  icon: Icons.work_rounded,
                  title: 'Job Match',
                  subtitle: 'Live jobs & internships ranked to your resume.',
                  badge: 'New',
                  onTap: () => context.go(AppRoutes.jobs),
                ),
                FeatureCard(
                  icon: Icons.mail_rounded,
                  title: 'Cover Letter',
                  subtitle: 'Tailored letters from your resume context.',
                  onTap: () => context.go(AppRoutes.coverLetter),
                ),
                FeatureCard(
                  icon: Icons.auto_awesome_rounded,
                  title: 'Quick Summary',
                  subtitle: 'One-tap snapshot of your profile.',
                  badge: 'AI',
                  onTap: () => context.go(AppRoutes.chat),
                ),
                FeatureCard(
                  icon: Icons.score_rounded,
                  title: 'Resume Score',
                  subtitle: 'ATS compatibility score with category breakdown.',
                  badge: 'New',
                  onTap: () => context.go(AppRoutes.resumeScore),
                ),
                FeatureCard(
                  icon: Icons.auto_fix_high_rounded,
                  title: 'ATS Resume',
                  subtitle: 'AI rewrites your resume in ATS-safe format + PDF.',
                  badge: 'New',
                  onTap: () => context.go(AppRoutes.atsResume),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 18) return 'Good afternoon';
    return 'Good evening';
  }
}

class _TopBar extends ConsumerWidget {
  const _TopBar({required this.user});
  final dynamic user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        const Spacer(),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.notifications_none_rounded),
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 4),
        _AccountMenu(user: user),
      ],
    );
  }
}

/// A polished account menu: avatar trigger + a custom-styled dropdown with a
/// profile header, a settings entry, and a destructive sign-out entry.
class _AccountMenu extends ConsumerWidget {
  const _AccountMenu({required this.user});
  final dynamic user;

  static const double _menuWidth = 260;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      tooltip: '',
      offset: const Offset(0, 52),
      padding: EdgeInsets.zero,
      position: PopupMenuPosition.under,
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        side: const BorderSide(color: AppColors.border),
      ),
      constraints: const BoxConstraints(minWidth: _menuWidth, maxWidth: _menuWidth),
      onSelected: (v) {
        if (v == 'signout') ref.read(authProvider.notifier).signOut();
        if (v == 'settings') context.go(AppRoutes.settings);
      },
      itemBuilder: (_) => [
        PopupMenuItem<String>(
          enabled: false,
          padding: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primarySoft,
                  foregroundImage: (user?.photoUrl != null &&
                          (user?.photoUrl as String).trim().isNotEmpty)
                      ? NetworkImage(user!.photoUrl as String)
                      : null,
                  child: Text(
                    user?.initials ?? '?',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        (user?.displayName as String?)?.trim().isNotEmpty ==
                                true
                            ? user!.displayName as String
                            : 'Your account',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user?.email ?? '',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const PopupMenuItem<String>(
          enabled: false,
          height: 1,
          padding: EdgeInsets.zero,
          child: Divider(height: 1, thickness: 1, color: AppColors.border),
        ),
        PopupMenuItem<String>(
          value: 'settings',
          padding: EdgeInsets.zero,
          child: _MenuTile(
            icon: Icons.settings_outlined,
            iconColor: AppColors.primary,
            iconBg: AppColors.primarySoft,
            label: 'Settings',
          ),
        ),
        const PopupMenuItem<String>(
          enabled: false,
          height: 9,
          padding: EdgeInsets.zero,
          child: SizedBox(height: 1),
        ),
        PopupMenuItem<String>(
          value: 'signout',
          padding: EdgeInsets.zero,
          child: _MenuTile(
            icon: Icons.logout_rounded,
            iconColor: AppColors.danger,
            iconBg: const Color(0xFFFEE2E2),
            label: 'Sign out',
            labelColor: AppColors.danger,
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
        ),
        child: CircleAvatar(
          radius: 17,
          backgroundColor: AppColors.primary,
          foregroundImage: (user?.photoUrl != null &&
                  (user?.photoUrl as String).trim().isNotEmpty)
              ? NetworkImage(user!.photoUrl as String)
              : null,
          child: Text(
            user?.initials ?? '?',
            style: const TextStyle(
              color: AppColors.secondary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

/// A single row inside [_AccountMenu] with a soft icon chip and hover/press
/// feedback via [InkWell], so the custom items still feel native.
class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    this.labelColor,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    // PopupMenuItem already wraps its child in an InkWell that pops the
    // menu with `value` on tap, so this widget stays purely presentational.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: labelColor ?? AppColors.textPrimary,
              fontWeight: FontWeight.w500,
              fontSize: 13.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResumeStatusBanner extends StatelessWidget {
  const _ResumeStatusBanner({required this.resume});
  final ResumeState resume;

  @override
  Widget build(BuildContext context) {
    final ready = resume.hasResume;
    final t = Theme.of(context).textTheme;

    return AppCard(
      color: ready ? AppColors.primarySoft : AppColors.surface,
      onTap: ready ? null : () => context.go(AppRoutes.upload),
      child: Row(
        children: [
          Icon(
            ready ? Icons.verified_rounded : Icons.info_outline_rounded,
            color: ready ? AppColors.primary : AppColors.warning,
            size: 26,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ready ? 'Resume indexed & ready' : 'No resume uploaded yet',
                  style: t.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  ready
                      ? '${resume.resume!.fileName} · ${resume.resume!.chunkCount} chunks searchable'
                      : 'Upload a PDF to unlock insights, chat, and interview prep.',
                  style: t.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (!ready)
            const Icon(Icons.arrow_forward_rounded,
                color: AppColors.textTertiary),
        ],
      ),
    );
  }
}
