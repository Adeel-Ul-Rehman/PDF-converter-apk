import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;
import 'package:uuid/uuid.dart';

import 'package:flux_convert/core/logging/logger_service.dart';
import 'package:flux_convert/features/conversion/core/engine/conversion_storage_manager.dart';
import 'package:flux_convert/features/history/domain/entities/conversion_history.dart';
import 'package:flux_convert/features/history/presentation/providers/history_providers.dart';
import 'package:flux_convert/features/pdf_compression/data/services/pdf_compression_service.dart';
import 'package:flux_convert/features/pdf_compression/domain/entities/pdf_compression_config.dart';

/// Riverpod Provider for PDF Compression State
final pdfCompressionProvider =
    StateNotifierProvider<PdfCompressionNotifier, PdfCompressionState>(
  (ref) => PdfCompressionNotifier(
    compressionService: const PdfCompressionService(),
    ref: ref,
  ),
);

class PdfCompressionNotifier extends StateNotifier<PdfCompressionState> {
  PdfCompressionNotifier({
    required PdfCompressionService compressionService,
    required Ref ref,
  })  : _compressionService = compressionService,
        _ref = ref,
        super(const PdfCompressionState());

  final PdfCompressionService _compressionService;
  final Ref _ref;

  /// Selects a PDF file for compression and inspects its metadata.
  Future<void> selectFile(String filePath, {String? password}) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        state = state.copyWith(
          status: PdfCompressionStatus.error,
          errorMessage: 'Selected file does not exist.',
        );
        return;
      }

      final fileName = filePath.split('/').last.split(r'\').last;
      final ext = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : '';
      if (ext != 'pdf') {
        state = state.copyWith(
          status: PdfCompressionStatus.error,
          errorMessage: 'Invalid file format. Only PDF files can be compressed.',
        );
        return;
      }

      final originalSize = file.lengthSync();
      if (originalSize == 0) {
        state = state.copyWith(
          status: PdfCompressionStatus.error,
          errorMessage: 'Selected PDF file is empty (0 bytes).',
        );
        return;
      }

      int pageCount = 0;
      try {
        final bytes = file.readAsBytesSync();
        final doc = sf.PdfDocument(inputBytes: bytes, password: password);
        pageCount = doc.pages.count;
        doc.dispose();
      } catch (e) {
        AppLogger.warning('Could not read PDF metadata for $filePath', e);
      }

      state = state.copyWith(
        status: PdfCompressionStatus.selected,
        selectedPath: filePath,
        fileName: fileName,
        originalSizeBytes: originalSize,
        pageCount: pageCount,
        password: password,
        clearError: true,
      );
      AppLogger.info('PdfCompressionNotifier: Selected file $fileName ($originalSize bytes, $pageCount pages)');
    } catch (e, stack) {
      AppLogger.error('Failed to select PDF file', e, stack);
      state = state.copyWith(
        status: PdfCompressionStatus.error,
        errorMessage: 'Failed to inspect PDF file: $e',
      );
    }
  }

  /// Sets the selected compression level (Max, Medium, Low).
  void setCompressionLevel(PdfCompressionLevel level) {
    state = state.copyWith(level: level);
    AppLogger.info('PdfCompressionNotifier: Selected level ${level.displayName}');
  }

  /// Clears the currently selected PDF file.
  void clearSelection() {
    state = const PdfCompressionState();
  }

  /// Triggers background PDF compression.
  Future<void> compressPdf() async {
    if (!state.hasFile || state.isCompressing) return;

    final inputPath = state.selectedPath!;
    final sourceName = state.fileName!;
    final baseName = sourceName.contains('.')
        ? sourceName.substring(0, sourceName.lastIndexOf('.'))
        : sourceName;

    state = state.copyWith(
      status: PdfCompressionStatus.compressing,
      progress: 0.15,
      statusMessage: 'Allocating storage for compressed output...',
      clearError: true,
    );

    // 1. Allocate destination storage path using ConversionStorageManager
    final destResult = await ConversionStorageManager.getDestinationPath(
      '${baseName}_compressed',
      'pdf',
    );

    if (destResult.isFailure) {
      state = state.copyWith(
        status: PdfCompressionStatus.error,
        errorMessage: destResult.failure.message,
      );
      return;
    }

    final destPath = destResult.value;

    state = state.copyWith(
      progress: 0.35,
      statusMessage: 'Optimizing PDF streams & resources in background isolate...',
    );

    final params = PdfCompressionParams(
      inputPath: inputPath,
      outputPath: destPath,
      level: state.level,
      password: state.password,
    );

    state = state.copyWith(
      progress: 0.65,
      statusMessage: 'Applying ${state.level.displayName}...',
    );

    // 2. Execute background isolate compression
    final result = await _compressionService.compressPdf(params);

    if (!result.isSuccess) {
      state = state.copyWith(
        status: PdfCompressionStatus.error,
        errorMessage: result.errorMessage ?? 'PDF compression failed.',
      );
      return;
    }

    state = state.copyWith(
      progress: 0.90,
      statusMessage: 'Registering conversion history...',
    );

    // 3. Register conversion record in HistoryRepository & RichHistoryNotifier
    try {
      final destName = destPath.split('/').last.split(r'\').last;
      final record = ConversionHistory(
        id: const Uuid().v4(),
        conversionId: const Uuid().v4(),
        sourceFileName: sourceName,
        sourceFilePath: inputPath,
        destinationFileName: destName,
        destinationFilePath: destPath,
        sourceFormat: 'PDF',
        destinationFormat: 'PDF',
        originalFileSize: result.originalSizeBytes,
        convertedFileSize: result.compressedSizeBytes,
        conversionDuration: result.duration,
        conversionStatus: 'completed',
        createdDate: DateTime.now(),
        completedDate: DateTime.now(),
      );

      await _ref.read(historyRepositoryProvider).saveConversion(record);
      await _ref.read(richHistoryNotifierProvider.notifier).loadAllHistory();
      await _ref.read(richHistoryNotifierProvider.notifier).refreshStats();
    } catch (e, stack) {
      AppLogger.error('Failed to log compression history record', e, stack);
    }

    state = state.copyWith(
      status: PdfCompressionStatus.completed,
      progress: 1.0,
      statusMessage: 'PDF Compression Completed Successfully!',
      result: result,
    );
    AppLogger.info('PdfCompressionNotifier: Compression finished successfully (${result.savedBytes} bytes saved)');
  }
}
