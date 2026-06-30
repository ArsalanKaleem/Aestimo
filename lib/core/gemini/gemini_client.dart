import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'gemini_config.dart';

class GeminiClient {
  GeminiClient({http.Client? httpClient, String? apiKey})
      : _http = httpClient ?? http.Client(),
        _apiKey = (apiKey != null && apiKey.trim().isNotEmpty)
            ? apiKey.trim()
            : GeminiConfig.apiKey;

  final http.Client _http;
  final String _apiKey;

  /// Shared, app-wide gate. Because [GeminiClient] is a singleton (see
  /// gemini_provider.dart), every repository funnels through this one gate —
  /// which is exactly what stops the simultaneous-request storms.
  static final _RequestGate _gate = _RequestGate(
    maxConcurrent: GeminiConfig.maxConcurrentRequests,
    minSpacing: GeminiConfig.minRequestSpacing,
    maxSpacing: GeminiConfig.maxRequestSpacing,
  );

  // ──────────────────────────────────────────────────────────────────────────
  // Text-only generation
  // ──────────────────────────────────────────────────────────────────────────

  Future<String> generate({
    required List<GeminiMessage> messages,
    String? systemInstruction,
    double temperature = 0.7,
    int maxOutputTokens = 2048,
    bool jsonMode = false,
  }) {
    // run() holds the single slot for the whole request *including* its
    // retries, so a 429 backoff blocks the queue instead of letting the next
    // request pile on top of the rate limit.
    return _gate.run(() => _withRetry(() async {
          final uri = _uri('${GeminiConfig.model}:generateContent');
          final body = _buildBody(
            messages: messages,
            system: systemInstruction,
            temperature: temperature,
            maxOutputTokens: maxOutputTokens,
            jsonMode: jsonMode,
          );

          debugPrint('[Gemini] POST ${GeminiConfig.model}');
          final resp = await _http.post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          );
          debugPrint('[Gemini] ${resp.statusCode}');

          if (resp.statusCode == 429) {
            throw GeminiQuotaException(_retryAfterSeconds(resp.headers));
          }
          _checkStatus(resp.statusCode, resp.body);
          return _extractTextOrThrow(
              jsonDecode(resp.body) as Map<String, dynamic>);
        }));
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Document (PDF / image) generation — sends file as inline base64 data.
  // Gemini 2.5 Flash natively reads PDFs, so no client-side extraction needed.
  // ──────────────────────────────────────────────────────────────────────────

  Future<String> generateWithDocument({
    required String base64Data,
    required String mimeType, // e.g. 'application/pdf'
    required String prompt,
    String? systemInstruction,
    double temperature = 0.0,
    int maxOutputTokens = 8192,
    bool jsonMode = false,
  }) {
    return _gate.run(() => _withRetry(() async {
          final uri = _uri('${GeminiConfig.model}:generateContent');

          final generationConfig = <String, dynamic>{
            'temperature': temperature,
            'maxOutputTokens': maxOutputTokens,
            'thinkingConfig': {'thinkingBudget': GeminiConfig.thinkingBudget},
          };
          if (jsonMode) {
            generationConfig['responseMimeType'] = 'application/json';
          }

          final body = <String, dynamic>{
            'contents': [
              {
                'role': 'user',
                'parts': [
                  {
                    'inline_data': {
                      'mime_type': mimeType,
                      'data': base64Data,
                    }
                  },
                  {'text': prompt},
                ],
              }
            ],
            'generationConfig': generationConfig,
          };

          if (systemInstruction != null && systemInstruction.isNotEmpty) {
            body['systemInstruction'] = {
              'parts': [
                {'text': systemInstruction}
              ],
            };
          }

          debugPrint('[Gemini] POST ${GeminiConfig.model} (document)');
          final resp = await _http.post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          );
          debugPrint('[Gemini] ${resp.statusCode}');

          if (resp.statusCode == 429) {
            throw GeminiQuotaException(_retryAfterSeconds(resp.headers));
          }
          _checkStatus(resp.statusCode, resp.body);
          return _extractTextOrThrow(
              jsonDecode(resp.body) as Map<String, dynamic>);
        }));
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Streaming generation (text only)
  // ──────────────────────────────────────────────────────────────────────────

  Stream<String> stream({
    required List<GeminiMessage> messages,
    String? systemInstruction,
    double temperature = 0.7,
    int maxOutputTokens = 2048,
  }) {
    // The stream holds the slot until it finishes, so a chat stream can't run
    // concurrently with other Gemini calls.
    return _gate.runStream(() => _streamInternal(
          messages: messages,
          systemInstruction: systemInstruction,
          temperature: temperature,
          maxOutputTokens: maxOutputTokens,
        ));
  }

  Stream<String> _streamInternal({
    required List<GeminiMessage> messages,
    String? systemInstruction,
    required double temperature,
    required int maxOutputTokens,
  }) async* {
    final body = _buildBody(
      messages: messages,
      system: systemInstruction,
      temperature: temperature,
      maxOutputTokens: maxOutputTokens,
    );
    final uri = _uri(
      '${GeminiConfig.model}:streamGenerateContent',
      sse: true,
    );

    debugPrint('[Gemini] STREAM ${GeminiConfig.model}');

    int retries = 0;
    while (true) {
      final request = http.Request('POST', uri)
        ..headers['Content-Type'] = 'application/json'
        ..body = jsonEncode(body);

      final response = await _http.send(request);
      debugPrint('[Gemini] stream ${response.statusCode}');

      if (response.statusCode == 429) {
        await response.stream.drain<void>();
        _gate.penalize();
        if (retries < GeminiConfig.maxRetries) {
          final wait = _backoffSeconds(
            retries,
            _retryAfterSeconds(response.headers),
          );
          retries++;
          debugPrint('[Gemini] stream quota hit, waiting ${wait}s...');
          await Future<void>.delayed(Duration(seconds: wait));
          continue;
        }
        throw GeminiException(
          'Rate limit reached. Please wait a moment and try again.',
        );
      }

      if (response.statusCode != 200) {
        final bodyStr = await response.stream.bytesToString();
        throw GeminiException(_parseError(response.statusCode, bodyStr));
      }

      await for (final line in response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
        if (!line.startsWith('data: ')) continue;
        final raw = line.substring(6).trim();
        if (raw.isEmpty || raw == '[DONE]') continue;
        try {
          final json = jsonDecode(raw) as Map<String, dynamic>;
          final delta = _extractText(json);
          if (delta.isNotEmpty) yield delta;
        } catch (_) {}
      }
      _gate.reward();
      break;
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Private helpers
  // ──────────────────────────────────────────────────────────────────────────

  Uri _uri(String action, {bool sse = false}) {
    final base = '${GeminiConfig.baseUrl}/$action?key=$_apiKey';
    return Uri.parse(sse ? '$base&alt=sse' : base);
  }

  Map<String, dynamic> _buildBody({
    required List<GeminiMessage> messages,
    String? system,
    required double temperature,
    required int maxOutputTokens,
    bool jsonMode = false,
  }) {
    final generationConfig = <String, dynamic>{
      'temperature': temperature,
      'maxOutputTokens': maxOutputTokens,
      // Disable thinking so reasoning tokens don't eat the output budget and
      // leave us with an empty 200. See GeminiConfig.thinkingBudget.
      'thinkingConfig': {'thinkingBudget': GeminiConfig.thinkingBudget},
    };
    if (jsonMode) {
      generationConfig['responseMimeType'] = 'application/json';
    }
    final body = <String, dynamic>{
      'contents': messages.map((m) => m.toJson()).toList(),
      'generationConfig': generationConfig,
    };
    if (system != null && system.isNotEmpty) {
      body['systemInstruction'] = {
        'parts': [
          {'text': system}
        ],
      };
    }
    return body;
  }

  /// Like [_extractText] but turns the silent "empty 200" cases into a clear,
  /// actionable error instead of letting an empty string reach a JSON parser.
  String _extractTextOrThrow(Map<String, dynamic> json) {
    final feedback = json['promptFeedback'] as Map<String, dynamic>?;
    final blockReason = feedback?['blockReason']?.toString();
    if (blockReason != null) {
      throw GeminiException(
        'The request was blocked by safety filters ($blockReason).',
      );
    }

    final candidates = json['candidates'] as List<dynamic>? ?? [];
    if (candidates.isEmpty) {
      throw GeminiException('The model returned no content. Please try again.');
    }

    final text = _extractText(json);
    if (text.trim().isEmpty) {
      final finish = (candidates.first as Map<String, dynamic>)['finishReason']
          ?.toString();
      if (finish == 'MAX_TOKENS') {
        throw GeminiException(
          'The response was cut off before any text was produced. '
          'Try again or raise maxOutputTokens.',
        );
      }
      if (finish == 'SAFETY' || finish == 'RECITATION') {
        throw GeminiException('The response was withheld ($finish).');
      }
      throw GeminiException('The model returned an empty response.');
    }
    return text;
  }

  String _extractText(Map<String, dynamic> json) {
    final candidates = json['candidates'] as List<dynamic>? ?? [];
    if (candidates.isEmpty) return '';
    final content = candidates.first['content'] as Map<String, dynamic>? ?? {};
    final parts = content['parts'] as List<dynamic>? ?? [];
    return parts
        .map((p) => (p as Map<String, dynamic>)['text']?.toString() ?? '')
        .join();
  }

  Future<T> _withRetry<T>(Future<T> Function() fn) async {
    int retries = 0;
    while (true) {
      try {
        final result = await fn();
        _gate.reward(); // success → let spacing relax back toward the base
        return result;
      } on GeminiQuotaException catch (e) {
        _gate.penalize(); // 429 → widen spacing for every future request
        if (retries < GeminiConfig.maxRetries) {
          final wait = _backoffSeconds(retries, e.retryAfterSeconds);
          retries++;
          debugPrint('[Gemini] quota hit, retrying in ${wait}s...');
          await Future<void>.delayed(Duration(seconds: wait));
          continue;
        }
        throw GeminiException(
          'Rate limit reached. Please wait a moment and try again.',
        );
      }
    }
  }

  static final Random _rng = Random();

  /// Exponential backoff with jitter, honoring a server Retry-After when given.
  /// attempt 0 → ~retryDelay, attempt 1 → ~2x, attempt 2 → ~4x … capped.
  int _backoffSeconds(int attempt, int? retryAfter) {
    if (retryAfter != null && retryAfter > 0) {
      return min(retryAfter, GeminiConfig.maxRetryDelaySeconds);
    }
    final base = GeminiConfig.retryDelaySeconds * pow(2, attempt).toInt();
    final jitter = _rng.nextInt(4); // 0–3s so retries don't re-synchronize
    return min(base + jitter, GeminiConfig.maxRetryDelaySeconds);
  }

  int? _retryAfterSeconds(Map<String, String> headers) {
    final val = headers['retry-after'] ?? headers['Retry-After'];
    if (val == null) return null;
    return int.tryParse(val);
  }

  void _checkStatus(int code, String body) {
    if (code == 200) return;
    throw GeminiException(_parseError(code, body));
  }

  String _parseError(int code, String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final error = json['error'] as Map<String, dynamic>?;
      final msg = error?['message']?.toString();
      if (msg != null) {
        if (msg.contains('quota') || msg.contains('Quota')) {
          return 'Rate limit reached. Please wait a minute and try again.';
        }
        return 'Gemini error: $msg';
      }
    } catch (_) {}
    return 'Gemini request failed ($code).';
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Request gate: serializes Gemini calls and spaces them out.
//
// Two guarantees:
//   1. At most [maxConcurrent] requests run at once (1 on the free tier).
//   2. Consecutive requests start at least [minSpacing] apart.
//
// Both one-shot futures and long-lived streams pass through the same gate, so
// nothing can sneak a concurrent call in while a chat stream is open.
// ────────────────────────────────────────────────────────────────────────────
class _RequestGate {
  _RequestGate({
    required this.maxConcurrent,
    required this.minSpacing,
    required this.maxSpacing,
  }) : _spacing = minSpacing;

  final int maxConcurrent;
  final Duration minSpacing;
  final Duration maxSpacing;

  /// Current spacing — grows after a 429, relaxes after sustained success.
  Duration _spacing;

  int _active = 0;
  DateTime _lastStart = DateTime.fromMillisecondsSinceEpoch(0);
  final Queue<Completer<void>> _waiters = Queue<Completer<void>>();

  /// A 429 was seen — widen spacing by 50% (capped) so the whole pipeline
  /// slows down and stops hammering the limit.
  void penalize() {
    final widened = (_spacing.inMilliseconds * 1.5).round();
    _spacing = Duration(
      milliseconds: widened.clamp(
        minSpacing.inMilliseconds,
        maxSpacing.inMilliseconds,
      ),
    );
    debugPrint('[Gemini] gate spacing -> ${_spacing.inMilliseconds}ms');
  }

  /// A request succeeded — gently relax spacing back toward the base so we
  /// don't stay slow forever once the burst is over.
  void reward() {
    if (_spacing <= minSpacing) return;
    final relaxed = _spacing.inMilliseconds - 1000;
    _spacing = Duration(
      milliseconds: relaxed < minSpacing.inMilliseconds
          ? minSpacing.inMilliseconds
          : relaxed,
    );
  }

  Future<T> run<T>(Future<T> Function() task) async {
    await _acquire();
    try {
      return await task();
    } finally {
      _release();
    }
  }

  Stream<T> runStream<T>(Stream<T> Function() task) async* {
    await _acquire();
    try {
      yield* task();
    } finally {
      _release();
    }
  }

  Future<void> _acquire() async {
    // Wait for a free slot.
    if (_active >= maxConcurrent) {
      final c = Completer<void>();
      _waiters.add(c);
      await c.future;
    }
    _active++;

    // Enforce the current (adaptive) spacing between request *starts*.
    final since = DateTime.now().difference(_lastStart);
    if (since < _spacing) {
      await Future<void>.delayed(_spacing - since);
    }
    _lastStart = DateTime.now();
  }

  void _release() {
    _active--;
    if (_waiters.isNotEmpty) {
      _waiters.removeFirst().complete();
    }
  }
}

class GeminiMessage {
  const GeminiMessage({required this.role, required this.text});
  final String role;
  final String text;

  Map<String, dynamic> toJson() => {
        'role': role,
        'parts': [
          {'text': text}
        ],
      };
}

class GeminiException implements Exception {
  GeminiException(this.message);
  final String message;
  @override
  String toString() => message;
}

class GeminiQuotaException implements Exception {
  GeminiQuotaException(this.retryAfterSeconds);
  final int? retryAfterSeconds;
}
