import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:flux_convert/features/smart_scan/domain/entities/document_quadrilateral.dart';

void main() {
  group('DocumentQuadrilateral Unit Tests', () {
    test('fullFrame represents valid full unit square', () {
      const quad = DocumentQuadrilateral.fullFrame;
      expect(quad.isValid, isTrue);
      expect(quad.areaRatio, closeTo(1.0, 0.01));
    });

    test('valid inner quadrilateral returns true for isValid', () {
      const quad = DocumentQuadrilateral(
        topLeft: Point(0.1, 0.1),
        topRight: Point(0.9, 0.1),
        bottomRight: Point(0.9, 0.9),
        bottomLeft: Point(0.1, 0.9),
      );
      expect(quad.isValid, isTrue);
      expect(quad.areaRatio, closeTo(0.64, 0.02));
    });

    test('non-convex self-intersecting polygon returns false for isValid', () {
      const quad = DocumentQuadrilateral(
        topLeft: Point(0.1, 0.1),
        topRight: Point(0.1, 0.9), // Swapped points causing self-intersection
        bottomRight: Point(0.9, 0.1),
        bottomLeft: Point(0.9, 0.9),
      );
      expect(quad.isValid, isFalse);
    });

    test('isSimilarTo returns true within tolerance', () {
      const quad1 = DocumentQuadrilateral(
        topLeft: Point(0.1, 0.1),
        topRight: Point(0.9, 0.1),
        bottomRight: Point(0.9, 0.9),
        bottomLeft: Point(0.1, 0.9),
      );
      const quad2 = DocumentQuadrilateral(
        topLeft: Point(0.11, 0.11),
        topRight: Point(0.91, 0.11),
        bottomRight: Point(0.91, 0.91),
        bottomLeft: Point(0.11, 0.91),
      );
      expect(quad1.isSimilarTo(quad2, tolerance: 0.05), isTrue);
    });

    test('toAbsolute maps normalized points to target resolution', () {
      const quad = DocumentQuadrilateral(
        topLeft: Point(0.1, 0.2),
        topRight: Point(0.9, 0.2),
        bottomRight: Point(0.9, 0.8),
        bottomLeft: Point(0.1, 0.8),
      );

      final absQuad = quad.toAbsolute(1000, 2000);

      expect(absQuad.topLeft.x, equals(100.0));
      expect(absQuad.topLeft.y, equals(400.0));
      expect(absQuad.bottomRight.x, equals(900.0));
      expect(absQuad.bottomRight.y, equals(1600.0));
    });
  });
}
