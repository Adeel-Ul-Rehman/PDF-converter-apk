import 'dart:io';
import 'package:flux_convert/core/core.dart';
import 'package:flux_convert/features/security/domain/entities/security_configuration.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// FileSecurityValidator — Low-level file property, header and type validator.
///
/// Responsible for inspecting physical files: verifying existences, sizes,
/// reading magic bytes/signatures, and checking corruption/encryption status.
/// ─────────────────────────────────────────────────────────────────────────────
abstract final class FileSecurityValidator {
  /// Validates a file against security policies (size, extension, signature, corruption).
  static Future<Result<void>> validate(String path, SecurityConfiguration config) async {
    final file = File(path);

    // ── 1. Basic Checks ──────────────────────────────────────────────────────
    if (!file.existsSync()) {
      return const FailureResult(InvalidFileFailure(message: 'File does not exist on disk.'));
    }

    final sizeBytes = file.lengthSync();
    if (sizeBytes == 0) {
      return const FailureResult(InvalidFileFailure(message: 'File is empty (0 bytes).'));
    }

    if (sizeBytes > config.maxFileSizeBytes) {
      return const FailureResult(InvalidFileFailure(message: 'File exceeds maximum permitted size.'));
    }

    // Check readable
    try {
      final access = await file.open();
      await access.close();
    } catch (e) {
      return FailureResult(LockedFileFailure(
        message: 'File is locked or currently in use by another process.',
        technicalMessage: e.toString(),
      ));
    }

    // ── 2. Extension & MIME Match ────────────────────────────────────────────
    final extension = path.split('.').last.toLowerCase();
    if (!config.allowedExtensions.contains(extension)) {
      return FailureResult(InvalidFileFailure(message: 'File extension .$extension is not permitted.'));
    }

    // ── 3. Read Magic Numbers/Signature ──────────────────────────────────────
    List<int> headerBytes;
    try {
      final stream = file.openRead(0, 16);
      headerBytes = await stream.first;
    } catch (e, stack) {
      return FailureResult(CorruptedFileFailure(
        message: 'File header is corrupted or unreadable.',
        technicalMessage: e.toString(),
        stackTrace: stack,
      ));
    }

    final signatureValid = _verifySignature(extension, headerBytes);
    if (!signatureValid) {
      return FailureResult(InvalidSignatureFailure(
        message: 'File type signature mismatch.',
        technicalMessage: 'Signature bytes $headerBytes do not match expected signature for extension: .$extension',
      ));
    }

    // ── 4. Encryption & Password Check ───────────────────────────────────────
    if (extension == 'pdf') {
      final isEncrypted = _isPdfEncrypted(headerBytes, file);
      if (isEncrypted) {
        return const FailureResult(SecurityViolationFailure(
          message: 'Encrypted or password-locked PDF files are not supported.',
        ));
      }
    }

    return const Success(null);
  }

  /// Verifies magic byte signatures for common supported file types.
  static bool _verifySignature(String extension, List<int> bytes) {
    if (bytes.length < 3) return false;

    switch (extension) {
      case 'pdf':
        // PDF magic: %PDF (0x25, 0x50, 0x44, 0x46)
        return bytes.length >= 4 &&
            bytes[0] == 0x25 &&
            bytes[1] == 0x50 &&
            bytes[2] == 0x44 &&
            bytes[3] == 0x46;

      case 'png':
        // PNG magic: 89 50 4E 47 0D 0A 1A 0A
        return bytes.length >= 4 &&
            bytes[0] == 0x89 &&
            bytes[1] == 0x50 &&
            bytes[2] == 0x4E &&
            bytes[3] == 0x47;

      case 'jpg':
      case 'jpeg':
        // JPEG magic: FF D8 FF
        return bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF;

      case 'gif':
        // GIF magic: GIF8 (47 49 46 38)
        return bytes.length >= 4 &&
            bytes[0] == 0x47 &&
            bytes[1] == 0x49 &&
            bytes[2] == 0x46 &&
            bytes[3] == 0x38;

      case 'bmp':
        // BMP magic: BM (0x42, 0x4D)
        return bytes[0] == 0x42 && bytes[1] == 0x4D;

      case 'webp':
        // WebP magic: RIFF....WEBP (RIFF: 52 49 46 46)
        return bytes.length >= 4 &&
            bytes[0] == 0x52 &&
            bytes[1] == 0x49 &&
            bytes[2] == 0x46 &&
            bytes[3] == 0x46;

      case 'zip':
      case 'docx':
      case 'xlsx':
      case 'pptx':
        // ZIP/Office formats magic: PK.. (0x50, 0x4B, 0x03, 0x04)
        return bytes[0] == 0x50 && bytes[1] == 0x4B;

      case 'txt':
      case 'html':
      case 'rtf':
        // Text-based files don't have binary signatures.
        // We require they don't start with binary non-printable control characters.
        for (final b in bytes.take(8)) {
          if (b < 9 && b != 0) return false; // Contains control characters
        }
        return true;

      default:
        // Gracefully allow other extensions without strict magic checking
        return true;
    }
  }

  /// Simple check to determine if a PDF file is encrypted/password locked.
  static bool _isPdfEncrypted(List<int> header, File file) {
    try {
      // PDF specification password markers typically contain '/Encrypt'
      // We can scan the first 1024 bytes of the PDF to check for the Encrypt key.
      final length = file.lengthSync();
      final scanBytes = file.readAsBytesSync().sublist(0, length > 1024 ? 1024 : length);
      final content = String.fromCharCodes(scanBytes);
      return content.contains('/Encrypt');
    } catch (_) {
      return false;
    }
  }
}
