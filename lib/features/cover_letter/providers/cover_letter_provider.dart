import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/cover_letter_repository.dart';
import '../models/cover_letter.dart';

final coverLetterRepositoryProvider = Provider<CoverLetterRepository>((ref) {
  return MockCoverLetterRepository();
});

@immutable
class CoverLetterState {
  const CoverLetterState({
    this.letter = '',
    this.isGenerating = false,
    this.error,
  });

  final String letter;
  final bool isGenerating;
  final String? error;

  bool get hasLetter => letter.isNotEmpty;

  CoverLetterState copyWith({
    String? letter,
    bool? isGenerating,
    String? error,
    bool clearError = false,
  }) {
    return CoverLetterState(
      letter: letter ?? this.letter,
      isGenerating: isGenerating ?? this.isGenerating,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class CoverLetterController extends StateNotifier<CoverLetterState> {
  CoverLetterController(this._repo) : super(const CoverLetterState());

  final CoverLetterRepository _repo;

  Future<void> generate(CoverLetterRequest request) async {
    if (state.isGenerating || !request.isValid) return;
    state = const CoverLetterState(isGenerating: true);
    try {
      final buffer = StringBuffer();
      await for (final delta in _repo.generate(request)) {
        buffer.write(delta);
        state = state.copyWith(letter: buffer.toString());
      }
      state = state.copyWith(isGenerating: false);
    } catch (e) {
      state = state.copyWith(
        isGenerating: false,
        error: 'Couldn’t generate the letter. Please try again.',
      );
    }
  }

  void clear() => state = const CoverLetterState();
}

final coverLetterProvider =
    StateNotifierProvider<CoverLetterController, CoverLetterState>((ref) {
  return CoverLetterController(ref.watch(coverLetterRepositoryProvider));
});
