import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/section_header.dart';
import '../../upload_resume/providers/resume_provider.dart';
import '../models/ats_resume.dart';
import '../providers/ats_resume_provider.dart';

// Web-only import — only used when kIsWeb is true at runtime.
// ignore: avoid_web_libraries_in_flutter
import 'package:universal_html/html.dart' as html show AnchorElement, Blob, Url;

class AtsResumeScreen extends ConsumerStatefulWidget {
  const AtsResumeScreen({super.key});

  @override
  ConsumerState<AtsResumeScreen> createState() => _AtsResumeScreenState();
}

class _AtsResumeScreenState extends ConsumerState<AtsResumeScreen> {
  final _jobTitleCtrl = TextEditingController();
  final _jobDescCtrl = TextEditingController();
  bool _showTargeting = false;

  @override
  void dispose() {
    _jobTitleCtrl.dispose();
    _jobDescCtrl.dispose();
    super.dispose();
  }

  void _generate() {
    ref.read(atsResumeProvider.notifier).generate(
          jobTitle: _jobTitleCtrl.text.trim().isEmpty
              ? null
              : _jobTitleCtrl.text.trim(),
          jobDescription: _jobDescCtrl.text.trim().isEmpty
              ? null
              : _jobDescCtrl.text.trim(),
        );
  }

  Future<void> _downloadPdf() async {
    final bytes = await ref.read(atsResumeProvider.notifier).exportPdf();
    if (bytes == null || !mounted) return;
    await _savePdf(bytes, 'ats_resume.pdf');
  }

  Future<void> _savePdf(Uint8List bytes, String filename) async {
    if (kIsWeb) {
      final blob = html.Blob([bytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', filename)
        ..click();
      html.Url.revokeObjectUrl(url);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF downloaded!')),
        );
      }
    } else {
      try {
        Directory? saveDir;

        if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
          final home = Platform.environment['USERPROFILE'] ??
              Platform.environment['HOME'];
          if (home != null) {
            final downloads =
                Directory('$home${Platform.pathSeparator}Downloads');
            saveDir = downloads.existsSync() ? downloads : Directory(home);
          }
        }

        saveDir ??= await getApplicationDocumentsDirectory();

        final file = File('${saveDir.path}${Platform.pathSeparator}$filename');
        await file.writeAsBytes(bytes, flush: true);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('PDF saved to: ${file.path}'),
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'OK',
                onPressed: () {},
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save PDF: $e'),
              backgroundColor: isDark ? AppColors.dangerDark : AppColors.danger,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final resume = ref.watch(resumeProvider);
    final ats = ref.watch(atsResumeProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColorsDark.textSecondary : AppColorsLight.textSecondary;
    final primary = theme.colorScheme.primary;
    final textOnPrimary =
        isDark ? AppColorsDark.textOnPrimary : AppColorsLight.textOnPrimary;

    if (!resume.hasResume) {
      return const Scaffold(
        body: EmptyState(
          icon: Icons.description_rounded,
          title: 'No Resume Yet',
          message: 'Upload your PDF resume first to generate an ATS version.',
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
            // ── Header ──────────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ATS Resume', style: theme.textTheme.headlineMedium),
                      const SizedBox(height: 4),
                      Text(
                        'AI rewrites your resume in a fully ATS-safe format',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (ats.hasResume) ...[
                  OutlinedButton.icon(
                    onPressed: () =>
                        ref.read(atsResumeProvider.notifier).reset(),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('New'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: textOnPrimary,
                    ),
                    onPressed: ats.isExporting ? null : _downloadPdf,
                    icon: ats.isExporting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.download_rounded, size: 18),
                    label:
                        Text(ats.isExporting ? 'Exporting…' : 'Download PDF'),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            if (ats.status == AtsResumeStatus.idle) ...[
              _ConfigCard(
                showTargeting: _showTargeting,
                onToggleTargeting: () =>
                    setState(() => _showTargeting = !_showTargeting),
                jobTitleCtrl: _jobTitleCtrl,
                jobDescCtrl: _jobDescCtrl,
                onGenerate: _generate,
              ),
            ],

            if (ats.isGenerating) ...[
              const _GeneratingCard(),
            ],

            if (ats.status == AtsResumeStatus.error) ...[
              _ErrorCard(
                message: ats.error ?? 'Something went wrong.',
                onRetry: _generate,
              ),
            ],

            if (ats.hasResume) ...[
              _ResumePreview(resume: ats.resume!),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Config / CTA card
// ─────────────────────────────────────────────────────────────────────────────

class _ConfigCard extends StatelessWidget {
  const _ConfigCard({
    required this.showTargeting,
    required this.onToggleTargeting,
    required this.jobTitleCtrl,
    required this.jobDescCtrl,
    required this.onGenerate,
  });

  final bool showTargeting;
  final VoidCallback onToggleTargeting;
  final TextEditingController jobTitleCtrl;
  final TextEditingController jobDescCtrl;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColorsDark.textSecondary : AppColorsLight.textSecondary;
    final primarySoft =
        isDark ? AppColorsDark.primarySoft : AppColorsLight.primarySoft;
    final primary = theme.colorScheme.primary;

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primarySoft,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                  child: Icon(Icons.auto_fix_high_rounded,
                      color: primary, size: 28),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Generate ATS Resume',
                          style: theme.textTheme.titleLarge),
                      const SizedBox(height: 2),
                      Text(
                        'AI rewrites your resume with ATS-safe formatting, '
                        'strong action verbs, and keyword optimisation.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const [
                _FeatureChip(
                    icon: Icons.check_circle_rounded,
                    label: 'Single-column layout'),
                _FeatureChip(
                    icon: Icons.check_circle_rounded,
                    label: 'Quantified achievements'),
                _FeatureChip(
                    icon: Icons.check_circle_rounded,
                    label: 'Keyword optimised'),
                _FeatureChip(
                    icon: Icons.check_circle_rounded,
                    label: 'Standard headings'),
                _FeatureChip(
                    icon: Icons.check_circle_rounded,
                    label: 'Action verb bullets'),
                _FeatureChip(
                    icon: Icons.check_circle_rounded, label: 'PDF download'),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            GestureDetector(
              onTap: onToggleTargeting,
              child: Row(
                children: [
                  Icon(
                    showTargeting
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: primary,
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    showTargeting
                        ? 'Hide job targeting (optional)'
                        : 'Target a specific job (optional)',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (showTargeting) ...[
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: jobTitleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Job Title',
                  hintText: 'e.g. Flutter Developer',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: jobDescCtrl,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Job Description (paste here)',
                  hintText: 'Paste the job posting…',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: 'Generate ATS Resume',
              icon: Icons.auto_fix_high_rounded,
              onPressed: onGenerate,
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primarySoft =
        isDark ? AppColorsDark.primarySoft : AppColorsLight.primarySoft;
    final primary = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: primarySoft,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: primary),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontSize: 12, color: primary, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Generating card
// ─────────────────────────────────────────────────────────────────────────────

class _GeneratingCard extends StatelessWidget {
  const _GeneratingCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColorsDark.textSecondary : AppColorsLight.textSecondary;
    final primary = theme.colorScheme.primary;

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            CircularProgressIndicator(color: primary),
            const SizedBox(height: AppSpacing.md),
            Text('Generating ATS Resume…', style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              'Our AI is rewriting and optimising your resume. This may take 15–30 seconds.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: textSecondary,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final danger = isDark ? AppColors.dangerDark : AppColors.danger;

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: danger),
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
// Resume preview
// This "paper" mimics a real, printable A4 resume page, so it intentionally
// stays light/white in BOTH themes — like a document preview in Docs/Word.
// The success banner above it also stays light-only for the same reason:
// it reads as "printed paper" content, not app chrome.
// ─────────────────────────────────────────────────────────────────────────────

class _ResumePreview extends StatelessWidget {
  const _ResumePreview({required this.resume});

  final AtsResume resume;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Success banner
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: const Color(0xFFDCFCE7),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.success, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'ATS resume generated successfully! Preview below or click "Download PDF".',
                  style: TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                      fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        const SectionHeader(title: 'Preview'),
        const SizedBox(height: AppSpacing.sm),

        // Paper card mimicking an A4 resume — deliberately always white,
        // with a fixed light-mode card background regardless of app theme.
        Container(
          decoration: BoxDecoration(
            color: AppColorsLight.surface,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: AppColorsLight.border),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  resume.name.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: AppColorsLight.textPrimary,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  resume.contactLine,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColorsLight.textSecondary,
                      ),
                ),
                const SizedBox(height: AppSpacing.md),
                const Divider(color: AppColorsLight.textPrimary),
                const SizedBox(height: AppSpacing.md),
                _PreviewSection(
                  heading: 'PROFESSIONAL SUMMARY',
                  content: resume.summary,
                ),
                const SizedBox(height: AppSpacing.md),
                ...resume.sections.map((s) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _PreviewSection(
                          heading: s.heading, content: s.content),
                    )),
              ],
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        // Copy raw text button — this IS app chrome, so it follows the theme.
        AppCard(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Icon(Icons.text_snippet_rounded,
                    color: Theme.of(context).colorScheme.primary, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Copy plain text version',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: resume.rawText));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied to clipboard!')),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: const Text('Copy'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PreviewSection extends StatelessWidget {
  const _PreviewSection({required this.heading, required this.content});

  final String heading;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          heading,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: AppColorsLight.textPrimary,
              ),
        ),
        const SizedBox(height: 3),
        const Divider(color: AppColorsLight.borderStrong, height: 1),
        const SizedBox(height: 6),
        Text(
          content,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColorsLight.textSecondary,
                height: 1.5,
              ),
        ),
      ],
    );
  }
}
