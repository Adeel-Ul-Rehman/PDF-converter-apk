import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Colors, Offset, Rect, TextAlign;
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;

import 'package:flux_convert/features/annotations/domain/annotation_models.dart';

// IMPROVED: Vector PDF annotation exporter with compute() isolate offloading
/// Bakes [PageAnnotations] onto an existing PDF as vector graphics.
///
/// The heavy byte-array work (reading source PDF, drawing, serializing)
/// runs in a background isolate via [compute()] so the UI thread stays free.
class PdfAnnotationExporter {
  /// Merges the annotation lists for all pages into the source PDF.
  ///
  /// IMPROVED: Offloaded to a background isolate — zero UI thread blocking.
  Future<List<int>> exportAnnotations({
    required String sourcePath,
    required List<PageAnnotations> pages,
  }) =>
      compute(
        _exportAnnotationsInIsolate,
        _AnnotationExportParams(sourcePath: sourcePath, pages: pages),
      );
}

// ─── Isolate entry point (must be top-level) ──────────────────────────────────

/// IMPROVED: Top-level function required by compute() — cannot be a closure.
List<int> _exportAnnotationsInIsolate(_AnnotationExportParams params) {
  final bytes = File(params.sourcePath).readAsBytesSync();
  final doc = sf.PdfDocument(inputBytes: bytes);

  try {
    final pageCount = doc.pages.count;

    for (var i = 0; i < pageCount && i < params.pages.length; i++) {
      final pageAnnots = params.pages[i];

      if (pageAnnots.doodles.isEmpty &&
          pageAnnots.texts.isEmpty &&
          pageAnnots.signatures.isEmpty) {
        continue;
      }

      final page = doc.pages[i];
      final size = page.getClientSize();
      final graphics = page.graphics;

      // FIXED: Dynamic ratio based on actual captured viewport canvas vs PDF page size
      final scaleX =
          size.width / (pageAnnots.width > 0 ? pageAnnots.width : size.width);
      final scaleY =
          size.height /
          (pageAnnots.height > 0 ? pageAnnots.height : size.height);

      // Draw doodles
      for (final stroke in pageAnnots.doodles) {
        if (stroke.isEraser) continue;
        _drawDoodle(graphics, stroke, scaleX, scaleY, Offset.zero, 1.0);
      }

      // Draw signatures
      for (final sig in pageAnnots.signatures) {
        _drawSignature(graphics, sig, scaleX, scaleY);
      }

      // Draw text annotations
      for (final t in pageAnnots.texts) {
        _drawTextAnnotation(graphics, t, scaleX, scaleY);
      }
    }

    return doc.saveSync();
  } finally {
    doc.dispose();
  }
}

// ─── Params message class for isolate ────────────────────────────────────────

/// IMPROVED: Plain-data message object for compute() — all fields are
/// primitives or Equatable objects safe to copy across isolate boundaries.
class _AnnotationExportParams {
  const _AnnotationExportParams({
    required this.sourcePath,
    required this.pages,
  });

  final String sourcePath;
  final List<PageAnnotations> pages;
}

// ─── Drawing helpers (top-level, reusable from isolate) ──────────────────────

void _drawSignature(
  sf.PdfGraphics graphics,
  SignatureAnnotation signature,
  double scaleX,
  double scaleY,
) {
  final ox = signature.offset.dx * scaleX;
  final oy = signature.offset.dy * scaleY;
  final s = signature.scale;

  graphics.save();
  graphics.translateTransform(ox, oy);
  if (signature.rotation != 0) {
    graphics.rotateTransform(signature.rotation * 180 / 3.14159);
  }

  if (signature.isTyped) {
    // Draw typed signature
    final font = sf.PdfStandardFont(
      _getFontFamily(signature.fontFamily),
      signature.fontSize * 0.75 * s * scaleY,
    );
    graphics.drawString(
      signature.text,
      font,
      brush: sf.PdfSolidBrush(_toPdfColor(signature.color)),
    );
  } else {
    // Draw drawn signature (scale coordinates manually)
    for (final stroke in signature.strokes) {
      if (stroke.points.isEmpty) continue;

      final pen = sf.PdfPen(_toPdfColor(signature.color))
        ..width = stroke.width * 0.75 * s * ((scaleX + scaleY) / 2)
        ..lineJoin = sf.PdfLineJoin.round;

      final pts = stroke.points;
      if (pts.length == 1) {
        final px = pts[0].dx * s * scaleX;
        final py = pts[0].dy * s * scaleY;
        graphics.drawRectangle(
          pen: pen,
          bounds: Rect.fromLTWH(
            px - pen.width / 2,
            py - pen.width / 2,
            pen.width,
            pen.width,
          ),
        );
        continue;
      }

      for (var i = 0; i < pts.length - 1; i++) {
        graphics.drawLine(
          pen,
          Offset(pts[i].dx * s * scaleX, pts[i].dy * s * scaleY),
          Offset(pts[i + 1].dx * s * scaleX, pts[i + 1].dy * s * scaleY),
        );
      }
    }
  }

  graphics.restore();
}

void _drawTextAnnotation(
  sf.PdfGraphics graphics,
  TextAnnotation text,
  double scaleX,
  double scaleY,
) {
  final fontSize = text.fontSize * scaleY;

  // Draw background highlight if not transparent
  if (text.backgroundColor != Colors.transparent) {
    final font = sf.PdfStandardFont(_getFontFamily(text.fontFamily), fontSize);
    final textWidth = font.measureString(text.text).width;
    final textHeight = fontSize * 1.2;
    final rect = Rect.fromLTWH(
      text.offset.dx * scaleX - 4,
      text.offset.dy * scaleY - 2,
      textWidth + 8,
      textHeight + 4,
    );
    final bgBrush = sf.PdfSolidBrush(_toPdfColor(text.backgroundColor));
    graphics.save();
    graphics.setTransparency(0.3);
    graphics.drawRectangle(brush: bgBrush, bounds: rect);
    graphics.restore();
  }

  graphics.save();
  graphics.translateTransform(
    text.offset.dx * scaleX,
    text.offset.dy * scaleY,
  );

  if (text.rotation != 0) {
    graphics.rotateTransform(text.rotation * 180 / 3.14159);
  }

  // PdfFontStyle is a plain enum — pick style
  final sf.PdfFontStyle fontStyle;
  if (text.isUnderline) {
    fontStyle = sf.PdfFontStyle.underline;
  } else if (text.fontWeight == 'bold') {
    fontStyle = sf.PdfFontStyle.bold;
  } else if (text.fontStyle == 'italic') {
    fontStyle = sf.PdfFontStyle.italic;
  } else {
    fontStyle = sf.PdfFontStyle.regular;
  }

  final font = sf.PdfStandardFont(
    _getFontFamily(text.fontFamily),
    fontSize,
    style: fontStyle,
  );

  final textWidth = font.measureString(text.text).width;
  final xOffset = switch (text.alignment) {
    TextAlign.center => -textWidth / 2,
    TextAlign.right => -textWidth,
    _ => 0.0,
  };

  graphics.translateTransform(xOffset, 0);
  graphics.drawString(
    text.text,
    font,
    brush: sf.PdfSolidBrush(_toPdfColor(text.color)),
  );

  graphics.restore();
}

void _drawDoodle(
  sf.PdfGraphics graphics,
  DoodleStroke stroke,
  double scaleX,
  double scaleY,
  Offset offset,
  double scale,
) {
  if (stroke.points.isEmpty) return;

  final pen = sf.PdfPen(_toPdfColor(stroke.color))
    ..width = stroke.width * scale * 0.75 * ((scaleX + scaleY) / 2)
    ..lineJoin = sf.PdfLineJoin.round;

  final points = stroke.points;
  if (points.length == 1) {
    final x = (points[0].dx * scale * scaleX) + offset.dx;
    final y = (points[0].dy * scale * scaleY) + offset.dy;
    graphics.drawRectangle(
      pen: pen,
      bounds: Rect.fromLTWH(
        x - pen.width / 2,
        y - pen.width / 2,
        pen.width,
        pen.width,
      ),
    );
    return;
  }

  for (var i = 0; i < points.length - 1; i++) {
    final aX = (points[i].dx * scale * scaleX) + offset.dx;
    final aY = (points[i].dy * scale * scaleY) + offset.dy;
    final bX = (points[i + 1].dx * scale * scaleX) + offset.dx;
    final bY = (points[i + 1].dy * scale * scaleY) + offset.dy;

    graphics.drawLine(pen, ui.Offset(aX, aY), ui.Offset(bX, bY));
  }
}

sf.PdfFontFamily _getFontFamily(String fontFamily) {
  switch (fontFamily.toLowerCase()) {
    case 'times new roman':
      return sf.PdfFontFamily.timesRoman;
    case 'courier new':
      return sf.PdfFontFamily.courier;
    case 'georgia':
      return sf.PdfFontFamily.timesRoman;
    case 'verdana':
    case 'comic sans ms':
    case 'impact':
    case 'trebuchet ms':
    case 'arial':
    case 'helvetica':
      return sf.PdfFontFamily.helvetica;
    default:
      return sf.PdfFontFamily.helvetica;
  }
}

sf.PdfColor _toPdfColor(ui.Color c) => sf.PdfColor(c.red, c.green, c.blue);
