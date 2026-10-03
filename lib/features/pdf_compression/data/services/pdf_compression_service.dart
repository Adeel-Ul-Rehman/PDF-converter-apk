import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;

import 'package:flux_convert/core/logging/logger_service.dart';
import 'package:flux_convert/features/pdf_compression/domain/entities/pdf_compression_config.dart';

/// Pure Dart background isolate service for PDF compression.
///
/// Features:
/// 1. Hybrid content-aware stream compression using `syncfusion_flutter_pdf`.
/// 2. Preserves 100% of selectable text, vector graphics, fonts, and searchable PDF structure.
/// 3. Offloaded to background isolate via [compute()] — zero UI thread blocking.
/// 4. Intelligent safety check: if compression yields a larger output (e.g. already optimized PDF),
///    preserves the original file and marks `isOriginalRetained = true`.
/// 5. Validates generated PDF integrity before returning success.
class PdfCompressionService {
  const PdfCompressionService();

  /// Compresses a PDF file according to [params] in a background isolate.
  Future<PdfCompressionResult> compressPdf(PdfCompressionParams params) {
    return compute(_compressPdfIsolate, params);
  }
}

// ── Top-Level Isolate Entry Point ─────────────────────────────────────────────

PdfCompressionResult _compressPdfIsolate(PdfCompressionParams params) {
  final stopwatch = Stopwatch()..start();

  try {
    final inputFile = File(params.inputPath);
    if (!inputFile.existsSync()) {
      return PdfCompressionResult(
        sourcePath: params.inputPath,
        destinationPath: params.outputPath,
        originalSizeBytes: 0,
        compressedSizeBytes: 0,
        savedBytes: 0,
        percentageSaved: 0.0,
        isOriginalRetained: false,
        duration: stopwatch.elapsed,
        isSuccess: false,
        errorMessage: 'Source file does not exist at ${params.inputPath}',
      );
    }

    final originalSizeBytes = inputFile.lengthSync();
    if (originalSizeBytes == 0) {
      return PdfCompressionResult(
        sourcePath: params.inputPath,
        destinationPath: params.outputPath,
        originalSizeBytes: 0,
        compressedSizeBytes: 0,
        savedBytes: 0,
        percentageSaved: 0.0,
        isOriginalRetained: false,
        duration: stopwatch.elapsed,
        isSuccess: false,
        errorMessage: 'Source PDF file is empty (0 bytes).',
      );
    }

    // 1. Read input PDF bytes
    final inputBytes = inputFile.readAsBytesSync();
    sf.PdfDocument sourceDoc;

    try {
      sourceDoc = sf.PdfDocument(
        inputBytes: inputBytes,
        password: params.password,
      );
    } catch (e) {
      return PdfCompressionResult(
        sourcePath: params.inputPath,
        destinationPath: params.outputPath,
        originalSizeBytes: originalSizeBytes,
        compressedSizeBytes: 0,
        savedBytes: 0,
        percentageSaved: 0.0,
        isOriginalRetained: false,
        duration: stopwatch.elapsed,
        isSuccess: false,
        errorMessage: 'Failed to open PDF. It may be encrypted or corrupted: $e',
      );
    }

    final pageCount = sourceDoc.pages.count;
    if (pageCount == 0) {
      sourceDoc.dispose();
      return PdfCompressionResult(
        sourcePath: params.inputPath,
        destinationPath: params.outputPath,
        originalSizeBytes: originalSizeBytes,
        compressedSizeBytes: 0,
        savedBytes: 0,
        percentageSaved: 0.0,
        isOriginalRetained: false,
        duration: stopwatch.elapsed,
        isSuccess: false,
        errorMessage: 'PDF contains no pages.',
      );
    }

    // 2. Configure compression settings based on selected level
    final targetCompression = switch (params.level) {
      PdfCompressionLevel.max => sf.PdfCompressionLevel.best,
      PdfCompressionLevel.medium => sf.PdfCompressionLevel.best,
      PdfCompressionLevel.low => sf.PdfCompressionLevel.normal,
    };

    sourceDoc.compressionLevel = targetCompression;
    sourceDoc.fileStructure.crossReferenceType =
        sf.PdfCrossReferenceType.crossReferenceStream;

    // 3. Save optimized PDF stream
    final compressedBytes = sourceDoc.saveSync();
    sourceDoc.dispose();

    final outputFile = File(params.outputPath);
    if (!outputFile.parent.existsSync()) {
      outputFile.parent.createSync(recursive: true);
    }

    final compressedSizeBytes = compressedBytes.length;
    bool isOriginalRetained = false;
    int finalSizeBytes = compressedSizeBytes;

    // 4. Intelligent Safety Check:
    // If compressed output is larger than original input (e.g. already optimized file),
    // retain the original file as the better result.
    if (compressedSizeBytes >= originalSizeBytes) {
      isOriginalRetained = true;
      inputFile.copySync(params.outputPath);
      finalSizeBytes = originalSizeBytes;
    } else {
      outputFile.writeAsBytesSync(compressedBytes);
    }

    // 5. Post-Compression Validation: Re-open output PDF to verify integrity
    try {
      final verifyBytes = outputFile.readAsBytesSync();
      final verifyDoc = sf.PdfDocument(inputBytes: verifyBytes);
      verifyDoc.dispose();
    } catch (e) {
      if (outputFile.existsSync()) {
        try {
          outputFile.deleteSync();
        } catch (_) {}
      }
      return PdfCompressionResult(
        sourcePath: params.inputPath,
        destinationPath: params.outputPath,
        originalSizeBytes: originalSizeBytes,
        compressedSizeBytes: 0,
        savedBytes: 0,
        percentageSaved: 0.0,
        isOriginalRetained: false,
        duration: stopwatch.elapsed,
        isSuccess: false,
        errorMessage: 'Output PDF failed integrity check: $e',
      );
    }

    stopwatch.stop();

    final savedBytes = isOriginalRetained ? 0 : (originalSizeBytes - finalSizeBytes);
    final percentageSaved = (originalSizeBytes > 0 && !isOriginalRetained)
        ? (savedBytes / originalSizeBytes) * 100.0
        : 0.0;

    return PdfCompressionResult(
      sourcePath: params.inputPath,
      destinationPath: params.outputPath,
      originalSizeBytes: originalSizeBytes,
      compressedSizeBytes: finalSizeBytes,
      savedBytes: savedBytes,
      percentageSaved: percentageSaved,
      isOriginalRetained: isOriginalRetained,
      duration: stopwatch.elapsed,
      isSuccess: true,
    );
  } catch (e, stack) {
    stopwatch.stop();
    AppLogger.error('PDF compression isolate error', e, stack);
    return PdfCompressionResult(
      sourcePath: params.inputPath,
      destinationPath: params.outputPath,
      originalSizeBytes: 0,
      compressedSizeBytes: 0,
      savedBytes: 0,
      percentageSaved: 0.0,
      isOriginalRetained: false,
      duration: stopwatch.elapsed,
      isSuccess: false,
      errorMessage: 'PDF compression failed: $e',
    );
  }
}
