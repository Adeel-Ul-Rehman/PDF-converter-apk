import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flux_convert/core/theme/app_colors.dart';

/// Custom Painter for Rule-of-Thirds crop grid and translucent dimming mask
class CropGridPainter extends CustomPainter {
  CropGridPainter({
    required this.cropRect,
    this.showGrid = true,
    this.maskColor = const Color(0x99000000),
    this.borderColor = AppColorScheme.primaryBlueStart,
  });

  final Rect cropRect;
  final bool showGrid;
  final Color maskColor;
  final Color borderColor;

  @override
  void paint(Canvas canvas, Size size) {
    final fullRect = Rect.fromLTWH(0, 0, size.width, size.height);

    // 1. Draw outer translucent mask outside crop area
    final maskPaint = Paint()..color = maskColor;
    final path = Path()
      ..addRect(fullRect)
      ..addRect(cropRect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, maskPaint);

    // 2. Draw high-contrast crop outline border
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRect(cropRect, borderPaint);

    // 3. Draw Rule-of-Thirds grid lines inside crop box
    if (showGrid && cropRect.width > 40 && cropRect.height > 40) {
      final gridPaint = Paint()
        ..color = Colors.white.withOpacity(0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      final w = cropRect.width;
      final h = cropRect.height;

      // Vertical grid lines
      canvas.drawLine(
        Offset(cropRect.left + w / 3, cropRect.top),
        Offset(cropRect.left + w / 3, cropRect.bottom),
        gridPaint,
      );
      canvas.drawLine(
        Offset(cropRect.left + (2 * w) / 3, cropRect.top),
        Offset(cropRect.left + (2 * w) / 3, cropRect.bottom),
        gridPaint,
      );

      // Horizontal grid lines
      canvas.drawLine(
        Offset(cropRect.left, cropRect.top + h / 3),
        Offset(cropRect.right, cropRect.top + h / 3),
        gridPaint,
      );
      canvas.drawLine(
        Offset(cropRect.left, cropRect.top + (2 * h) / 3),
        Offset(cropRect.right, cropRect.top + (2 * h) / 3),
        gridPaint,
      );
    }
  }

  @override
  bool shouldRepaint(CropGridPainter oldDelegate) =>
      oldDelegate.cropRect != cropRect ||
      oldDelegate.showGrid != showGrid ||
      oldDelegate.maskColor != maskColor ||
      oldDelegate.borderColor != borderColor;
}

/// 8 Handle Types for 360° Crop Control
enum CropHandleType {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
  top,
  bottom,
  left,
  right,
}

/// High-Precision, Ultra-Smooth Crop Handle Widget with 48x48 Touch Target Area
class CropHandleWidget extends StatelessWidget {
  const CropHandleWidget({
    required this.position,
    required this.type,
    required this.onPanUpdate,
    this.onPanStart,
    this.onPanEnd,
    super.key,
  });

  final Offset position;
  final CropHandleType type;
  final ValueChanged<Offset> onPanUpdate;
  final VoidCallback? onPanStart;
  final VoidCallback? onPanEnd;

  @override
  Widget build(BuildContext context) {
    const hitAreaSize = 48.0;

    return Positioned(
      left: position.dx - hitAreaSize / 2,
      top: position.dy - hitAreaSize / 2,
      width: hitAreaSize,
      height: hitAreaSize,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (_) {
          HapticFeedback.selectionClick();
          onPanStart?.call();
        },
        onPanUpdate: (details) => onPanUpdate(details.delta),
        onPanEnd: (_) => onPanEnd?.call(),
        child: Center(
          child: _buildHandleVisual(),
        ),
      ),
    );
  }

  Widget _buildHandleVisual() {
    final isCorner = type == CropHandleType.topLeft ||
        type == CropHandleType.topRight ||
        type == CropHandleType.bottomLeft ||
        type == CropHandleType.bottomRight;

    if (isCorner) {
      // Sleek Corner L-Bracket
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColorScheme.primaryBlueStart, width: 3.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(80),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      );
    } else {
      // Sleek Edge Horizontal / Vertical Bar
      final isHorizontal = type == CropHandleType.top || type == CropHandleType.bottom;

      return Container(
        width: isHorizontal ? 32 : 12,
        height: isHorizontal ? 12 : 32,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColorScheme.primaryBlueStart, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(60),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      );
    }
  }
}
