import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import 'app_user.dart';

abstract class AuthRepository {
  Future<AppUser?> currentUser();
  Future<AppUser> signInWithEmail(String email, String password);
  Future<AppUser> registerWithEmail(String email, String password, String? name);
  Future<AppUser> signInWithGoogle();
  Future<void> signOut();
}

/// Local mock — persists a fake session so the app can be demoed with no backend.
class MockAuthRepository implements AuthRepository {
  static const _key = 'careergpt_mock_user';

  @override
  Future<AppUser?> currentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    return AppUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<AppUser> signInWithEmail(String email, String password) async {
    await Future<void>.delayed(AppConstants.mockLatency);
    if (password.length < 6) throw Exception('Password must be at least 6 characters.');
    final user = AppUser(
      id: 'mock-${email.hashCode}',
      email: email,
      displayName: _nameFromEmail(email),
    );
    await _persist(user);
    return user;
  }

  @override
  Future<AppUser> registerWithEmail(
      String email, String password, String? name) async {
    await Future<void>.delayed(AppConstants.mockLatency);
    if (password.length < 6) throw Exception('Password must be at least 6 characters.');
    final user = AppUser(
      id: 'mock-${email.hashCode}',
      email: email,
      displayName: name?.trim().isNotEmpty == true ? name!.trim() : _nameFromEmail(email),
    );
    await _persist(user);
    return user;
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    await Future<void>.delayed(AppConstants.mockLatency);
    const user = AppUser(
      id: 'mock-google',
      email: 'alex.morgan@gmail.com',
      displayName: 'Alex Morgan',
    );
    await _persist(user);
    return user;
  }

  @override
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  Future<void> _persist(AppUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(user.toJson()));
  }

  String _nameFromEmail(String email) {
    final handle = email.split('@').first.replaceAll(RegExp(r'[._]'), ' ');
    return handle
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }
}

/// Real Firebase implementation.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository([fb.FirebaseAuth? auth])
      : _auth = auth ?? fb.FirebaseAuth.instance;

  final fb.FirebaseAuth _auth;

  @override
  Future<AppUser?> currentUser() async {
    final user = await _auth.authStateChanges().first;
    return _map(user);
  }

  @override
  Future<AppUser> signInWithEmail(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _map(cred.user)!;
    } on fb.FirebaseAuthException catch (e) {
      throw Exception(_friendly(e));
    }
  }

  /// ✅  FIX: explicit registration method — no accidental account creation on
  /// sign-in anymore. The login screen calls this when the user taps "Register".
  @override
  Future<AppUser> registerWithEmail(
      String email, String password, String? name) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Set display name right away so the dashboard greeting works.
      final displayName = name?.trim().isNotEmpty == true ? name!.trim() : null;
      if (displayName != null) {
        await cred.user?.updateDisplayName(displayName);
        // Reload to get the updated profile on the same User object.
        await cred.user?.reload();
      }
      // Re-read after reload.
      final updated = _auth.currentUser;
      return _map(updated ?? cred.user)!;
    } on fb.FirebaseAuthException catch (e) {
      throw Exception(_friendly(e));
    }
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    final isDesktop = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux);
    if (isDesktop) {
      throw Exception(
        'Google sign-in isn\'t available on desktop yet — please use email and password.',
      );
    }
    throw Exception(
      'Google sign-in isn\'t set up yet — please use email and password.',
    );
  }

  @override
  Future<void> signOut() => _auth.signOut();

  AppUser? _map(fb.User? u) => u == null
      ? null
      : AppUser(
          id: u.uid,
          email: u.email ?? '',
          displayName: u.displayName,
          photoUrl: u.photoURL,
        );

  String _friendly(fb.FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'That email address looks invalid.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'user-not-found':
        return 'No account found for that email. Please register first.';
      case 'weak-password':
        return 'Password is too weak (minimum 6 characters).';
      case 'email-already-in-use':
        return 'An account already exists for that email. Please sign in.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is disabled in the Firebase console.';
      case 'network-request-failed':
        return 'Network error — check your connection.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      default:
        return e.message ?? 'Authentication failed (${e.code}).';
    }
  }
}
