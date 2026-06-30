import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../upload_resume/providers/resume_provider.dart';
import '../models/insights.dart';

abstract class InsightsRepository {
  Future<ResumeInsights> generate();
}

class MockInsightsRepository implements InsightsRepository {
  @override
  Future<ResumeInsights> generate() async {
    await Future<void>.delayed(AppConstants.mockLatency * 2);
    return const ResumeInsights(
      technicalSkills: [
        'Python', 'Go', 'TypeScript', 'AWS', 'Terraform', 'Docker',
        'PostgreSQL', 'Redis', 'REST APIs', 'CI/CD',
      ],
      softSkills: [
        'Technical Leadership', 'Mentorship', 'Cross-functional Collaboration',
        'Communication', 'Ownership',
      ],
      missingSkills: [
        'Kubernetes', 'gRPC', 'Observability (Grafana/Datadog)',
        'Event Streaming (Kafka)',
      ],
      yearsExperience: 6,
      expertiseAreas: [
        'Backend Systems', 'Cloud Infrastructure', 'Distributed Systems',
        'Cost Optimization',
      ],
      strengths: [
        'Scaled services to millions of requests/day',
        'Proven cost reduction (30% cloud spend)',
        'Led and mentored engineering teams',
        'Strong system-design fundamentals',
      ],
      advantages: [
        'Rare blend of hands-on depth and leadership',
        'Quantified, outcome-driven track record',
        'Full-cycle ownership from design to on-call',
      ],
      improvements: [
        (
          title: 'Quantify remaining bullets',
          detail:
              'Two experience bullets lack metrics. Add scale, latency, or '
              'revenue impact to strengthen them.',
        ),
        (
          title: 'Add high-signal keywords',
          detail:
              'Include Kubernetes, gRPC, and observability tooling — common '
              'in target senior backend roles.',
        ),
        (
          title: 'Reposition leadership earlier',
          detail:
              'Move mentorship and team-lead signals up; they currently '
              'appear only in your third role.',
        ),
      ],
    );
  }
}

final insightsRepositoryProvider = Provider<InsightsRepository>((ref) {
  return MockInsightsRepository();
});

/// Generated once per resume and cached for the session. Re-runs only when a
/// new resume is uploaded (the repository rebuilds with new text) or when the
/// user taps "Try again" (ref.invalidate). Navigating away and back reuses the
/// cached result instead of regenerating.
final insightsProvider = FutureProvider<ResumeInsights>((ref) async {
  final hasResume = ref.watch(resumeProvider.select((s) => s.hasResume));
  if (!hasResume) {
    throw const _NoResumeException();
  }
  return ref.watch(insightsRepositoryProvider).generate();
});

class _NoResumeException implements Exception {
  const _NoResumeException();
}

bool isNoResume(Object error) => error is _NoResumeException;
