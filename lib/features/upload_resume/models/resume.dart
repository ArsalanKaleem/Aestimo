import 'package:flutter/foundation.dart';

enum ResumeStatus { idle, uploading, processing, ready, error }

@immutable
class Resume {
  const Resume({
    required this.id,
    required this.fileName,
    required this.sizeBytes,
    required this.uploadedAt,
    this.pageCount,
    this.chunkCount,
    this.status = ResumeStatus.ready,
  });

  final String id;
  final String fileName;
  final int sizeBytes;
  final DateTime uploadedAt;
  final int? pageCount;

  /// Number of vector chunks produced by the RAG ingestion step.
  final int? chunkCount;
  final ResumeStatus status;

  String get readableSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(0)} KB';
    }
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Resume copyWith({ResumeStatus? status, int? chunkCount, int? pageCount}) {
    return Resume(
      id: id,
      fileName: fileName,
      sizeBytes: sizeBytes,
      uploadedAt: uploadedAt,
      pageCount: pageCount ?? this.pageCount,
      chunkCount: chunkCount ?? this.chunkCount,
      status: status ?? this.status,
    );
  }
}
