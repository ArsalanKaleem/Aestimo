import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../core/gemini/gemini_client.dart';
import 'job.dart';

/// Ranks a batch of [Job]s against the user's resume using a single Gemini
/// call (important: one request keeps us within the rate limit). Returns
/// [JobMatch]es sorted best-first. Falls back to unranked matches if the model
/// response can't be parsed, so the user still sees jobs.
class GeminiJobMatcher {
  GeminiJobMatcher({required GeminiClient client}) : _client = client;

  final GeminiClient _client;

  Future<List<JobMatch>> rank({
    required String resumeText,
    required List<Job> jobs,
    int minScore = 35,
  }) async {
    if (jobs.isEmpty) return const [];

    final catalog = StringBuffer();
    for (final job in jobs) {
      final desc = job.description.length > 320
          ? job.description.substring(0, 320)
          : job.description;
      catalog.writeln(
        '[${job.id}] ${job.title} @ ${job.company} '
        '| type: ${job.type} | tags: ${job.tags.take(8).join(", ")} '
        '| location: ${job.location}\n$desc\n',
      );
    }

    try {
      final raw = await _client.generate(
        jsonMode: true,
        temperature: 0.2,
        maxOutputTokens: 2048,
        systemInstruction:
            'You are a career matching engine. Compare each job to the '
            'candidate resume and score the fit. Respond ONLY with JSON.',
        messages: [
          GeminiMessage(
            role: 'user',
            text: '''
Score how well each job below fits the candidate's resume.

Return a JSON array (no markdown) of objects with EXACTLY this shape:
[
  { "id": "<job id>", "score": <0-100>, "reason": "<one short sentence>",
    "matchedSkills": ["<resume skill that matches>"] }
]

Rules:
- Include an entry for EVERY job id given.
- score reflects overall fit (skills, seniority, domain).
- reason: one concise sentence on why it fits or not.
- matchedSkills: up to 4 skills from the resume that this job needs.

CANDIDATE RESUME:
$resumeText

JOBS:
$catalog
''',
          ),
        ],
      );

      return _merge(raw, jobs, minScore);
    } catch (e) {
      debugPrint('[Jobs] ranking failed, returning unranked: $e');
      // Graceful fallback — show the jobs without scores.
      return jobs
          .map((j) => JobMatch(job: j, score: -1))
          .toList(growable: false);
    }
  }

  List<JobMatch> _merge(String raw, List<Job> jobs, int minScore) {
    final byId = {for (final j in jobs) j.id: j};

    final clean = raw.replaceAll(RegExp(r'```json|```'), '').trim();
    final start = clean.indexOf('[');
    final end = clean.lastIndexOf(']');
    final slice =
        (start != -1 && end > start) ? clean.substring(start, end + 1) : clean;

    final decoded = jsonDecode(slice) as List<dynamic>;
    final matches = <JobMatch>[];

    for (final item in decoded.whereType<Map<String, dynamic>>()) {
      final id = (item['id'] ?? '').toString();
      final job = byId[id];
      if (job == null) continue;
      final score = (item['score'] as num? ?? 0).round().clamp(0, 100);
      if (score < minScore) continue;
      matches.add(
        JobMatch(
          job: job,
          score: score,
          reason: (item['reason'] ?? '').toString(),
          matchedSkills: (item['matchedSkills'] as List<dynamic>? ?? [])
              .map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .take(4)
              .toList(),
        ),
      );
    }

    matches.sort((a, b) => b.score.compareTo(a.score));
    // If everything scored below the threshold, still show the top few jobs
    // unranked so the screen isn't empty.
    if (matches.isEmpty) {
      return jobs.take(8).map((j) => JobMatch(job: j, score: -1)).toList();
    }
    return matches;
  }
}
