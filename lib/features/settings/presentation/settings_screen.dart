import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/settings/settings_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/primary_button.dart';

const String _kStudioKeyUrl = 'https://aistudio.google.com/apikey';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _controller;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    final current = ref.read(geminiApiKeyProvider);
    final isCustom = ref.read(geminiApiKeyProvider.notifier).isCustom;
    // Pre-fill only a user-supplied key; never expose the built-in default.
    _controller = TextEditingController(text: isCustom ? current : '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await ref.read(geminiApiKeyProvider.notifier).setKey(_controller.text);
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('API key saved')),
    );
  }

  Future<void> _useDefault() async {
    await ref.read(geminiApiKeyProvider.notifier).reset();
    _controller.clear();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reverted to the built-in key')),
    );
  }

  Future<void> _openGuide() async {
    final uri = Uri.parse(_kStudioKeyUrl);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the link')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the value so the labels/buttons update after a save.
    ref.watch(geminiApiKeyProvider);
    final isCustom = ref.read(geminiApiKeyProvider.notifier).isCustom;
    final t = Theme.of(context).textTheme;

    return Scaffold(
      body: ResponsiveContainer(
        padding:
            EdgeInsets.all(context.responsive(mobile: 16.0, desktop: 32.0)),
        child: ListView(
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                if (Navigator.of(context).canPop())
                  IconButton(
                    onPressed: () => context.go(AppRoutes.dashboard),
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: AppColors.textSecondary,
                  ),
                Text('Settings', style: t.titleLarge),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── API key ───────────────────────────────────────────────────
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(AppRadii.md),
                        ),
                        child: const Icon(Icons.key_rounded,
                            color: AppColors.primary, size: 19),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Gemini API key', style: t.titleMedium),
                            Text(
                              isCustom
                                  ? 'Using your own key'
                                  : 'Using the built-in key',
                              style: t.bodySmall?.copyWith(
                                color: isCustom
                                    ? AppColors.success
                                    : AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Use your own Google Gemini API key to avoid shared rate '
                    'limits. It is stored only on this device.',
                    style: t.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'API key',
                    hint: 'AIza… or paste your key',
                    controller: _controller,
                    obscureText: _obscure,
                    onSubmitted: (_) => _save(),
                    textInputAction: TextInputAction.done,
                    suffix: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Paste',
                          icon: const Icon(Icons.content_paste_rounded,
                              size: 18),
                          color: AppColors.textTertiary,
                          onPressed: () async {
                            final data =
                                await Clipboard.getData('text/plain');
                            if (data?.text != null) {
                              _controller.text = data!.text!.trim();
                            }
                          },
                        ),
                        IconButton(
                          tooltip: _obscure ? 'Show' : 'Hide',
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_rounded
                                : Icons.visibility_off_rounded,
                            size: 18,
                          ),
                          color: AppColors.textTertiary,
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: PrimaryButton(
                          label: 'Save key',
                          icon: Icons.check_rounded,
                          onPressed: _save,
                        ),
                      ),
                      if (isCustom) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: PrimaryButton(
                            label: 'Use default',
                            variant: ButtonVariant.outlined,
                            onPressed: _useDefault,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Tutorial ──────────────────────────────────────────────────
            Text('How to get a Gemini API key', style: t.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _Step(
                    n: 1,
                    text:
                        'Open Google AI Studio and sign in with your Google '
                        'account.',
                  ),
                  _Step(
                    n: 2,
                    text:
                        'Click “Create API key”. You can create one in a new '
                        'project or an existing one.',
                  ),
                  _Step(
                    n: 3,
                    text: 'Copy the key that starts with “AIza…”.',
                  ),
                  _Step(
                    n: 4,
                    text:
                        'Paste it in the field above and tap Save. The free '
                        'tier needs no credit card.',
                    last: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                label: 'Open Google AI Studio',
                icon: Icons.open_in_new_rounded,
                variant: ButtonVariant.outlined,
                onPressed: _openGuide,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.n, required this.text, this.last = false});
  final int n;
  final String text;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$n',
              style: const TextStyle(
                color: AppColors.secondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
