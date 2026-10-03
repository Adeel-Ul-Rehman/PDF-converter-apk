/// ─────────────────────────────────────────────────────────────────────────────
/// PDF Engine Task Entities
///
/// Models specifying operations and configurations for the offline PDF engine.
/// ─────────────────────────────────────────────────────────────────────────────
library;

enum PdfTaskType {
  imageToPdf,
  pdfToImage,
  merge,
  split,
  rotate,
  compress;
}

enum PdfPageSizePreset {
  a4,
  letter,
  original;
}

enum PdfOrientation {
  portrait,
  landscape;
}

enum PdfCompressionPreset {
  highQuality, // balanced compression
  balanced,
  smallSize; // lossy downscaling
}

/// Parameters for creating a PDF from a list of images.
class ImageToPdfParams {
  const ImageToPdfParams({
    required this.imagePaths,
    this.pageSize = PdfPageSizePreset.a4,
    this.orientation = PdfOrientation.portrait,
    this.marginDouble = 20.0,
  });

  final List<String> imagePaths;
  final PdfPageSizePreset pageSize;
  final PdfOrientation orientation;
  final double marginDouble;
}

/// Parameters for exporting PDF pages as PNG images.
class PdfToImageParams {
  const PdfToImageParams({
    required this.pdfPath,
    this.qualityPercent = 80,
    this.pageRange,
  });

  final String pdfPath;
  final int qualityPercent;
  final List<int>? pageRange; // Null means export all pages
}

/// Parameters for merging multiple PDF files into one.
class PdfMergeParams {
  const PdfMergeParams({
    required this.pdfPaths,
  });

  final List<String> pdfPaths;
}

/// Parameters for splitting PDF pages.
class PdfSplitParams {
  const PdfSplitParams({
    required this.pdfPath,
    this.splitRanges = const [],
    this.splitEveryN,
  });

  final String pdfPath;
  final List<List<int>> splitRanges; // List of [startPage, endPage] pairs
  final int? splitEveryN; // Splits every N pages (e.g. splitEveryN = 2)
}

/// Parameters for rotating PDF pages.
class PdfRotateParams {
  const PdfRotateParams({
    required this.pdfPath,
    required this.angleDegrees, // 90, 180, 270
    this.targetPages, // Null means rotate all pages
  });

  final String pdfPath;
  final int angleDegrees;
  final List<int>? targetPages;
}

/// Parameters for compressing PDF document contents.
class PdfCompressParams {
  const PdfCompressParams({
    required this.pdfPath,
    this.preset = PdfCompressionPreset.balanced,
  });

  final String pdfPath;
  final PdfCompressionPreset preset;
}

/// Unified task container wrapping target parameters.
class PdfTask {
  const PdfTask({
    required this.taskId,
    required this.type,
    required this.outputPath,
    this.imageToPdfParams,
    this.pdfToImageParams,
    this.mergeParams,
    this.splitParams,
    this.rotateParams,
    this.compressParams,
  });

  final String taskId;
  final PdfTaskType type;
  final String outputPath;

  // Configurations mapped by task type
  final ImageToPdfParams? imageToPdfParams;
  final PdfToImageParams? pdfToImageParams;
  final PdfMergeParams? mergeParams;
  final PdfSplitParams? splitParams;
  final PdfRotateParams? rotateParams;
  final PdfCompressParams? compressParams;
}
