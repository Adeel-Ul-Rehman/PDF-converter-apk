/// ─────────────────────────────────────────────────────────────────────────────
/// ConverterCapabilities
///
/// Model describing the operational capabilities of a format converter.
/// Helps the UI layer dynamically enable/disable advanced setting panels.
/// ─────────────────────────────────────────────────────────────────────────────
class ConverterCapabilities {
  const ConverterCapabilities({
    required this.supportsBatch,
    required this.supportsProgress,
    required this.supportsCancellation,
    required this.supportsPasswordProtectedFiles,
    required this.supportsMetadata,
    required this.supportsCompression,
    required this.supportsMultiPage,
  });

  /// Standard capability presets for quick instantiation
  
  /// Base simple single-file capabilities
  static const basic = ConverterCapabilities(
    supportsBatch: false,
    supportsProgress: false,
    supportsCancellation: false,
    supportsPasswordProtectedFiles: false,
    supportsMetadata: false,
    supportsCompression: false,
    supportsMultiPage: false,
  );

  /// Advanced interactive features (like PDF rendering or image compressions)
  static const fullFeatured = ConverterCapabilities(
    supportsBatch: true,
    supportsProgress: true,
    supportsCancellation: true,
    supportsPasswordProtectedFiles: true,
    supportsMetadata: true,
    supportsCompression: true,
    supportsMultiPage: true,
  );

  /// Dynamic conversion features
  final bool supportsBatch;
  final bool supportsProgress;
  final bool supportsCancellation;
  final bool supportsPasswordProtectedFiles;
  final bool supportsMetadata;
  final bool supportsCompression;
  final bool supportsMultiPage;
}
