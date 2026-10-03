import 'package:flutter/material.dart';
import 'package:flux_convert/features/annotations/domain/annotation_models.dart';

// FIXED: Enhanced smooth Bezier doodle board painter
/// Renders annotations for a single page with silk-smooth Bezier curve interpolation.
class DoodleBoardPainter extends CustomPainter {
  const DoodleBoardPainter({required this.strokes, this.pageIndex = 0});

  final List<DoodleStroke> strokes;
  final int pageIndex;

  @override
  void paint(Canvas canvas, Size size) {
    // Filter strokes by page (or 0 for single page image editor)
    final pageStrokes = pageIndex == 0
        ? strokes
        : strokes.where((s) => s.pageIndex == pageIndex || s.pageIndex == 0).toList();

    for (final stroke in pageStrokes) {
      if (stroke.points.isEmpty) continue;

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = stroke.width
        ..color = stroke.isEraser ? const Color(0x00000000) : stroke.color
        ..blendMode = stroke.isEraser ? BlendMode.clear : BlendMode.srcOver;

      _drawSmoothPath(canvas, paint, stroke.points);
    }
  }

  /// Draws a smooth Bezier curve from points
  void _drawSmoothPath(Canvas canvas, Paint paint, List<Offset> points) {
    if (points.isEmpty) return;

    if (points.length == 1) {
      canvas.drawCircle(points.first, paint.strokeWidth / 2, paint);
      return;
    }

    // Quadratic bezier interpolation for silk-smooth lines
    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    for (var i = 0; i < points.length - 1; i++) {
      final p2 = points[i + 1];

      if (i < points.length - 2) {
        final p3 = points[i + 2];
        final mid = Offset((p2.dx + p3.dx) / 2, (p2.dy + p3.dy) / 2);
        path.quadraticBezierTo(p2.dx, p2.dy, mid.dx, mid.dy);
      } else {
        path.lineTo(p2.dx, p2.dy);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant DoodleBoardPainter oldDelegate) =>
      oldDelegate.strokes != strokes || oldDelegate.pageIndex != pageIndex;
}
