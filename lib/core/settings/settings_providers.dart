import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../gemini/gemini_config.dart';

const String _kApiKeyPref = 'gemini_api_key';

/// Holds the Gemini API key currently in use. Defaults to the built-in key
/// from [GeminiConfig], but the user can override it from the Settings screen.
/// The override is persisted with SharedPreferences and loaded on startup.
class ApiKeyController extends StateNotifier<String> {
  ApiKeyController() : super(GeminiConfig.apiKey) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_kApiKeyPref);
      if (saved != null && saved.trim().isNotEmpty) {
        state = saved.trim();
      }
    } catch (_) {
      // Ignore — fall back to the built-in default key.
    }
  }

  /// Whether a custom (user-supplied) key is currently active.
  bool get isCustom => state != GeminiConfig.apiKey;

  /// Saves [key]. An empty value clears the override and reverts to the
  /// built-in default key.
  Future<void> setKey(String key) async {
    final clean = key.trim();
    state = clean.isEmpty ? GeminiConfig.apiKey : clean;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (clean.isEmpty) {
        await prefs.remove(_kApiKeyPref);
      } else {
        await prefs.setString(_kApiKeyPref, clean);
      }
    } catch (_) {
      // Persisting failed (e.g. unsupported platform) — the in-memory value
      // still applies for this session.
    }
  }

  Future<void> reset() => setKey('');
}

final geminiApiKeyProvider =
    StateNotifierProvider<ApiKeyController, String>(
  (ref) => ApiKeyController(),
);
