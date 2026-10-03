/// ─────────────────────────────────────────────────────────────────────────────
/// Security Utilities (Stub)
///
/// Placeholder for future security-related helpers:
///   - File integrity validation via SHA-256 checksum
///   - Secure temp file cleanup
///   - Path traversal sanitisation
///
/// No network permissions are required for the current offline mode.
/// This class is prepared for the future Hybrid (online) mode.
/// ─────────────────────────────────────────────────────────────────────────────
abstract final class SecurityUtils {
  // TODO(security): Implement SHA-256 file checksum validation.
  // static Future<String> computeFileChecksum(File file) async { ... }

  // TODO(security): Implement path traversal sanitisation.
  // static String sanitisePath(String rawPath) { ... }

  // TODO(security): Implement secure temp file removal.
  // static Future<void> secureDeleteFile(File file) async { ... }
}
