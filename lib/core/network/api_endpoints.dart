/// Single source of truth for FastAPI route paths.
///
/// These mirror the backend contract the mock repositories emulate, so
/// swapping mock → live is a one-line change per repository.
abstract class ApiEndpoints {
  // Resume / RAG ingestion
  static const String uploadResume = '/resume/upload';
  static const String resume = '/resume';
  static String deleteResume(String id) => '/resume/$id';

  // Chat (RAG)
  static const String chat = '/chat';
  static const String chatStream = '/chat/stream';
  static const String chatHistory = '/chat/history';

  // Insights
  static const String insights = '/insights';

  // Interview prep
  static const String interviewQuestions = '/interview/questions';
  static const String interviewFeedback = '/interview/feedback';

  // Cover letter
  static const String coverLetter = '/cover-letter';
}
