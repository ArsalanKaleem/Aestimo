import 'package:flutter/foundation.dart';

/// A single job/internship listing fetched from a jobs API.
@immutable
class Job {
  const Job({
    required this.id,
    required this.title,
    required this.company,
    required this.url,
    this.companyLogo,
    this.category = '',
    this.tags = const [],
    this.type = '',
    this.location = '',
    this.salary = '',
    this.description = '',
    this.postedAt,
  });

  final String id;
  final String title;
  final String company;
  final String url;
  final String? companyLogo;
  final String category;
  final List<String> tags;
  final String type; // full_time, internship, contract…
  final String location;
  final String salary;
  final String description; // plain text (HTML stripped)
  final DateTime? postedAt;

  bool get isInternship =>
      type.toLowerCase().contains('intern') ||
      title.toLowerCase().contains('intern');

  /// A short, single-line description preview.
  String get preview {
    final clean = description.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (clean.length <= 160) return clean;
    return '${clean.substring(0, 160)}…';
  }
}

/// A [Job] paired with how well it fits the user's resume.
@immutable
class JobMatch {
  const JobMatch({
    required this.job,
    required this.score,
    this.reason = '',
    this.matchedSkills = const [],
  });

  final Job job;

  /// 0–100 fit score, or -1 when the listing could not be ranked.
  final int score;
  final String reason;
  final List<String> matchedSkills;

  bool get isRanked => score >= 0;
}
