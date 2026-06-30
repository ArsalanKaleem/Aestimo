import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../../core/gemini/gemini_client.dart';
import '../models/resume.dart';
import 'resume_repository.dart';

/// Sends the PDF bytes directly to Gemini as a native document —
/// no client-side text extraction needed. Gemini 2.5 Flash reads PDFs
/// natively, so we get perfect text extraction for free.
class GeminiResumeRepository implements ResumeRepository {
  GeminiResumeRepository({required GeminiClient client}) : _client = client;

  final GeminiClient _client;

  Resume? _resume;
  String _resumeText = '';
  String get resumeText => _resumeText;

  @override
  Future<Resume?> getResume() async => _resume;

  @override
  Stream<IngestProgress> upload({
    required String fileName,
    required int sizeBytes,
    List<int>? bytes,
  }) async* {
    yield const IngestProgress('Reading file…', 0.1);
    yield const IngestProgress('Sending PDF to AI for extraction…', 0.3);

    try {
      if (bytes != null && bytes.isNotEmpty) {
        // Convert bytes to base64 — Gemini accepts PDF as inline document.
        final base64Pdf = base64Encode(bytes);

        yield const IngestProgress('Extracting and cleaning resume content…', 0.5);

        // Ask Gemini to read the PDF directly and return clean text.
        _resumeText = await _client.generateWithDocument(
          base64Data: base64Pdf,
          mimeType: 'application/pdf',
          prompt:
              'Extract all text from this resume PDF exactly as written. '
              'Preserve all section headings, job titles, dates, skills, '
              'and bullet points. Format clearly with newlines between sections. '
              'Return ONLY the resume text — no commentary, no preamble.',
          systemInstruction:
              'You are a precise document parser. Extract resume content '
              'faithfully and completely. Never summarise or omit details.',
          temperature: 0.0,
          maxOutputTokens: 8192,
        );

        debugPrint('[Resume] Extracted ${_resumeText.length} chars from PDF');
      } else {
        _resumeText = '';
      }
    } catch (e) {
      debugPrint('[Resume] PDF extraction error: $e');
      _resumeText = '';
    }

    yield const IngestProgress('Analysing resume structure…', 0.8);

    final lineCount = _resumeText.split('\n').where((l) => l.trim().isNotEmpty).length;

    _resume = Resume(
      id: 'res-${DateTime.now().millisecondsSinceEpoch}',
      fileName: fileName,
      sizeBytes: sizeBytes,
      uploadedAt: DateTime.now(),
      pageCount: _estimatePages(sizeBytes),
      chunkCount: (lineCount / 5).ceil().clamp(1, 999),
      status: _resumeText.isNotEmpty ? ResumeStatus.ready : ResumeStatus.error,
    );

    yield const IngestProgress('Done ✓', 1.0);
  }

  @override
  Future<void> deleteResume() async {
    _resume = null;
    _resumeText = '';
  }

  int _estimatePages(int bytes) => (bytes / 50000).ceil().clamp(1, 20);
}
