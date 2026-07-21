import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/section_header.dart';
import '../../upload_resume/providers/resume_provider.dart';
import '../models/interview.dart';
import '../providers/interview_provider.dart';

class InterviewPrepScreen extends ConsumerStatefulWidget {
  const InterviewPrepScreen({super.key});

  @override
  ConsumerState<InterviewPrepScreen> createState() =>
      _InterviewPrepScreenState();
}

class _InterviewPrepScreenState extends ConsumerState<InterviewPrepScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
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
                icon: Icons.psychology_rounded,
                title: 'Upload a resume to prep',
                message: 'Your interview questions are personalized from your '
                    'resume. Upload one to get started.',
                actionLabel: 'Upload resume',
                onAction: () => context.go(AppRoutes.upload),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  const SectionHeader(
                    title: 'Interview Prep',
                    subtitle:
                        'Personalized questions and a live mock interview, '
                        'grounded in your resume.',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _Tabs(controller: _tabs),
                  const SizedBox(height: AppSpacing.lg),
                  Expanded(
                    child: TabBarView(
                      controller: _tabs,
                      children: const [
                        _QuestionsTab(),
                        _MockInterviewTab(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({required this.controller});
  final TabController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceMuted =
        isDark ? AppColorsDark.surfaceMuted : AppColorsLight.surfaceMuted;
    final surface = isDark ? AppColorsDark.surface : AppColorsLight.surface;
    final primary = theme.colorScheme.primary;
    final textSecondary =
        isDark ? AppColorsDark.textSecondary : AppColorsLight.textSecondary;

    return Container(
      decoration: BoxDecoration(
        color: surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      padding: const EdgeInsets.all(4),
      child: TabBar(
        controller: controller,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(AppRadii.sm),
          boxShadow: AppShadows.card(context),
        ),
        labelColor: primary,
        unselectedLabelColor: textSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        tabs: const [
          Tab(text: 'Questions'),
          Tab(text: 'Mock Interview'),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Questions tab
// ---------------------------------------------------------------------------

class _QuestionsTab extends ConsumerWidget {
  const _QuestionsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(interviewQuestionsProvider);

    return async.when(
      loading: () => const LoadingView(message: 'Generating your questions…'),
      error: (err, _) => ErrorView(
        message: 'We couldn’t generate questions. Please try again.',
        onRetry: () => ref.invalidate(interviewQuestionsProvider),
      ),
      data: (questions) {
        final grouped = <QuestionCategory, List<InterviewQuestion>>{};
        for (final q in questions) {
          grouped.putIfAbsent(q.category, () => []).add(q);
        }
        return ListView(
          children: [
            for (final entry in grouped.entries) ...[
              _CategoryHeader(category: entry.key, count: entry.value.length),
              const SizedBox(height: AppSpacing.sm),
              for (final q in entry.value) ...[
                _QuestionCard(question: q),
                const SizedBox(height: AppSpacing.sm),
              ],
              const SizedBox(height: AppSpacing.md),
            ],
            const SizedBox(height: AppSpacing.lg),
          ],
        );
      },
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({required this.category, required this.count});
  final QuestionCategory category;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final surfaceMuted =
        isDark ? AppColorsDark.surfaceMuted : AppColorsLight.surfaceMuted;
    final textSecondary =
        isDark ? AppColorsDark.textSecondary : AppColorsLight.textSecondary;

    final icon = switch (category) {
      QuestionCategory.technical => Icons.terminal_rounded,
      QuestionCategory.behavioral => Icons.diversity_3_rounded,
      QuestionCategory.roleSpecific => Icons.badge_rounded,
    };
    return Row(
      children: [
        Icon(icon, size: 18, color: primary),
        const SizedBox(width: AppSpacing.sm),
        Text(category.label, style: theme.textTheme.titleMedium),
        const SizedBox(width: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: surfaceMuted,
            borderRadius: BorderRadius.circular(AppRadii.pill),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              color: textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _QuestionCard extends StatefulWidget {
  const _QuestionCard({required this.question});
  final InterviewQuestion question;

  @override
  State<_QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<_QuestionCard> {
  bool _showTip = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final primarySoft =
        isDark ? AppColorsDark.primarySoft : AppColorsLight.primarySoft;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.question.question, style: t.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          InkWell(
            onTap: () => setState(() => _showTip = !_showTip),
            borderRadius: BorderRadius.circular(AppRadii.sm),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Icon(
                    _showTip
                        ? Icons.lightbulb_rounded
                        : Icons.lightbulb_outline_rounded,
                    size: 16,
                    color: primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _showTip ? 'Hide guidance' : 'How to answer',
                    style: t.labelLarge?.copyWith(color: primary),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: AppDurations.fast,
            crossFadeState:
                _showTip ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            firstChild: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: AppSpacing.sm),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: primarySoft,
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: Text(widget.question.tip, style: t.bodyMedium),
            ),
            secondChild: const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mock interview tab
// ---------------------------------------------------------------------------

class _MockInterviewTab extends ConsumerStatefulWidget {
  const _MockInterviewTab();

  @override
  ConsumerState<_MockInterviewTab> createState() => _MockInterviewTabState();
}

class _MockInterviewTabState extends ConsumerState<_MockInterviewTab> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    _controller.clear();
    ref.read(mockInterviewProvider.notifier).answer(text);
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent + 200,
          duration: AppDurations.normal,
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mockInterviewProvider);
    ref.listen(mockInterviewProvider, (_, __) => _scrollToEnd());

    if (!state.started) {
      return _StartPanel(
        onStart: () => ref.read(mockInterviewProvider.notifier).start(),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            itemCount: state.turns.length + (state.finished ? 1 : 0),
            itemBuilder: (context, i) {
              if (i == state.turns.length) {
                return _FinishedCard(
                  onRestart: () =>
                      ref.read(mockInterviewProvider.notifier).reset(),
                );
              }
              return _TurnBubble(turn: state.turns[i]);
            },
          ),
        ),
        if (!state.finished)
          _AnswerInput(
            controller: _controller,
            enabled: state.awaitingAnswer,
            responding: state.isResponding,
            onSend: _send,
          ),
      ],
    );
  }
}

class _StartPanel extends StatelessWidget {
  const _StartPanel({required this.onStart});
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;
    final primarySoft =
        isDark ? AppColorsDark.primarySoft : AppColorsLight.primarySoft;
    final primary = theme.colorScheme.primary;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: AppCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: primarySoft,
                  borderRadius: BorderRadius.circular(AppRadii.xl),
                ),
                child: Icon(Icons.record_voice_over_rounded,
                    color: primary, size: 30),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Mock Interview', style: t.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'I’ll ask questions one at a time. Answer in your own words and '
                'I’ll give you instant, specific feedback after each one.',
                textAlign: TextAlign.center,
                style: t.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: 'Start mock interview',
                icon: Icons.play_arrow_rounded,
                expand: false,
                onPressed: onStart,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TurnBubble extends StatelessWidget {
  const _TurnBubble({required this.turn});
  final MockTurn turn;

  @override
  Widget build(BuildContext context) {
    final isInterviewer = turn.role == MockRole.interviewer;
    final theme = Theme.of(context);
    final t = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final onPrimary =
        isDark ? AppColorsDark.textOnPrimary : AppColorsLight.textOnPrimary;
    final primarySoft =
        isDark ? AppColorsDark.primarySoft : AppColorsLight.primarySoft;
    final surfaceMuted =
        isDark ? AppColorsDark.surfaceMuted : AppColorsLight.surfaceMuted;
    final textTertiary =
        isDark ? AppColorsDark.textTertiary : AppColorsLight.textTertiary;
    final textPrimary =
        isDark ? AppColorsDark.textPrimary : AppColorsLight.textPrimary;

    if (!isInterviewer) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(top: AppSpacing.sm, left: 48),
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: 10),
          decoration: BoxDecoration(
            color: primary,
            borderRadius: BorderRadius.circular(AppRadii.lg).copyWith(
              bottomRight: const Radius.circular(4),
            ),
          ),
          child: Text(
            turn.content,
            style: t.bodyLarge?.copyWith(color: onPrimary),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.sm, right: 32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: turn.isFeedback ? primarySoft : surfaceMuted,
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: Icon(
              turn.isFeedback
                  ? Icons.tips_and_updates_rounded
                  : Icons.person_search_rounded,
              size: 18,
              color: primary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  turn.isFeedback ? 'Feedback' : 'Interviewer',
                  style: t.labelSmall?.copyWith(
                    color: textTertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                if (turn.streaming && turn.content.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text('…', style: TextStyle(color: textTertiary)),
                  )
                else
                  MarkdownBody(
                    data: turn.content,
                    styleSheet: MarkdownStyleSheet(
                      p: t.bodyLarge?.copyWith(color: textPrimary),
                      strong:
                          t.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                      listBullet: t.bodyLarge?.copyWith(color: textPrimary),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FinishedCard extends StatelessWidget {
  const _FinishedCard({required this.onRestart});
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;
    final primarySoft =
        isDark ? AppColorsDark.primarySoft : AppColorsLight.primarySoft;
    final primary = theme.colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.lg),
      child: AppCard(
        color: primarySoft,
        child: Column(
          children: [
            Icon(Icons.celebration_rounded, color: primary, size: 28),
            const SizedBox(height: AppSpacing.sm),
            Text('That’s a wrap!', style: t.titleMedium),
            const SizedBox(height: 4),
            Text(
              'You completed the mock interview. Review the feedback above, '
              'then run it again to sharpen your answers.',
              textAlign: TextAlign.center,
              style: t.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              label: 'Restart',
              icon: Icons.refresh_rounded,
              expand: false,
              variant: ButtonVariant.outlined,
              onPressed: onRestart,
            ),
          ],
        ),
      ),
    );
  }
}

class _AnswerInput extends StatelessWidget {
  const _AnswerInput({
    required this.controller,
    required this.enabled,
    required this.responding,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool enabled;
  final bool responding;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColorsDark.surface : AppColorsLight.surface;

    return Container(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              minLines: 1,
              maxLines: 5,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: responding
                    ? 'Interviewer is responding…'
                    : enabled
                        ? 'Type your answer…'
                        : 'Waiting for the next question…',
                filled: true,
                fillColor: surface,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            height: 52,
            width: 52,
            child: FilledButton(
              onPressed: enabled ? onSend : null,
              style: FilledButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
              ),
              child: const Icon(Icons.send_rounded, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
