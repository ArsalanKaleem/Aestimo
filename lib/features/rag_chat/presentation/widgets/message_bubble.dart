import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../models/chat_message.dart';
import 'sources_panel.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark ? AppColorsDark.surface : AppColorsLight.surface;
    final border = isDark ? AppColorsDark.border : AppColorsLight.border;
    final primary = theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) const _Avatar(isUser: false),
          if (!isUser) const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: const BoxConstraints(maxWidth: 640),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isUser ? primary : surface,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(AppRadii.lg),
                      topRight: const Radius.circular(AppRadii.lg),
                      bottomLeft:
                          Radius.circular(isUser ? AppRadii.lg : AppRadii.sm),
                      bottomRight:
                          Radius.circular(isUser ? AppRadii.sm : AppRadii.lg),
                    ),
                    border: isUser ? null : Border.all(color: border),
                    boxShadow: isUser ? null : AppShadows.card(context),
                  ),
                  child: _BubbleContent(message: message),
                ),
                if (!isUser && message.sources.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: SourcesPanel(sources: message.sources),
                  ),
                if (!isUser && !message.streaming && message.content.isNotEmpty)
                  _MessageActions(content: message.content),
              ],
            ),
          ),
          if (isUser) const SizedBox(width: AppSpacing.sm),
          if (isUser) const _Avatar(isUser: true),
        ],
      ),
    );
  }
}

class _BubbleContent extends StatelessWidget {
  const _BubbleContent({required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textOnPrimary =
        isDark ? AppColorsDark.textOnPrimary : AppColorsLight.textOnPrimary;
    final textPrimary =
        isDark ? AppColorsDark.textPrimary : AppColorsLight.textPrimary;
    final surfaceMuted =
        isDark ? AppColorsDark.surfaceMuted : AppColorsLight.surfaceMuted;
    final primarySoft =
        isDark ? AppColorsDark.primarySoft : AppColorsLight.primarySoft;

    if (message.isUser) {
      return Text(
        message.content,
        style: TextStyle(color: textOnPrimary, height: 1.5),
      );
    }

    if (message.content.isEmpty && message.streaming) {
      return const TypingIndicator();
    }

    final base = theme.textTheme.bodyLarge!;
    return MarkdownBody(
      data: message.content,
      selectable: true,
      styleSheet: MarkdownStyleSheet(
        p: base.copyWith(color: textPrimary),
        strong: base.copyWith(fontWeight: FontWeight.w700),
        listBullet: base.copyWith(color: textPrimary),
        code: base.copyWith(
          fontFamily: 'monospace',
          backgroundColor: surfaceMuted,
          fontSize: 13.5,
        ),
        codeblockDecoration: BoxDecoration(
          color: surfaceMuted,
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
        blockquoteDecoration: BoxDecoration(
          color: primarySoft,
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
      ),
    );
  }
}

class _MessageActions extends StatelessWidget {
  const _MessageActions({required this.content});
  final String content;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTertiary =
        isDark ? AppColorsDark.textTertiary : AppColorsLight.textTertiary;

    return Padding(
      padding: const EdgeInsets.only(top: 4, left: 4),
      child: TextButton.icon(
        style: TextButton.styleFrom(
          foregroundColor: textTertiary,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onPressed: () {
          Clipboard.setData(ClipboardData(text: content));
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
                const SnackBar(content: Text('Copied to clipboard')));
        },
        icon: const Icon(Icons.copy_rounded, size: 15),
        label: const Text('Copy', style: TextStyle(fontSize: 12.5)),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.isUser});
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceMuted =
        isDark ? AppColorsDark.surfaceMuted : AppColorsLight.surfaceMuted;
    final textSecondary =
        isDark ? AppColorsDark.textSecondary : AppColorsLight.textSecondary;
    final textOnPrimary =
        isDark ? AppColorsDark.textOnPrimary : AppColorsLight.textOnPrimary;
    final primary = theme.colorScheme.primary;

    return CircleAvatar(
      radius: 16,
      backgroundColor: isUser ? surfaceMuted : primary,
      child: Icon(
        isUser ? Icons.person_rounded : Icons.auto_awesome_rounded,
        size: 16,
        color: isUser ? textSecondary : textOnPrimary,
      ),
    );
  }
}

/// Three-dot typing animation shown before the first token arrives.
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTertiary =
        isDark ? AppColorsDark.textTertiary : AppColorsLight.textTertiary;

    return SizedBox(
      height: 18,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              final t = (_c.value + i * 0.2) % 1.0;
              final scale = 0.6 + 0.4 * (1 - (2 * t - 1).abs());
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.5),
                child: Transform.scale(
                  scale: scale,
                  child: CircleAvatar(
                    radius: 3.5,
                    backgroundColor: textTertiary,
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
