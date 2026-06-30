import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/gemini/resume_sync.dart';
import '../data/resume_repository.dart';
import '../models/resume.dart';

final resumeRepositoryProvider = Provider<ResumeRepository>((ref) {
  // Overridden via buildGeminiOverrides() in main.dart
  return MockResumeRepository();
});

@immutable
class ResumeState {
  const ResumeState({
    this.resume,
    this.status = ResumeStatus.idle,
    this.progressLabel,
    this.progress = 0,
    this.error,
  });

  final Resume? resume;
  final ResumeStatus status;
  final String? progressLabel;
  final double progress;
  final String? error;

  bool get hasResume => resume != null && status == ResumeStatus.ready;
  bool get isBusy =>
      status == ResumeStatus.uploading || status == ResumeStatus.processing;

  ResumeState copyWith({
    Resume? resume,
    ResumeStatus? status,
    String? progressLabel,
    double? progress,
    String? error,
    bool clearError = false,
    bool clearResume = false,
  }) {
    return ResumeState(
      resume: clearResume ? null : (resume ?? this.resume),
      status: status ?? this.status,
      progressLabel: progressLabel ?? this.progressLabel,
      progress: progress ?? this.progress,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ResumeController extends StateNotifier<ResumeState> {
  ResumeController(this._repo, this._ref) : super(const ResumeState()) {
    _load();
  }

  final ResumeRepository _repo;
  final Ref _ref;

  Future<void> _load() async {
    final existing = await _repo.getResume();
    if (existing != null) {
      state = state.copyWith(resume: existing, status: ResumeStatus.ready);
    } else {
      state = state.copyWith(status: ResumeStatus.idle);
    }
  }

  Future<void> upload({
    required String fileName,
    required int sizeBytes,
    List<int>? bytes,
  }) async {
    state = state.copyWith(
      status: ResumeStatus.processing,
      progress: 0,
      progressLabel: 'Starting…',
      clearError: true,
    );
    try {
      await for (final p in _repo.upload(
        fileName: fileName,
        sizeBytes: sizeBytes,
        bytes: bytes,
      )) {
        state = state.copyWith(
          progress: p.fraction,
          progressLabel: p.label,
        );
      }
      final resume = await _repo.getResume();
      // Push extracted text to all Gemini repositories BEFORE flipping to
      // "ready". This way the insights/interview providers re-run exactly once
      // — with the correct resume text already in place — instead of firing a
      // first time against stale/empty text.
      syncResumeText(_ref);
      state = state.copyWith(resume: resume, status: ResumeStatus.ready);
    } catch (e) {
      state = state.copyWith(
        status: ResumeStatus.error,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> delete() async {
    await _repo.deleteResume();
    state = const ResumeState(status: ResumeStatus.idle);
  }
}

final resumeProvider =
    StateNotifierProvider<ResumeController, ResumeState>((ref) {
  return ResumeController(ref.watch(resumeRepositoryProvider), ref);
});
