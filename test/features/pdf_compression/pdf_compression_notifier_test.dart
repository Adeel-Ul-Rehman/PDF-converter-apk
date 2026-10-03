import 'dart:io';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;

import 'package:flux_convert/core/logging/logger_service.dart';
import 'package:flux_convert/features/pdf_compression/domain/entities/pdf_compression_config.dart';
import 'package:flux_convert/features/pdf_compression/presentation/providers/pdf_compression_notifier.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    try {
      AppLogger.init();
    } catch (_) {}
  });

  late Directory tempDir;
  late ProviderContainer container;
  late PdfCompressionNotifier notifier;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('notifier_compress_test_');

    container = ProviderContainer();

    notifier = container.read(pdfCompressionProvider.notifier);
  });

  tearDown(() async {
    container.dispose();
    if (tempDir.existsSync()) {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    }
  });

  String createTestPdf(String name) {
    final doc = sf.PdfDocument();
    final page = doc.pages.add();
    page.graphics.drawString(
      'Test PDF Page content',
      sf.PdfStandardFont(sf.PdfFontFamily.helvetica, 16),
      bounds: const Rect.fromLTWH(20, 20, 300, 30),
    );
    final bytes = doc.saveSync();
    doc.dispose();

    final filePath = '${tempDir.path}/$name';
    File(filePath).writeAsBytesSync(bytes);
    return filePath;
  }

  group('PdfCompressionNotifier Tests', () {
    test('initial state has no file and default medium level', () {
      final state = container.read(pdfCompressionProvider);
      expect(state.hasFile, isFalse);
      expect(state.level, equals(PdfCompressionLevel.medium));
      expect(state.status, equals(PdfCompressionStatus.initial));
    });

    test('selectFile sets selected PDF metadata', () async {
      final pdfPath = createTestPdf('sample.pdf');
      await notifier.selectFile(pdfPath);

      final state = container.read(pdfCompressionProvider);
      expect(state.hasFile, isTrue);
      expect(state.fileName, equals('sample.pdf'));
      expect(state.pageCount, equals(1));
      expect(state.originalSizeBytes, greaterThan(0));
      expect(state.status, equals(PdfCompressionStatus.selected));
    });

    test('setCompressionLevel updates selected mode', () async {
      notifier.setCompressionLevel(PdfCompressionLevel.max);
      expect(container.read(pdfCompressionProvider).level, equals(PdfCompressionLevel.max));

      notifier.setCompressionLevel(PdfCompressionLevel.low);
      expect(container.read(pdfCompressionProvider).level, equals(PdfCompressionLevel.low));
    });

    test('clearSelection resets state to initial', () async {
      final pdfPath = createTestPdf('sample.pdf');
      await notifier.selectFile(pdfPath);

      notifier.clearSelection();

      final state = container.read(pdfCompressionProvider);
      expect(state.hasFile, isFalse);
      expect(state.status, equals(PdfCompressionStatus.initial));
    });

    test('selectFile errors gracefully on non-pdf extension', () async {
      final textFile = File('${tempDir.path}/sample.txt')..writeAsStringSync('not a pdf');
      await notifier.selectFile(textFile.path);

      final state = container.read(pdfCompressionProvider);
      expect(state.status, equals(PdfCompressionStatus.error));
      expect(state.errorMessage, contains('Only PDF files can be compressed'));
    });
  });
}
