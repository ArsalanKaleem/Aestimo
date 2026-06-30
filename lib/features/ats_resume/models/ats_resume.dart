import 'package:flutter/foundation.dart';

@immutable
class AtsResumeSection {
  const AtsResumeSection({
    required this.heading,
    required this.content,
  });

  final String heading;
  final String content; // pre-formatted text for this section
}

@immutable
class AtsResume {
  const AtsResume({
    required this.name,
    required this.contactLine,
    required this.summary,
    required this.sections,
    required this.rawText,
    required this.generatedAt,
  });

  final String name;
  final String contactLine; // email | phone | location | linkedin
  final String summary;
  final List<AtsResumeSection> sections;

  /// Full plain-text version (used for PDF generation).
  final String rawText;

  final DateTime generatedAt;
}
