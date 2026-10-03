import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flux_convert/features/pdf_engine/data/repositories/pdf_repository_impl.dart';
import 'package:flux_convert/features/pdf_engine/domain/repositories/pdf_repository.dart';
import 'package:flux_convert/features/pdf_engine/services/pdf_service.dart';

/// Exposes the [PdfRepository].
final pdfRepositoryProvider = Provider<PdfRepository>(
  (ref) => PdfRepositoryImpl(),
);

/// Exposes the [PdfService].
final pdfServiceProvider = Provider<PdfService>(
  (ref) => PdfService(ref.watch(pdfRepositoryProvider)),
);

/// Operational states of the PDF Engine.
enum PdfEngineStatus {
  idle,
  processing,
  success,
  failed;
}

/// State details holder for Riverpod state binds.
class PdfEngineState {
  const PdfEngineState({
    required this.status,
    this.progress = 0.0,
    this.outputPath,
    this.outputPaths = const [],
    this.errorMessage,
  });

  final PdfEngineStatus status;
  final double progress;
  final String? outputPath;
  final List<String> outputPaths;
  final String? errorMessage;

  PdfEngineState copyWith({
    PdfEngineStatus? status,
    double? progress,
    String? outputPath,
    List<String>? outputPaths,
    String? errorMessage,
  }) => PdfEngineState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      outputPath: outputPath ?? this.outputPath,
      outputPaths: outputPaths ?? this.outputPaths,
      errorMessage: errorMessage ?? this.errorMessage,
    );
}

/// StateNotifier controlling PDF pipelines.
class PdfEngineNotifier extends StateNotifier<PdfEngineState> {
  PdfEngineNotifier(this._service) : super(const PdfEngineState(status: PdfEngineStatus.idle));

  final PdfService _service;

  /// Executes Image-to-PDF conversion task.
  Future<void> runImagesToPdf(String taskId, List<String> images, String outPath) async {
    state = state.copyWith(status: PdfEngineStatus.processing, progress: 0.0);

    final result = await _service.convertImagesToPdf(
      taskId: taskId,
      imagePaths: images,
      outputPath: outPath,
      onProgress: (p) => state = state.copyWith(progress: p),
    );

    if (result.isSuccess) {
      state = state.copyWith(status: PdfEngineStatus.success, outputPath: result.value);
    } else {
      state = state.copyWith(status: PdfEngineStatus.failed, errorMessage: result.failure.message);
    }
  }

  /// Exports pages of a PDF to PNG images.
  Future<void> runPdfToImages(String taskId, String pdfPath, String outDir, [List<int>? pages]) async {
    state = state.copyWith(status: PdfEngineStatus.processing, progress: 0.0);

    final result = await _service.convertPdfToImages(
      taskId: taskId,
      pdfPath: pdfPath,
      outputDir: outDir,
      pageRange: pages,
      onProgress: (p) => state = state.copyWith(progress: p),
    );

    if (result.isSuccess) {
      state = state.copyWith(status: PdfEngineStatus.success, outputPaths: result.value);
    } else {
      state = state.copyWith(status: PdfEngineStatus.failed, errorMessage: result.failure.message);
    }
  }

  /// Merges multiple PDFs into one document.
  Future<void> runMergePdfs(String taskId, List<String> pdfPaths, String outPath) async {
    state = state.copyWith(status: PdfEngineStatus.processing, progress: 0.0);

    final result = await _service.mergePdfFiles(
      taskId: taskId,
      pdfPaths: pdfPaths,
      outputPath: outPath,
      onProgress: (p) => state = state.copyWith(progress: p),
    );

    if (result.isSuccess) {
      state = state.copyWith(status: PdfEngineStatus.success, outputPath: result.value);
    } else {
      state = state.copyWith(status: PdfEngineStatus.failed, errorMessage: result.failure.message);
    }
  }

  /// Splits PDF pages.
  Future<void> runSplitPdf(String taskId, String pdfPath, List<List<int>> ranges, String outDir) async {
    state = state.copyWith(status: PdfEngineStatus.processing, progress: 0.0);

    final result = await _service.splitPdfFile(
      taskId: taskId,
      pdfPath: pdfPath,
      splitRanges: ranges,
      outputDir: outDir,
      onProgress: (p) => state = state.copyWith(progress: p),
    );

    if (result.isSuccess) {
      state = state.copyWith(status: PdfEngineStatus.success, outputPaths: result.value);
    } else {
      state = state.copyWith(status: PdfEngineStatus.failed, errorMessage: result.failure.message);
    }
  }

  /// Rotates pages in a PDF.
  Future<void> runRotatePdf(String taskId, String pdfPath, int angle, String outPath) async {
    state = state.copyWith(status: PdfEngineStatus.processing, progress: 0.0);

    final result = await _service.rotatePdfPages(
      taskId: taskId,
      pdfPath: pdfPath,
      angleDegrees: angle,
      outputPath: outPath,
      onProgress: (p) => state = state.copyWith(progress: p),
    );

    if (result.isSuccess) {
      state = state.copyWith(status: PdfEngineStatus.success, outputPath: result.value);
    } else {
      state = state.copyWith(status: PdfEngineStatus.failed, errorMessage: result.failure.message);
    }
  }

  /// Compresses PDF file.
  Future<void> runCompressPdf(String taskId, String pdfPath, String outPath) async {
    state = state.copyWith(status: PdfEngineStatus.processing, progress: 0.0);

    final result = await _service.compressPdfFile(
      taskId: taskId,
      pdfPath: pdfPath,
      outputPath: outPath,
      onProgress: (p) => state = state.copyWith(progress: p),
    );

    if (result.isSuccess) {
      state = state.copyWith(status: PdfEngineStatus.success, outputPath: result.value);
    } else {
      state = state.copyWith(status: PdfEngineStatus.failed, errorMessage: result.failure.message);
    }
  }

  /// Cancels ongoing operations.
  Future<void> cancelActiveTask(String taskId) async {
    await _service.cancelActiveTask(taskId);
    state = const PdfEngineState(status: PdfEngineStatus.idle);
  }

  /// Resets state.
  void reset() {
    state = const PdfEngineState(status: PdfEngineStatus.idle);
  }
}

/// Provides [PdfEngineNotifier] state notifier.
final pdfEngineNotifierProvider =
    StateNotifierProvider<PdfEngineNotifier, PdfEngineState>((ref) => PdfEngineNotifier(ref.watch(pdfServiceProvider)));
