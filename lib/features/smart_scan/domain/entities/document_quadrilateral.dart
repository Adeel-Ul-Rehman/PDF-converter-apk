import 'dart:math';
import 'package:equatable/equatable.dart';

/// Represents a 4-corner document polygon in normalized (0.0 to 1.0) coordinates.
class DocumentQuadrilateral extends Equatable {
  const DocumentQuadrilateral({
    required this.topLeft,
    required this.topRight,
    required this.bottomRight,
    required this.bottomLeft,
  });

  final Point<double> topLeft;
  final Point<double> topRight;
  final Point<double> bottomRight;
  final Point<double> bottomLeft;

  /// Default bounding box fallback spanning whole frame
  static const DocumentQuadrilateral fullFrame = DocumentQuadrilateral(
    topLeft: Point(0.0, 0.0),
    topRight: Point(1.0, 0.0),
    bottomRight: Point(1.0, 1.0),
    bottomLeft: Point(0.0, 1.0),
  );

  /// Checks whether the 4 corners form a valid convex quadrilateral.
  bool get isValid {
    // 1. Check points are within 0.0..1.0 range (with small tolerance)
    final points = [topLeft, topRight, bottomRight, bottomLeft];
    for (final p in points) {
      if (p.x < -0.1 || p.x > 1.1 || p.y < -0.1 || p.y > 1.1) {
        return false;
      }
    }

    // 2. Minimum area ratio check (must occupy at least 5% of total frame)
    if (areaRatio < 0.05) return false;

    // 3. Convexity check using cross product of adjacent edges
    return _isConvex();
  }

  /// Calculates quadrilateral area as a percentage of total unit frame (0.0 to 1.0).
  double get areaRatio {
    // Shoelace formula for 4-vertex polygon
    final area = 0.5 *
        ((topLeft.x * topRight.y - topRight.x * topLeft.y) +
            (topRight.x * bottomRight.y - bottomRight.x * topRight.y) +
            (bottomRight.x * bottomLeft.y - bottomLeft.x * bottomRight.y) +
            (bottomLeft.x * topLeft.y - topLeft.x * bottomLeft.y))
            .abs();
    return area;
  }

  bool _isConvex() {
    final points = [topLeft, topRight, bottomRight, bottomLeft];
    bool? positive;

    for (var i = 0; i < 4; i++) {
      final p1 = points[i];
      final p2 = points[(i + 1) % 4];
      final p3 = points[(i + 2) % 4];

      final dx1 = p2.x - p1.x;
      final dy1 = p2.y - p1.y;
      final dx2 = p3.x - p2.x;
      final dy2 = p3.y - p2.y;

      final crossProduct = dx1 * dy2 - dy1 * dx2;
      if (crossProduct == 0) continue;

      if (positive == null) {
        positive = crossProduct > 0;
      } else if ((crossProduct > 0) != positive) {
        return false;
      }
    }
    return positive != null;
  }

  /// Checks if this quadrilateral is similar to another within a coordinate distance tolerance.
  bool isSimilarTo(DocumentQuadrilateral other, {double tolerance = 0.04}) {
    return _dist(topLeft, other.topLeft) <= tolerance &&
        _dist(topRight, other.topRight) <= tolerance &&
        _dist(bottomRight, other.bottomRight) <= tolerance &&
        _dist(bottomLeft, other.bottomLeft) <= tolerance;
  }

  double _dist(Point<double> p1, Point<double> p2) {
    final dx = p1.x - p2.x;
    final dy = p1.y - p2.y;
    return sqrt(dx * dx + dy * dy);
  }

  /// Maps normalized (0..1) corners to absolute pixel dimensions (width x height).
  DocumentQuadrilateral toAbsolute(double width, double height) {
    return DocumentQuadrilateral(
      topLeft: Point(topLeft.x * width, topLeft.y * height),
      topRight: Point(topRight.x * width, topRight.y * height),
      bottomRight: Point(bottomRight.x * width, bottomRight.y * height),
      bottomLeft: Point(bottomLeft.x * width, bottomLeft.y * height),
    );
  }

  @override
  List<Object?> get props => [topLeft, topRight, bottomRight, bottomLeft];
}
