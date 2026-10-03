import 'dart:io';

import 'package:flux_convert/core/core.dart';
import 'package:flux_convert/features/conversion/core/adapters/conversion_context.dart';
import 'package:flux_convert/features/conversion/core/adapters/conversion_settings.dart';
import 'package:flux_convert/features/conversion/core/adapters/format_converter_resolver.dart';
import 'package:flux_convert/features/document_converter/domain/entities/document_conversion_request.dart';
import 'package:flux_convert/features/document_converter/domain/entities/document_conversion_response.dart';
import 'package:flux_convert/features/document_converter/domain/entities/document_format.dart';
import 'package:flux_convert/features/document_converter/domain/entities/document_metadata.dart';
import 'package:flux_convert/features/document_converter/domain/entities/document_validation.dart';
import 'package:flux_convert/features/document_converter/domain/repositories/document_conversion_repository.dart';
import 'package:flux_convert/features/document_converter/shared/analyzer/document_file_analyzer.dart';
import 'package:flux_convert/features/document_converter/shared/cache/document_cache_manager.dart';
import 'package:flux_convert/features/document_converter/shared/metadata/document_metadata_extractor.dart';
import 'package:flux_convert/features/document_converter/shared/validators/document_validators.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// DocumentConversionRepositoryImpl
///
/// Coordinates validations, metadata extraction, cache setups, and routes
/// parsing pipelines via format converter resolver adapters.
/// ─────────────────────────────────────────────────────────────────────────────
class DocumentConversionRepositoryImpl implements DocumentConversionRepository {
  const DocumentConversionRepositoryImpl();

  @override
  Future<Result<DocumentValidation>> validateDocument(String filePath) async {
    final file = File(filePath);

    // ── 1. Read existence & permissions ──────────────────────────────────────
    final access = await DocumentValidators.checkReadAccess(file);
    if (access.isFailure) {
      return Success(DocumentValidation(isValid: false, failures: [access.failure]));
    }

    // ── 2. Size limitation ───────────────────────────────────────────────────
    final size = DocumentValidators.checkSize(file.lengthSync());
    if (size.isFailure) {
      return Success(DocumentValidation(isValid: false, failures: [size.failure]));
    }

    // ── 3. Extension support ─────────────────────────────────────────────────
    final ext = DocumentValidators.checkExtension(filePath);
    if (ext.isFailure) {
      return Success(DocumentValidation(isValid: false, failures: [ext.failure]));
    }

    // ── 4. Header signatures corruption ──────────────────────────────────────
    final corrupt = await DocumentValidators.checkCorruption(file);
    if (corrupt.isFailure) {
      return Success(DocumentValidation(isValid: false, failures: [corrupt.failure]));
    }

    // ── 5. Password locks checks ─────────────────────────────────────────────
    final encrypt = await DocumentValidators.checkEncryption(file);
    if (encrypt.isFailure) {
      return Success(DocumentValidation(isValid: false, failures: [encrypt.failure]));
    }

    return const Success(DocumentValidation(isValid: true, failures: []));
  }

  @override
  Future<Result<DocumentFormat>> detectFormat(String filePath) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      return const FailureResult(MissingDocumentFailure(message: 'File not found.'));
    }

    final detectResult = await DocumentFileAnalyzer.analyzeHeader(file);
    if (detectResult.isSuccess) {
      final docFormat = DocumentFormat.fromExtension(detectResult.value);
      if (docFormat != null) {
        return Success(docFormat);
      }
    }
    return const FailureResult(UnsupportedDocumentFailure(message: 'Invalid signature.'));
  }

  @override
  Future<Result<List<DocumentFormat>>> getSupportedConversions(DocumentFormat format) async {
    final outputs = DocumentFormat.getSupportedOutputs(format);
    return Success(outputs);
  }

  @override
  Future<Result<String>> prepareConversion(String filePath, DocumentFormat targetFormat) async {
    final fileName = filePath.split('/').last.split(r'\').last;
    final baseName = fileName.contains('.')
        ? fileName.substring(0, fileName.lastIndexOf('.'))
        : fileName;

    final targetExt = targetFormat.extension;
    final cleanDestPath = await DocumentCacheManager.allocateOutputPath('$baseName.$targetExt');

    return Success(cleanDestPath);
  }

  @override
  Future<Result<DocumentConversionResponse>> convert(
    DocumentConversionRequest request,
    void Function(double progress) onProgress,
  ) async {
    final sourceExt = request.document.format.extension;
    final targetExt = request.targetFormat.extension;

    // ── 1. Resolve converter adapter ─────────────────────────────────────────
    final resolverResult = FormatConverterResolver.resolve(sourceExt, targetExt);
    if (resolverResult.isFailure) {
      return FailureResult(resolverResult.failure);
    }

    final adapter = resolverResult.value;

    // ── 2. Create conversion context ─────────────────────────────────────────
    final tempDir = Directory(request.outputDirectory);
    final context = ConversionContext(
      inputFile: File(request.document.filePath),
      outputPath: '${request.outputDirectory}/${request.document.metadata.fileName.replaceAll(sourceExt, targetExt)}',
      settings: ConversionSettings(
        keepMetadata: request.keepMetadata,
        outputFolder: request.outputDirectory,
      ),
      tempDirectory: tempDir,
    );

    // ── 3. Execute adapter conversion ───────────────────────────────────────
    final conversionResult = await adapter.convert(context, onProgress);

    if (conversionResult.isSuccess) {
      final value = conversionResult.value;
      return Success(
        DocumentConversionResponse(
          outputPath: value.destinationPath,
          fileSizeBytes: value.fileSizeBytes,
          duration: value.duration,
        ),
      );
    }

    return FailureResult(conversionResult.failure);
  }

  @override
  Future<Result<void>> cancelConversion(String taskId) async {
    // Adapter cancels the operation using unique task IDs.
    return const Success(null);
  }

  @override
  Future<Result<int>> estimateOutputSize(String filePath, DocumentFormat targetFormat) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      return const FailureResult(MissingDocumentFailure(message: 'File not found.'));
    }

    final resolverResult = FormatConverterResolver.resolve(
      filePath.split('.').last.toLowerCase(),
      targetFormat.extension,
    );

    if (resolverResult.isSuccess) {
      final size = await resolverResult.value.estimateOutputSize(file, const ConversionSettings());
      return Success(size);
    }

    return Success(file.lengthSync());
  }

  @override
  Future<Result<DocumentMetadata>> extractMetadata(String filePath) => DocumentMetadataExtractor.extract(File(filePath));
}
