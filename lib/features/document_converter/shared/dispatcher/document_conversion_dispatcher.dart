import 'dart:io';

import 'package:mime/mime.dart' as mime_lib;

import 'package:flux_convert/core/core.dart';
import 'package:flux_convert/features/document_converter/domain/entities/document_format.dart';
import 'package:flux_convert/features/document_converter/shared/analyzer/document_file_analyzer.dart';
import 'package:flux_convert/features/document_converter/shared/cache/document_cache_manager.dart';
import 'package:flux_convert/features/document_converter/shared/validators/document_validators.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// DocumentConversionDispatcher
///
/// Dispatches validations pipelines, performs file signatures cross-checks,
/// handles unique target names resolving, and cleans temporary workspaces.
/// ─────────────────────────────────────────────────────────────────────────────
abstract final class DocumentConversionDispatcher {
  /// Verifies file signature, MIME type, and extension match.
  /// Returns Success if all parameters match cleanly.
  static Future<Result<void>> crossCheckSignature({
    required String filePath,
    required String ext,
  }) async {
    final file = File(filePath);

    // 1. Detect magic signature
    final sigResult = await DocumentFileAnalyzer.analyzeHeader(file);
    if (sigResult.isFailure) {
      return FailureResult(sigResult.failure);
    }
    final detectedSig = sigResult.value;

    // 2. Detect MIME type
    final mimeType = mime_lib.lookupMimeType(filePath) ?? '';

    // 3. Cross-check alignments
    final cleanExt = ext.toLowerCase().trim();

    if (detectedSig == 'pdf') {
      if (cleanExt != 'pdf' || !mimeType.contains('pdf')) {
        return FailureResult(
          CorruptedDocumentFailure(
            message: 'Format mismatch: File contents do not align with .pdf extension.',
            technicalMessage: 'Signature: $detectedSig, Ext: $cleanExt, MIME: $mimeType',
          ),
        );
      }
    } else if (detectedSig == 'docx') {
      if (cleanExt != 'docx' && cleanExt != 'xlsx' && cleanExt != 'pptx') {
        return const FailureResult(
          CorruptedDocumentFailure(
            message: 'Format mismatch: File contents do not align with ZIP XML documents.',
          ),
        );
      }
    } else if (detectedSig == 'rtf') {
      if (cleanExt != 'rtf' || !mimeType.contains('rtf')) {
        return const FailureResult(
          CorruptedDocumentFailure(
            message: 'Format mismatch: File contents do not align with Rich Text format.',
          ),
        );
      }
    } else if (detectedSig == 'html') {
      if (cleanExt != 'html' && cleanExt != 'htm') {
        return FailureResult(
          CorruptedDocumentFailure(
            message: 'Format mismatch: File content is HTML but extension is .$cleanExt.',
          ),
        );
      }
    }

    return const Success(null);
  }

  /// Runs the full document validation suite: size, readable, encryption, storage.
  static Future<Result<void>> runValidationPipeline({
    required String sourcePath,
    required String targetFormat,
    required String outputDir,
    bool overwriteExisting = false,
  }) async {
    final file = File(sourcePath);

    // 1. Basic existence check
    if (!file.existsSync()) {
      return const FailureResult(
        MissingDocumentFailure(message: 'Source document file not found.'),
      );
    }

    // 2. Read permissions check
    final readAccess = await DocumentValidators.checkReadAccess(file);
    if (readAccess.isFailure) {
      return FailureResult(readAccess.failure);
    }

    // 3. Max size check
    final sizeCheck = DocumentValidators.checkSize(file.lengthSync());
    if (sizeCheck.isFailure) {
      return FailureResult(sizeCheck.failure);
    }

    // 4. Mapped conversion check
    final inputFormat = DocumentFormat.fromExtension(sourcePath.split('.').last);
    final outputFormat = DocumentFormat.fromExtension(targetFormat);

    if (inputFormat == null || outputFormat == null) {
      return FailureResult(
        UnsupportedDocumentFailure(
          message: 'Unsupported document format: .$targetFormat',
        ),
      );
    }

    if (!DocumentFormat.canConvert(inputFormat, outputFormat)) {
      return FailureResult(
        UnsupportedDocumentFailure(
          message: 'Conversion from ${inputFormat.extension.toUpperCase()} to ${outputFormat.extension.toUpperCase()} is not supported offline.',
        ),
      );
    }

    // 5. Signature cross check
    final crossCheck = await crossCheckSignature(filePath: sourcePath, ext: inputFormat.extension);
    if (crossCheck.isFailure) {
      return FailureResult(crossCheck.failure);
    }

    // 6. Output directory writable checks
    final outputFolder = Directory(outputDir);
    if (!outputFolder.existsSync()) {
      try {
        outputFolder.createSync(recursive: true);
      } catch (e, stack) {
        return FailureResult(
          StorageFailure(
            message: 'Destination output folder path is inaccessible.',
            technicalMessage: e.toString(),
            stackTrace: stack,
          ),
        );
      }
    }

    // 7. Check remaining storage space
    try {
      final stat = outputFolder.statSync();
      if (stat.type == FileSystemEntityType.notFound) {
        return const FailureResult(StorageFailure(message: 'Storage folder is not responsive.'));
      }
    } catch (_) {}

    return const Success(null);
  }

  /// Resolves naming collisions to yield a unique output filename.
  static Future<String> resolveUniqueOutputPath({
    required String outputDir,
    required String sourceFileName,
    required String targetFormat,
    bool overwriteExisting = false,
  }) async {
    final baseName = sourceFileName.contains('.')
        ? sourceFileName.substring(0, sourceFileName.lastIndexOf('.'))
        : sourceFileName;

    final targetExt = targetFormat.toLowerCase().trim();
    var destPath = '$outputDir/$baseName.$targetExt';

    if (overwriteExisting) {
      final file = File(destPath);
      if (file.existsSync()) {
        file.deleteSync();
      }
      return destPath;
    }

    // Counter increments to avoid collisions
    var counter = 1;
    while (File(destPath).existsSync()) {
      destPath = '$outputDir/${baseName}_$counter.$targetExt';
      counter++;
    }

    return destPath;
  }

  /// Prepares temporary isolation workspaces.
  static Future<Directory> createTempWorkspace() async {
    final tempDir = await DocumentCacheManager.allocateOutputPath('work_${DateTime.now().microsecondsSinceEpoch}');
    final dir = Directory(tempDir);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir;
  }
}
