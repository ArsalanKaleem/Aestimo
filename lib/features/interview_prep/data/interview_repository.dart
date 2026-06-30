import 'dart:async';
import 'dart:math';

import '../../../core/constants/app_constants.dart';
import '../models/interview.dart';

abstract class InterviewRepository {
  /// Generates personalized questions grounded in the resume.
  Future<List<InterviewQuestion>> generateQuestions();

  /// The interviewer's opening question for a mock session.
  Future<String> openingQuestion();

  /// Streams interviewer feedback for the candidate's [answer], followed by
  /// the next question (returned via [nextQuestion]).
  Stream<String> feedback(String answer, {required int questionIndex});

  /// The next question to ask after feedback, or null when the set is done.
  String? nextQuestion(int questionIndex);
}

class MockInterviewRepository implements InterviewRepository {
  final _rng = Random();

  static const _mockQuestions = [
    'Tell me about a service you scaled to millions of requests per day. '
        'Where did it break first, and how did you fix it?',
    'Describe a time you reduced infrastructure cost. What tradeoffs did you '
        'weigh, and how did you measure success?',
    'How do you balance shipping features with mentoring less-experienced '
        'engineers on your team?',
    'Walk me through a system-design decision you later regretted. What would '
        'you do differently?',
    'Tell me about a cross-functional conflict you navigated. How did you '
        'reach alignment?',
  ];

  @override
  Future<List<InterviewQuestion>> generateQuestions() async {
    await Future<void>.delayed(AppConstants.mockLatency * 2);
    return const [
      InterviewQuestion(
        category: QuestionCategory.technical,
        question:
            'How would you design a rate limiter for an API handling millions '
            'of requests per day?',
        tip:
            'Cover algorithm choice (token bucket vs sliding window), where '
            'state lives (Redis), and failure modes under load.',
      ),
      InterviewQuestion(
        category: QuestionCategory.technical,
        question:
            'Your resume mentions cutting cloud costs by 30%. Walk through how '
            'you’d find and validate those savings.',
        tip:
            'Tie it to real levers: right-sizing, spot/reserved instances, and '
            'how you measured impact without hurting reliability.',
      ),
      InterviewQuestion(
        category: QuestionCategory.behavioral,
        question:
            'Tell me about a time a production incident was your fault. How did '
            'you handle it?',
        tip:
            'Use STAR. Emphasize ownership, the fix, and the systemic change '
            'you made so it couldn’t recur.',
      ),
      InterviewQuestion(
        category: QuestionCategory.behavioral,
        question:
            'Describe how you mentored an engineer from struggling to '
            'high-performing.',
        tip:
            'Show specific coaching actions and a measurable outcome — this '
            'maps to the leadership signals on your resume.',
      ),
      InterviewQuestion(
        category: QuestionCategory.roleSpecific,
        question:
            'For a Staff Backend role, how would you drive technical strategy '
            'across multiple teams?',
        tip:
            'Talk about influence without authority, RFCs, and aligning teams '
            'on shared platforms — your team-lead experience is relevant here.',
      ),
      InterviewQuestion(
        category: QuestionCategory.roleSpecific,
        question:
            'How do you decide when to build in-house vs adopt a managed '
            'service for infrastructure?',
        tip:
            'Weigh team capacity, cost, and differentiation. Reference your '
            'Terraform/AWS background concretely.',
      ),
    ];
  }

  @override
  Future<String> openingQuestion() async {
    await Future<void>.delayed(AppConstants.mockLatency);
    return _mockQuestions.first;
  }

  @override
  Stream<String> feedback(
    String answer, {
    required int questionIndex,
  }) async* {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final text = _feedbackFor(answer);
    for (final word in text.split(' ')) {
      yield '$word ';
      await Future<void>.delayed(Duration(milliseconds: 16 + _rng.nextInt(30)));
    }
  }

  @override
  String? nextQuestion(int questionIndex) {
    final next = questionIndex + 1;
    if (next >= _mockQuestions.length) return null;
    return _mockQuestions[next];
  }

  String _feedbackFor(String answer) {
    final words = answer.trim().split(RegExp(r'\s+')).length;
    final hasNumbers = RegExp(r'\d').hasMatch(answer);

    final strength = hasNumbers
        ? 'Nice — you quantified the impact, which is exactly what '
            'interviewers want to hear.'
        : 'Good structure. The next level is to **quantify the outcome** — '
            'add a metric (scale, latency, %, or dollars).';

    final depth = words < 25
        ? 'Try to **go deeper**: walk through the tradeoffs you considered and '
            'why you chose your approach.'
        : 'You gave solid detail. Tighten the opening so the impact lands in '
            'the first sentence.';

    return '**Feedback:**\n\n'
        '- $strength\n'
        '- $depth\n'
        '- Consider closing with what you’d do differently next time — it '
        'signals growth.\n\n'
        'Ready for the next one? 👇';
  }
}
