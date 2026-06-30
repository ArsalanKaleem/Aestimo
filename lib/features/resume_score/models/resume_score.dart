import 'package:flutter/foundation.dart';

@immutable
class ScoreCategory {
  const ScoreCategory({
    required this.name,
    required this.score,
    required this.maxScore,
    required this.feedback,
  });

  final String name;
  final int score;
  final int maxScore;
  final String feedback;

  double get fraction => score / maxScore;
}

@immutable
class ResumeScore {
  const ResumeScore({
    required this.overallScore,
    required this.categories,
    required this.topStrengths,
    required this.criticalFixes,
    required this.atsKeywords,
    required this.missingKeywords,
  });

  /// Overall ATS compatibility score out of 100.
  final int overallScore;

  /// Breakdown scores per category.
  final List<ScoreCategory> categories;

  /// 3–5 top strengths found.
  final List<String> topStrengths;

  /// 3–5 critical issues to fix.
  final List<String> criticalFixes;

  /// Keywords present in resume that are ATS-friendly.
  final List<String> atsKeywords;

  /// Important keywords missing from resume.
  final List<String> missingKeywords;

  String get grade {
    if (overallScore >= 90) return 'A+';
    if (overallScore >= 80) return 'A';
    if (overallScore >= 70) return 'B';
    if (overallScore >= 60) return 'C';
    return 'D';
  }

  String get gradeLabel {
    if (overallScore >= 90) return 'Excellent';
    if (overallScore >= 80) return 'Great';
    if (overallScore >= 70) return 'Good';
    if (overallScore >= 60) return 'Fair';
    return 'Needs Work';
  }
}
