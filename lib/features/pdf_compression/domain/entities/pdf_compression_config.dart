import 'package:equatable/equatable.dart';

/// User-facing compression modes
enum PdfCompressionLevel {
  /// Maximum compression — smallest size, lower quality
  max(
    displayName: 'Max Compression',
    subtitle: 'Smallest size • Lower quality',
    maxDimension: 1400,
    jpegQuality: 50,
  ),

  /// Medium compression — balanced size, balanced quality (DEFAULT)
  medium(
    displayName: 'Medium Compression',
    subtitle: 'Balanced size • Balanced quality',
    maxDimension: 2000,
    jpegQuality: 70,
  ),

  /// Low compression — larger size, maximum quality
  low(
    displayName: 'Low Compression',
    subtitle: 'Larger size • Maximum quality',
    maxDimension: 2600,
    jpegQuality: 85,
  );

  const PdfCompressionLevel({
    required this.displayName,
    required this.subtitle,
    required this.maxDimension,
    required this.jpegQuality,
  });

  final String displayName;
  final String subtitle;
  final int maxDimension;
  final int jpegQuality;
}

/// Parameters passed to the background compression isolate
class PdfCompressionParams extends Equatable {
  const PdfCompressionParams({
    required this.inputPath,
    required this.outputPath,
    required this.level,
    this.password,
  });

  final String inputPath;
  final String outputPath;
  final PdfCompressionLevel level;
  final String? password;

  @override
  List<Object?> get props => [inputPath, outputPath, level, password];
}

/// Result returned after compression execution
class PdfCompressionResult extends Equatable {
  const PdfCompressionResult({
    required this.sourcePath,
    required this.destinationPath,
    required this.originalSizeBytes,
    required this.compressedSizeBytes,
    required this.savedBytes,
    required this.percentageSaved,
    required this.isOriginalRetained,
    required this.duration,
    required this.isSuccess,
    this.errorMessage,
  });

  final String sourcePath;
  final String destinationPath;
  final int originalSizeBytes;
  final int compressedSizeBytes;
  final int savedBytes;
  final double percentageSaved;
  final bool isOriginalRetained;
  final Duration duration;
  final bool isSuccess;
  final String? errorMessage;

  @override
  List<Object?> get props => [
        sourcePath,
        destinationPath,
        originalSizeBytes,
        compressedSizeBytes,
        savedBytes,
        percentageSaved,
        isOriginalRetained,
        duration,
        isSuccess,
        errorMessage,
      ];
}

/// Status enum for PDF compression lifecycle
enum PdfCompressionStatus {
  initial,
  selecting,
  selected,
  compressing,
  completed,
  error,
}

/// State container for PDF Compression Provider
class PdfCompressionState extends Equatable {
  const PdfCompressionState({
    this.status = PdfCompressionStatus.initial,
    this.selectedPath,
    this.fileName,
    this.originalSizeBytes = 0,
    this.pageCount = 0,
    this.level = PdfCompressionLevel.medium,
    this.progress = 0.0,
    this.statusMessage = '',
    this.result,
    this.errorMessage,
    this.password,
  });

  final PdfCompressionStatus status;
  final String? selectedPath;
  final String? fileName;
  final int originalSizeBytes;
  final int pageCount;
  final PdfCompressionLevel level;
  final double progress;
  final String statusMessage;
  final PdfCompressionResult? result;
  final String? errorMessage;
  final String? password;

  bool get hasFile => selectedPath != null && selectedPath!.isNotEmpty;
  bool get isCompressing => status == PdfCompressionStatus.compressing;
  bool get isCompleted => status == PdfCompressionStatus.completed;

  PdfCompressionState copyWith({
    PdfCompressionStatus? status,
    String? selectedPath,
    String? fileName,
    int? originalSizeBytes,
    int? pageCount,
    PdfCompressionLevel? level,
    double? progress,
    String? statusMessage,
    PdfCompressionResult? result,
    String? errorMessage,
    String? password,
    bool clearFile = false,
    bool clearError = false,
  }) {
    return PdfCompressionState(
      status: status ?? this.status,
      selectedPath: clearFile ? null : (selectedPath ?? this.selectedPath),
      fileName: clearFile ? null : (fileName ?? this.fileName),
      originalSizeBytes: clearFile ? 0 : (originalSizeBytes ?? this.originalSizeBytes),
      pageCount: clearFile ? 0 : (pageCount ?? this.pageCount),
      level: level ?? this.level,
      progress: progress ?? this.progress,
      statusMessage: statusMessage ?? this.statusMessage,
      result: result ?? this.result,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      password: password ?? this.password,
    );
  }

  @override
  List<Object?> get props => [
        status,
        selectedPath,
        fileName,
        originalSizeBytes,
        pageCount,
        level,
        progress,
        statusMessage,
        result,
        errorMessage,
        password,
      ];
}
