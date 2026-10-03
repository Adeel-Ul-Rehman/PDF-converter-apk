import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

// IMPROVED: Discovered file entity model
class DiscoveredFile {
  const DiscoveredFile({
    required this.path,
    required this.name,
    required this.extension,
    required this.sizeBytes,
    required this.modifiedDate,
  });

  final String path;
  final String name;
  final String extension;
  final int sizeBytes;
  final DateTime modifiedDate;
}

enum FileSortOption { name, date, type, size }
enum FileTypeCategoryFilter { all, pdf, images, documents }

// IMPROVED: Domain Use Case for scanning all device storage in background isolate
class ScanAllFilesUseCase {
  /// Scans storage directories in a background isolate to keep UI free of lag
  Future<List<DiscoveredFile>> executeScan({
    FileTypeCategoryFilter category = FileTypeCategoryFilter.all,
    FileSortOption sortOption = FileSortOption.date,
  }) async {
    final dirsToScan = <String>[];

    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      dirsToScan.add(appDocDir.path);
    } catch (_) {}

    try {
      final tempDir = await getTemporaryDirectory();
      dirsToScan.add(tempDir.path);
    } catch (_) {}

    if (Platform.isAndroid) {
      dirsToScan.addAll([
        '/storage/emulated/0/Download',
        '/storage/emulated/0/Documents',
        '/storage/emulated/0/Pictures',
        '/storage/emulated/0/DCIM',
      ]);
    }

    final rawList = await compute(
      _scanDirectoryIsolate,
      _ScanParams(dirPaths: dirsToScan, category: category),
    );

    // Sort files according to sortOption
    final sorted = List<DiscoveredFile>.from(rawList);
    switch (sortOption) {
      case FileSortOption.name:
        sorted.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      case FileSortOption.date:
        sorted.sort((a, b) => b.modifiedDate.compareTo(a.modifiedDate));
      case FileSortOption.type:
        sorted.sort((a, b) => a.extension.compareTo(b.extension));
      case FileSortOption.size:
        sorted.sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));
    }

    return sorted;
  }
}

// ─── Isolate Entry Point ───────────────────────────────────────────────────

class _ScanParams {
  const _ScanParams({
    required this.dirPaths,
    required this.category,
  });

  final List<String> dirPaths;
  final FileTypeCategoryFilter category;
}

List<DiscoveredFile> _scanDirectoryIsolate(_ScanParams params) {
  final results = <DiscoveredFile>[];
  final visitedPaths = <String>{};

  final allowedPdfExts = {'pdf'};
  final allowedImgExts = {'png', 'jpg', 'jpeg', 'webp', 'bmp', 'gif'};
  final allowedDocExts = {'doc', 'docx', 'txt', 'csv', 'xlsx', 'pptx'};

  for (final dirPath in params.dirPaths) {
    final dir = Directory(dirPath);
    if (!dir.existsSync()) continue;

    try {
      final entities = dir.listSync();
      for (final entity in entities) {
        if (entity is File) {
          if (visitedPaths.contains(entity.path)) continue;
          visitedPaths.add(entity.path);

          final ext = entity.path.split('.').last.toLowerCase();

          // Category filter check
          final matchesCategory = switch (params.category) {
            FileTypeCategoryFilter.all =>
              allowedPdfExts.contains(ext) || allowedImgExts.contains(ext) || allowedDocExts.contains(ext),
            FileTypeCategoryFilter.pdf => allowedPdfExts.contains(ext),
            FileTypeCategoryFilter.images => allowedImgExts.contains(ext),
            FileTypeCategoryFilter.documents => allowedDocExts.contains(ext),
          };

          if (!matchesCategory) continue;

          try {
            final stat = entity.statSync();
            final fileName = entity.path.split('/').last.split(r'\').last;

            results.add(
              DiscoveredFile(
                path: entity.path,
                name: fileName,
                extension: ext,
                sizeBytes: stat.size,
                modifiedDate: stat.modified,
              ),
            );
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  return results;
}
