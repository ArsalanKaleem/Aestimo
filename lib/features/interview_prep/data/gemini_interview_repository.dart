import 'dart:async';
import 'dart:convert';

import '../../../../core/gemini/gemini_client.dart';
import '../models/interview.dart';
import 'interview_repository.dart';

/// Live implementation of [InterviewRepository] backed by Gemini.
class GeminiInterviewRepository implements InterviewRepository {
  GeminiInterviewRepository({
    required GeminiClient client,
    required String resumeText,
  })  : _client = client,
        _resumeText = resumeText;

  final GeminiClient _client;
  final String _resumeText;

  List<String> _sessionQuestions = [];

  // ------------------------------------------------------------------ public

  @override
  Future<List<InterviewQuestion>> generateQuestions() async {
    final raw = await _client.generate(
      messages: [
        GeminiMessage(
          role: 'user',
          text: '''
Based on the resume below, generate 6 interview questions as a JSON array.
Each item must match this shape exactly (no markdown, no extra keys):
[
  {
    "category": "technical" | "behavioral" | "roleSpecific",
    "question": "...",
    "tip": "..."
  }
]
Include 2 technical, 2 behavioral, and 2 role-specific questions.
For each question include a short coaching tip (1-2 sentences).

RESUME:
$_resumeText
''',
        ),
      ],
      systemInstruction: 'You are an expert interview coach. '
          'Respond ONLY with the JSON array, no markdown fences.',
      temperature: 0.5,
      maxOutputTokens: 2048,
      jsonMode: true,
    );

    return _parseQuestions(raw);
  }

  @override
  Future<String> openingQuestion() async {
    if (_sessionQuestions.isEmpty) {
      await _loadSessionQuestions();
    }
    return _sessionQuestions.isNotEmpty
        ? _sessionQuestions.first
        : 'Tell me about yourself and your most relevant experience.';
  }

  @override
  Stream<String> feedback(String answer, {required int questionIndex}) async* {
    final question = questionIndex < _sessionQuestions.length
        ? _sessionQuestions[questionIndex]
        : 'the question';

    yield* _client.stream(
      messages: [
        GeminiMessage(
          role: 'user',
          text: '''
Interview question: "$question"

Candidate's answer: "$answer"

Provide concise, actionable feedback in markdown format:
- Start with one strength of the answer.
- Identify one specific improvement with an example.
- End with "Ready for the next question? 👇"

Keep it under 120 words.
''',
        ),
      ],
      systemInstruction: 'You are a supportive but rigorous interview coach. '
          'Be direct, specific, and constructive.',
      temperature: 0.6,
      maxOutputTokens: 300,
    );
  }

  @override
  String? nextQuestion(int questionIndex) {
    final next = questionIndex + 1;
    if (next >= _sessionQuestions.length) return null;
    return _sessionQuestions[next];
  }

  // ----------------------------------------------------------------- helpers

  Future<void> _loadSessionQuestions() async {
    final raw = await _client.generate(
      messages: [
        GeminiMessage(
          role: 'user',
          text: '''
Based on the resume below, generate 5 realistic interview questions for a
mock interview session. Return a JSON array of strings only.

RESUME:
$_resumeText
''',
        ),
      ],
      systemInstruction: 'Return ONLY a JSON array of 5 question strings. '
          'No markdown, no extra keys.',
      temperature: 0.5,
      maxOutputTokens: 800,
      jsonMode: true,
    );

    try {
      final clean = raw.replaceAll(RegExp(r'```json|```'), '').trim();
      final list = jsonDecode(clean) as List<dynamic>;
      _sessionQuestions = list.map((e) => e.toString()).toList();
    } catch (_) {
      _sessionQuestions = [
        'Tell me about yourself.',
        'What is your greatest professional achievement?',
        'Describe a technical challenge you overcame.',
        'Where do you see yourself in 5 years?',
        'Do you have any questions for us?',
      ];
    }
  }

  List<InterviewQuestion> _parseQuestions(String raw) {
    try {
      final clean = raw.replaceAll(RegExp(r'```json|```'), '').trim();
      final list = jsonDecode(clean) as List<dynamic>;
      return list.map((item) {
        final m = item as Map<String, dynamic>;
        return InterviewQuestion(
          category: _parseCategory(m['category']?.toString() ?? ''),
          question: m['question']?.toString() ?? '',
          tip: m['tip']?.toString() ?? '',
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to parse interview questions: $e');
    }
  }

  QuestionCategory _parseCategory(String raw) {
    switch (raw.toLowerCase()) {
      case 'technical':
        return QuestionCategory.technical;
      case 'behavioral':
        return QuestionCategory.behavioral;
      default:
        return QuestionCategory.roleSpecific;
    }
  }
}
