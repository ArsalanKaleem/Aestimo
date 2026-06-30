import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/gemini/gemini_provider.dart';
import '../../../core/gemini/gemini_providers.dart';
import '../data/gemini_job_matcher.dart';
import '../data/job.dart';
import '../data/job_repository.dart';

final _jobHttpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final jobRepositoryProvider = Provider<JobRepository>((ref) {
  return RemotiveJobRepository(client: ref.watch(_jobHttpClientProvider));
});

final jobMatcherProvider = Provider<GeminiJobMatcher>((ref) {
  return GeminiJobMatcher(client: ref.watch(geminiClientProvider));
});

/// The current search keyword. Empty = recent listings. The screen updates it.
final jobQueryProvider = StateProvider<String>((ref) => '');

/// Fetches jobs for the current query and ranks them against the resume.
/// Cached (not autoDispose) so navigating away and back doesn't refetch;
/// re-runs when the query changes or on ref.invalidate (pull to refresh).
final jobMatchProvider = FutureProvider<List<JobMatch>>((ref) async {
  final resumeText = ref.watch(resumeTextProvider);
  if (resumeText.trim().isEmpty) {
    throw const NoResumeForJobsException();
  }

  final query = ref.watch(jobQueryProvider);
  final jobs = await ref.read(jobRepositoryProvider).search(
        query: query,
        limit: 20,
      );
  if (jobs.isEmpty) return const [];

  return ref.read(jobMatcherProvider).rank(
        resumeText: resumeText,
        jobs: jobs,
      );
});

class NoResumeForJobsException implements Exception {
  const NoResumeForJobsException();
}

bool isNoResumeForJobs(Object error) => error is NoResumeForJobsException;
