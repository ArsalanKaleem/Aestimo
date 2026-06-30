import 'dart:convert';

import '../../../../core/gemini/gemini_client.dart';
import '../models/insights.dart';
import '../providers/insights_provider.dart';

/// Generates [ResumeInsights] by asking Gemini to analyse the resume text.
class GeminiInsightsRepository implements InsightsRepository {
  GeminiInsightsRepository({
    required GeminiClient client,
    required String resumeText,
  })  : _client = client,
        _resumeText = resumeText;

  final GeminiClient _client;
  final String _resumeText;

  @override
  Future<ResumeInsights> generate() async {
    final raw = await _client.generate(
      messages: [
        GeminiMessage(
          role: 'user',
          text: '''
Analyse the following resume and return a JSON object with EXACTLY this shape
(no markdown fences, no extra keys):

{
  "technicalSkills": ["..."],
  "softSkills": ["..."],
  "missingSkills": ["..."],
  "yearsExperience": <number>,
  "expertiseAreas": ["..."],
  "strengths": ["..."],
  "advantages": ["..."],
  "improvements": [
    { "title": "...", "detail": "..." }
  ]
}

Rules:
• technicalSkills: up to 12 items (languages, frameworks, tools, platforms).
• softSkills: up to 6 items.
• missingSkills: up to 6 skills commonly expected in the candidate's target
  roles but absent from the resume.
• yearsExperience: total professional years as a decimal number.
• expertiseAreas: up to 5 domain areas.
• strengths: up to 5 standout achievements or capabilities.
• advantages: up to 4 competitive differentiators.
• improvements: 3 to 5 actionable suggestions, each with a short title and
  a one-to-two sentence detail.

RESUME:
$_resumeText
''',
        ),
      ],
      systemInstruction: 'You are a professional resume analyst. '
          'Respond ONLY with the JSON object described. No prose, no markdown.',
      temperature: 0.3,
      maxOutputTokens: 2048,
      jsonMode: true,
    );

    return _parse(raw);
  }

  // ----------------------------------------------------------------- helpers

  ResumeInsights _parse(String raw) {
    try {
      final json = _decodeObject(raw);

      List<String> strings(String key) =>
          (json[key] as List<dynamic>? ?? []).map((e) => e.toString()).toList();

      final improvements =
          (json['improvements'] as List<dynamic>? ?? []).map((item) {
        final m = item as Map<String, dynamic>;
        return (
          title: m['title']?.toString() ?? '',
          detail: m['detail']?.toString() ?? '',
        );
      }).toList();

      return ResumeInsights(
        technicalSkills: strings('technicalSkills'),
        softSkills: strings('softSkills'),
        missingSkills: strings('missingSkills'),
        yearsExperience:
            (json['yearsExperience'] as num? ?? 0).toDouble(),
        expertiseAreas: strings('expertiseAreas'),
        strengths: strings('strengths'),
        advantages: strings('advantages'),
        improvements: improvements,
      );
    } catch (e) {
      throw Exception('Failed to parse Gemini insights response: $e');
    }
  }

  /// Decodes a JSON object even if the model wrapped it in markdown fences or
  /// added stray prose around it (belt-and-braces alongside jsonMode).
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
