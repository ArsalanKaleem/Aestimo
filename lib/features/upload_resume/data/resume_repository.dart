import 'dart:async';

import '../../../core/constants/app_constants.dart';
import '../models/resume.dart';

/// Stages emitted during upload so the UI can show RAG pipeline progress.
class IngestProgress {
  const IngestProgress(this.label, this.fraction);
  final String label;
  final double fraction; // 0..1
}

abstract class ResumeRepository {
  Future<Resume?> getResume();

  /// Uploads [bytes] and runs the RAG pipeline, streaming progress:
  /// extract text → chunk → embed → store vectors.
  Stream<IngestProgress> upload({
    required String fileName,
    required int sizeBytes,
    List<int>? bytes,
  });

  Future<void> deleteResume();
}

class MockResumeRepository implements ResumeRepository {
  Resume? _stored;

  @override
  Future<Resume?> getResume() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return _stored;
  }

  @override
  Stream<IngestProgress> upload({
    required String fileName,
    required int sizeBytes,
    List<int>? bytes,
  }) async* {
    const steps = [
      'Extracting text from PDF…',
      'Chunking content…',
      'Generating embeddings…',
      'Storing vectors in ChromaDB…',
      'Enabling semantic search…',
    ];
    for (var i = 0; i < steps.length; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 520));
      yield IngestProgress(steps[i], (i + 1) / steps.length);
    }
    _stored = Resume(
      id: 'res-${DateTime.now().millisecondsSinceEpoch}',
      fileName: fileName,
      sizeBytes: sizeBytes,
      uploadedAt: DateTime.now(),
      pageCount: 2,
      chunkCount: 38,
      status: ResumeStatus.ready,
    );
  }

  @override
  Future<void> deleteResume() async {
    await Future<void>.delayed(AppConstants.mockLatency);
    _stored = null;
  }
}

/// ---------------------------------------------------------------------------
/// Live implementation seam (FastAPI + Firebase Storage + ChromaDB):
///   1. PUT file bytes → Firebase Storage, get download URL
///   2. POST {url} → FastAPI /resume/upload  (server runs the RAG pipeline)
///   3. Server returns {id, pageCount, chunkCount}; persist metadata
/// Stream progress via SSE/WebSocket or poll /resume status.
/// ---------------------------------------------------------------------------
