import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'package:flux_convert/features/smart_scan/data/scan_enhancement_service.dart';
import 'package:flux_convert/features/smart_scan/domain/entities/scanned_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late ScanEnhancementService service;
  late String sampleImagePath;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('enhancement_test_');
    service = const ScanEnhancementService();

    // Create a 100x100 RGB image fixture
    final image = img.Image(width: 100, height: 100);
    img.fill(image, color: img.ColorRgb8(200, 100, 50));
    sampleImagePath = '${tempDir.path}/test_source.jpg';
    File(sampleImagePath).writeAsBytesSync(img.encodeJpg(image));
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    }
  });

  group('ScanEnhancementService Unit Tests', () {
    test('calculateColorMatrix returns 20-element list for all modes', () {
      for (final mode in ScanEnhancementMode.values) {
        final matrix = service.calculateColorMatrix(
          mode,
          brightness: 10.0,
          contrast: 120.0,
        );
        expect(matrix.length, equals(20));
      }
    });

    test('buildColorFilter returns valid ColorFilter', () {
      final filter = service.buildColorFilter(
        ScanEnhancementMode.document,
        brightness: 5.0,
        contrast: 110.0,
      );
      expect(filter, isNotNull);
    });

    test('processImageInIsolate bakes enhanced image to output path', () async {
      final outputPath = '${tempDir.path}/test_output.jpg';

      final params = ScanEnhancementParams(
        sourcePath: sampleImagePath,
        outputPath: outputPath,
        rotation: 90,
        enhancementMode: ScanEnhancementMode.grayscale,
        brightness: 5.0,
        contrast: 110.0,
      );

      final result = await service.processImageInIsolate(params);

      expect(result, equals(outputPath));
      final outFile = File(outputPath);
      expect(outFile.existsSync(), isTrue);

      final decoded = img.decodeImage(outFile.readAsBytesSync());
      expect(decoded, isNotNull);
      expect(decoded!.width, equals(100)); // 100x100 rotated is 100x100
    });
  });
}
