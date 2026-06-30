import 'dart:async';

import '../../../../core/gemini/gemini_client.dart';
import '/features/rag_chat/models/chat_message.dart';
import 'chat_repository.dart';

/// Live implementation of [ChatRepository] backed by Google Gemini.
///
/// Because Aestimo is a RAG app, the "retrieval" step is approximated here
/// by including the full resume text in the system prompt. When you add a real
/// vector store (ChromaDB / Vertex AI Search) you only need to replace
/// [_buildSystem] — the rest stays the same.
class GeminiChatRepository implements ChatRepository {
  GeminiChatRepository({
    required GeminiClient client,
    required String resumeText,
  })  : _client = client,
        _resumeText = resumeText;

  final GeminiClient _client;
  final String _resumeText;

  static const _systemTemplate = '''
You are Aestimo, an AI career coach. You have been given the user's resume
below. Answer every question by grounding your response in the resume content.
Be specific, concise, and actionable. Use markdown for structure where helpful.

--- RESUME START ---
{RESUME}
--- RESUME END ---
''';

  @override
  Stream<ChatChunk> ask(
    String prompt, {
    List<ChatMessage> history = const [],
  }) async* {
    final system = _buildSystem();
    final messages = [
      ..._historyToGemini(history),
      GeminiMessage(role: 'user', text: prompt),
    ];

    final buffer = StringBuffer();
    await for (final delta in _client.stream(
      messages: messages,
      systemInstruction: system,
      temperature: 0.6,
      maxOutputTokens: 1024,
    )) {
      buffer.write(delta);
      yield ChatChunk(textDelta: delta);
    }

    // Emit stub sources (replace with real retrieved chunks when you add RAG).
    yield ChatChunk(
      sources: [
        const SourceSnippet(
          section: 'Resume (full)',
          text: 'Answer grounded in your uploaded resume.',
          score: 1.0,
          reason: 'Entire resume provided as context to the model.',
        ),
      ],
    );
  }

  // ----------------------------------------------------------------- helpers

  String _buildSystem() =>
      _systemTemplate.replaceFirst('{RESUME}', _resumeText);

  List<GeminiMessage> _historyToGemini(List<ChatMessage> history) {
    return history.map((m) {
      return GeminiMessage(
        role: m.role == Role.user ? 'user' : 'model',
        text: m.content,
      );
    }).toList();
  }
}
