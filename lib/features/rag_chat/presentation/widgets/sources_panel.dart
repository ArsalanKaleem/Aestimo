import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../models/chat_message.dart';

/// Transparency panel: shows the retrieved resume chunks that grounded the
/// answer, their similarity score, and why each was selected.
class SourcesPanel extends StatefulWidget {
  const SourcesPanel({super.key, required this.sources});
  final List<SourceSnippet> sources;

  @override
  State<SourcesPanel> createState() => _SourcesPanelState();
}

class _SourcesPanelState extends State<SourcesPanel> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      constraints: const BoxConstraints(maxWidth: 640),
      decoration: BoxDecoration(
        color: AppColors.primarySoft.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.primarySurface),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(AppRadii.md),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.travel_explore_rounded,
                      size: 17, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Sources · ${widget.sources.length} resume sections',
                    style: t.bodySmall?.copyWith(
                      color: AppColors.primaryDarker,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: AppDurations.fast,
                    child: const Icon(Icons.expand_more_rounded,
                        size: 18, color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: AppDurations.normal,
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                children: [
                  for (final s in widget.sources) _SourceTile(snippet: s),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({required this.snippet});
  final SourceSnippet snippet;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(snippet.section,
                    style: t.bodySmall?.copyWith(
                        color: AppColors.primaryDarker,
                        fontWeight: FontWeight.w600)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                child: Text(
                  '${(snippet.score * 100).round()}% match',
                  style: t.bodySmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('“${snippet.text}”',
              style: t.bodyMedium?.copyWith(
                  color: AppColors.textSecondary, height: 1.45)),
          if (snippet.reason != null) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline_rounded,
                    size: 13, color: AppColors.textTertiary),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(snippet.reason!,
                      style: t.bodySmall
                          ?.copyWith(fontStyle: FontStyle.italic)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
