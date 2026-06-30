import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/resume_score_repository.dart';
import '../models/resume_score.dart';

// Overridden in gemini_providers.dart via buildGeminiOverrides().
final resumeScoreRepositoryProvider = Provider<ResumeScoreRepository>(
  (_) => MockResumeScoreRepository(),
);

enum ScoreStatus { idle, loading, ready, error }

class ResumeScoreState {
  const ResumeScoreState({
    this.score,
    this.status = ScoreStatus.idle,
    this.error,
  });

  final ResumeScore? score;
  final ScoreStatus status;
  final String? error;

  bool get hasScore => score != null && status == ScoreStatus.ready;
  bool get isLoading => status == ScoreStatus.loading;

  ResumeScoreState copyWith({
    ResumeScore? score,
    ScoreStatus? status,
    String? error,
    bool clearError = false,
  }) {
    return ResumeScoreState(
      score: score ?? this.score,
      status: status ?? this.status,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ResumeScoreController extends StateNotifier<ResumeScoreState> {
  ResumeScoreController(this._repo) : super(const ResumeScoreState());

  final ResumeScoreRepository _repo;

  Future<void> analyse() async {
    state = state.copyWith(status: ScoreStatus.loading, clearError: true);
    try {
      final result = await _repo.score();
      state = state.copyWith(score: result, status: ScoreStatus.ready);
    } catch (e) {
      state = state.copyWith(
        status: ScoreStatus.error,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void reset() => state = const ResumeScoreState();
}

final resumeScoreProvider =
    StateNotifierProvider<ResumeScoreController, ResumeScoreState>((ref) {
  return ResumeScoreController(ref.watch(resumeScoreRepositoryProvider));
});
