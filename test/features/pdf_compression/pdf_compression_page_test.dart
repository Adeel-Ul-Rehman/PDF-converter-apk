import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;

import 'package:flux_convert/core/logging/logger_service.dart';
import 'package:flux_convert/features/pdf_compression/presentation/pages/pdf_compression_page.dart';
import 'package:flux_convert/features/pdf_compression/presentation/providers/pdf_compression_notifier.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    try {
      AppLogger.init();
    } catch (_) {}
  });

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('page_compress_test_');
  });

  tearDown(() async {
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

  testWidgets('PdfCompressionPage renders empty state when no file selected', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: PdfCompressionPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Compress PDF'), findsOneWidget);
    expect(find.text('Select a PDF Document'), findsOneWidget);
    expect(find.text('Browse Files'), findsOneWidget);
  });

  testWidgets('PdfCompressionPage renders info and compression levels when file selected', (WidgetTester tester) async {
    final pdfPath = createTestPdf('sample.pdf');

    await tester.pumpWidget(
      ProviderScope(
        child: Consumer(
          builder: (context, ref, _) {
            Future.microtask(() => ref.read(pdfCompressionProvider.notifier).selectFile(pdfPath));
            return const MaterialApp(
              home: PdfCompressionPage(),
            );
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('sample.pdf'), findsOneWidget);
    expect(find.text('Select Compression Level'), findsOneWidget);
    expect(find.text('Max Compression'), findsOneWidget);
    expect(find.text('Medium Compression'), findsOneWidget);
    expect(find.text('Low Compression'), findsOneWidget);
    expect(find.text('Recommended'), findsOneWidget);
  });
}
