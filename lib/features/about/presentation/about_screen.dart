import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/app_card.dart';
import '../data/developer_profile.dart';

/// A polished, professional "About" page: a gradient hero with the developer's
/// photo and quick links, a bio with focus areas, a connect grid, and an
/// "About the app" section with feature highlights.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _open(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open $url')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: ResponsiveContainer(
        maxWidth: 920,
        padding: EdgeInsets.symmetric(
          horizontal: context.responsive(mobile: 16.0, desktop: 32.0),
          vertical: context.responsive(mobile: 16.0, desktop: 28.0),
        ),
        child: ListView(
          children: [
            _Hero(onOpen: (url) => _open(context, url)),
            const SizedBox(height: AppSpacing.lg),
            const _BioCard(),
            const SizedBox(height: AppSpacing.lg),
            _ConnectSection(onOpen: (url) => _open(context, url)),
            const SizedBox(height: AppSpacing.lg),
            const _AboutAppCard(),
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: Text(
                'Made with Flutter · © ${DateTime.now().year} '
                '${DeveloperProfile.name}',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.textTertiary),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────
//  Hero
// ───────────────────────────────────────────────────────────────────────────

class _Hero extends StatelessWidget {
  const _Hero({required this.onOpen});
  final void Function(String url) onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        boxShadow: AppShadows.raised,
      ),
      child: Stack(
        children: [
          // Subtle decorative glow.
          Positioned(
            top: -40,
            right: -30,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary.withValues(alpha: 0.08),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: LayoutBuilder(
              builder: (context, c) {
                final wide = c.maxWidth > 540;
                return wide
                    ? _wideHero(context)
                    : _narrowHero(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _narrowHero(BuildContext context) {
    return Column(
      children: [
        const _DeveloperAvatar(radius: 54),
        const SizedBox(height: AppSpacing.md),
        _heroText(context, center: true),
        const SizedBox(height: AppSpacing.lg),
        _SocialRow(onOpen: onOpen, center: true),
      ],
    );
  }

  Widget _wideHero(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const _DeveloperAvatar(radius: 58),
        const SizedBox(width: AppSpacing.xl),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _heroText(context, center: false),
              const SizedBox(height: AppSpacing.lg),
              _SocialRow(onOpen: onOpen, center: false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _heroText(BuildContext context, {required bool center}) {
    final t = Theme.of(context).textTheme;
    final align = center ? CrossAxisAlignment.center : CrossAxisAlignment.start;
    final textAlign = center ? TextAlign.center : TextAlign.start;

    return Column(
      crossAxisAlignment: align,
      children: [
        Text(
          DeveloperProfile.name,
          style: t.headlineMedium?.copyWith(
            color: AppColors.secondary,
            fontWeight: FontWeight.w800,
          ),
          textAlign: textAlign,
        ),
        const SizedBox(height: 8),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.secondary.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(AppRadii.pill),
          ),
          child: Text(
            DeveloperProfile.role,
            style: t.bodySmall?.copyWith(
              color: AppColors.secondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          DeveloperProfile.headline,
          style: t.bodyMedium?.copyWith(
            color: AppColors.secondary.withValues(alpha: 0.92),
            height: 1.4,
          ),
          textAlign: textAlign,
        ),
        if (DeveloperProfile.location.trim().isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_on_rounded,
                  size: 15,
                  color: AppColors.secondary.withValues(alpha: 0.8)),
              const SizedBox(width: 4),
              Text(
                DeveloperProfile.location,
                style: t.bodySmall?.copyWith(
                  color: AppColors.secondary.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _SocialRow extends StatelessWidget {
  const _SocialRow({required this.onOpen, required this.center});
  final void Function(String url) onOpen;
  final bool center;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: center ? WrapAlignment.center : WrapAlignment.start,
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final link in DeveloperProfile.links)
          Tooltip(
            message: link.label,
            child: Material(
              color: AppColors.secondary.withValues(alpha: 0.16),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => onOpen(link.url),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Icon(link.icon,
                      size: 20, color: AppColors.secondary),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Circular developer picture with a white ring — network photo when set,
/// otherwise initials. Shows a spinner while loading and falls back to
/// initials if the image fails.
class _DeveloperAvatar extends StatelessWidget {
  const _DeveloperAvatar({required this.radius});
  final double radius;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = DeveloperProfile.photoUrl.trim().isNotEmpty;

    Widget initials() => Container(
          color: AppColors.secondary,
          alignment: Alignment.center,
          child: Text(
            DeveloperProfile.initials,
            style: TextStyle(
              fontSize: radius * 0.74,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
        );

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.25),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.secondary,
        child: ClipOval(
          child: SizedBox(
            width: radius * 2,
            height: radius * 2,
            child: hasPhoto
                ? Image.network(
                    DeveloperProfile.photoUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        color: AppColors.secondary,
                        alignment: Alignment.center,
                        child: const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: AppColors.primary,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) => initials(),
                  )
                : initials(),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────
//  Bio
// ───────────────────────────────────────────────────────────────────────────

class _BioCard extends StatelessWidget {
  const _BioCard();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _MiniLabel('About me'),
          const SizedBox(height: AppSpacing.sm),
          Text(
            DeveloperProfile.bio,
            style: t.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
          if (DeveloperProfile.focusAreas.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            const _MiniLabel('Focus areas'),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final area in DeveloperProfile.focusAreas)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                    ),
                    child: Text(
                      area,
                      style: const TextStyle(
                        color: AppColors.primaryDarker,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────
//  Connect
// ───────────────────────────────────────────────────────────────────────────

class _ConnectSection extends StatelessWidget {
  const _ConnectSection({required this.onOpen});
  final void Function(String url) onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _MiniLabel('Connect'),
        const SizedBox(height: AppSpacing.sm),
        LayoutBuilder(
          builder: (context, c) {
            final twoCol = c.maxWidth > 460;
            final width =
                twoCol ? (c.maxWidth - AppSpacing.sm) / 2 : c.maxWidth;
            return Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final link in DeveloperProfile.links)
                  SizedBox(
                    width: width,
                    child: _LinkButton(
                      link: link,
                      onTap: () => onOpen(link.url),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _LinkButton extends StatelessWidget {
  const _LinkButton({required this.link, required this.onTap});
  final DeveloperLink link;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.md),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Icon(link.icon, size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  link.label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.north_east_rounded,
                  size: 16, color: AppColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────
//  About the app
// ───────────────────────────────────────────────────────────────────────────

class _AboutAppCard extends StatelessWidget {
  const _AboutAppCard();

  static const _features = [
    (Icons.insights_rounded, 'Resume Insights',
        'Skills, experience, strengths & gaps at a glance.'),
    (Icons.forum_rounded, 'AI Chat',
        'Ask anything about your career — answers cite your resume.'),
    (Icons.psychology_rounded, 'Interview Prep',
        'Personalized questions and live mock interviews.'),
    (Icons.mail_rounded, 'Cover Letters',
        'Tailored letters generated from your background.'),
  ];

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return AppCard(
      color: AppColors.primarySoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: const Icon(Icons.auto_awesome_rounded,
                    size: 19, color: AppColors.secondary),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text('About ${AppConstants.appName}', style: t.titleMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            AppConstants.tagline,
            style: t.bodyLarge?.copyWith(
              color: AppColors.primaryDarker,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${AppConstants.appName} reads your resume and turns it into a '
            'personal career copilot — grounded in your real experience.',
            style: t.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (var i = 0; i < _features.length; i++) ...[
            _FeatureRow(
              icon: _features[i].$1,
              title: _features[i].$2,
              subtitle: _features[i].$3,
            ),
            if (i != _features.length - 1)
              const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.sm),
          ),
          child: Icon(icon, size: 19, color: AppColors.primary),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: t.titleSmall),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: t.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
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
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: AppColors.textTertiary,
        fontWeight: FontWeight.w700,
        fontSize: 11,
        letterSpacing: 0.6,
      ),
    );
  }
}
