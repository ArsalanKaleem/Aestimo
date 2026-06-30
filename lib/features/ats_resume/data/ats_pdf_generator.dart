import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/ats_resume.dart';

/// Generates an ATS-safe PDF from [AtsResume].
///
/// Design principles:
/// • Single-column layout — ATS parsers choke on multi-column.
/// • Standard Helvetica — no custom fonts needed, fully embedded.
/// • No Unicode bullets (•) — Helvetica lacks them; use ASCII hyphen instead.
/// • No images, icons, or graphics.
class AtsPdfGenerator {
  static Future<Uint8List> generate(AtsResume resume) async {
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 36),
        build: (pw.Context context) => [
          _header(resume),
          pw.SizedBox(height: 6),
          _divider(),
          pw.SizedBox(height: 8),
          _summary(resume.summary),
          pw.SizedBox(height: 10),
          ...resume.sections.expand((s) => [
            _sectionHeading(s.heading),
            pw.SizedBox(height: 4),
            _sectionBody(s.content),
            pw.SizedBox(height: 10),
          ]),
        ],
      ),
    );

    return doc.save();
  }

  // ── Sanitise text — strip any non-ASCII that Helvetica can't render ────────

  /// Replaces Unicode bullet variants with an ASCII hyphen and removes any
  /// other characters outside the Latin-1 printable range (32–255) that
  /// Helvetica cannot render, avoiding the □ / ▯ glyph-missing boxes.
  static String _sanitise(String input) {
    return input
    // All common Unicode bullet / dash variants → ASCII hyphen
        .replaceAll('•', '-')
        .replaceAll('\u2022', '-') // bullet
        .replaceAll('\u2023', '-') // triangular bullet
        .replaceAll('\u25E6', '-') // white bullet
        .replaceAll('\u2043', '-') // hyphen bullet
        .replaceAll('\u2013', '-') // en dash
        .replaceAll('\u2014', '-') // em dash
        .replaceAll('\u2018', "'") // left single quote
        .replaceAll('\u2019', "'") // right single quote
        .replaceAll('\u201C', '"') // left double quote
        .replaceAll('\u201D', '"') // right double quote
        .replaceAll('\u2026', '...') // ellipsis
    // Remove anything still outside printable Latin-1
        .replaceAll(RegExp(r'[^\x20-\xFF\n\r\t]'), '');
  }

  // ── Widgets ────────────────────────────────────────────────────────────────

  static pw.Widget _header(AtsResume resume) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          _sanitise(resume.name.toUpperCase()),
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          _sanitise(resume.contactLine),
          textAlign: pw.TextAlign.center,
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
        ),
      ],
    );
  }

  static pw.Widget _divider() {
    return pw.Container(height: 1, color: PdfColors.grey800);
  }

  static pw.Widget _summary(String text) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'PROFESSIONAL SUMMARY',
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
        pw.SizedBox(height: 3),
        pw.Container(height: 0.5, color: PdfColors.grey500),
        pw.SizedBox(height: 4),
        pw.Text(
          _sanitise(text),
          style: const pw.TextStyle(fontSize: 9.5, lineSpacing: 1.4),
        ),
      ],
    );
  }

  static pw.Widget _sectionHeading(String title) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          _sanitise(title),
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Container(height: 0.5, color: PdfColors.grey500),
      ],
    );
  }

  static pw.Widget _sectionBody(String content) {
    final lines = _sanitise(content).split('\n');
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: lines.map((line) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) return pw.SizedBox(height: 3);

        // Detect bullet lines: -, *, or any leftover • already sanitised to -
        final isBullet = RegExp(r'^[-*]').hasMatch(trimmed);

        if (isBullet) {
          final text = trimmed.replaceFirst(RegExp(r'^[-*]\s*'), '');
          return pw.Padding(
            padding: const pw.EdgeInsets.only(left: 12, bottom: 2),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // ASCII hyphen — renders perfectly in Helvetica
                pw.Text(
                  '-  ',
                  style: const pw.TextStyle(fontSize: 9.5),
                ),
                pw.Expanded(
                  child: pw.Text(
                    text,
                    style: const pw.TextStyle(fontSize: 9.5, lineSpacing: 1.3),
                  ),
                ),
              ],
            ),
          );
        }

        // Job title / company / date line — bold if it contains | or a year
        final isMeta =
            trimmed.contains('|') || RegExp(r'\d{4}').hasMatch(trimmed);
        return pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 2),
          child: pw.Text(
            trimmed,
            style: pw.TextStyle(
              fontSize: 9.5,
              fontWeight:
              isMeta ? pw.FontWeight.bold : pw.FontWeight.normal,
              lineSpacing: 1.3,
            ),
          ),
        );
      }).toList(),
    );
  }
}