/// App-wide constants and runtime flags.
abstract class AppConstants {
  static const String appName = 'Aestimo';
  static const String tagline =
      'Turn your resume into your career copilot.';

  /// When true, the app runs entirely on local mock repositories — no
  /// FastAPI / Firebase / OpenAI keys required. Flip to false once the real
  /// backend is wired (see README "Going to prod").
  static const bool useMockBackend = false;

  /// Base URL of the FastAPI backend (used only when [useMockBackend] is off).
  static const String apiBaseUrl = 'http://localhost:8000';

  /// Simulated latency for mock calls so loading/streaming states are visible.
  static const Duration mockLatency = Duration(milliseconds: 650);
}

/// Suggested chat prompts surfaced as quick chips in the chat empty state.
abstract class SamplePrompts {
  static const List<String> items = [
    'What are my strongest skills?',
    'Summarize my resume.',
    'What roles fit my background?',
    'What projects should I highlight?',
    'How can I improve my resume?',
    'Generate interview questions for me.',
  ];
}