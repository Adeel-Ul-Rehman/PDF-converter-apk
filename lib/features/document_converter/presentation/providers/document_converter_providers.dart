import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flux_convert/features/document_converter/data/repositories/document_conversion_repository_impl.dart';
import 'package:flux_convert/features/document_converter/domain/entities/document_conversion_request.dart';
import 'package:flux_convert/features/document_converter/domain/entities/document_conversion_response.dart';
import 'package:flux_convert/features/document_converter/domain/entities/document_file.dart';
import 'package:flux_convert/features/document_converter/domain/entities/document_format.dart';
import 'package:flux_convert/features/document_converter/domain/entities/document_validation.dart';
import 'package:flux_convert/features/document_converter/domain/repositories/document_conversion_repository.dart';
import 'package:flux_convert/features/document_converter/domain/usecases/cancel_conversion.dart';
import 'package:flux_convert/features/document_converter/domain/usecases/convert_document.dart';
import 'package:flux_convert/features/document_converter/domain/usecases/detect_document_type.dart';
import 'package:flux_convert/features/document_converter/domain/usecases/estimate_output_size.dart';
import 'package:flux_convert/features/document_converter/domain/usecases/get_supported_formats.dart';
import 'package:flux_convert/features/document_converter/domain/usecases/prepare_conversion.dart';
import 'package:flux_convert/features/document_converter/domain/usecases/validate_document.dart';

/// Provides [DocumentConversionRepository].
final documentConversionRepositoryProvider = Provider<DocumentConversionRepository>(
  (ref) => const DocumentConversionRepositoryImpl(),
);

/// Provides [ValidateDocument] use case.
final validateDocumentUseCaseProvider = Provider<ValidateDocument>(
  (ref) => ValidateDocument(ref.watch(documentConversionRepositoryProvider)),
);

/// Provides [DetectDocumentType] use case.
final detectDocumentTypeUseCaseProvider = Provider<DetectDocumentType>(
  (ref) => DetectDocumentType(ref.watch(documentConversionRepositoryProvider)),
);

/// Provides [GetSupportedFormats] use case.
final getSupportedFormatsUseCaseProvider = Provider<GetSupportedFormats>(
  (ref) => GetSupportedFormats(ref.watch(documentConversionRepositoryProvider)),
);

/// Provides [PrepareConversion] use case.
final prepareConversionUseCaseProvider = Provider<PrepareConversion>(
  (ref) => PrepareConversion(ref.watch(documentConversionRepositoryProvider)),
);

/// Provides [ConvertDocument] use case.
final convertDocumentUseCaseProvider = Provider<ConvertDocument>(
  (ref) => ConvertDocument(ref.watch(documentConversionRepositoryProvider)),
);

/// Provides [CancelConversion] use case.
final cancelConversionUseCaseProvider = Provider<CancelConversion>(
  (ref) => CancelConversion(ref.watch(documentConversionRepositoryProvider)),
);

/// Provides [EstimateOutputSize] use case.
final estimateOutputSizeUseCaseProvider = Provider<EstimateOutputSize>(
  (ref) => EstimateOutputSize(ref.watch(documentConversionRepositoryProvider)),
);

/// Operational states of the document converter.
enum DocumentConverterStatus {
  idle,
  validating,
  ready,
  converting,
  completed,
  failed,
  cancelled;
}

/// State holder class for document converter actions.
class DocumentConverterState {
  const DocumentConverterState({
    required this.status,
    this.selectedFile,
    this.validation,
    this.conversionResponse,
    this.progress = 0.0,
    this.errorMessage,
  });

  final DocumentConverterStatus status;
  final DocumentFile? selectedFile;
  final DocumentValidation? validation;
  final DocumentConversionResponse? conversionResponse;
  final double progress;
  final String? errorMessage;

  DocumentConverterState copyWith({
    DocumentConverterStatus? status,
    DocumentFile? selectedFile,
    DocumentValidation? validation,
    DocumentConversionResponse? conversionResponse,
    double? progress,
    String? errorMessage,
    bool clearFile = false,
  }) => DocumentConverterState(
      status: status ?? this.status,
      selectedFile: clearFile ? null : (selectedFile ?? this.selectedFile),
      validation: clearFile ? null : (validation ?? this.validation),
      conversionResponse: clearFile ? null : (conversionResponse ?? this.conversionResponse),
      progress: progress ?? this.progress,
      errorMessage: errorMessage ?? this.errorMessage,
    );
}

/// Notifier driving the document converter pipeline.
class DocumentConverterNotifier extends StateNotifier<DocumentConverterState> {
  DocumentConverterNotifier(
    this._validateDocument,
    this._detectDocumentType,
    this._convertDocument,
    this._cancelConversion,
    this._repository,
  ) : super(const DocumentConverterState(status: DocumentConverterStatus.idle));

  final ValidateDocument _validateDocument;
  final DetectDocumentType _detectDocumentType;
  final ConvertDocument _convertDocument;
  final CancelConversion _cancelConversion;
  final DocumentConversionRepository _repository;

  /// Selected file analysis and validations loop.
  Future<void> selectAndValidateFile(String path) async {
    state = state.copyWith(status: DocumentConverterStatus.validating);

    // 1. Detect format signature
    final formatResult = await _detectDocumentType(path);
    if (formatResult.isFailure) {
      state = state.copyWith(
        status: DocumentConverterStatus.failed,
        errorMessage: formatResult.failure.message,
      );
      return;
    }

    // 2. Validate document structures
    final validationResult = await _validateDocument(path);
    if (validationResult.isFailure) {
      state = state.copyWith(
        status: DocumentConverterStatus.failed,
        errorMessage: validationResult.failure.message,
      );
      return;
    }

    final validation = validationResult.value;
    if (!validation.isValid) {
      state = state.copyWith(
        status: DocumentConverterStatus.failed,
        validation: validation,
        errorMessage: validation.firstErrorMessage ?? 'Document validation failed.',
      );
      return;
    }

    // 3. Extract metadata
    final metadataResult = await _repository.extractMetadata(path);
    if (metadataResult.isFailure) {
      state = state.copyWith(
        status: DocumentConverterStatus.failed,
        errorMessage: metadataResult.failure.message,
      );
      return;
    }

    final documentFile = DocumentFile(
      filePath: path,
      format: formatResult.value,
      metadata: metadataResult.value,
    );

    state = state.copyWith(
      status: DocumentConverterStatus.ready,
      selectedFile: documentFile,
      validation: validation,
    );
  }

  /// Executes conversion.
  Future<void> convertSelected(DocumentFormat targetFormat, String outputDir) async {
    final docFile = state.selectedFile;
    if (docFile == null || state.status != DocumentConverterStatus.ready) return;

    state = state.copyWith(
      status: DocumentConverterStatus.converting,
      progress: 0.0,
    );

    final request = DocumentConversionRequest(
      document: docFile,
      targetFormat: targetFormat,
      outputDirectory: outputDir,
    );

    final result = await _convertDocument(request, (progressVal) {
      state = state.copyWith(progress: progressVal);
    });

    if (result.isSuccess) {
      state = state.copyWith(
        status: DocumentConverterStatus.completed,
        conversionResponse: result.value,
      );
    } else {
      state = state.copyWith(
        status: DocumentConverterStatus.failed,
        errorMessage: result.failure.message,
      );
    }
  }

  /// Cancels conversion task.
  Future<void> cancelActiveConversion(String taskId) async {
    if (state.status != DocumentConverterStatus.converting) return;
    
    await _cancelConversion(taskId);
    state = state.copyWith(status: DocumentConverterStatus.cancelled);
  }

  /// Resets notifier state.
  void reset() {
    state = const DocumentConverterState(status: DocumentConverterStatus.idle);
  }
}

/// Provides [DocumentConverterNotifier] state provider.
final documentConverterNotifierProvider =
    StateNotifierProvider<DocumentConverterNotifier, DocumentConverterState>((ref) => DocumentConverterNotifier(
    ref.watch(validateDocumentUseCaseProvider),
    ref.watch(detectDocumentTypeUseCaseProvider),
    ref.watch(convertDocumentUseCaseProvider),
    ref.watch(cancelConversionUseCaseProvider),
    ref.watch(documentConversionRepositoryProvider),
  ));
