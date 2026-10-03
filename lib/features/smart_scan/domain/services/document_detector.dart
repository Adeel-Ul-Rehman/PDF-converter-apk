import 'dart:math';
import 'package:image/image.dart' as img;
import 'package:flux_convert/features/smart_scan/domain/entities/document_quadrilateral.dart';

/// Pure Dart Document Boundary & Quadrilateral Detector.
class DocumentDetector {
  const DocumentDetector();

  /// Analyzes an image and returns the best detected 4-corner document quadrilateral,
  /// or null if no distinct document edges are found.
  DocumentQuadrilateral? detectDocument(img.Image srcImage) {
    if (srcImage.width < 50 || srcImage.height < 50) return null;

    final w = srcImage.width;
    final h = srcImage.height;

    // Downscale for fast edge detection analysis
    const maxDim = 320;
    var evalImg = srcImage;
    var scale = 1.0;

    if (w > maxDim || h > maxDim) {
      if (w > h) {
        scale = maxDim / w;
        evalImg = img.copyResize(srcImage, width: maxDim, height: (h * scale).round());
      } else {
        scale = maxDim / h;
        evalImg = img.copyResize(srcImage, width: (w * scale).round(), height: maxDim);
      }
    }

    final ew = evalImg.width;
    final eh = evalImg.height;

    // Convert to grayscale luminance matrix
    final luminance = List<int>.filled(ew * eh, 0);
    for (var y = 0; y < eh; y++) {
      for (var x = 0; x < ew; x++) {
        final pixel = evalImg.getPixel(x, y);
        // Luminance formula
        final l = (0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b).round();
        luminance[y * ew + x] = l;
      }
    }

    // Sobel gradient magnitude calculation
    final edges = List<int>.filled(ew * eh, 0);
    for (var y = 1; y < eh - 1; y++) {
      for (var x = 1; x < ew - 1; x++) {
        final gx = (luminance[(y - 1) * ew + (x + 1)] + 2 * luminance[y * ew + (x + 1)] + luminance[(y + 1) * ew + (x + 1)]) -
                   (luminance[(y - 1) * ew + (x - 1)] + 2 * luminance[y * ew + (x - 1)] + luminance[(y + 1) * ew + (x - 1)]);
        final gy = (luminance[(y + 1) * ew + (x - 1)] + 2 * luminance[(y + 1) * ew + x] + luminance[(y + 1) * ew + (x + 1)]) -
                   (luminance[(y - 1) * ew + (x - 1)] + 2 * luminance[(y - 1) * ew + x] + luminance[(y - 1) * ew + (x + 1)]);
        final mag = sqrt(gx * gx + gy * gy).round();
        edges[y * ew + x] = mag > 60 ? mag : 0;
      }
    }

    // Find extreme corners of edge pixels across 4 quadrants
    Point<double>? bestTL;
    Point<double>? bestTR;
    Point<double>? bestBR;
    Point<double>? bestBL;
    var minTL = double.infinity;
    var minTR = double.infinity;
    var minBR = double.infinity;
    var minBL = double.infinity;

    for (var y = 0; y < eh; y++) {
      for (var x = 0; x < ew; x++) {
        if (edges[y * ew + x] > 50) {
          final nx = x / ew;
          final ny = y / eh;

          final dTL = nx * nx + ny * ny;
          final dTR = (1.0 - nx) * (1.0 - nx) + ny * ny;
          final dBR = (1.0 - nx) * (1.0 - nx) + (1.0 - ny) * (1.0 - ny);
          final dBL = nx * nx + (1.0 - ny) * (1.0 - ny);

          if (dTL < minTL) {
            minTL = dTL;
            bestTL = Point(nx, ny);
          }
          if (dTR < minTR) {
            minTR = dTR;
            bestTR = Point(nx, ny);
          }
          if (dBR < minBR) {
            minBR = dBR;
            bestBR = Point(nx, ny);
          }
          if (dBL < minBL) {
            minBL = dBL;
            bestBL = Point(nx, ny);
          }
        }
      }
    }

    // Fallback padding if corners are too close to edge or missing
    const margin = 0.05;
    final quad = DocumentQuadrilateral(
      topLeft: bestTL ?? const Point(margin, margin),
      topRight: bestTR ?? const Point(1.0 - margin, margin),
      bottomRight: bestBR ?? const Point(1.0 - margin, 1.0 - margin),
      bottomLeft: bestBL ?? const Point(margin, 1.0 - margin),
    );

    if (quad.isValid && quad.areaRatio >= 0.15) {
      return quad;
    }

    // Default document inset if edge detection is uncertain
    return const DocumentQuadrilateral(
      topLeft: Point(0.05, 0.05),
      topRight: Point(0.95, 0.05),
      bottomRight: Point(0.95, 0.95),
      bottomLeft: Point(0.05, 0.95),
    );
  }
}
