import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;

import 'package:flux_convert/core/core.dart';
import 'package:flux_convert/features/smart_scan/data/perspective_transform.dart';
import 'package:flux_convert/features/smart_scan/domain/entities/document_quadrilateral.dart';
import 'package:flux_convert/features/smart_scan/domain/services/document_detector.dart';

/// SmartScanCropPage — Interactive 4-Corner Manual Perspective Crop & Dewarp Page.
class SmartScanCropPage extends StatefulWidget {
  const SmartScanCropPage({
    required this.imagePath,
    this.initialQuad,
    super.key,
  });

  final String imagePath;
  final DocumentQuadrilateral? initialQuad;

  @override
  State<SmartScanCropPage> createState() => _SmartScanCropPageState();
}

class _SmartScanCropPageState extends State<SmartScanCropPage> {
  late Point<double> _tl;
  late Point<double> _tr;
  late Point<double> _br;
  late Point<double> _bl;
  bool _isProcessing = false;
  img.Image? _decodedImg;

  @override
  void initState() {
    super.initState();
    final quad = widget.initialQuad ?? const DocumentQuadrilateral(
      topLeft: Point(0.05, 0.05),
      topRight: Point(0.95, 0.05),
      bottomRight: Point(0.95, 0.95),
      bottomLeft: Point(0.05, 0.95),
    );
    _tl = quad.topLeft;
    _tr = quad.topRight;
    _br = quad.bottomRight;
    _bl = quad.bottomLeft;
    _loadSrcImage();
  }

  Future<void> _loadSrcImage() async {
    try {
      final file = File(widget.imagePath);
      if (file.existsSync()) {
        final bytes = await file.readAsBytes();
        final decoded = img.decodeImage(bytes);
        if (decoded != null && mounted) {
          setState(() {
            _decodedImg = decoded;
          });
          if (widget.initialQuad == null) {
            const detector = DocumentDetector();
            final detected = detector.detectDocument(decoded);
            if (detected != null && mounted) {
              setState(() {
                _tl = detected.topLeft;
                _tr = detected.topRight;
                _br = detected.bottomRight;
                _bl = detected.bottomLeft;
              });
            }
          }
        }
      }
    } catch (e) {
      AppLogger.error('SmartScanCropPage: Failed to load source image', e);
    }
  }

  void _resetCorners() {
    setState(() {
      _tl = const Point(0.05, 0.05);
      _tr = const Point(0.95, 0.05);
      _br = const Point(0.95, 0.95);
      _bl = const Point(0.05, 0.95);
    });
  }

  Future<void> _applyPerspectiveWarp() async {
    if (_decodedImg == null || _isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final quad = DocumentQuadrilateral(
        topLeft: _tl,
        topRight: _tr,
        bottomRight: _br,
        bottomLeft: _bl,
      );

      final warpedImg = await PerspectiveTransform.warpPerspective(_decodedImg!, quad);
      if (warpedImg != null) {
        final warpedBytes = img.encodeJpg(warpedImg, quality: 92);
        final file = File(widget.imagePath);
        await file.writeAsBytes(warpedBytes);

        if (mounted) {
          context.pop(widget.imagePath);
        }
      } else {
        if (mounted) {
          setState(() => _isProcessing = false);
          AppPopups.showSnackBar(context: context, message: 'Failed to process crop.');
        }
      }
    } catch (e, stack) {
      AppLogger.error('SmartScanCropPage: Warp calculation failed', e, stack);
      if (mounted) {
        setState(() => _isProcessing = false);
        AppPopups.showSnackBar(context: context, message: 'Crop error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColorScheme.backgroundDark : Colors.black;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Crop & Perspective',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Reset Corners',
            onPressed: _resetCorners,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _decodedImg == null
                  ? const Center(child: CustomCircularProgress())
                  : LayoutBuilder(
                      builder: (ctx, constraints) {
                        final size = Size(constraints.maxWidth, constraints.maxHeight);
                        return Stack(
                          children: [
                            Positioned.fill(
                              child: Image.file(
                                File(widget.imagePath),
                                fit: BoxFit.contain,
                              ),
                            ),
                            CustomPaint(
                              size: size,
                              painter: _CropGridOverlayPainter(
                                tl: _tl,
                                tr: _tr,
                                br: _br,
                                bl: _bl,
                              ),
                            ),
                            _buildHandle(_tl, (np) => setState(() => _tl = np), size),
                            _buildHandle(_tr, (np) => setState(() => _tr = np), size),
                            _buildHandle(_br, (np) => setState(() => _br = np), size),
                            _buildHandle(_bl, (np) => setState(() => _bl = np), size),
                          ],
                        );
                      },
                    ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.black,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white38),
                      ),
                      onPressed: () => context.pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColorScheme.primaryBlueStart,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _isProcessing ? null : _applyPerspectiveWarp,
                      child: _isProcessing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Apply Warp'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHandle(
    Point<double> point,
    void Function(Point<double>) onDrag,
    Size containerSize,
  ) {
    final handleX = point.x * containerSize.width;
    final handleY = point.y * containerSize.height;

    return Positioned(
      left: handleX - 22,
      top: handleY - 22,
      child: GestureDetector(
        onPanUpdate: (details) {
          final dx = details.delta.dx / containerSize.width;
          final dy = details.delta.dy / containerSize.height;
          final newX = (point.x + dx).clamp(0.0, 1.0);
          final newY = (point.y + dy).clamp(0.0, 1.0);
          onDrag(Point(newX, newY));
        },
        child: Container(
          width: 44,
          height: 44,
          color: Colors.transparent,
          child: Center(
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColorScheme.primaryBlueStart,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [
                  BoxShadow(color: Colors.black45, blurRadius: 4),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CropGridOverlayPainter extends CustomPainter {
  _CropGridOverlayPainter({
    required this.tl,
    required this.tr,
    required this.br,
    required this.bl,
  });

  final Point<double> tl;
  final Point<double> tr;
  final Point<double> br;
  final Point<double> bl;

  @override
  void paint(Canvas canvas, Size size) {
    final p1 = Offset(tl.x * size.width, tl.y * size.height);
    final p2 = Offset(tr.x * size.width, tr.y * size.height);
    final p3 = Offset(br.x * size.width, br.y * size.height);
    final p4 = Offset(bl.x * size.width, bl.y * size.height);

    final path = Path()
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p3.dx, p3.dy)
      ..lineTo(p4.dx, p4.dy)
      ..close();

    final fillPaint = Paint()
      ..color = const Color(0x330080FF)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    final strokePaint = Paint()
      ..color = AppColorScheme.primaryBlueStart
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _CropGridOverlayPainter oldDelegate) {
    return oldDelegate.tl != tl || oldDelegate.tr != tr || oldDelegate.br != br || oldDelegate.bl != bl;
  }
}
