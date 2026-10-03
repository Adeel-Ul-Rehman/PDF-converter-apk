import 'package:flux_convert/core/core.dart';
import 'package:flux_convert/features/pdf_engine/core/pdf_progress_tracker.dart';
import 'package:flux_convert/features/pdf_engine/domain/entities/pdf_task.dart';
import 'package:flux_convert/features/pdf_engine/domain/repositories/pdf_repository.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// PdfService
///
/// High-level coordinator coordinating validations, progress, caching, and
/// background workers orchestration.
/// ─────────────────────────────────────────────────────────────────────────────
class PdfService {
  PdfService(this._repository) : _progressTracker = PdfProgressTracker();

  final PdfRepository _repository;
  final PdfProgressTracker _progressTracker;

  /// Retrieves the active progress tracker instance.
  PdfProgressTracker get progressTracker => _progressTracker;

  /// Converts a set of image files into a single PDF.
  Future<Result<String>> convertImagesToPdf({
    required String taskId,
    required List<String> imagePaths,
    required String outputPath,
    required void Function(double progress) onProgress,
  }) async {
    _progressTracker.register(taskId, onProgress);
    final params = ImageToPdfParams(imagePaths: imagePaths);

    final result = await _repository.imageToPdf(
      taskId: taskId,
      params: params,
      outputPath: outputPath,
      onProgress: (val) => _progressTracker.updateProgress(taskId, val),
    );

    _progressTracker.remove(taskId);
    return result;
  }

  /// Exports PDF document pages into image files.
  Future<Result<List<String>>> convertPdfToImages({
    required String taskId,
    required String pdfPath,
    required String outputDir,
    required void Function(double progress) onProgress, List<int>? pageRange,
  }) async {
    _progressTracker.register(taskId, onProgress);
    final params = PdfToImageParams(pdfPath: pdfPath, pageRange: pageRange);

    final result = await _repository.pdfToImage(
      taskId: taskId,
      params: params,
      outputDir: outputDir,
      onProgress: (val) => _progressTracker.updateProgress(taskId, val),
    );

    _progressTracker.remove(taskId);
    return result;
  }

  /// Merges multiple PDF documents together.
  Future<Result<String>> mergePdfFiles({
    required String taskId,
    required List<String> pdfPaths,
    required String outputPath,
    required void Function(double progress) onProgress,
  }) async {
    _progressTracker.register(taskId, onProgress);
    final params = PdfMergeParams(pdfPaths: pdfPaths);

    final result = await _repository.mergePdf(
      taskId: taskId,
      params: params,
      outputPath: outputPath,
      onProgress: (val) => _progressTracker.updateProgress(taskId, val),
    );

    _progressTracker.remove(taskId);
    return result;
  }

  /// Splits PDF pages into segments.
  Future<Result<List<String>>> splitPdfFile({
    required String taskId,
    required String pdfPath,
    required List<List<int>> splitRanges,
    required String outputDir,
    required void Function(double progress) onProgress,
  }) async {
    _progressTracker.register(taskId, onProgress);
    final params = PdfSplitParams(pdfPath: pdfPath, splitRanges: splitRanges);

    final result = await _repository.splitPdf(
      taskId: taskId,
      params: params,
      outputDir: outputDir,
      onProgress: (val) => _progressTracker.updateProgress(taskId, val),
    );

    _progressTracker.remove(taskId);
    return result;
  }

  /// Rotates pages in a PDF document.
  Future<Result<String>> rotatePdfPages({
    required String taskId,
    required String pdfPath,
    required int angleDegrees,
    required String outputPath,
    required void Function(double progress) onProgress,
  }) async {
    _progressTracker.register(taskId, onProgress);
    final params = PdfRotateParams(pdfPath: pdfPath, angleDegrees: angleDegrees);

    final result = await _repository.rotatePdf(
      taskId: taskId,
      params: params,
      outputPath: outputPath,
      onProgress: (val) => _progressTracker.updateProgress(taskId, val),
    );

    _progressTracker.remove(taskId);
    return result;
  }

  /// Compresses a PDF file.
  Future<Result<String>> compressPdfFile({
    required String taskId,
    required String pdfPath,
    required String outputPath,
    required void Function(double progress) onProgress,
  }) async {
    _progressTracker.register(taskId, onProgress);
    final params = PdfCompressParams(pdfPath: pdfPath);

    final result = await _repository.compressPdf(
      taskId: taskId,
      params: params,
      outputPath: outputPath,
      onProgress: (val) => _progressTracker.updateProgress(taskId, val),
    );

    _progressTracker.remove(taskId);
    return result;
  }

  /// Cancels an active PDF pipeline.
  Future<Result<void>> cancelActiveTask(String taskId) async {
    _progressTracker.remove(taskId);
    return _repository.cancelTask(taskId);
  }
}
