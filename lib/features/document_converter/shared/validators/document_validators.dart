import 'dart:io';

import 'package:flux_convert/core/core.dart';
import 'package:flux_convert/features/document_converter/shared/analyzer/document_file_analyzer.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// DocumentValidators
///
/// Reusable verification suite testing limits, permissions, headers,
/// corruption, empty contents, and encryption tags.
/// ─────────────────────────────────────────────────────────────────────────────
abstract final class DocumentValidators {
  /// Checks extension mappings.
  static Result<void> checkExtension(String path) {
    final ext = path.split('.').last.toLowerCase();
    final isDoc = ['pdf', 'doc', 'docx', 'txt', 'rtf', 'html', 'odt'].contains(ext);
    if (!isDoc) {
      return FailureResult(
        UnsupportedDocumentFailure(
          message: 'Unsupported document format: .$ext',
          technicalMessage: 'Extension checked: $ext',
        ),
      );
    }
    return const Success(null);
  }

  /// Checks maximum size limitations (100 MB).
  static Result<void> checkSize(int sizeBytes) {
    if (sizeBytes <= 0) {
      return FailureResult(
        CorruptedDocumentFailure(
          message: 'Selected document file is empty.',
          technicalMessage: 'File size read: $sizeBytes',
        ),
      );
    }
    if (sizeBytes > AppFileConstants.maxFileSizeBytes) {
      final sizeFormatted = FileSizeUtils.format(sizeBytes);
      return FailureResult(
        LargeDocumentFailure(
          message: 'File size ($sizeFormatted) exceeds the limit of 100 MB.',
          technicalMessage: 'Size limits violation: $sizeBytes bytes',
        ),
      );
    }
    return const Success(null);
  }

  /// Verifies read access permissions.
  static Future<Result<void>> checkReadAccess(File file) async {
    try {
      if (!file.existsSync()) {
        return FailureResult(
          MissingDocumentFailure(
            message: 'Target document could not be found.',
            technicalMessage: 'File not found at path: ${file.path}',
          ),
        );
      }
      final descriptor = await file.open();
      await descriptor.close();
      return const Success(null);
    } catch (e, stack) {
      return FailureResult(
        UnknownDocumentFailure(
          message: 'Unable to read selected document. Check storage permissions.',
          technicalMessage: e.toString(),
          stackTrace: stack,
        ),
      );
    }
  }

  /// Checks basic file header signature mismatches.
  static Future<Result<void>> checkCorruption(File file) async {
    try {
      final analysis = await DocumentFileAnalyzer.analyzeHeader(file);
      if (analysis.isFailure) {
        return FailureResult(analysis.failure);
      }
      return const Success(null);
    } catch (e, stack) {
      return FailureResult(
        CorruptedDocumentFailure(
          message: 'Document header is corrupted or unreadable.',
          technicalMessage: e.toString(),
          stackTrace: stack,
        ),
      );
    }
  }

  /// Checks for encryption (e.g. PDF password tags).
  static Future<Result<void>> checkEncryption(File file) async {
    try {
      final isEncrypted = await DocumentFileAnalyzer.detectEncryption(file);
      if (isEncrypted) {
        return const FailureResult(
          EncryptedDocumentFailure(
            message: 'Selected document is password protected.',
            technicalMessage: 'Password protection encryption detected.',
          ),
        );
      }
      return const Success(null);
    } catch (e, stack) {
      return FailureResult(
        UnknownDocumentFailure(
          message: 'Failed to verify document encryption status.',
          technicalMessage: e.toString(),
          stackTrace: stack,
        ),
      );
    }
  }
}
