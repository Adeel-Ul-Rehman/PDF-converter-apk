import 'package:equatable/equatable.dart';
import 'package:flux_convert/features/smart_scan/domain/entities/document_quadrilateral.dart';

/// Available document color enhancement modes.
enum ScanEnhancementMode {
  original,
  color,
  grayscale,
  blackAndWhite,
  document;

  String get displayName => switch (this) {
        ScanEnhancementMode.original => 'Original',
        ScanEnhancementMode.color => 'Color',
        ScanEnhancementMode.grayscale => 'Grayscale',
        ScanEnhancementMode.blackAndWhite => 'B&W',
        ScanEnhancementMode.document => 'Document',
      };
}

/// Status of background image processing for a scanned page.
enum PageProcessingStatus {
  idle,
  processing,
  completed,
  failed,
}

/// Immutable entity representing an individual scanned document page.
class ScannedPage extends Equatable {
  const ScannedPage({
    required this.id,
    required this.originalPath,
    required this.processedPath,
    this.width = 0,
    this.height = 0,
    this.rotation = 0,
    this.enhancementMode = ScanEnhancementMode.original,
    this.brightness = 0.0,
    this.contrast = 100.0,
    this.processingStatus = PageProcessingStatus.idle,
    this.creationOrder = 0,
    this.quadrilateral,
  });

  final String id;
  final String originalPath;
  final String processedPath;
  final int width;
  final int height;
  final int rotation; // Degrees: 0, 90, 180, 270
  final ScanEnhancementMode enhancementMode;
  final double brightness; // -100.0 to +100.0
  final double contrast; // 0.0 to 200.0 (100.0 = default)
  final PageProcessingStatus processingStatus;
  final int creationOrder;
  final DocumentQuadrilateral? quadrilateral;

  bool get isProcessed => processingStatus == PageProcessingStatus.completed;

  ScannedPage copyWith({
    String? id,
    String? originalPath,
    String? processedPath,
    int? width,
    int? height,
    int? rotation,
    ScanEnhancementMode? enhancementMode,
    double? brightness,
    double? contrast,
    PageProcessingStatus? processingStatus,
    int? creationOrder,
    DocumentQuadrilateral? quadrilateral,
    bool clearQuadrilateral = false,
  }) {
    return ScannedPage(
      id: id ?? this.id,
      originalPath: originalPath ?? this.originalPath,
      processedPath: processedPath ?? this.processedPath,
      width: width ?? this.width,
      height: height ?? this.height,
      rotation: rotation ?? this.rotation,
      enhancementMode: enhancementMode ?? this.enhancementMode,
      brightness: brightness ?? this.brightness,
      contrast: contrast ?? this.contrast,
      processingStatus: processingStatus ?? this.processingStatus,
      creationOrder: creationOrder ?? this.creationOrder,
      quadrilateral:
          clearQuadrilateral ? null : (quadrilateral ?? this.quadrilateral),
    );
  }

  @override
  List<Object?> get props => [
        id,
        originalPath,
        processedPath,
        width,
        height,
        rotation,
        enhancementMode,
        brightness,
        contrast,
        processingStatus,
        creationOrder,
        quadrilateral,
      ];
}
