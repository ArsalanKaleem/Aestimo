import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../data/app_user.dart';
import '../data/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AppConstants.useMockBackend
      ? MockAuthRepository()
      : FirebaseAuthRepository();
});

enum AuthStatus { unknown, authenticated, unauthenticated }

@immutable
class AuthState {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.loading = false,
    this.error,
  });

  final AuthStatus status;
  final AppUser? user;
  final bool loading;
  final String? error;

  AuthState copyWith({
    AuthStatus? status,
    AppUser? user,
    bool? loading,
    String? error,
    bool clearError = false,
    bool clearUser = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repo) : super(const AuthState()) {
    _restore();
  }

  final AuthRepository _repo;

  Future<void> _restore() async {
    try {
      final user =
          await _repo.currentUser().timeout(const Duration(seconds: 4));
      state = state.copyWith(
        status: user == null
            ? AuthStatus.unauthenticated
            : AuthStatus.authenticated,
        user: user,
      );
    } catch (_) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final user = await _repo.signInWithEmail(email.trim(), password);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        loading: false,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: _msg(e));
    }
  }

  /// ✅  New: called by the register form.
  Future<void> registerWithEmail(
      String email, String password, String name) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final user =
          await _repo.registerWithEmail(email.trim(), password, name.trim());
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        loading: false,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: _msg(e));
    }
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final user = await _repo.signInWithGoogle();
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        loading: false,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: _msg(e));
    }
  }

  Future<void> signOut() async {
    await _repo.signOut();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void clearError() => state = state.copyWith(clearError: true);

  String _msg(Object e) => e.toString().replaceFirst('Exception: ', '').trim();
}

final authProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});
