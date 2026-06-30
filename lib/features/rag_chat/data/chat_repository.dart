import 'dart:async';
import 'dart:math';

import '../models/chat_message.dart';

/// A streamed answer event: either a text delta or the final source list.
class ChatChunk {
  const ChatChunk({this.textDelta, this.sources});
  final String? textDelta;
  final List<SourceSnippet>? sources;
}

abstract class ChatRepository {
  /// Streams a RAG answer for [prompt]. Implementations should:
  ///   1. embed the prompt, 2. retrieve top-k chunks, 3. stream the LLM answer,
  ///   4. emit the retrieved sources.
  Stream<ChatChunk> ask(String prompt, {List<ChatMessage> history = const []});
}

/// Deterministic-ish mock that streams word-by-word and returns plausible
/// resume sources, so the full chat UX works with no API key.
class MockChatRepository implements ChatRepository {
  final _rng = Random();

  @override
  Stream<ChatChunk> ask(
    String prompt, {
    List<ChatMessage> history = const [],
  }) async* {
    await Future<void>.delayed(const Duration(milliseconds: 350));

    final answer = _answerFor(prompt);
    final words = answer.split(' ');
    final buffer = StringBuffer();

    for (var i = 0; i < words.length; i++) {
      buffer.write(words[i]);
      if (i != words.length - 1) buffer.write(' ');
      yield ChatChunk(textDelta: words[i] + (i == words.length - 1 ? '' : ' '));
      await Future<void>.delayed(
          Duration(milliseconds: 16 + _rng.nextInt(34)));
    }

    yield ChatChunk(sources: _sourcesFor(prompt));
  }

  String _answerFor(String prompt) {
    final p = prompt.toLowerCase();
    if (p.contains('skill')) {
      return "Based on your resume, your strongest skills cluster around "
          "**backend engineering** and **cloud infrastructure**:\n\n"
          "- **Languages:** Python, Go, and TypeScript — used across 4+ "
          "production services.\n"
          "- **Cloud & DevOps:** AWS (ECS, Lambda, RDS), Docker, and "
          "Terraform.\n"
          "- **Data:** PostgreSQL, Redis, and event-driven pipelines.\n\n"
          "Your **soft skills** also stand out: you repeatedly led "
          "cross-functional teams and mentored junior engineers. If you're "
          "targeting senior roles, lean into the leadership and "
          "system-design signals.";
    }
    if (p.contains('summar')) {
      return "Here's a snapshot of your resume:\n\n"
          "You're a **Senior Software Engineer** with ~6 years of "
          "experience, focused on scalable backend systems. You've shipped "
          "services handling millions of requests/day, cut infra costs by "
          "30%, and led a team of 5. Core stack: Python, Go, AWS, and "
          "PostgreSQL. Strong fit for **Backend / Platform / Staff "
          "Engineer** roles.";
    }
    if (p.contains('role') || p.contains('fit') || p.contains('job')) {
      return "Given your background, these roles are a strong match:\n\n"
          "1. **Senior Backend Engineer** — your service-ownership and "
          "scaling work map directly.\n"
          "2. **Platform / Infrastructure Engineer** — Terraform + AWS + "
          "cost optimization stand out.\n"
          "3. **Staff Engineer (Backend)** — your mentorship and "
          "system-design leadership support the jump.\n\n"
          "I'd de-prioritize pure frontend roles — your resume signals are "
          "heavily backend.";
    }
    if (p.contains('improve') || p.contains('better')) {
      return "A few high-impact improvements:\n\n"
          "- **Quantify more outcomes.** Two bullets lack metrics — add "
          "latency, scale, or revenue numbers.\n"
          "- **Add missing keywords** recruiters scan for: *Kubernetes, "
          "CI/CD, observability, gRPC*.\n"
          "- **Tighten the summary** to 2 lines focused on impact, not "
          "responsibilities.\n"
          "- **Surface leadership earlier** — it's currently buried in the "
          "third role.";
    }
    if (p.contains('cover letter')) {
      return "I can draft a tailored cover letter for you. Head to the "
          "**Cover Letter** tab and give me the job title, company, and "
          "description — I'll weave in the most relevant parts of your "
          "resume automatically.";
    }
    if (p.contains('interview') || p.contains('question')) {
      return "Here are a few tailored interview questions:\n\n"
          "1. Walk me through how you scaled a service to millions of "
          "requests/day. What broke first?\n"
          "2. Describe a time you cut infrastructure costs — what tradeoffs "
          "did you weigh?\n"
          "3. How do you mentor engineers while still shipping?\n\n"
          "Open the **Interview Prep** tab for a full set plus a mock "
          "interview mode.";
    }
    if (p.contains('project')) {
      return "Highlight these projects — they best showcase your range:\n\n"
          "- **Payments platform rewrite** — scale + reliability story.\n"
          "- **Cost-optimization initiative** — measurable 30% savings.\n"
          "- **Internal developer platform** — leadership + DX impact.";
    }
    return "Great question. Based on the relevant sections of your resume, "
        "here's my take: your experience points to a strong, "
        "backend-leaning profile with clear leadership signals. Ask me to "
        "summarize your resume, surface your top skills, suggest roles, or "
        "draft interview questions — I'll ground every answer in your actual "
        "resume content.";
  }

  List<SourceSnippet> _sourcesFor(String prompt) {
    return const [
      SourceSnippet(
        section: 'Experience · Senior Software Engineer, Acme',
        text:
            'Led design and rollout of a payments platform handling 3M+ '
            'requests/day; reduced p99 latency by 45%.',
        score: 0.91,
        reason: 'Top semantic match for impact and scale signals.',
      ),
      SourceSnippet(
        section: 'Skills',
        text:
            'Python, Go, TypeScript · AWS (ECS, Lambda, RDS), Terraform, '
            'Docker · PostgreSQL, Redis.',
        score: 0.86,
        reason: 'Directly lists the technical skills referenced.',
      ),
      SourceSnippet(
        section: 'Experience · Tech Lead, Northwind',
        text:
            'Mentored 5 engineers; cut cloud spend 30% via right-sizing and '
            'spot instances.',
        score: 0.79,
        reason: 'Supports leadership and cost-optimization claims.',
      ),
    ];
  }
}
