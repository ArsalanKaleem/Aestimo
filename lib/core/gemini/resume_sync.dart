/// resume_sync.dart
///
/// After a successful upload, call [syncResumeText] so every Gemini-backed
/// repository gets the latest resume text without a full app restart.
///
/// Usage in ResumeController (resume_provider.dart), after upload completes:
///
///   syncResumeText(ref, repository.resumeText);
///
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'gemini_provider.dart';
import 'gemini_providers.dart';
import '/features/upload_resume/data/gemini_resume_repository.dart';
import '/features/upload_resume/providers/resume_provider.dart';

/// Reads the cleaned resume text from [GeminiResumeRepository] and writes it
/// to [resumeTextProvider] so all dependent repositories rebuild.
void syncResumeText(Ref ref) {
  final repo = ref.read(resumeRepositoryProvider);
  if (repo is GeminiResumeRepository) {
    ref.read(resumeTextProvider.notifier).state = repo.resumeText;
  }
}
