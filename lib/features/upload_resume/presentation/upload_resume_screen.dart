import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/section_header.dart';
import '../models/resume.dart';
import '../providers/resume_provider.dart';

class UploadResumeScreen extends ConsumerWidget {
  const UploadResumeScreen({super.key});

  Future<void> _pick(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final f = result.files.single;
    await ref.read(resumeProvider.notifier).upload(
          fileName: f.name,
          sizeBytes: f.size,
          bytes: f.bytes,
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(resumeProvider);

    return Scaffold(
      body: ResponsiveContainer(
        padding:
            EdgeInsets.all(context.responsive(mobile: 16.0, desktop: 32.0)),
        child: ListView(
          children: [
            const SizedBox(height: 8),
            const SectionHeader(
              title: 'Resume',
              subtitle:
                  'Upload your PDF resume to power insights, chat, and more.',
            ),
            const SizedBox(height: AppSpacing.xl),
            if (state.isBusy)
              _IngestProgressCard(state: state)
            else if (state.hasResume)
              _ResumeCard(
                resume: state.resume!,
                onReplace: () => _pick(context, ref),
                onDelete: () => _confirmDelete(context, ref),
              )
            else
              _DropZone(onPick: () => _pick(context, ref)),
            const SizedBox(height: AppSpacing.xl),
            const _PipelineExplainer(),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final danger = isDark ? AppColors.dangerDark : AppColors.danger;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete resume?'),
        content: const Text(
          'This removes your resume and its embeddings. Insights and chat '
          'context will be cleared.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) await ref.read(resumeProvider.notifier).delete();
  }
}

class _DropZone extends StatelessWidget {
  const _DropZone({required this.onPick});
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primarySoft =
        isDark ? AppColorsDark.primarySoft : AppColorsLight.primarySoft;
    final primary = theme.colorScheme.primary;

    return DottedBorderBox(
      onTap: onPick,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: primarySoft,
                borderRadius: BorderRadius.circular(AppRadii.lg),
              ),
              child: Icon(Icons.upload_file_rounded, color: primary, size: 30),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Upload your resume', style: theme.textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              'PDF up to 10 MB. We extract, chunk, and embed it for search.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: 'Choose PDF',
              icon: Icons.attach_file_rounded,
              expand: false,
              onPressed: onPick,
            ),
          ],
        ),
      ),
    );
  }
}

class DottedBorderBox extends StatelessWidget {
  const DottedBorderBox({super.key, required this.child, this.onTap});
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primarySoft =
        isDark ? AppColorsDark.primarySoft : AppColorsLight.primarySoft;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: primarySoft.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
            // Fixed brand accent border — same in both themes, matches the
            // AppCard hover-border convention.
            color: AppColors.primaryLight,
            width: 1.4,
          ),
        ),
        child: child,
      ),
    );
  }
}

class _IngestProgressCard extends StatelessWidget {
  const _IngestProgressCard({required this.state});
  final ResumeState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceMuted =
        isDark ? AppColorsDark.surfaceMuted : AppColorsLight.surfaceMuted;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text('Processing resume',
                    style: theme.textTheme.titleMedium),
              ),
              Text('${(state.progress * 100).round()}%',
                  style: theme.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.pill),
            child: LinearProgressIndicator(
              value: state.progress,
              minHeight: 8,
              backgroundColor: surfaceMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(state.progressLabel ?? '', style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _ResumeCard extends StatelessWidget {
  const _ResumeCard({
    required this.resume,
    required this.onReplace,
    required this.onDelete,
  });

  final Resume resume;
  final VoidCallback onReplace;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;
    final danger = isDark ? AppColors.dangerDark : AppColors.danger;
    final success = isDark ? AppColors.successDark : AppColors.success;

    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: danger.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child:
                    Icon(Icons.picture_as_pdf_rounded, color: danger, size: 26),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(resume.fileName,
                        style: t.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(
                      '${resume.readableSize} · ${resume.pageCount ?? 0} pages · '
                      '${resume.chunkCount ?? 0} chunks indexed',
                      style: t.bodySmall,
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded, size: 14, color: success),
                    const SizedBox(width: 4),
                    Text('Indexed',
                        style: t.bodySmall?.copyWith(
                            color: success, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  label: 'Replace',
                  icon: Icons.swap_horiz_rounded,
                  variant: ButtonVariant.outlined,
                  onPressed: onReplace,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: danger,
                    side: BorderSide(color: danger.withValues(alpha: 0.4)),
                  ),
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded, size: 19),
                  label: const Text('Delete'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PipelineExplainer extends StatelessWidget {
  const _PipelineExplainer();

  static const _steps = [
    ('Extract', Icons.text_snippet_outlined, 'Pull raw text from the PDF'),
    (
      'Chunk',
      Icons.dashboard_customize_outlined,
      'Split into overlapping passages'
    ),
    ('Embed', Icons.scatter_plot_outlined, 'text-embedding-3-small vectors'),
    ('Store', Icons.storage_outlined, 'Index vectors in ChromaDB'),
    (
      'Search',
      Icons.travel_explore_outlined,
      'Semantic retrieval at query time'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;
    final surfaceMuted =
        isDark ? AppColorsDark.surfaceMuted : AppColorsLight.surfaceMuted;
    final primarySoft =
        isDark ? AppColorsDark.primarySoft : AppColorsLight.primarySoft;
    final primary = theme.colorScheme.primary;

    return AppCard(
      color: surfaceMuted,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How the RAG pipeline works', style: t.titleMedium),
          const SizedBox(height: AppSpacing.md),
          ...List.generate(_steps.length, (i) {
            final (label, icon, desc) = _steps[i];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: primarySoft,
                    child: Icon(icon, size: 17, color: primary),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text('$label  ',
                      style:
                          t.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                  Expanded(
                      child: Text(desc,
                          style: t.bodyMedium,
                          overflow: TextOverflow.ellipsis)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
