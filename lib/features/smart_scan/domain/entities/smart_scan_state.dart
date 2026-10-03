import 'package:camera/camera.dart';
import 'package:equatable/equatable.dart';
import 'package:flux_convert/features/smart_scan/domain/entities/document_quadrilateral.dart';

/// Status of the Smart Scan camera session.
enum SmartScanStatus {
  initial,
  permissionRequesting,
  permissionDenied,
  permissionPermanentlyDenied,
  cameraInitializing,
  cameraReady,
  cameraError,
  capturing,
  disposed,
}

/// Immutable state model representing a Smart Scan camera session.
class SmartScanState extends Equatable {
  const SmartScanState({
    this.status = SmartScanStatus.initial,
    this.errorMessage,
    this.flashMode = FlashMode.off,
    this.stagedImagePaths = const [],
    this.isCapturing = false,
    this.detectedQuad,
    this.isAutoCaptureEnabled = true,
    this.isStableForAutoCapture = false,
    this.isProcessingWarp = false,
  });

  final SmartScanStatus status;
  final String? errorMessage;
  final FlashMode flashMode;
  final List<String> stagedImagePaths;
  final bool isCapturing;
  final DocumentQuadrilateral? detectedQuad;
  final bool isAutoCaptureEnabled;
  final bool isStableForAutoCapture;
  final bool isProcessingWarp;

  bool get isCameraReady => status == SmartScanStatus.cameraReady;
  bool get hasStagedPages => stagedImagePaths.isNotEmpty;
  int get pageCount => stagedImagePaths.length;

  SmartScanState copyWith({
    SmartScanStatus? status,
    String? errorMessage,
    FlashMode? flashMode,
    List<String>? stagedImagePaths,
    bool? isCapturing,
    DocumentQuadrilateral? detectedQuad,
    bool? isAutoCaptureEnabled,
    bool? isStableForAutoCapture,
    bool? isProcessingWarp,
    bool clearError = false,
    bool clearDetectedQuad = false,
  }) {
    return SmartScanState(
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      flashMode: flashMode ?? this.flashMode,
      stagedImagePaths: stagedImagePaths ?? this.stagedImagePaths,
      isCapturing: isCapturing ?? this.isCapturing,
      detectedQuad: clearDetectedQuad ? null : (detectedQuad ?? this.detectedQuad),
      isAutoCaptureEnabled: isAutoCaptureEnabled ?? this.isAutoCaptureEnabled,
      isStableForAutoCapture: isStableForAutoCapture ?? this.isStableForAutoCapture,
      isProcessingWarp: isProcessingWarp ?? this.isProcessingWarp,
    );
  }

  @override
  List<Object?> get props => [
        status,
        errorMessage,
        flashMode,
        stagedImagePaths,
        isCapturing,
        detectedQuad,
        isAutoCaptureEnabled,
        isStableForAutoCapture,
        isProcessingWarp,
      ];
}
