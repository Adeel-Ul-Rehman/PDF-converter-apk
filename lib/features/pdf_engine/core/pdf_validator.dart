import 'dart:convert';
import 'dart:io';

import 'package:flux_convert/core/core.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// PdfValidator
///
/// Handles checking PDF integrity, checking password protection state, validating
/// file sizes, and verifying signature offsets.
/// ─────────────────────────────────────────────────────────────────────────────
abstract final class PdfValidator {
  /// Scans file start bytes and trailer marks to verify PDF signature and corruption.
  static Future<Result<void>> validateFile(File file) async {
    try {
      if (!file.existsSync()) {
        return const FailureResult(
          StorageFailure(message: 'Target file could not be found.'),
        );
      }

      final length = file.lengthSync();
      if (length <= 0) {
        return const FailureResult(
          ConversionFailure(message: 'The file is empty (0 bytes).'),
        );
      }

      if (length > AppFileConstants.maxFileSizeBytes) {
        return const FailureResult(
          ConversionFailure(message: 'File exceeds 100 MB limit.'),
        );
      }

      // Check header signature (%PDF-)
      final headerStream = file.openRead(0, 4);
      final headerBytes = await headerStream.first;
      if (headerBytes.length < 4 ||
          headerBytes[0] != 0x25 || // %
          headerBytes[1] != 0x50 || // P
          headerBytes[2] != 0x44 || // D
          headerBytes[3] != 0x46) { // F
        return const FailureResult(
          ConversionFailure(message: 'Invalid file signature: Not a valid PDF document.'),
        );
      }

      // Check trailer signature (%%EOF) within last 1024 bytes
      final startOffset = length > 1024 ? length - 1024 : 0;
      final trailerStream = file.openRead(startOffset, length);
      final trailerBytes = await trailerStream.first;
      final trailerText = String.fromCharCodes(trailerBytes);

      if (!trailerText.contains('%%EOF')) {
        return const FailureResult(
          ConversionFailure(message: 'PDF document is corrupted or incomplete (missing EOF).'),
        );
      }

      return const Success(null);
    } catch (e, stack) {
      return FailureResult(
        ConversionFailure(
          message: 'Failed to validate PDF document structure.',
          technicalMessage: e.toString(),
          stackTrace: stack,
        ),
      );
    }
  }

  /// Scans trailer structures for encryption tags.
  static Future<bool> isPasswordProtected(File file) async {
    try {
      final content = await file.readAsString(encoding: latin1);
      return content.contains('/Encrypt');
    } catch (_) {
      try {
        final bytes = await file.readAsBytes();
        final search = '/Encrypt'.codeUnits;
        for (var i = 0; i <= bytes.length - search.length; i++) {
          var match = true;
          for (var j = 0; j < search.length; j++) {
            if (bytes[i + j] != search[j]) {
              match = false;
              break;
            }
          }
          if (match) return true;
        }
      } catch (_) {}
    }
    return false;
  }

  /// Parses page count properties from the document catalog tree.
  static Future<int> parsePageCount(File file) async {
    try {
      final content = await file.readAsString(encoding: latin1);
      
      // Match page count catalog pattern: /Count [0-9]+
      final exp = RegExp(r'/Count\s+(\d+)');
      final matches = exp.allMatches(content);
      
      if (matches.isNotEmpty) {
        // Return the highest match count since the root node has the total page count
        var maxPages = 1;
        for (final m in matches) {
          final countVal = int.tryParse(m.group(1) ?? '1') ?? 1;
          if (countVal > maxPages) {
            maxPages = countVal;
          }
        }
        return maxPages;
      }
    } catch (_) {}
    return 1; // Default fallback to 1 page if unparseable
  }
}
