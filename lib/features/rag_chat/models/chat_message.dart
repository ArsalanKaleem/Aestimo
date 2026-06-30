import 'package:flutter/foundation.dart';

enum Role { user, assistant }

/// A retrieved resume passage surfaced for transparency ("Sources").
@immutable
class SourceSnippet {
  const SourceSnippet({
    required this.section,
    required this.text,
    required this.score,
    this.reason,
  });

  /// Resume section the chunk came from (e.g. "Experience · Acme Corp").
  final String section;
  final String text;

  /// Cosine similarity 0..1 from the vector store.
  final double score;

  /// Why this chunk was selected for the answer.
  final String? reason;
}

@immutable
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    this.sources = const [],
    this.streaming = false,
    this.error = false,
  });

  final String id;
  final Role role;
  final String content;
  final List<SourceSnippet> sources;
  final bool streaming;
  final bool error;

  bool get isUser => role == Role.user;

  ChatMessage copyWith({
    String? content,
    List<SourceSnippet>? sources,
    bool? streaming,
    bool? error,
  }) {
    return ChatMessage(
      id: id,
      role: role,
      content: content ?? this.content,
      sources: sources ?? this.sources,
      streaming: streaming ?? this.streaming,
      error: error ?? this.error,
    );
  }
}
