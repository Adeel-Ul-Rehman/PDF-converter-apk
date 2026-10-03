import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:flux_convert/core/core.dart';
import 'package:flux_convert/features/history/domain/entities/history_record.dart';
import 'package:flux_convert/features/history/presentation/providers/history_providers.dart';
import 'package:flux_convert/features/document_converter/domain/entities/document_conversion_request.dart';
import 'package:flux_convert/features/document_converter/domain/entities/document_conversion_response.dart';
import 'package:flux_convert/features/document_converter/services/document_conversion_manager.dart';
import 'package:flux_convert/features/document_converter/services/document_conversion_service.dart';

/// Provides [DocumentConversionService].
final documentConversionServiceProvider = Provider<DocumentConversionService>(
  (ref) => DocumentConversionService(),
);

/// Provides [DocumentConversionManager].
final documentConversionManagerProvider = Provider<DocumentConversionManager>(
  (ref) => DocumentConversionManager(ref.watch(documentConversionServiceProvider)),
);

/// Operational states of the Document Conversion Notifier.
enum DocumentConversionStatus {
  idle,
  validating,
  preparing,
  processing,
  writing,
  completed,
  failed,
  cancelled;
}

/// State details holder.
class DocumentConversionState {
  const DocumentConversionState({
    required this.status,
    this.progress = 0.0,
    this.currentStep = 'Idle',
    this.response,
    this.errorMessage,
  });

  final DocumentConversionStatus status;
  final double progress;
  final String currentStep;
  final DocumentConversionResponse? response;
  final String? errorMessage;

  DocumentConversionState copyWith({
    DocumentConversionStatus? status,
    double? progress,
    String? currentStep,
    DocumentConversionResponse? response,
    String? errorMessage,
  }) => DocumentConversionState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      currentStep: currentStep ?? this.currentStep,
      response: response ?? this.response,
      errorMessage: errorMessage ?? this.errorMessage,
    );
}

/// Notifier driving the Riverpod document conversion events and database logging.
class DocumentConversionNotifier extends StateNotifier<DocumentConversionState> {
  DocumentConversionNotifier(
    this._manager,
    this._ref,
  ) : super(const DocumentConversionState(status: DocumentConversionStatus.idle));

  final DocumentConversionManager _manager;
  final Ref _ref;

  /// Executes conversion pipelines and logs results to the history database.
  Future<void> runConversion(DocumentConversionRequest request) async {
    final taskId = const Uuid().v4();
    state = state.copyWith(
      status: DocumentConversionStatus.preparing,
      progress: 0.0,
      currentStep: 'Preparing',
    );

    final result = await _manager.executeConversion(
      taskId: taskId,
      request: request,
      onProgress: (p, step) {
        state = state.copyWith(
          status: _mapStepToStatus(step),
          progress: p,
          currentStep: step,
        );
      },
    );

    if (result.isSuccess) {
      final res = result.value;
      state = state.copyWith(
        status: DocumentConversionStatus.completed,
        response: res,
      );

      // Log success to history repository database
      try {
        final historyRepo = _ref.read(historyRepositoryProvider);
        final record = HistoryRecord(
          id: const Uuid().v4(),
          inputFileName: request.document.metadata.fileName,
          outputFileName: res.outputPath.split('/').last.split(r'\').last,
          inputFormat: request.document.format.extension.toUpperCase(),
          outputFormat: request.targetFormat.extension.toUpperCase(),
          inputSizeBytes: request.document.metadata.sizeBytes,
          outputSizeBytes: res.fileSizeBytes,
          convertedAt: DateTime.now(),
          wasSuccessful: true,
          outputFilePath: res.outputPath,
        );
        await historyRepo.saveRecord(record);
      } catch (e, stack) {
        AppLogger.error('DocumentConversionNotifier: History DB logging failed.', e, stack);
      }
    } else {
      state = state.copyWith(
        status: DocumentConversionStatus.failed,
        errorMessage: result.failure.message,
      );
    }
  }

  /// Cancels an active conversion.
  Future<void> cancelConversion(String taskId) async {
    await _manager.cancelActiveTask(taskId);
    state = const DocumentConversionState(status: DocumentConversionStatus.cancelled);
  }

  /// Resets state.
  void reset() {
    state = const DocumentConversionState(status: DocumentConversionStatus.idle);
  }

  DocumentConversionStatus _mapStepToStatus(String step) => switch (step) {
      'Preparing' => DocumentConversionStatus.preparing,
      'Validating' => DocumentConversionStatus.validating,
      'Reading' => DocumentConversionStatus.idle, // Maps logically
      'Processing' => DocumentConversionStatus.processing,
      'Writing' => DocumentConversionStatus.writing,
      'Cleaning' => DocumentConversionStatus.writing,
      'Completed' => DocumentConversionStatus.completed,
      'Cancelled' => DocumentConversionStatus.cancelled,
      _ => DocumentConversionStatus.failed,
    };
}

/// Provides [DocumentConversionNotifier] state notifier.
final documentConversionNotifierProvider =
    StateNotifierProvider<DocumentConversionNotifier, DocumentConversionState>((ref) => DocumentConversionNotifier(ref.watch(documentConversionManagerProvider), ref));
