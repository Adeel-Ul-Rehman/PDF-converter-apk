import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import 'package:flux_convert/core/core.dart';
import 'package:flux_convert/features/image_editor/presentation/widgets/aspect_ratio_selector.dart';
import 'package:flux_convert/features/image_editor/presentation/widgets/crop_controller.dart';
import 'package:flux_convert/features/image_editor/presentation/widgets/crop_handle.dart';

/// CropRect data model for compatibility with image editor pipeline.
class CropRect {
  const CropRect({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  final double left;   // Fraction 0..1
  final double top;    // Fraction 0..1
  final double width;  // Fraction 0..1
  final double height; // Fraction 0..1
}

// FIXED: Enterprise Ultra-Smooth Crop Page featuring 8 interactive touch handles & Mirror Effect
class CropPage extends StatefulWidget {
  const CropPage({
    required this.imageFile,
    this.initialCropRect,
    super.key,
  });

  final File imageFile;
  final CropRect? initialCropRect;

  @override
  State<CropPage> createState() => _CropPageState();
}

class _CropPageState extends State<CropPage> {
  late final CropController _controller;
  Uint8List? _uint8Bytes;
  Size _imageSize = Size.zero;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final initData = widget.initialCropRect != null
        ? CropRectData(
            left: widget.initialCropRect!.left,
            top: widget.initialCropRect!.top,
            width: widget.initialCropRect!.width,
            height: widget.initialCropRect!.height,
          )
        : CropRectData.full;

    _controller = CropController(initialCrop: initData);
    _loadImage();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadImage() async {
    try {
      final bytes = await widget.imageFile.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded != null) {
        setState(() {
          _uint8Bytes = bytes;
          _imageSize = Size(decoded.width.toDouble(), decoded.height.toDouble());
          _isLoading = false;
        });
      }
    } catch (e) {
      AppLogger.error('CropPage: Failed decoding image', e);
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF12151C) : const Color(0xFF181818),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Crop & Adjust',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => IconButton(
              icon: const Icon(Icons.undo_rounded, color: Colors.white),
              onPressed: _controller.canUndo ? () => _controller.undo() : null,
              tooltip: 'Undo',
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: () => _controller.reset(),
            tooltip: 'Reset Crop',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColorScheme.primaryBlueStart,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                final c = _controller.current;
                final result = CropRect(
                  left: c.left,
                  top: c.top,
                  width: c.width,
                  height: c.height,
                );
                Navigator.pop(context, result);
              },
              child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: _isLoading || _uint8Bytes == null
          ? const Center(child: CircularProgressIndicator(color: AppColorScheme.primaryBlueStart))
          : Column(
              children: [
                // Aspect Ratio Selector Bar
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) => AspectRatioSelector(
                    selectedRatio: _controller.aspectRatio,
                    onRatioSelected: (ratio) =>
                        _controller.setAspectRatio(ratio, _imageSize),
                  ),
                ),

                // Main Interactive Interactive Crop Viewport
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return AnimatedBuilder(
                          animation: _controller,
                          builder: (context, _) => _buildCropViewport(
                            context,
                            constraints.maxWidth,
                            constraints.maxHeight,
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // FIXED: Bottom Control Toolbar with prominent Mirror & Rotate Buttons
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E2028),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: SafeArea(
                    top: false,
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) => Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          // Mirror Horizontal Button
                          _buildControlActionButton(
                            icon: Icons.flip_rounded,
                            label: 'Mirror H',
                            isActive: _controller.isFlippedHorizontally,
                            onTap: () => _controller.toggleFlipHorizontal(),
                          ),

                          // Mirror Vertical Button
                          _buildControlActionButton(
                            icon: Icons.flip_camera_android_rounded,
                            label: 'Mirror V',
                            isActive: _controller.isFlippedVertically,
                            onTap: () => _controller.toggleFlipVertical(),
                          ),

                          // Rotate 90° Button
                          _buildControlActionButton(
                            icon: Icons.rotate_right_rounded,
                            label: 'Rotate 90°',
                            isActive: false,
                            onTap: () => _controller.rotate90Degrees(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildControlActionButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? AppColorScheme.primaryBlueStart : Colors.white,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppColorScheme.primaryBlueStart : Colors.white70,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCropViewport(BuildContext context, double viewWidth, double viewHeight) {
    final imgWidth = _imageSize.width;
    final imgHeight = _imageSize.height;

    final viewRatio = viewWidth / viewHeight;
    final imgRatio = imgWidth / imgHeight;

    double renderedWidth;
    double renderedHeight;

    if (imgRatio > viewRatio) {
      renderedWidth = viewWidth;
      renderedHeight = viewWidth / imgRatio;
    } else {
      renderedHeight = viewHeight;
      renderedWidth = viewHeight * imgRatio;
    }

    final offsetX = (viewWidth - renderedWidth) / 2;
    final offsetY = (viewHeight - renderedHeight) / 2;

    final c = _controller.current;
    final cropRectPx = Rect.fromLTWH(
      offsetX + (c.left * renderedWidth),
      offsetY + (c.top * renderedHeight),
      c.width * renderedWidth,
      c.height * renderedHeight,
    );

    return Stack(
      children: [
        // 1. Rendered Image with Mirror & Rotation Transformations
        Positioned(
          left: offsetX,
          top: offsetY,
          width: renderedWidth,
          height: renderedHeight,
          child: Transform.scale(
            scaleX: _controller.isFlippedHorizontally ? -1.0 : 1.0,
            scaleY: _controller.isFlippedVertically ? -1.0 : 1.0,
            child: RotatedBox(
              quarterTurns: _controller.rotationTurns,
              child: Image.memory(
                _uint8Bytes!,
                fit: BoxFit.contain,
                gaplessPlayback: true,
              ),
            ),
          ),
        ),

        // 2. Rule of Thirds painter & dimming mask
        CustomPaint(
          size: Size(viewWidth, viewHeight),
          painter: CropGridPainter(
            cropRect: cropRectPx,
          ),
        ),

        // 3. Pan gesture on crop box center (Move whole crop area)
        Positioned(
          left: cropRectPx.left,
          top: cropRectPx.top,
          width: cropRectPx.width,
          height: cropRectPx.height,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onPanUpdate: (details) {
              final dLeft = details.delta.dx / renderedWidth;
              final dTop = details.delta.dy / renderedHeight;
              _controller.updateCropEdges(
                left: c.left + dLeft,
                top: c.top + dTop,
                right: c.right + dLeft,
                bottom: c.bottom + dTop,
                imageSize: _imageSize,
              );
            },
          ),
        ),

        // 4. Corner Handles (Top-Left, Top-Right, Bottom-Left, Bottom-Right)
        CropHandleWidget(
          position: cropRectPx.topLeft,
          type: CropHandleType.topLeft,
          onPanUpdate: (delta) {
            final dL = delta.dx / renderedWidth;
            final dT = delta.dy / renderedHeight;
            _controller.updateCropEdges(
              left: c.left + dL,
              top: c.top + dT,
              right: c.right,
              bottom: c.bottom,
              imageSize: _imageSize,
            );
          },
        ),
        CropHandleWidget(
          position: cropRectPx.topRight,
          type: CropHandleType.topRight,
          onPanUpdate: (delta) {
            final dR = delta.dx / renderedWidth;
            final dT = delta.dy / renderedHeight;
            _controller.updateCropEdges(
              left: c.left,
              top: c.top + dT,
              right: c.right + dR,
              bottom: c.bottom,
              imageSize: _imageSize,
            );
          },
        ),
        CropHandleWidget(
          position: cropRectPx.bottomLeft,
          type: CropHandleType.bottomLeft,
          onPanUpdate: (delta) {
            final dL = delta.dx / renderedWidth;
            final dB = delta.dy / renderedHeight;
            _controller.updateCropEdges(
              left: c.left + dL,
              top: c.top,
              right: c.right,
              bottom: c.bottom + dB,
              imageSize: _imageSize,
            );
          },
        ),
        CropHandleWidget(
          position: cropRectPx.bottomRight,
          type: CropHandleType.bottomRight,
          onPanUpdate: (delta) {
            final dR = delta.dx / renderedWidth;
            final dB = delta.dy / renderedHeight;
            _controller.updateCropEdges(
              left: c.left,
              top: c.top,
              right: c.right + dR,
              bottom: c.bottom + dB,
              imageSize: _imageSize,
            );
          },
        ),

        // 5. Edge Handles (Top Edge, Bottom Edge, Left Edge, Right Edge)
        CropHandleWidget(
          position: Offset(cropRectPx.left + cropRectPx.width / 2, cropRectPx.top),
          type: CropHandleType.top,
          onPanUpdate: (delta) {
            final dT = delta.dy / renderedHeight;
            _controller.updateCropEdges(
              left: c.left,
              top: c.top + dT,
              right: c.right,
              bottom: c.bottom,
              imageSize: _imageSize,
            );
          },
        ),
        CropHandleWidget(
          position: Offset(cropRectPx.left + cropRectPx.width / 2, cropRectPx.bottom),
          type: CropHandleType.bottom,
          onPanUpdate: (delta) {
            final dB = delta.dy / renderedHeight;
            _controller.updateCropEdges(
              left: c.left,
              top: c.top,
              right: c.right,
              bottom: c.bottom + dB,
              imageSize: _imageSize,
            );
          },
        ),
        CropHandleWidget(
          position: Offset(cropRectPx.left, cropRectPx.top + cropRectPx.height / 2),
          type: CropHandleType.left,
          onPanUpdate: (delta) {
            final dL = delta.dx / renderedWidth;
            _controller.updateCropEdges(
              left: c.left + dL,
              top: c.top,
              right: c.right,
              bottom: c.bottom,
              imageSize: _imageSize,
            );
          },
        ),
        CropHandleWidget(
          position: Offset(cropRectPx.right, cropRectPx.top + cropRectPx.height / 2),
          type: CropHandleType.right,
          onPanUpdate: (delta) {
            final dR = delta.dx / renderedWidth;
            _controller.updateCropEdges(
              left: c.left,
              top: c.top,
              right: c.right + dR,
              bottom: c.bottom,
              imageSize: _imageSize,
            );
          },
        ),
      ],
    );
  }
}

/// CropEditorDialog wrapper for modal dialog usage across existing routes.
class CropEditorDialog extends StatelessWidget {
  const CropEditorDialog({
    required this.imageFile,
    this.initialCropRect,
    super.key,
  });

  final File imageFile;
  final CropRect? initialCropRect;

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: CropPage(
        imageFile: imageFile,
        initialCropRect: initialCropRect,
      ),
    );
  }
}
