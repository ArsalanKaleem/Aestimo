import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/app_logo.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/primary_button.dart';
import '../providers/auth_provider.dart';

enum _Mode { signIn, register }

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool _obscure = true;
  _Mode _mode = _Mode.signIn;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _mode = _mode == _Mode.signIn ? _Mode.register : _Mode.signIn;
      _formKey.currentState?.reset();
    });
    ref.read(authProvider.notifier).clearError();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_mode == _Mode.signIn) {
      ref
          .read(authProvider.notifier)
          .signInWithEmail(_email.text, _password.text);
    } else {
      ref
          .read(authProvider.notifier)
          .registerWithEmail(_email.text, _password.text, _name.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final isRegister = _mode == _Mode.register;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark ? AppColorsDark.surface : AppColorsLight.surface;
    final border = isDark ? AppColorsDark.border : AppColorsLight.border;
    final textTertiary =
        isDark ? AppColorsDark.textTertiary : AppColorsLight.textTertiary;
    final primary = theme.colorScheme.primary;

    ref.listen(authProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(next.error!)));
      }
    });

    final card = Container(
      constraints: const BoxConstraints(maxWidth: 420),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(color: border),
        boxShadow: AppShadows.raised(context),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child: AppLogo(size: 34)),
            const SizedBox(height: AppSpacing.lg),
            Text(
              isRegister ? 'Create your account' : 'Welcome back',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            Text(
              isRegister
                  ? 'Sign up to get started with your AI career copilot.'
                  : 'Sign in to pick up where your career copilot left off.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.xl),

            // Name (register only)
            if (isRegister) ...[
              AppTextField(
                label: 'Full name',
                hint: 'Alex Morgan',
                controller: _name,
                prefixIcon: Icons.person_outline_rounded,
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            AppTextField(
              label: 'Email',
              hint: 'you@example.com',
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.mail_outline_rounded,
              textInputAction: TextInputAction.next,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email is required';
                if (!v.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),

            AppTextField(
              label: 'Password',
              hint: '••••••••',
              controller: _password,
              obscureText: _obscure,
              prefixIcon: Icons.lock_outline_rounded,
              textInputAction:
                  isRegister ? TextInputAction.next : TextInputAction.done,
              onSubmitted: isRegister ? null : (_) => _submit(),
              suffix: IconButton(
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                  color: textTertiary,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
              // Firebase requires ≥ 6 chars — the old validator allowed 4 which
              // caused silent failures during account creation.
              validator: (v) => (v == null || v.length < 6)
                  ? 'Password must be at least 6 characters'
                  : null,
            ),

            // Confirm password (register only)
            if (isRegister) ...[
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Confirm password',
                hint: '••••••••',
                controller: _confirm,
                obscureText: _obscure,
                prefixIcon: Icons.lock_outline_rounded,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                validator: (v) =>
                    v != _password.text ? 'Passwords do not match' : null,
              ),
            ],

            // Forgot password (sign-in only)
            if (!isRegister)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _forgotPassword(context),
                  child: const Text('Forgot password?'),
                ),
              ),

            const SizedBox(height: AppSpacing.sm),
            PrimaryButton(
              label: isRegister ? 'Create account' : 'Sign in',
              loading: auth.loading,
              onPressed: _submit,
            ),

            // Google (sign-in only)
            if (!isRegister) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('or', style: TextStyle(color: textTertiary)),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              PrimaryButton(
                label: 'Continue with Google',
                variant: ButtonVariant.outlined,
                icon: Icons.g_mobiledata_rounded,
                loading: auth.loading,
                onPressed: () =>
                    ref.read(authProvider.notifier).signInWithGoogle(),
              ),
            ],

            const SizedBox(height: AppSpacing.lg),

            // Toggle
            Center(
              child: GestureDetector(
                onTap: _toggle,
                child: Text.rich(
                  TextSpan(
                    text: isRegister
                        ? 'Already have an account?  '
                        : "New here?  ",
                    style: theme.textTheme.bodyMedium,
                    children: [
                      TextSpan(
                        text: isRegister ? 'Sign in' : 'Create an account',
                        style: TextStyle(
                          color: primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return Scaffold(
      body: Stack(
        children: [
          // Fixed brand gradient banner — sits behind the card, does not
          // change with theme (matches the drawer header / about hero
          // convention used elsewhere in the app).
          Container(
            height: context.height * 0.42,
            decoration: const BoxDecoration(gradient: AppColors.brandGradient),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    SizedBox(height: context.isMobile ? 24 : 48),
                    const AppLogo(size: 30, onLight: true),
                    const SizedBox(height: 6),
                    Text(
                      AppConstants.tagline,
                      style: TextStyle(
                        color: AppColors.secondary.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    card,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _forgotPassword(BuildContext context) {
    final emailCtrl = TextEditingController(text: _email.text.trim());
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                "Enter your email and we'll send a password reset link."),
            const SizedBox(height: 16),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.mail_outline_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final email = emailCtrl.text.trim();
              Navigator.pop(ctx);
              if (email.isEmpty) return;
              try {
                if (!AppConstants.useMockBackend) {
                  await fb.FirebaseAuth.instance
                      .sendPasswordResetEmail(email: email);
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password reset email sent.')),
                  );
                }
              } on fb.FirebaseAuthException catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(e.message ?? 'Could not send email.')),
                  );
                }
              }
            },
            child: const Text('Send link'),
          ),
        ],
      ),
    );
  }
}
