import 'dart:io';
import 'dart:isolate';

import 'package:flux_convert/core/logging/logger_service.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// StorageScanner
///
/// Performs lazy filesystem scans in an isolate so the UI never freezes.
/// ─────────────────────────────────────────────────────────────────────────────
class StorageScanner {
  /// Scans [tempDir] for files older than [olderThan].
  /// Returns absolute paths of orphan temp files.
  Future<List<String>> scanOrphanTempFiles({
    required String tempDir,
    Duration olderThan = const Duration(hours: 1),
  }) async {
    final result = await Isolate.run(
      () => _findOrphans(tempDir, olderThan),
    );
    AppLogger.info('StorageScanner: found ${result.length} orphan temp files');
    return result;
  }

  /// Filters [knownPaths] to those that no longer exist on disk.
  Future<List<String>> scanMissingFiles(List<String> knownPaths) async {
    if (knownPaths.isEmpty) return const [];
    final result = await Isolate.run(
      () => knownPaths.where((p) => !File(p).existsSync()).toList(),
    );
    AppLogger.info('StorageScanner: found ${result.length} missing converted files');
    return result;
  }

  /// Scans common directories for local document files (PDF, DOCX, PPT, XLS, etc).
  Future<List<String>> scanLocalDocuments({required String appDocPath}) async {
    final result = await Isolate.run(
      () => _scanLocalDocs(appDocPath),
    );
    AppLogger.info('StorageScanner: found ${result.length} local document files');
    return result;
  }

  // ── Isolate entry point ────────────────────────────────────────────────────

  static List<String> _findOrphans(String dir, Duration olderThan) {
    final cutoff = DateTime.now().subtract(olderThan);
    final directory = Directory(dir);
    if (!directory.existsSync()) return const [];

    final orphans = <String>[];
    try {
      for (final entity in directory.listSync()) {
        if (entity is! File) continue;
        final modified = entity.statSync().modified;
        if (modified.isBefore(cutoff)) {
          orphans.add(entity.path);
        }
      }
    } on Exception catch (_) {
      // Silently ignore permission or I/O errors during scan
    }
    return orphans;
  }

  static List<String> _scanLocalDocs(String appDocPath) {
    final docs = <String>[];

    // Ensure app doc subfolder for mock files exists
    final mockDir = Directory('$appDocPath/documents');
    if (!mockDir.existsSync()) {
      mockDir.createSync(recursive: true);
    }

    // Populate mock files if directory is empty
    try {
      final existing = mockDir.listSync();
      if (existing.isEmpty) {
        final mockFiles = [
          'Academic Calendar (Fall-2026).pdf',
          'FYP_Proposal_V4.pdf',
          'Legal Documents Formate.pdf',
          'All_Form_2025.pdf',
          'Minimum-Aggregate-UG-2026.pdf',
          'Annual_Budget_Report.xlsx',
          'Product_Roadmap_2026.pptx',
          'Meeting_Minutes.txt',
        ];
        for (final name in mockFiles) {
          final f = File('${mockDir.path}/$name');
          if (name.endsWith('.pdf')) {
            f.writeAsStringSync('%PDF-1.4\n% Mock PDF File: $name\n%%EOF\n');
          } else if (name.endsWith('.xlsx') || name.endsWith('.pptx')) {
            f.writeAsStringSync('PK\u0003\u0004 Mock Zip File: $name');
          } else {
            f.writeAsStringSync('Mock Text File Contents: $name');
          }
        }
      }
    } catch (_) {}

    // Scan directories
    final scanTargets = <String>[appDocPath];
    if (Platform.isAndroid) {
      scanTargets.addAll([
        '/storage/emulated/0/Download',
        '/storage/emulated/0/Downloads',
        '/storage/emulated/0/Documents',
        '/storage/emulated/0/PDF',
        '/storage/emulated/0/Office',
        '/storage/emulated/0/WhatsApp/Media/WhatsApp Documents',
        '/storage/emulated/0/Telegram/Telegram Documents',
        '/storage/emulated/0/DCIM',
        '/storage/emulated/0/Pictures',
        '/storage/emulated/0/Music',
      ]);
    }

    // Documents + image formats so the Files screen shows all supported files.
    const allowedExtensions = {
      'pdf', 'docx', 'doc', 'xlsx', 'xls', 'csv', 'ods', 'pptx', 'ppt',
      'txt', 'rtf', 'html', 'odt',
      'png', 'jpg', 'jpeg', 'webp', 'bmp', 'gif', 'heic', 'tiff',
    };

    for (final path in scanTargets) {
      final dir = Directory(path);
      if (!dir.existsSync()) continue;
      try {
        _recurseScan(dir, allowedExtensions, docs, 0, 4);
      } catch (_) {}
    }

    return docs;
  }

  static void _recurseScan(
    Directory dir,
    Set<String> extensions,
    List<String> results,
    int currentDepth,
    int maxDepth,
  ) {
    if (currentDepth > maxDepth) return;
    try {
      for (final entity in dir.listSync(followLinks: false)) {
        if (entity is File) {
          final ext = entity.path.split('.').last.toLowerCase();
          if (extensions.contains(ext)) {
            if (!results.contains(entity.path)) {
              results.add(entity.path);
            }
          }
        } else if (entity is Directory) {
          final name = entity.path.split('/').last.split(r'\').last;
          if (!name.startsWith('.') && name != 'Android' && name != 'cache') {
            _recurseScan(entity, extensions, results, currentDepth + 1, maxDepth);
          }
        }
      }
    } catch (_) {}
  }
}
