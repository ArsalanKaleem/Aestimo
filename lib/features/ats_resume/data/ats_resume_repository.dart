import '../models/ats_resume.dart';

abstract class AtsResumeRepository {
  Future<AtsResume> generate({String? jobTitle, String? jobDescription});
}

class MockAtsResumeRepository implements AtsResumeRepository {
  @override
  Future<AtsResume> generate(
      {String? jobTitle, String? jobDescription}) async {
    await Future.delayed(const Duration(seconds: 2));
    return AtsResume(
      name: 'John Doe',
      contactLine: 'john@email.com | +1 555 0100 | New York, NY | linkedin.com/in/johndoe',
      summary: 'Results-driven software engineer with 4+ years of experience...',
      sections: const [
        AtsResumeSection(heading: 'WORK EXPERIENCE', content: '...'),
        AtsResumeSection(heading: 'EDUCATION', content: '...'),
        AtsResumeSection(heading: 'SKILLS', content: '...'),
      ],
      rawText: 'JOHN DOE\n...',
      generatedAt: DateTime.now(),
    );
  }
}
