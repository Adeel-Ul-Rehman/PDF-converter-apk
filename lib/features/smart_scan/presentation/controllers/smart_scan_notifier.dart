import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:flux_convert/core/logging/logger_service.dart';
import 'package:flux_convert/core/permissions/permission_service.dart';
import 'package:flux_convert/features/smart_scan/domain/entities/document_quadrilateral.dart';
import 'package:flux_convert/features/smart_scan/domain/entities/smart_scan_state.dart';
import 'package:flux_convert/features/storage/data/services/directory_manager.dart';

/// Provider for [SmartScanNotifier].
final smartScanNotifierProvider =
    StateNotifierProvider.autoDispose<SmartScanNotifier, SmartScanState>(
  (ref) => SmartScanNotifier(
    permissionService: ref.watch(permissionServiceProvider),
    directoryManager: DirectoryManager(),
  ),
);

/// Controller to drive Smart Scan camera lifecycle, permissions, and scan session staging.
class SmartScanNotifier extends StateNotifier<SmartScanState> {
  SmartScanNotifier({
    required PermissionService permissionService,
    required DirectoryManager directoryManager,
  })  : _permissionService = permissionService,
        _directoryManager = directoryManager,
        super(const SmartScanState());

  final PermissionService _permissionService;
  final DirectoryManager _directoryManager;
  CameraController? _cameraController;
  int _stableFrameCount = 0;
  DateTime? _lastAutoCaptureTime;

  CameraController? get cameraController => _cameraController;

  /// Updates the currently detected document quadrilateral and evaluates auto-capture stability.
  void updateDetectedQuadrilateral(DocumentQuadrilateral? quad) {
    if (!mounted || state.isCapturing) return;

    if (quad == null || !quad.isValid) {
      _stableFrameCount = 0;
      state = state.copyWith(
        clearDetectedQuad: true,
        isStableForAutoCapture: false,
      );
      return;
    }

    final prevQuad = state.detectedQuad;
    var isStable = false;

    if (prevQuad != null && quad.isSimilarTo(prevQuad)) {
      _stableFrameCount++;
      if (_stableFrameCount >= 3) {
        isStable = true;
      }
    } else {
      _stableFrameCount = 0;
    }

    state = state.copyWith(
      detectedQuad: quad,
      isStableForAutoCapture: isStable,
    );

    // Auto-capture trigger check
    if (state.isAutoCaptureEnabled && isStable && !state.isCapturing) {
      final now = DateTime.now();
      if (_lastAutoCaptureTime == null ||
          now.difference(_lastAutoCaptureTime!) > const Duration(milliseconds: 1800)) {
        _lastAutoCaptureTime = now;
        _stableFrameCount = 0;
        capturePage();
      }
    }
  }

  /// Toggles automatic capture mode.
  void toggleAutoCapture() {
    state = state.copyWith(isAutoCaptureEnabled: !state.isAutoCaptureEnabled);
  }

  /// Initializes the Smart Scan camera session: checks permission & sets up rear camera.
  Future<void> initializeSession() async {
    if (state.status == SmartScanStatus.cameraInitializing ||
        state.status == SmartScanStatus.cameraReady) {
      return;
    }

    state = state.copyWith(status: SmartScanStatus.permissionRequesting);

    final status = await _permissionService.requestCameraPermission();

    if (status.isPermanentlyDenied) {
      state = state.copyWith(status: SmartScanStatus.permissionPermanentlyDenied);
      return;
    }

    if (!status.isGranted) {
      state = state.copyWith(status: SmartScanStatus.permissionDenied);
      return;
    }

    await _initCameraController();
  }

  Future<void> _initCameraController() async {
    state = state.copyWith(status: SmartScanStatus.cameraInitializing);

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        state = state.copyWith(
          status: SmartScanStatus.cameraError,
          errorMessage: 'No cameras available on this device.',
        );
        return;
      }

      // Prefer rear camera
      final rearCamera = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        rearCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      _cameraController = controller;
      await controller.initialize();
      await controller.setFlashMode(state.flashMode);

      if (mounted) {
        state = state.copyWith(status: SmartScanStatus.cameraReady);
        AppLogger.info('SmartScanNotifier: Camera initialized successfully');
      }
    } catch (e, stack) {
      AppLogger.error('SmartScanNotifier: Camera initialization failed', e, stack);
      if (mounted) {
        state = state.copyWith(
          status: SmartScanStatus.cameraError,
          errorMessage: 'Failed to initialize camera: $e',
        );
      }
    }
  }

  /// Cycles through flash modes: Off -> Auto -> Always -> Torch -> Off.
  Future<void> toggleFlashMode() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;

    final nextMode = switch (state.flashMode) {
      FlashMode.off => FlashMode.auto,
      FlashMode.auto => FlashMode.always,
      FlashMode.always => FlashMode.torch,
      FlashMode.torch => FlashMode.off,
    };

    try {
      await _cameraController!.setFlashMode(nextMode);
      state = state.copyWith(flashMode: nextMode);
      AppLogger.trace('SmartScanNotifier: Flash mode set to $nextMode');
    } catch (e) {
      AppLogger.warning('SmartScanNotifier: Failed to set flash mode: $e');
    }
  }

  /// Captures a photo and stages it safely into the temporary scan directory.
  Future<String?> capturePage() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        state.isCapturing) {
      return null;
    }

    state = state.copyWith(isCapturing: true);

    try {
      final xFile = await _cameraController!.takePicture();
      final config = await _directoryManager.ensureAll();
      final scansDir = Directory(config.scansTempPath);
      if (!scansDir.existsSync()) {
        scansDir.createSync(recursive: true);
      }

      final timeStamp = DateTime.now().millisecondsSinceEpoch;
      final targetPath = '${config.scansTempPath}/scan_${timeStamp}_${state.pageCount + 1}.jpg';

      // Copy camera XFile to app sandbox scans folder
      final capturedFile = File(xFile.path);
      await capturedFile.copy(targetPath);

      // Clean up temporary XFile
      if (capturedFile.existsSync()) {
        try {
          capturedFile.deleteSync();
        } catch (_) {}
      }

      final updatedStaged = List<String>.from(state.stagedImagePaths)..add(targetPath);

      state = state.copyWith(
        stagedImagePaths: updatedStaged,
        isCapturing: false,
      );

      AppLogger.info('SmartScanNotifier: Page captured & staged at $targetPath');
      return targetPath;
    } catch (e, stack) {
      AppLogger.error('SmartScanNotifier: Failed to capture page', e, stack);
      state = state.copyWith(
        isCapturing: false,
        errorMessage: 'Capture failed: $e',
      );
      return null;
    }
  }

  /// Removes a staged page at the given index.
  void removeStagedPage(int index) {
    if (index < 0 || index >= state.stagedImagePaths.length) return;

    final updated = List<String>.from(state.stagedImagePaths);
    final removedPath = updated.removeAt(index);

    // Delete temp file from filesystem
    try {
      final file = File(removedPath);
      if (file.existsSync()) {
        file.deleteSync();
      }
    } catch (e) {
      AppLogger.warning('SmartScanNotifier: Failed to delete staged temp scan file', e);
    }

    state = state.copyWith(stagedImagePaths: updated);
  }

  /// Clears all staged pages and deletes temporary files.
  void clearStagedPages() {
    for (final path in state.stagedImagePaths) {
      try {
        final file = File(path);
        if (file.existsSync()) {
          file.deleteSync();
        }
      } catch (_) {}
    }
    state = state.copyWith(stagedImagePaths: []);
  }

  /// Opens application settings page if permission was permanently denied.
  Future<void> openSettings() async {
    await _permissionService.openAppSettingsPage();
  }

  @override
  void dispose() {
    state = state.copyWith(status: SmartScanStatus.disposed);
    _cameraController?.dispose();
    _cameraController = null;
    super.dispose();
  }
}
