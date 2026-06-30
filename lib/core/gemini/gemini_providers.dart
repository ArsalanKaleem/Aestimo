import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/cover_letter/data/cover_letter_repository.dart';
import '../../features/cover_letter/data/gemini_cover_letter_repository.dart';
import '../../features/cover_letter/providers/cover_letter_provider.dart';

import '../../features/insights/data/gemini_insights_repository.dart';
import '../../features/insights/providers/insights_provider.dart';

import '../../features/interview_prep/data/gemini_interview_repository.dart';
import '../../features/interview_prep/data/interview_repository.dart';
import '../../features/interview_prep/providers/interview_provider.dart';

import '../../features/rag_chat/data/chat_repository.dart';
import '../../features/rag_chat/data/gemini_chat_repository.dart';
import '../../features/rag_chat/providers/chat_provider.dart';

import '../../features/upload_resume/data/gemini_resume_repository.dart';
import '../../features/upload_resume/providers/resume_provider.dart';

// ── NEW: Resume Score ────────────────────────────────────────────────────────
import '../../features/resume_score/data/gemini_resume_score_repository.dart';
import '../../features/resume_score/providers/resume_score_provider.dart';

// ── NEW: ATS Resume ──────────────────────────────────────────────────────────
import '../../features/ats_resume/data/gemini_ats_resume_repository.dart';
import '../../features/ats_resume/providers/ats_resume_provider.dart';

import 'gemini_client.dart';
import 'gemini_provider.dart';

// ---------------------------------------------------------------------------
// Shared resume-text state
// ---------------------------------------------------------------------------

/// Plain-text content of the currently uploaded resume.
/// GeminiResumeRepository writes to this via resume_sync.dart after upload.
final resumeTextProvider = StateProvider<String>((ref) => '');

// ---------------------------------------------------------------------------
// Gemini-backed repository providers
// ---------------------------------------------------------------------------

final geminiResumeRepositoryProvider =
    Provider<GeminiResumeRepository>((ref) {
  final client = ref.watch(geminiClientProvider);
  return GeminiResumeRepository(client: client);
});

final geminiChatRepositoryProvider = Provider<ChatRepository>((ref) {
  final client = ref.watch(geminiClientProvider);
  final text = ref.watch(resumeTextProvider);
  return GeminiChatRepository(client: client, resumeText: text);
});

final geminiInsightsRepositoryProvider =
    Provider<InsightsRepository>((ref) {
  final client = ref.watch(geminiClientProvider);
  final text = ref.watch(resumeTextProvider);
  return GeminiInsightsRepository(client: client, resumeText: text);
});

final geminiCoverLetterRepositoryProvider =
    Provider<CoverLetterRepository>((ref) {
  final client = ref.watch(geminiClientProvider);
  final text = ref.watch(resumeTextProvider);
  return GeminiCoverLetterRepository(client: client, resumeText: text);
});

final geminiInterviewRepositoryProvider =
    Provider<InterviewRepository>((ref) {
  final client = ref.watch(geminiClientProvider);
  final text = ref.watch(resumeTextProvider);
  return GeminiInterviewRepository(client: client, resumeText: text);
});

// ── NEW ─────────────────────────────────────────────────────────────────────

final geminiResumeScoreRepositoryProvider =
    Provider<GeminiResumeScoreRepository>((ref) {
  final client = ref.watch(geminiClientProvider);
  final text = ref.watch(resumeTextProvider);
  return GeminiResumeScoreRepository(client: client, resumeText: text);
});

final geminiAtsResumeRepositoryProvider =
    Provider<GeminiAtsResumeRepository>((ref) {
  final client = ref.watch(geminiClientProvider);
  final text = ref.watch(resumeTextProvider);
  return GeminiAtsResumeRepository(client: client, resumeText: text);
});

// ---------------------------------------------------------------------------
// ProviderScope overrides — pass to ProviderContainer in main.dart
// ---------------------------------------------------------------------------

List<Override> buildGeminiOverrides() {
  return [
    resumeRepositoryProvider
        .overrideWith((ref) => ref.watch(geminiResumeRepositoryProvider)),
    chatRepositoryProvider
        .overrideWith((ref) => ref.watch(geminiChatRepositoryProvider)),
    insightsRepositoryProvider
        .overrideWith((ref) => ref.watch(geminiInsightsRepositoryProvider)),
    coverLetterRepositoryProvider
        .overrideWith(
            (ref) => ref.watch(geminiCoverLetterRepositoryProvider)),
    interviewRepositoryProvider
        .overrideWith(
            (ref) => ref.watch(geminiInterviewRepositoryProvider)),

    // ── NEW ─────────────────────────────────────────────────────────────────
    resumeScoreRepositoryProvider
        .overrideWith(
            (ref) => ref.watch(geminiResumeScoreRepositoryProvider)),
    atsResumeRepositoryProvider
        .overrideWith(
            (ref) => ref.watch(geminiAtsResumeRepositoryProvider)),
  ];
}
