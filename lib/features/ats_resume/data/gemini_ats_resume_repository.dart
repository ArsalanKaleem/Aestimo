import 'dart:convert';

import '../../../../core/gemini/gemini_client.dart';
import '../models/ats_resume.dart';
import 'ats_resume_repository.dart';

class GeminiAtsResumeRepository implements AtsResumeRepository {
  GeminiAtsResumeRepository({
    required GeminiClient client,
    required String resumeText,
  })  : _client = client,
        _resumeText = resumeText;

  final GeminiClient _client;
  final String _resumeText;

  @override
  Future<AtsResume> generate({
    String? jobTitle,
    String? jobDescription,
  }) async {
    final targetContext = jobTitle != null || jobDescription != null
        ? '''
Target job title: ${jobTitle ?? 'Not specified'}
Job description:
${jobDescription ?? 'Not specified'}
'''
        : 'Optimise for general software/tech roles.';

    final raw = await _client.generate(
      messages: [
        GeminiMessage(
          role: 'user',
          text: '''
Rewrite and optimise the following resume to be fully ATS-compatible.
Return a JSON object with EXACTLY this shape (no markdown fences, no extra keys):

{
  "name":        "<full name>",
  "contactLine": "<email> | <phone> | <city, country> | <linkedin url>",
  "summary":     "<3-4 sentence professional summary packed with keywords>",
  "sections": [
    { "heading": "WORK EXPERIENCE", "content": "<formatted experience>"},
    { "heading": "EDUCATION",       "content": "<formatted education>"},
    { "heading": "SKILLS",          "content": "<formatted skills>"},
    { "heading": "PROJECTS",        "content": "<formatted projects if present>"},
    { "heading": "CERTIFICATIONS",  "content": "<formatted certs if present>"}
  ],
  "rawText": "<complete ATS-optimised resume as plain text>"
}

ATS Optimisation Rules:
• Use standard section headings in ALL CAPS (WORK EXPERIENCE, EDUCATION, SKILLS, etc).
• Quantify every achievement — add realistic metrics if exact figures are absent.
• Start each bullet point with a strong action verb (Led, Built, Reduced, Improved…).
• Weave relevant keywords naturally from the target role throughout.
• Remove all tables, columns, graphics, headers/footers, special characters.
• Keep formatting to plain text with clear line breaks — ATS-safe.
• Professional summary must include the target job title and core tech stack.
• Skills section: list as comma-separated items grouped by category.
• Dates: MM/YYYY – MM/YYYY format.
• Remove any "References available on request" line.
• rawText: a clean, complete, copy-pasteable plain-text version of the whole resume.

$targetContext

ORIGINAL RESUME:
$_resumeText
''',
        ),
      ],
      systemInstruction:
          'You are an expert ATS resume writer and recruiter. '
          'Respond ONLY with the JSON object described. No prose, no markdown.',
      temperature: 0.4,
      maxOutputTokens: 4096,
      jsonMode: true,
    );

    return _parse(raw);
  }

  AtsResume _parse(String raw) {
    try {
      final json = _decodeObject(raw);

      final sections = (json['sections'] as List<dynamic>? ?? []).map((item) {
        final m = item as Map<String, dynamic>;
        return AtsResumeSection(
          heading: m['heading']?.toString() ?? '',
          content: m['content']?.toString() ?? '',
        );
      }).where((s) => s.heading.isNotEmpty && s.content.trim().isNotEmpty).toList();

      return AtsResume(
        name: json['name']?.toString() ?? '',
        contactLine: json['contactLine']?.toString() ?? '',
        summary: json['summary']?.toString() ?? '',
        sections: sections,
        rawText: json['rawText']?.toString() ?? '',
        generatedAt: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Failed to parse ATS resume response: $e');
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
