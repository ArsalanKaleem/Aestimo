import 'package:flutter/foundation.dart';

@immutable
class ResumeInsights {
  const ResumeInsights({
    required this.technicalSkills,
    required this.softSkills,
    required this.missingSkills,
    required this.yearsExperience,
    required this.expertiseAreas,
    required this.strengths,
    required this.advantages,
    required this.improvements,
  });

  final List<String> technicalSkills;
  final List<String> softSkills;
  final List<String> missingSkills;

  final double yearsExperience;
  final List<String> expertiseAreas;

  final List<String> strengths;
  final List<String> advantages;

  /// Improvement suggestions: (title, detail).
  final List<({String title, String detail})> improvements;
}
