/// ─────────────────────────────────────────────────────────────────────────────
/// StoragePathConfig — Resolved Application Directory Paths
///
/// Immutable value object produced by [DirectoryManager] once all directories
/// have been created and verified. All other services obtain paths from here.
/// ─────────────────────────────────────────────────────────────────────────────
class StoragePathConfig {
  const StoragePathConfig({
    required this.rootPath,
    required this.convertedDocumentsPath,
    required this.convertedImagesPath,
    required this.tempPath,
    required this.cachePath,
    required this.logsPath,
    required this.exportsPath,
    required this.historyPath,
    required this.thumbnailsPath,
    required this.scansTempPath,
  });

  final String rootPath;
  final String convertedDocumentsPath;
  final String convertedImagesPath;
  final String tempPath;
  final String cachePath;
  final String logsPath;
  final String exportsPath;
  final String historyPath;
  final String thumbnailsPath;
  final String scansTempPath;

  /// Returns the correct output directory for a given output [extension].
  String resolveOutputDirectory(String extension) {
    const imageExts = {
      'png', 'jpg', 'jpeg', 'webp', 'bmp', 'gif', 'tiff', 'svg', 'heic',
    };
    final ext = extension.toLowerCase().replaceFirst('.', '');
    return imageExts.contains(ext) ? convertedImagesPath : convertedDocumentsPath;
  }

  @override
  String toString() => 'StoragePathConfig(root: $rootPath)';
}
