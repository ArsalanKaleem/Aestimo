import '../../../../core/gemini/gemini_client.dart';
import '../models/cover_letter.dart';
import 'cover_letter_repository.dart';

/// Streams a tailored cover letter from Gemini, grounded in the resume.
class GeminiCoverLetterRepository implements CoverLetterRepository {
  GeminiCoverLetterRepository({
    required GeminiClient client,
    required String resumeText,
  })  : _client = client,
        _resumeText = resumeText;

  final GeminiClient _client;
  final String _resumeText;

  @override
  Stream<String> generate(CoverLetterRequest request) async* {
    final prompt = _buildPrompt(request);

    yield* _client.stream(
      messages: [GeminiMessage(role: 'user', text: prompt)],
      systemInstruction: '''
You are an expert career coach writing a compelling cover letter.
Write in first person, professional but warm tone.
Ground every claim in the candidate's actual resume.
Do NOT add a subject line or [YOUR NAME] placeholders — end with "Sincerely,"
followed by a blank line for the candidate to fill in their name.
Output the letter body only, no preamble.
''',
      temperature: 0.75,
      maxOutputTokens: 800,
    );
  }

  // ----------------------------------------------------------------- helpers

  String _buildPrompt(CoverLetterRequest r) {
    final parts = <String>[
      'Write a cover letter for this role:',
      'Job title: ${r.jobTitle}',
      'Company: ${r.company}',
    ];
    if (r.jobDescription.trim().isNotEmpty) {
      parts.add('Job description:\n${r.jobDescription}');
    }
    parts.add('\nCandidate resume:\n$_resumeText');
    return parts.join('\n');
  }
}
