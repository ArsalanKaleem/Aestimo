import '../models/resume_score.dart';

abstract class ResumeScoreRepository {
  Future<ResumeScore> score();
}

class MockResumeScoreRepository implements ResumeScoreRepository {
  @override
  Future<ResumeScore> score() async {
    await Future.delayed(const Duration(seconds: 1));
    return const ResumeScore(
      overallScore: 72,
      categories: [],
      topStrengths: ['Strong technical skills section'],
      criticalFixes: ['Add measurable achievements'],
      atsKeywords: ['Flutter', 'Firebase'],
      missingKeywords: ['CI/CD', 'REST API'],
    );
  }
}
