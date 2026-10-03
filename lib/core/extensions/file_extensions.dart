import 'dart:io';
import 'package:flux_convert/core/utils/file_size_utils.dart';
import 'package:flux_convert/core/utils/file_type_detector.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// FileExtensions — Practical extensions on native File objects
/// ─────────────────────────────────────────────────────────────────────────────
extension FileExtensions on File {
  /// Returns the file extension as a lowercase string (without dot).
  String get extension => path.split('.').last.toLowerCase();

  /// Returns the file name with its extension.
  String get name => path.split(Platform.pathSeparator).last;

  /// Returns the file name without its extension.
  String get nameWithoutExtension {
    final filename = name;
    final dotIndex = filename.lastIndexOf('.');
    return dotIndex == -1 ? filename : filename.substring(0, dotIndex);
  }

  /// Returns the human-readable formatted file size.
  String get sizeFormatted {
    if (!existsSync()) return '0 B';
    return FileSizeUtils.format(lengthSync());
  }

  /// Detects the category type of this file.
  FileCategory get category => FileTypeDetector.detectCategory(path);
}
