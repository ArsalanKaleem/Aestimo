import 'package:flutter/foundation.dart';

@immutable
class CoverLetterRequest {
  const CoverLetterRequest({
    required this.jobTitle,
    required this.company,
    required this.jobDescription,
  });

  final String jobTitle;
  final String company;
  final String jobDescription;

  bool get isValid => jobTitle.trim().isNotEmpty && company.trim().isNotEmpty;
}
