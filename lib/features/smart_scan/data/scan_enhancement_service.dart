import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import 'package:flux_convert/features/smart_scan/domain/entities/document_quadrilateral.dart';
import 'package:flux_convert/features/smart_scan/domain/entities/scanned_page.dart';

/// Parameters for background image enhancement processing.
class ScanEnhancementParams {
  const ScanEnhancementParams({
    required this.sourcePath,
    required this.outputPath,
    this.quadrilateral,
    this.rotation = 0,
    this.enhancementMode = ScanEnhancementMode.original,
    this.brightness = 0.0,
    this.contrast = 100.0,
  });

  final String sourcePath;
  final String outputPath;
  final DocumentQuadrilateral? quadrilateral;
  final int rotation;
  final ScanEnhancementMode enhancementMode;
  final double brightness; // -100 to +100
  final double contrast; // 0 to 200

  ScanEnhancementParams copyWith({
    String? sourcePath,
    String? outputPath,
    DocumentQuadrilateral? quadrilateral,
    int? rotation,
    ScanEnhancementMode? enhancementMode,
    double? brightness,
    double? contrast,
  }) {
    return ScanEnhancementParams(
      sourcePath: sourcePath ?? this.sourcePath,
      outputPath: outputPath ?? this.outputPath,
      quadrilateral: quadrilateral ?? this.quadrilateral,
      rotation: rotation ?? this.rotation,
      enhancementMode: enhancementMode ?? this.enhancementMode,
      brightness: brightness ?? this.brightness,
      contrast: contrast ?? this.contrast,
    );
  }
}

/// Offline, pure Dart document enhancement service.
/// Uses background isolates via Flutter compute() to prevent freezing the UI.
class ScanEnhancementService {
  const ScanEnhancementService();

  /// Offloads heavy image decoding, perspective transform, rotation, and color
  /// enhancement to a background isolate.
  Future<String> processImageInIsolate(ScanEnhancementParams params) async {
    return compute(_bakeScanEnhancementIsolate, params);
  }

  /// Calculates a 5x5 ColorFilter matrix for instant 60fps Flutter UI preview feedback
  /// while background isolate baking runs.
  ColorFilter buildColorFilter(
    ScanEnhancementMode mode, {
    double brightness = 0.0,
    double contrast = 100.0,
  }) {
    final matrix = calculateColorMatrix(mode, brightness: brightness, contrast: contrast);
    return ColorFilter.matrix(matrix);
  }

  /// Generates 20-element matrix for ColorFilter.matrix()
  List<double> calculateColorMatrix(
    ScanEnhancementMode mode, {
    double brightness = 0.0,
    double contrast = 100.0,
  }) {
    final c = contrast / 100.0;
    final b = brightness;

    final base = switch (mode) {
      ScanEnhancementMode.original => const [
          1.0, 0.0, 0.0, 0.0, 0.0,
          0.0, 1.0, 0.0, 0.0, 0.0,
          0.0, 0.0, 1.0, 0.0, 0.0,
          0.0, 0.0, 0.0, 1.0, 0.0,
        ],
      ScanEnhancementMode.color => const [
          1.2, -0.1, -0.1, 0.0, 0.0,
          -0.1, 1.2, -0.1, 0.0, 0.0,
          -0.1, -0.1, 1.2, 0.0, 0.0,
          0.0, 0.0, 0.0, 1.0, 0.0,
        ],
      ScanEnhancementMode.grayscale => const [
          0.2126, 0.7152, 0.0722, 0.0, 0.0,
          0.2126, 0.7152, 0.0722, 0.0, 0.0,
          0.2126, 0.7152, 0.0722, 0.0, 0.0,
          0.0, 0.0, 0.0, 1.0, 0.0,
        ],
      ScanEnhancementMode.blackAndWhite => const [
          0.33 * 1.8, 0.33 * 1.8, 0.33 * 1.8, 0.0, -35.0,
          0.33 * 1.8, 0.33 * 1.8, 0.33 * 1.8, 0.0, -35.0,
          0.33 * 1.8, 0.33 * 1.8, 0.33 * 1.8, 0.0, -35.0,
          0.0, 0.0, 0.0, 1.0, 0.0,
        ],
      ScanEnhancementMode.document => const [
          0.33 * 2.0, 0.33 * 2.0, 0.33 * 2.0, 0.0, -20.0,
          0.33 * 2.0, 0.33 * 2.0, 0.33 * 2.0, 0.0, -20.0,
          0.33 * 2.0, 0.33 * 2.0, 0.33 * 2.0, 0.0, -20.0,
          0.0, 0.0, 0.0, 1.0, 0.0,
        ],
    };

    final result = List<double>.from(base);

    // Apply contrast scaling
    if (contrast != 100.0) {
      for (var i = 0; i < 15; i++) {
        result[i] *= c;
      }
    }

    // Apply brightness offset
    if (brightness != 0.0) {
      result[4] += b;
      result[9] += b;
      result[14] += b;
    }

    return result;
  }
}

// ─── Background Isolate Entry Point ──────────────────────────────────────────

String _bakeScanEnhancementIsolate(ScanEnhancementParams params) {
  final srcFile = File(params.sourcePath);
  if (!srcFile.existsSync()) return params.sourcePath;

  final decoded = img.decodeImage(srcFile.readAsBytesSync());
  if (decoded == null) return params.sourcePath;

  img.Image activeImage = decoded;

  // 1. Optional Perspective Dewarp
  if (params.quadrilateral != null && params.quadrilateral!.isValid) {
    try {
      final quad = params.quadrilateral!;
      final src = activeImage;
      final srcW = src.width.toDouble();
      final srcH = src.height.toDouble();

      final x0 = quad.topLeft.x * srcW;
      final y0 = quad.topLeft.y * srcH;
      final x1 = quad.topRight.x * srcW;
      final y1 = quad.topRight.y * srcH;
      final x2 = quad.bottomRight.x * srcW;
      final y2 = quad.bottomRight.y * srcH;
      final x3 = quad.bottomLeft.x * srcW;
      final y3 = quad.bottomLeft.y * srcH;

      final topW = sqrt((x1 - x0) * (x1 - x0) + (y1 - y0) * (y1 - y0));
      final botW = sqrt((x2 - x3) * (x2 - x3) + (y2 - y3) * (y2 - y3));
      final leftH = sqrt((x3 - x0) * (x3 - x0) + (y3 - y0) * (y3 - y0));
      final rightH = sqrt((x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1));

      final maxW = topW > botW ? topW : botW;
      final maxH = leftH > rightH ? leftH : rightH;

      final w = maxW.round().clamp(200, 3500);
      final h = maxH.round().clamp(200, 3500);

      final outImg = img.Image(width: w, height: h);

      for (var y = 0; y < h; y++) {
        final v = y / h;
        for (var x = 0; x < w; x++) {
          final u = x / w;
          final srcX = (1 - u) * (1 - v) * x0 + u * (1 - v) * x1 + u * v * x2 + (1 - u) * v * x3;
          final srcY = (1 - u) * (1 - v) * y0 + u * (1 - v) * y1 + u * v * y2 + (1 - u) * v * y3;
          final px = srcX.round().clamp(0, src.width - 1);
          final py = srcY.round().clamp(0, src.height - 1);
          outImg.setPixel(x, y, src.getPixel(px, py));
        }
      }
      activeImage = outImg;
    } catch (_) {
      // Fall back to original image if dewarp fails
    }
  }

  // 2. Rotation (0, 90, 180, 270)
  if (params.rotation != 0) {
    activeImage = img.copyRotate(activeImage, angle: params.rotation);
  }

  // 3. Brightness & Contrast
  final cVal = params.contrast / 100.0;
  final bVal = (params.brightness + 100.0) / 100.0;
  if (cVal != 1.0 || bVal != 1.0) {
    activeImage = img.adjustColor(activeImage, contrast: cVal, brightness: bVal);
  }

  // 4. Enhancement Modes
  switch (params.enhancementMode) {
    case ScanEnhancementMode.original:
      break;
    case ScanEnhancementMode.color:
      activeImage = img.adjustColor(activeImage, contrast: 1.25, saturation: 1.2);
    case ScanEnhancementMode.grayscale:
      activeImage = img.grayscale(activeImage);
    case ScanEnhancementMode.blackAndWhite:
      activeImage = img.grayscale(activeImage);
      activeImage = img.adjustColor(activeImage, contrast: 1.8);
    case ScanEnhancementMode.document:
      activeImage = img.grayscale(activeImage);
      activeImage = img.adjustColor(activeImage, contrast: 2.0, brightness: 1.05);
  }

  final outFile = File(params.outputPath);
  if (!outFile.parent.existsSync()) {
    outFile.parent.createSync(recursive: true);
  }

  outFile.writeAsBytesSync(img.encodeJpg(activeImage, quality: 90));
  return params.outputPath;
}
