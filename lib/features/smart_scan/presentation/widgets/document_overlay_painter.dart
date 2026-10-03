import 'package:flutter/material.dart';
import 'package:flux_convert/core/core.dart';
import 'package:flux_convert/features/smart_scan/domain/entities/document_quadrilateral.dart';

/// CustomPainter rendering real-time document bounding polygon and corner indicators.
class DocumentOverlayPainter extends CustomPainter {
  DocumentOverlayPainter({
    required this.quadrilateral,
    required this.isStable,
  });

  final DocumentQuadrilateral? quadrilateral;
  final bool isStable;

  @override
  void paint(Canvas canvas, Size size) {
    if (quadrilateral == null) {
      _drawGuideGrid(canvas, size);
      return;
    }

    final quad = quadrilateral!;
    final strokeColor = isStable ? const Color(0xFF00E676) : AppColorScheme.primaryBlueStart;
    final fillColor = isStable ? const Color(0x3300E676) : const Color(0x220080FF);

    final tl = Offset(quad.topLeft.x * size.width, quad.topLeft.y * size.height);
    final tr = Offset(quad.topRight.x * size.width, quad.topRight.y * size.height);
    final br = Offset(quad.bottomRight.x * size.width, quad.bottomRight.y * size.height);
    final bl = Offset(quad.bottomLeft.x * size.width, quad.bottomLeft.y * size.height);

    final path = Path()
      ..moveTo(tl.dx, tl.dy)
      ..lineTo(tr.dx, tr.dy)
      ..lineTo(br.dx, br.dy)
      ..lineTo(bl.dx, bl.dy)
      ..close();

    // 1. Draw quad fill
    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // 2. Draw quad boundary stroke
    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, strokePaint);

    // 3. Draw corner handles
    final cornerPaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.fill;
    final innerDotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (final p in [tl, tr, br, bl]) {
      canvas.drawCircle(p, 8, cornerPaint);
      canvas.drawCircle(p, 3.5, innerDotPaint);
    }
  }

  void _drawGuideGrid(Canvas canvas, Size size) {
    final guidePaint = Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final marginX = size.width * 0.08;
    final marginY = size.height * 0.08;

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTRB(marginX, marginY, size.width - marginX, size.height - marginY),
      const Radius.circular(16),
    );

    canvas.drawRRect(rect, guidePaint);
  }

  @override
  bool shouldRepaint(covariant DocumentOverlayPainter oldDelegate) {
    return oldDelegate.quadrilateral != quadrilateral || oldDelegate.isStable != isStable;
  }
}
