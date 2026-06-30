import 'dart:convert';

import '../../../../core/gemini/gemini_client.dart';
import '../models/resume_score.dart';
import 'resume_score_repository.dart';

class GeminiResumeScoreRepository implements ResumeScoreRepository {
  GeminiResumeScoreRepository({
    required GeminiClient client,
    required String resumeText,
  })  : _client = client,
        _resumeText = resumeText;

  final GeminiClient _client;
  final String _resumeText;

  @override
  Future<ResumeScore> score() async {
    final raw = await _client.generate(
      messages: [
        GeminiMessage(
          role: 'user',
          text: '''
Analyse the following resume for ATS compatibility and overall quality.
Return a JSON object with EXACTLY this shape (no markdown fences, no extra keys):

{
  "overallScore": <integer 0-100>,
  "categories": [
    { "name": "Contact & Header",    "score": <0-10>, "maxScore": 10, "feedback": "..." },
    { "name": "Work Experience",     "score": <0-25>, "maxScore": 25, "feedback": "..." },
    { "name": "Skills & Keywords",   "score": <0-25>, "maxScore": 25, "feedback": "..." },
    { "name": "Education",           "score": <0-15>, "maxScore": 15, "feedback": "..." },
    { "name": "Formatting & Length", "score": <0-15>, "maxScore": 15, "feedback": "..." },
    { "name": "Achievements",        "score": <0-10>, "maxScore": 10, "feedback": "..." }
  ],
  "topStrengths":     ["...", "...", "..."],
  "criticalFixes":    ["...", "...", "..."],
  "atsKeywords":      ["...", "...", "..."],
  "missingKeywords":  ["...", "...", "..."]
}

Rules:
• overallScore: weighted composite of all category scores (sum of scores out of total max).
• Each category feedback: 1-2 actionable sentences.
• topStrengths: 3-5 clear strengths of this resume.
• criticalFixes: 3-5 specific, actionable fixes to improve the score.
• atsKeywords: up to 10 ATS-friendly keywords already present.
• missingKeywords: up to 8 important keywords absent from this resume for typical roles.

RESUME:
$_resumeText
''',
        ),
      ],
      systemInstruction:
          'You are a senior ATS resume evaluator and career coach. '
          'Respond ONLY with the JSON object described. No prose, no markdown.',
      temperature: 0.2,
      maxOutputTokens: 2048,
      jsonMode: true,
    );

    return _parse(raw);
  }

  ResumeScore _parse(String raw) {
    try {
      final json = _decodeObject(raw);

      List<String> strings(String key) =>
          (json[key] as List<dynamic>? ?? []).map((e) => e.toString()).toList();

      final cats = (json['categories'] as List<dynamic>? ?? []).map((item) {
        final m = item as Map<String, dynamic>;
        return ScoreCategory(
          name: m['name']?.toString() ?? '',
          score: (m['score'] as num? ?? 0).toInt(),
          maxScore: (m['maxScore'] as num? ?? 10).toInt(),
          feedback: m['feedback']?.toString() ?? '',
        );
      }).toList();

      return ResumeScore(
        overallScore: (json['overallScore'] as num? ?? 0).toInt(),
        categories: cats,
        topStrengths: strings('topStrengths'),
        criticalFixes: strings('criticalFixes'),
        atsKeywords: strings('atsKeywords'),
        missingKeywords: strings('missingKeywords'),
      );
    } catch (e) {
      throw Exception('Failed to parse resume score response: $e');
    }
  }

  Map<String, dynamic> _decodeObject(String raw) {
    final clean = raw.replaceAll(RegExp(r'```json|```'), '').trim();
    try {
      return jsonDecode(clean) as Map<String, dynamic>;
    } catch (_) {
      final start = clean.indexOf('{');
      final end = clean.lastIndexOf('}');
      if (start != -1 && end > start) {
        return jsonDecode(clean.substring(start, end + 1))
            as Map<String, dynamic>;
      }
      rethrow;
    }
  }
}
