import 'dart:convert';
import 'dart:io';

import 'package:flux_convert/core/core.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// DocumentFileAnalyzer
///
/// Signature-based file type verification using file header magic bytes.
/// ─────────────────────────────────────────────────────────────────────────────
abstract final class DocumentFileAnalyzer {
  /// Reads the leading 16 bytes of [file] to verify file signatures.
  static Future<Result<String>> analyzeHeader(File file) async {
    try {
      final length = file.lengthSync();
      if (length < 4) {
        return const FailureResult(
          CorruptedDocumentFailure(message: 'File size too small to parse signature.'),
        );
      }

      // Read first 16 bytes
      final stream = file.openRead(0, 16);
      final bytes = await stream.first;

      // 1. PDF: %PDF- (0x25 0x50 0x44 0x46)
      if (bytes.length >= 4 &&
          bytes[0] == 0x25 &&
          bytes[1] == 0x50 &&
          bytes[2] == 0x44 &&
          bytes[3] == 0x46) {
        return const Success('pdf');
      }

      // 2. ZIP formats (DOCX, XLSX, PPTX): PK (0x50 0x4B)
      if (bytes.length >= 2 && bytes[0] == 0x50 && bytes[1] == 0x4B) {
        return const Success('docx'); // Represents docx, pptx, xlsx, zip
      }

      // 3. MS Office OLECF formats (DOC, XLS, PPT): 0xD0 0xCF 0x11 0xE0
      if (bytes.length >= 4 &&
          bytes[0] == 0xD0 &&
          bytes[1] == 0xCF &&
          bytes[2] == 0x11 &&
          bytes[3] == 0xE0) {
        return const Success('doc');
      }

      // 4. RTF: {\rtf (0x7B 0x5C 0x72 0x74 0x66)
      if (bytes.length >= 5 &&
          bytes[0] == 0x7B &&
          bytes[1] == 0x5C &&
          bytes[2] == 0x72 &&
          bytes[3] == 0x74 &&
          bytes[4] == 0x66) {
        return const Success('rtf');
      }

      // Default fallback check for HTML or plain text
      final content = String.fromCharCodes(bytes.take(8)).trim().toLowerCase();
      if (content.contains('<!doc') || content.contains('<html')) {
        return const Success('html');
      }

      // Fallback for TXT files (ensure no null bytes in sample)
      if (!bytes.contains(0x00)) {
        return const Success('txt');
      }

      return const FailureResult(
        UnsupportedDocumentFailure(message: 'Invalid file signature or binary type.'),
      );
    } catch (e, stack) {
      return FailureResult(
        CorruptedDocumentFailure(
          message: 'Failed to verify file signatures.',
          technicalMessage: e.toString(),
          stackTrace: stack,
        ),
      );
    }
  }

  /// Parses file descriptors to check for security lock (PDF password encryption).
  static Future<bool> detectEncryption(File file) async {
    try {
      final ext = file.path.split('.').last.toLowerCase();
      if (ext != 'pdf') return false;

      // Scan file contents for the "/Encrypt" dictionary tag
      final content = await file.readAsString(encoding: latin1);
      return content.contains('/Encrypt');
    } catch (_) {
      // If reading string throws (e.g. binary file), read raw bytes for safety
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
}
