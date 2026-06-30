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
        padding: EdgeInsets.all(context.responsive(mobile: 16.0, desktop: 32.0)),
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
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
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
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(AppRadii.lg),
              ),
              child: const Icon(Icons.upload_file_rounded,
                  color: AppColors.primary, size: 30),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Upload your resume',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              'PDF up to 10 MB. We extract, chunk, and embed it for search.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primarySoft.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
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
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              Text('${(state.progress * 100).round()}%',
                  style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.pill),
            child: LinearProgressIndicator(
              value: state.progress,
              minHeight: 8,
              backgroundColor: AppColors.surfaceMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(state.progressLabel ?? '',
              style: Theme.of(context).textTheme.bodyMedium),
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
    final t = Theme.of(context).textTheme;
    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: const Icon(Icons.picture_as_pdf_rounded,
                    color: AppColors.danger, size: 26),
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
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        size: 14, color: AppColors.success),
                    const SizedBox(width: 4),
                    Text('Indexed',
                        style: t.bodySmall?.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600)),
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
                    foregroundColor: AppColors.danger,
                    side: BorderSide(
                        color: AppColors.danger.withValues(alpha: 0.4)),
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
    ('Chunk', Icons.dashboard_customize_outlined, 'Split into overlapping passages'),
    ('Embed', Icons.scatter_plot_outlined, 'text-embedding-3-small vectors'),
    ('Store', Icons.storage_outlined, 'Index vectors in ChromaDB'),
    ('Search', Icons.travel_explore_outlined, 'Semantic retrieval at query time'),
  ];

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return AppCard(
      color: AppColors.surfaceMuted,
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
                    backgroundColor: AppColors.primarySoft,
                    child: Icon(icon, size: 17, color: AppColors.primary),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text('$label  ',
                      style: t.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  Expanded(
                      child: Text(desc,
                          style: t.bodyMedium, overflow: TextOverflow.ellipsis)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
