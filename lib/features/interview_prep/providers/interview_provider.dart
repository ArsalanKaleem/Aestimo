import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../upload_resume/providers/resume_provider.dart';
import '../data/interview_repository.dart';
import '../models/interview.dart';

final interviewRepositoryProvider = Provider<InterviewRepository>((ref) {
  return MockInterviewRepository();
});

/// Generated once per resume and cached for the session (see insightsProvider
/// for the rationale). Re-runs on a new upload or on ref.invalidate.
final interviewQuestionsProvider =
    FutureProvider<List<InterviewQuestion>>((ref) async {
  final hasResume = ref.watch(resumeProvider.select((s) => s.hasResume));
  if (!hasResume) {
    throw const _NoResumeException();
  }
  return ref.watch(interviewRepositoryProvider).generateQuestions();
});

class _NoResumeException implements Exception {
  const _NoResumeException();
}

bool isNoResume(Object error) => error is _NoResumeException;

// ---------------------------------------------------------------------------
// Mock interview session
// ---------------------------------------------------------------------------

@immutable
class MockInterviewState {
  const MockInterviewState({
    this.turns = const [],
    this.questionIndex = 0,
    this.isResponding = false,
    this.started = false,
    this.finished = false,
  });

  final List<MockTurn> turns;
  final int questionIndex;
  final bool isResponding;
  final bool started;
  final bool finished;

  /// Candidate can type only when it's their turn (last turn is a question).
  bool get awaitingAnswer =>
      started &&
      !finished &&
      !isResponding &&
      turns.isNotEmpty &&
      turns.last.role == MockRole.interviewer &&
      !turns.last.isFeedback;

  MockInterviewState copyWith({
    List<MockTurn>? turns,
    int? questionIndex,
    bool? isResponding,
    bool? started,
    bool? finished,
  }) {
    return MockInterviewState(
      turns: turns ?? this.turns,
      questionIndex: questionIndex ?? this.questionIndex,
      isResponding: isResponding ?? this.isResponding,
      started: started ?? this.started,
      finished: finished ?? this.finished,
    );
  }
}

class MockInterviewController extends StateNotifier<MockInterviewState> {
  MockInterviewController(this._repo) : super(const MockInterviewState());

  final InterviewRepository _repo;
  int _seq = 0;

  String _id() => 't${_seq++}_${DateTime.now().microsecondsSinceEpoch}';

  Future<void> start() async {
    if (state.isResponding) return;
    state = const MockInterviewState(started: true, isResponding: true);
    final q = await _repo.openingQuestion();
    state = state.copyWith(
      turns: [
        MockTurn(id: _id(), role: MockRole.interviewer, content: q),
      ],
      isResponding: false,
    );
  }

  Future<void> answer(String text) async {
    final answer = text.trim();
    if (answer.isEmpty || !state.awaitingAnswer) return;

    final userTurn =
        MockTurn(id: _id(), role: MockRole.candidate, content: answer);
    final feedbackId = _id();
    final feedbackTurn = MockTurn(
      id: feedbackId,
      role: MockRole.interviewer,
      content: '',
      isFeedback: true,
      streaming: true,
    );

    state = state.copyWith(
      turns: [...state.turns, userTurn, feedbackTurn],
      isResponding: true,
    );

    final buffer = StringBuffer();
    await for (final delta
        in _repo.feedback(answer, questionIndex: state.questionIndex)) {
      buffer.write(delta);
      _update(feedbackId, content: buffer.toString());
    }
    _update(feedbackId, streaming: false);

    final next = _repo.nextQuestion(state.questionIndex);
    if (next == null) {
      state = state.copyWith(isResponding: false, finished: true);
      return;
    }

    state = state.copyWith(
      turns: [
        ...state.turns,
        MockTurn(id: _id(), role: MockRole.interviewer, content: next),
      ],
      questionIndex: state.questionIndex + 1,
      isResponding: false,
    );
  }

  void reset() => state = const MockInterviewState();

  void _update(String id, {String? content, bool? streaming}) {
    state = state.copyWith(
      turns: [
        for (final turn in state.turns)
          if (turn.id == id)
            turn.copyWith(content: content, streaming: streaming)
          else
            turn,
      ],
    );
  }
}

final mockInterviewProvider =
    StateNotifierProvider<MockInterviewController, MockInterviewState>((ref) {
  return MockInterviewController(ref.watch(interviewRepositoryProvider));
});
