import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:flux_convert/features/smart_scan/data/perspective_transform.dart';
import 'package:flux_convert/features/smart_scan/domain/entities/document_quadrilateral.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PerspectiveTransform Unit Tests', () {
    test('warpPerspective executes on test image fixture without errors', () async {
      // Create test 200x200 image
      final testImg = img.Image(width: 200, height: 200);
      img.fill(testImg, color: img.ColorRgb8(255, 0, 0));

      const quad = DocumentQuadrilateral(
        topLeft: Point(0.1, 0.1),
        topRight: Point(0.9, 0.1),
        bottomRight: Point(0.9, 0.9),
        bottomLeft: Point(0.1, 0.9),
      );

      final warped = await PerspectiveTransform.warpPerspective(
        testImg,
        quad,
        targetWidth: 400,
        targetHeight: 400,
      );

      expect(warped, isNotNull);
      expect(warped!.width, equals(400));
      expect(warped.height, equals(400));
    });
  });
}
