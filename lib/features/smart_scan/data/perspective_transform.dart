import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import 'package:flux_convert/features/smart_scan/domain/entities/document_quadrilateral.dart';

/// Parameters passed to the perspective warp isolate.
class PerspectiveParams {
  const PerspectiveParams({
    required this.imageBytes,
    required this.quadrilateral,
    required this.targetWidth,
    required this.targetHeight,
  });

  final Uint8List imageBytes;
  final DocumentQuadrilateral quadrilateral;
  final int targetWidth;
  final int targetHeight;
}

/// Homography Matrix & Perspective Transformation Engine.
class PerspectiveTransform {
  /// Warps a document image according to a 4-corner quadrilateral using a background isolate.
  static Future<img.Image?> warpPerspective(
    img.Image srcImage,
    DocumentQuadrilateral quad, {
    int? targetWidth,
    int? targetHeight,
  }) async {
    final srcW = srcImage.width.toDouble();
    final srcH = srcImage.height.toDouble();

    // Determine destination target dimensions based on quad corner distances
    final topW = _dist(quad.topLeft, quad.topRight) * srcW;
    final botW = _dist(quad.bottomLeft, quad.bottomRight) * srcW;
    final leftH = _dist(quad.topLeft, quad.bottomLeft) * srcH;
    final rightH = _dist(quad.topRight, quad.bottomRight) * srcH;

    final maxW = topW > botW ? topW : botW;
    final maxH = leftH > rightH ? leftH : rightH;

    final outW = (targetWidth ?? maxW.round()).clamp(200, 3500);
    final outH = (targetHeight ?? maxH.round()).clamp(200, 3500);

    final encodedPng = Uint8List.fromList(img.encodePng(srcImage));

    final params = PerspectiveParams(
      imageBytes: encodedPng,
      quadrilateral: quad,
      targetWidth: outW,
      targetHeight: outH,
    );

    final resultBytes = await compute(_warpPerspectiveIsolate, params);
    if (resultBytes == null) return null;
    return img.decodeImage(resultBytes);
  }

  static double _dist(Point<double> p1, Point<double> p2) {
    final dx = p1.x - p2.x;
    final dy = p1.y - p2.y;
    return sqrt(dx * dx + dy * dy);
  }
}

/// Top-level isolate entry point for computing perspective warping off the UI thread.
Uint8List? _warpPerspectiveIsolate(PerspectiveParams params) {
  final src = img.decodeImage(params.imageBytes);
  if (src == null) return null;

  final w = params.targetWidth;
  final h = params.targetHeight;
  final quad = params.quadrilateral;

  final outImg = img.Image(width: w, height: h);

  // Absolute corner coordinates on source image
  final x0 = quad.topLeft.x * src.width;
  final y0 = quad.topLeft.y * src.height;

  final x1 = quad.topRight.x * src.width;
  final y1 = quad.topRight.y * src.height;

  final x2 = quad.bottomRight.x * src.width;
  final y2 = quad.bottomRight.y * src.height;

  final x3 = quad.bottomLeft.x * src.width;
  final y3 = quad.bottomLeft.y * src.height;

  // Bilinear perspective transformation loop
  for (var y = 0; y < h; y++) {
    final v = y / h;
    for (var x = 0; x < w; x++) {
      final u = x / w;

      // Bilinear interpolation formula between the 4 vertices
      final srcX = (1 - u) * (1 - v) * x0 + u * (1 - v) * x1 + u * v * x2 + (1 - u) * v * x3;
      final srcY = (1 - u) * (1 - v) * y0 + u * (1 - v) * y1 + u * v * y2 + (1 - u) * v * y3;

      final px = srcX.round().clamp(0, src.width - 1);
      final py = srcY.round().clamp(0, src.height - 1);

      final color = src.getPixel(px, py);
      outImg.setPixel(x, y, color);
    }
  }

  return Uint8List.fromList(img.encodeJpg(outImg, quality: 92));
}
