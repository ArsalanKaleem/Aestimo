import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'job.dart';

/// Fetches job/internship listings from a jobs source.
abstract class JobRepository {
  /// [query] is a free-text role/keyword (e.g. "flutter developer",
  /// "data science internship"). Empty returns recent listings.
  Future<List<Job>> search({String query = '', int limit = 20});
}

/// Live jobs from Remotive's free, no-auth remote-jobs API.
///
/// Endpoint: https://remotive.com/api/remote-jobs?search=<q>&limit=<n>
///
/// Note: works on mobile/desktop. On Flutter **Web** the call may be blocked
/// by CORS — route it through a tiny proxy of your own if you ship to web.
class RemotiveJobRepository implements JobRepository {
  RemotiveJobRepository({http.Client? client})
      : _http = client ?? http.Client();

  final http.Client _http;

  static const String _base = 'https://remotive.com/api/remote-jobs';

  @override
  Future<List<Job>> search({String query = '', int limit = 20}) async {
    final params = <String, String>{'limit': '$limit'};
    if (query.trim().isNotEmpty) params['search'] = query.trim();
    final uri = Uri.parse(_base).replace(queryParameters: params);

    debugPrint('[Jobs] GET $uri');
    final resp = await _http.get(uri, headers: {'Accept': 'application/json'});
    debugPrint('[Jobs] ${resp.statusCode}');

    if (resp.statusCode != 200) {
      throw Exception('Job search failed (${resp.statusCode}).');
    }

    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    final raw = json['jobs'] as List<dynamic>? ?? [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(_fromRemotive)
        .toList(growable: false);
  }

  Job _fromRemotive(Map<String, dynamic> j) {
    final tags = (j['tags'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .where((e) => e.isNotEmpty)
        .toList();

    return Job(
      id: (j['id'] ?? '').toString(),
      title: (j['title'] ?? 'Untitled role').toString(),
      company: (j['company_name'] ?? 'Unknown').toString(),
      url: (j['url'] ?? '').toString(),
      companyLogo: (j['company_logo'] as String?)?.trim().isEmpty ?? true
          ? null
          : j['company_logo'] as String,
      category: (j['category'] ?? '').toString(),
      tags: tags,
      type: (j['job_type'] ?? '').toString(),
      location: (j['candidate_required_location'] ?? 'Remote').toString(),
      salary: (j['salary'] ?? '').toString(),
      description: _stripHtml((j['description'] ?? '').toString()),
      postedAt: DateTime.tryParse((j['publication_date'] ?? '').toString()),
    );
  }

  /// Cheap HTML → text for previews and for feeding the matcher.
  static String _stripHtml(String html) {
    var text = html.replaceAll(RegExp(r'<[^>]*>'), ' ');
    text = text
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ');
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
