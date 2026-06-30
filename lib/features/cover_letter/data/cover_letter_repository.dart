import 'dart:async';
import 'dart:math';

import '../models/cover_letter.dart';

abstract class CoverLetterRepository {
  /// Streams a tailored cover letter, weaving in retrieved resume context.
  Stream<String> generate(CoverLetterRequest request);
}

class MockCoverLetterRepository implements CoverLetterRepository {
  final _rng = Random();

  @override
  Stream<String> generate(CoverLetterRequest request) async* {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final letter = _compose(request);
    for (final word in letter.split(' ')) {
      yield '$word ';
      await Future<void>.delayed(Duration(milliseconds: 12 + _rng.nextInt(24)));
    }
  }

  String _compose(CoverLetterRequest r) {
    final title = r.jobTitle.trim();
    final company = r.company.trim();

    return 'Dear Hiring Team at $company,\n\n'
        'I’m excited to apply for the **$title** role at $company. With over '
        'six years building and scaling backend systems, I bring a track '
        'record that maps directly to what this position demands.\n\n'
        'In my current role I led the design of a payments platform handling '
        '3M+ requests per day while cutting p99 latency by 45%. I also drove a '
        'cloud cost-optimization initiative that reduced spend by 30% without '
        'sacrificing reliability — the kind of pragmatic, measurable impact I '
        'would bring to $company. My core stack (Python, Go, AWS, and '
        'Terraform) and my experience mentoring a team of five engineers '
        'position me to contribute from day one.\n\n'
        'What draws me to $company specifically is the chance to apply this '
        'depth to harder problems alongside a strong team. I’m confident the '
        'combination of hands-on engineering and technical leadership on my '
        'resume aligns closely with the goals outlined for this role.\n\n'
        'I’d welcome the opportunity to discuss how I can help $company. Thank '
        'you for your consideration.\n\n'
        'Sincerely,\n'
        'Alex Morgan';
  }
}
