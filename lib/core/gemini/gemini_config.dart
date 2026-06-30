abstract class GeminiConfig {
  /// The API key is injected at build/run time via --dart-define, so the
  /// secret never lives in source control. Provide it like:
  ///   flutter run --dart-define=GEMINI_API_KEY=your_key_here
  /// You can also set a default for local dev via settings, but never commit
  /// a real key here.
  static const String apiKey = String.fromEnvironment('GEMINI_API_KEY');

  /// Primary model — gemini-2.5-flash has the highest free-tier quota.
  /// Your key confirmed it has access to this model.
  static const String model = 'gemini-2.5-flash';

  static const String baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  /// Gemini 2.5 Flash has *thinking on by default*, and thinking tokens are
  /// deducted from maxOutputTokens — which makes the model return an empty
  /// 200 (finishReason MAX_TOKENS, no text) for tight token budgets. That was
  /// the "request succeeds but screen shows nothing" bug.
  ///
  /// 0 disables thinking entirely: replies are reliable, faster and cheaper.
  /// These tasks (JSON extraction, coaching, cover letters) don't need it.
  /// Set to -1 for dynamic thinking, or a positive number to allow a budget
  /// (and raise maxOutputTokens accordingly) if you ever want reasoning back.
  static const int thinkingBudget = 0;

  // ──────────────────────────────────────────────────────────────────────────
  // Concurrency / rate-limit controls
  //
  // The root cause of the 429 storms was that every repository fired its
  // request the instant it was built. On resume upload, several features
  // rebuild at once and used to hammer the API simultaneously.
  //
  // [maxConcurrentRequests] forces requests through a single in-flight slot,
  // and [minRequestSpacing] guarantees a gap between consecutive calls so we
  // stay under the free-tier requests-per-minute ceiling.
  // ──────────────────────────────────────────────────────────────────────────

  /// How many Gemini requests may be in flight at once. Keep at 1 on the free
  /// tier — it is the single most important fix for the "too many requests"
  /// problem.
  static const int maxConcurrentRequests = 1;

  /// Minimum delay between the *start* of one request and the next.
  /// Gemini 2.5 Flash free tier is ~10 requests/min, so 7s (~8.5 rpm) keeps a
  /// safety margin. The gate widens this automatically after a 429 and relaxes
  /// it again on success, so it self-tunes to the real limit.
  static const Duration minRequestSpacing = Duration(seconds: 7);

  /// Upper bound the adaptive gate may stretch spacing to after repeated 429s.
  static const Duration maxRequestSpacing = Duration(seconds: 30);

  /// Base wait after a 429 before retrying (seconds). Real wait grows with
  /// exponential backoff + jitter so simultaneous failures don't re-sync.
  static const int retryDelaySeconds = 20;

  /// Hard ceiling on a single backoff wait (seconds).
  static const int maxRetryDelaySeconds = 62;

  /// Max retries on quota errors before surfacing an error to the user.
  static const int maxRetries = 3;
}