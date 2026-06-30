import 'package:flutter/foundation.dart';

enum QuestionCategory { technical, behavioral, roleSpecific }

extension QuestionCategoryX on QuestionCategory {
  String get label => switch (this) {
        QuestionCategory.technical => 'Technical',
        QuestionCategory.behavioral => 'Behavioral',
        QuestionCategory.roleSpecific => 'Role-specific',
      };
}

@immutable
class InterviewQuestion {
  const InterviewQuestion({
    required this.category,
    required this.question,
    required this.tip,
  });

  final QuestionCategory category;
  final String question;

  /// What a strong answer should cover.
  final String tip;
}

enum MockRole { interviewer, candidate }

@immutable
class MockTurn {
  const MockTurn({
    required this.id,
    required this.role,
    required this.content,
    this.isFeedback = false,
    this.streaming = false,
  });

  final String id;
  final MockRole role;
  final String content;

  /// True when this interviewer turn is coaching feedback rather than a
  /// fresh question.
  final bool isFeedback;
  final bool streaming;

  MockTurn copyWith({String? content, bool? streaming}) {
    return MockTurn(
      id: id,
      role: role,
      content: content ?? this.content,
      isFeedback: isFeedback,
      streaming: streaming ?? this.streaming,
    );
  }
}
