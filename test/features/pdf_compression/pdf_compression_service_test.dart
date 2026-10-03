import 'dart:io';
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;

import 'package:flux_convert/core/logging/logger_service.dart';
import 'package:flux_convert/features/pdf_compression/data/services/pdf_compression_service.dart';
import 'package:flux_convert/features/pdf_compression/domain/entities/pdf_compression_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    try {
      AppLogger.init();
    } catch (_) {}
  });

  late Directory tempDir;
  late PdfCompressionService compressionService;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('compress_service_test_');
    compressionService = const PdfCompressionService();
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    }
  });

  String createTestPdf(String name, {int numPages = 1}) {
    final doc = sf.PdfDocument();
    doc.compressionLevel = sf.PdfCompressionLevel.none;

    for (var i = 0; i < numPages; i++) {
      final page = doc.pages.add();
      page.graphics.drawString(
        'Test PDF Page ${i + 1} content for compression testing',
        sf.PdfStandardFont(sf.PdfFontFamily.helvetica, 16),
        bounds: const Rect.fromLTWH(20, 20, 400, 40),
      );
    }

    final bytes = doc.saveSync();
    doc.dispose();

    final filePath = '${tempDir.path}/$name';
    final file = File(filePath);
    file.writeAsBytesSync(bytes);
    return filePath;
  }

  group('PdfCompressionService Unit Tests', () {
    test('compressPdf reduces file size or safely retains original', () async {
      final inputPath = createTestPdf('test_sample.pdf', numPages: 3);
      final outputPath = '${tempDir.path}/test_sample_compressed.pdf';

      final params = PdfCompressionParams(
        inputPath: inputPath,
        outputPath: outputPath,
        level: PdfCompressionLevel.medium,
      );

      final result = await compressionService.compressPdf(params);

      expect(result.isSuccess, isTrue);
      expect(File(outputPath).existsSync(), isTrue);
      expect(result.destinationPath, equals(outputPath));
      expect(result.originalSizeBytes, greaterThan(0));
      expect(result.compressedSizeBytes, greaterThan(0));
    });

    test('compressPdf handles missing file safely without crashing', () async {
      final inputPath = '${tempDir.path}/non_existent.pdf';
      final outputPath = '${tempDir.path}/non_existent_compressed.pdf';

      final params = PdfCompressionParams(
        inputPath: inputPath,
        outputPath: outputPath,
        level: PdfCompressionLevel.max,
      );

      final result = await compressionService.compressPdf(params);

      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, contains('does not exist'));
    });

    test('compressPdf handles Max, Medium, and Low levels cleanly', () async {
      for (final lvl in PdfCompressionLevel.values) {
        final inputPath = createTestPdf('test_${lvl.name}.pdf', numPages: 2);
        final outputPath = '${tempDir.path}/test_${lvl.name}_out.pdf';

        final params = PdfCompressionParams(
          inputPath: inputPath,
          outputPath: outputPath,
          level: lvl,
        );

        final result = await compressionService.compressPdf(params);
        expect(result.isSuccess, isTrue);
        expect(File(outputPath).existsSync(), isTrue);
      }
    });

    test('pdf compression config props check', () {
      expect(PdfCompressionLevel.max.displayName, equals('Max Compression'));
      expect(PdfCompressionLevel.medium.displayName, equals('Medium Compression'));
      expect(PdfCompressionLevel.low.displayName, equals('Low Compression'));
    });
  });
}
