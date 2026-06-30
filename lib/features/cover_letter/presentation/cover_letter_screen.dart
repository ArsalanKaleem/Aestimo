import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/section_header.dart';
import '../../upload_resume/providers/resume_provider.dart';
import '../models/cover_letter.dart';
import '../providers/cover_letter_provider.dart';

class CoverLetterScreen extends ConsumerStatefulWidget {
  const CoverLetterScreen({super.key});

  @override
  ConsumerState<CoverLetterScreen> createState() => _CoverLetterScreenState();
}

class _CoverLetterScreenState extends ConsumerState<CoverLetterScreen> {
  final _title = TextEditingController();
  final _company = TextEditingController();
  final _description = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    _company.dispose();
    _description.dispose();
    super.dispose();
  }

  void _generate() {
    FocusScope.of(context).unfocus();
    ref.read(coverLetterProvider.notifier).generate(
          CoverLetterRequest(
            jobTitle: _title.text,
            company: _company.text,
            jobDescription: _description.text,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final hasResume = ref.watch(resumeProvider).hasResume;

    return Scaffold(
      body: ResponsiveContainer(
        padding:
            EdgeInsets.all(context.responsive(mobile: 16.0, desktop: 32.0)),
        child: !hasResume
            ? EmptyState(
                icon: Icons.mail_rounded,
                title: 'Upload a resume first',
                message:
                    'Cover letters are tailored using your resume context. '
                    'Upload one to generate a letter.',
                actionLabel: 'Upload resume',
                onAction: () => context.go(AppRoutes.upload),
              )
            : ListView(
                children: [
                  const SizedBox(height: 8),
                  const SectionHeader(
                    title: 'Cover Letter Generator',
                    subtitle:
                        'Tailored to the role and grounded in your resume.',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (context.isDesktop)
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(width: 380, child: _form()),
                          const SizedBox(width: AppSpacing.md),
                          const Expanded(child: _OutputCard()),
                        ],
                      ),
                    )
                  else ...[
                    _form(),
                    const SizedBox(height: AppSpacing.md),
                    const _OutputCard(),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
      ),
    );
  }

  Widget _form() {
    final generating = ref.watch(
      coverLetterProvider.select((s) => s.isGenerating),
    );
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Job details',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: 'Job title',
            hint: 'e.g. Senior Backend Engineer',
            controller: _title,
            prefixIcon: Icons.work_outline_rounded,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Company',
            hint: 'e.g. Acme Corp',
            controller: _company,
            prefixIcon: Icons.business_rounded,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Job description (optional)',
            hint: 'Paste the description to tailor the letter further…',
            controller: _description,
            maxLines: 5,
            minLines: 3,
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: generating ? 'Generating…' : 'Generate cover letter',
            icon: Icons.auto_awesome_rounded,
            loading: generating,
            onPressed: _generate,
          ),
        ],
      ),
    );
  }
}

class _OutputCard extends ConsumerWidget {
  const _OutputCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(coverLetterProvider);
    final t = Theme.of(context).textTheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Your cover letter', style: t.titleMedium),
              const Spacer(),
              if (state.hasLetter && !state.isGenerating) ...[
                _IconAction(
                  icon: Icons.copy_rounded,
                  tooltip: 'Copy',
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: state.letter));
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                          const SnackBar(content: Text('Copied to clipboard')));
                  },
                ),
                const SizedBox(width: 4),
                _IconAction(
                  icon: Icons.refresh_rounded,
                  tooltip: 'Clear',
                  onTap: () => ref.read(coverLetterProvider.notifier).clear(),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (!state.hasLetter && !state.isGenerating)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.description_outlined,
                        size: 40, color: AppColors.textTertiary),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Fill in the job details and your tailored letter will '
                      'appear here.',
                      textAlign: TextAlign.center,
                      style: t.bodyMedium,
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: MarkdownBody(
                data: state.letter.isEmpty ? '…' : state.letter,
                selectable: true,
                styleSheet: MarkdownStyleSheet(
                  p: t.bodyLarge?.copyWith(
                    color: AppColors.textPrimary,
                    height: 1.55,
                  ),
                  strong: t.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          if (state.error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(state.error!,
                style: t.bodySmall?.copyWith(color: AppColors.danger)),
          ],
        ],
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 18, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
