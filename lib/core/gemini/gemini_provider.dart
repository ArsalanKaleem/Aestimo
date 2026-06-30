import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings/settings_providers.dart';
import 'gemini_client.dart';

/// Singleton [GeminiClient] shared across all repositories. Rebuilt when the
/// user changes their API key in Settings.
final geminiClientProvider = Provider<GeminiClient>((ref) {
  final apiKey = ref.watch(geminiApiKeyProvider);
  return GeminiClient(apiKey: apiKey);
});
