import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/chat_repository.dart';
import '../models/chat_message.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return MockChatRepository();
});

@immutable
class ChatState {
  const ChatState({this.messages = const [], this.isResponding = false});

  final List<ChatMessage> messages;
  final bool isResponding;

  bool get isEmpty => messages.isEmpty;

  ChatState copyWith({List<ChatMessage>? messages, bool? isResponding}) {
    return ChatState(
      messages: messages ?? this.messages,
      isResponding: isResponding ?? this.isResponding,
    );
  }
}

class ChatController extends StateNotifier<ChatState> {
  ChatController(this._repo) : super(const ChatState());

  final ChatRepository _repo;
  int _seq = 0;

  String _id() => 'm${_seq++}_${DateTime.now().microsecondsSinceEpoch}';

  Future<void> send(String text) async {
    final prompt = text.trim();
    if (prompt.isEmpty || state.isResponding) return;

    final userMsg = ChatMessage(id: _id(), role: Role.user, content: prompt);
    final assistantId = _id();
    final assistantMsg = ChatMessage(
      id: assistantId,
      role: Role.assistant,
      content: '',
      streaming: true,
    );

    state = state.copyWith(
      messages: [...state.messages, userMsg, assistantMsg],
      isResponding: true,
    );

    try {
      final buffer = StringBuffer();
      await for (final chunk in _repo.ask(prompt, history: state.messages)) {
        if (chunk.textDelta != null) buffer.write(chunk.textDelta);
        _updateAssistant(
          assistantId,
          content: buffer.toString(),
          sources: chunk.sources,
        );
      }
      _updateAssistant(assistantId, streaming: false);
    } catch (e) {
      _updateAssistant(
        assistantId,
        content: 'Sorry — I couldn’t generate a response. Please try again.',
        streaming: false,
        error: true,
      );
    } finally {
      state = state.copyWith(isResponding: false);
    }
  }

  void _updateAssistant(
    String id, {
    String? content,
    List<SourceSnippet>? sources,
    bool? streaming,
    bool? error,
  }) {
    state = state.copyWith(
      messages: [
        for (final m in state.messages)
          if (m.id == id)
            m.copyWith(
              content: content,
              sources: sources,
              streaming: streaming,
              error: error,
            )
          else
            m,
      ],
    );
  }

  void clear() => state = const ChatState();
}

final chatProvider =
    StateNotifierProvider<ChatController, ChatState>((ref) {
  return ChatController(ref.watch(chatRepositoryProvider));
});
