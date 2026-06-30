import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/about/presentation/about_screen.dart';
import '../../features/resume_score/presentation/resume_score_screen.dart';
import '../../features/ats_resume/presentation/ats_resume_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/cover_letter/presentation/cover_letter_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/insights/presentation/insights_screen.dart';
import '../../features/job_match/presentation/job_match_screen.dart';
import '../../features/interview_prep/presentation/interview_prep_screen.dart';
import '../../features/rag_chat/presentation/chat_screen.dart';
import '../../features/upload_resume/presentation/upload_resume_screen.dart';
import '../../shared/widgets/app_shell.dart';
import 'app_routes.dart';

final _rootKey = GlobalKey<NavigatorState>();
final _shellKey = GlobalKey<NavigatorState>();

/// App router.
/// Listens to [authProvider] and triggers a refresh on every auth state change.
/// This ensures reliable redirection on all platforms, including Windows,
/// even if the initial auth check completes before the router is mounted.
final routerProvider = Provider<GoRouter>((ref) {
  // Use a local notifier to trigger GoRouter refreshes.
  final notifier = ValueNotifier<AuthStatus>(AuthStatus.unknown);

  // Sync the notifier with the actual auth status from authProvider.
  ref.listen(authProvider, (previous, next) {
    if (previous?.status != next.status) {
      notifier.value = next.status;
    }
  });

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: notifier,
    redirect: (context, state) {
      final status = ref.read(authProvider).status;
      final loc = state.matchedLocation;

      // While status is unknown, stay on splash or redirect to it.
      if (status == AuthStatus.unknown) {
        return loc == AppRoutes.splash ? null : AppRoutes.splash;
      }

      final loggedIn = status == AuthStatus.authenticated;

      // If not logged in, the only allowed page is login — including kicking
      // the user off the splash screen once status resolves.
      if (!loggedIn) {
        return loc == AppRoutes.login ? null : AppRoutes.login;
      }

      // If logged in and still on splash or login, move to dashboard.
      if (loc == AppRoutes.login || loc == AppRoutes.splash) {
        return AppRoutes.dashboard;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const LoginScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellKey,
        builder: (_, __, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            pageBuilder: (_, s) => _fade(s, const DashboardScreen()),
          ),
          GoRoute(
            path: AppRoutes.upload,
            pageBuilder: (_, s) => _fade(s, const UploadResumeScreen()),
          ),
          GoRoute(
            path: AppRoutes.insights,
            pageBuilder: (_, s) => _fade(s, const InsightsScreen()),
          ),
          GoRoute(
            path: AppRoutes.chat,
            pageBuilder: (_, s) => _fade(s, const ChatScreen()),
          ),
          GoRoute(
            path: AppRoutes.interview,
            pageBuilder: (_, s) => _fade(s, const InterviewPrepScreen()),
          ),
          GoRoute(
            path: AppRoutes.coverLetter,
            pageBuilder: (_, s) => _fade(s, const CoverLetterScreen()),
          ),
          GoRoute(
            path: AppRoutes.jobs,
            pageBuilder: (_, s) => _fade(s, const JobMatchScreen()),
          ),
          GoRoute(
            path: AppRoutes.resumeScore,
            pageBuilder: (_, s) => _fade(s, const ResumeScoreScreen()),
          ),
          GoRoute(
            path: AppRoutes.atsResume,
            pageBuilder: (_, s) => _fade(s, const AtsResumeScreen()),
          ),
          GoRoute(
            path: AppRoutes.about,
            pageBuilder: (_, s) => _fade(s, const AboutScreen()),
          ),
          GoRoute(
            path: AppRoutes.settings,
            pageBuilder: (_, s) => _fade(s, const SettingsScreen()),
          ),
        ],
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(child: Text('Route not found: ${state.uri}')),
    ),
  );
});

CustomTransitionPage _fade(GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (_, animation, __, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.012),
            end: Offset.zero,
          ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOut)),
          child: child,
        ),
      );
    },
  );
}