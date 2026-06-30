import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/ats_pdf_generator.dart';
import '../data/ats_resume_repository.dart';
import '../models/ats_resume.dart';

// Overridden via buildGeminiOverrides() in gemini_providers.dart.
final atsResumeRepositoryProvider = Provider<AtsResumeRepository>(
  (_) => MockAtsResumeRepository(),
);

enum AtsResumeStatus { idle, generating, ready, exportingPdf, error }

class AtsResumeState {
  const AtsResumeState({
    this.resume,
    this.pdfBytes,
    this.status = AtsResumeStatus.idle,
    this.error,
  });

  final AtsResume? resume;
  final Uint8List? pdfBytes;
  final AtsResumeStatus status;
  final String? error;

  bool get hasResume => resume != null && status == AtsResumeStatus.ready;
  bool get isGenerating => status == AtsResumeStatus.generating;
  bool get isExporting => status == AtsResumeStatus.exportingPdf;

  AtsResumeState copyWith({
    AtsResume? resume,
    Uint8List? pdfBytes,
    AtsResumeStatus? status,
    String? error,
    bool clearError = false,
  }) {
    return AtsResumeState(
      resume: resume ?? this.resume,
      pdfBytes: pdfBytes ?? this.pdfBytes,
      status: status ?? this.status,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AtsResumeController extends StateNotifier<AtsResumeState> {
  AtsResumeController(this._repo) : super(const AtsResumeState());

  final AtsResumeRepository _repo;

  Future<void> generate({String? jobTitle, String? jobDescription}) async {
    state = state.copyWith(
        status: AtsResumeStatus.generating, clearError: true);
    try {
      final result = await _repo.generate(
        jobTitle: jobTitle,
        jobDescription: jobDescription,
      );
      state = state.copyWith(resume: result, status: AtsResumeStatus.ready);
    } catch (e) {
      state = state.copyWith(
        status: AtsResumeStatus.error,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<Uint8List?> exportPdf() async {
    final resume = state.resume;
    if (resume == null) return null;

    state = state.copyWith(status: AtsResumeStatus.exportingPdf);
    try {
      final bytes = await AtsPdfGenerator.generate(resume);
      state = state.copyWith(pdfBytes: bytes, status: AtsResumeStatus.ready);
      return bytes;
    } catch (e) {
      state = state.copyWith(
        status: AtsResumeStatus.error,
        error: 'PDF export failed: ${e.toString()}',
      );
      return null;
    }
  }

  void reset() => state = const AtsResumeState();
}

final atsResumeProvider =
    StateNotifierProvider<AtsResumeController, AtsResumeState>((ref) {
  return AtsResumeController(ref.watch(atsResumeRepositoryProvider));
});
