import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/app_logo.dart';
import '../providers/chat_provider.dart';
import 'widgets/chat_input.dart';
import 'widgets/message_bubble.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 120,
        duration: AppDurations.normal,
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatProvider);

    ref.listen(chatProvider, (_, __) => _scrollToBottom());

    return Scaffold(
      body: Column(
        children: [
          _ChatHeader(
            canClear: !state.isEmpty,
            onClear: () => ref.read(chatProvider.notifier).clear(),
          ),
          const Divider(height: 1),
          Expanded(
            child: state.isEmpty
                ? _ChatEmptyState(
                    onPrompt: (p) => ref.read(chatProvider.notifier).send(p),
                  )
                : ListView.builder(
                    controller: _scroll,
                    padding: EdgeInsets.symmetric(
                      horizontal:
                          context.responsive(mobile: 12.0, desktop: 24.0),
                      vertical: AppSpacing.md,
                    ),
                    itemCount: state.messages.length,
                    itemBuilder: (_, i) => Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 860),
                        child: MessageBubble(message: state.messages[i]),
                      ),
                    ),
                  ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 880),
              child: ChatInput(
                enabled: !state.isResponding,
                onSend: (text) =>
                    ref.read(chatProvider.notifier).send(text),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({required this.canClear, required this.onClear});
  final bool canClear;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const AppLogo(size: 24, showWordmark: false),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('AI Career Assistant',
                  style: Theme.of(context).textTheme.titleMedium),
              Text('Grounded in your resume',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const Spacer(),
          if (canClear)
            TextButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.delete_sweep_outlined, size: 18),
              label: const Text('Clear'),
              style:
                  TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
            ),
        ],
      ),
    );
  }
}

class _ChatEmptyState extends StatelessWidget {
  const _ChatEmptyState({required this.onPrompt});
  final ValueChanged<String> onPrompt;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                  boxShadow: AppShadows.card,
                ),
                child: const Icon(Icons.auto_awesome_rounded,
                    color: AppColors.secondary, size: 30),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Ask your career copilot',
                  style: t.headlineSmall, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                'Every answer is grounded in your resume — with the exact '
                'sections it used shown for transparency.',
                style: t.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  for (final prompt in SamplePrompts.items)
                    _PromptChip(label: prompt, onTap: () => onPrompt(prompt)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PromptChip extends StatelessWidget {
  const _PromptChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadii.pill),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.pill),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.pill),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
      ),
    );
  }
}
