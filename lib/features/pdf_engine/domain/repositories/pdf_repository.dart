import 'package:flux_convert/core/core.dart';
import 'package:flux_convert/features/pdf_engine/domain/entities/pdf_task.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// PdfRepository
///
/// Repository contract detailing PDF creation, manipulation and conversion paths.
/// ─────────────────────────────────────────────────────────────────────────────
abstract interface class PdfRepository {
  /// Converts multiple images to a PDF file.
  Future<Result<String>> imageToPdf({
    required String taskId,
    required ImageToPdfParams params,
    required String outputPath,
    required void Function(double progress) onProgress,
  });

  /// Exports PDF pages to PNG image files.
  Future<Result<List<String>>> pdfToImage({
    required String taskId,
    required PdfToImageParams params,
    required String outputDir,
    required void Function(double progress) onProgress,
  });

  /// Merges multiple PDFs into one.
  Future<Result<String>> mergePdf({
    required String taskId,
    required PdfMergeParams params,
    required String outputPath,
    required void Function(double progress) onProgress,
  });

  /// Splits PDF pages into multiple PDF segments.
  Future<Result<List<String>>> splitPdf({
    required String taskId,
    required PdfSplitParams params,
    required String outputDir,
    required void Function(double progress) onProgress,
  });

  /// Rotates pages in a PDF file.
  Future<Result<String>> rotatePdf({
    required String taskId,
    required PdfRotateParams params,
    required String outputPath,
    required void Function(double progress) onProgress,
  });

  /// Compresses a PDF file size.
  Future<Result<String>> compressPdf({
    required String taskId,
    required PdfCompressParams params,
    required String outputPath,
    required void Function(double progress) onProgress,
  });

  /// Cancels an active PDF task.
  Future<Result<void>> cancelTask(String taskId);
}
