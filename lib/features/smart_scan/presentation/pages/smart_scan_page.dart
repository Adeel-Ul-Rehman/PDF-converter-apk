import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flux_convert/core/core.dart';
import 'package:flux_convert/features/smart_scan/domain/entities/smart_scan_state.dart';
import 'package:flux_convert/features/smart_scan/presentation/controllers/scan_session_notifier.dart';
import 'package:flux_convert/features/smart_scan/presentation/controllers/smart_scan_notifier.dart';
import 'package:flux_convert/features/smart_scan/presentation/widgets/document_overlay_painter.dart';

/// SmartScanPage — Live Camera Viewport & Capture Staging Screen.
class SmartScanPage extends ConsumerStatefulWidget {
  const SmartScanPage({super.key});

  @override
  ConsumerState<SmartScanPage> createState() => _SmartScanPageState();
}

class _SmartScanPageState extends ConsumerState<SmartScanPage>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(smartScanNotifierProvider.notifier).initializeSession();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    final notifier = ref.read(smartScanNotifierProvider.notifier);
    final controller = notifier.cameraController;

    if (controller == null || !controller.value.isInitialized) return;

    if (lifecycleState == AppLifecycleState.inactive ||
        lifecycleState == AppLifecycleState.paused) {
      // Free camera resource when app goes to background
    } else if (lifecycleState == AppLifecycleState.resumed) {
      notifier.initializeSession();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  IconData _getFlashIcon(FlashMode mode) {
    return switch (mode) {
      FlashMode.off => Icons.flash_off_rounded,
      FlashMode.auto => Icons.flash_auto_rounded,
      FlashMode.always => Icons.flash_on_rounded,
      FlashMode.torch => Icons.highlight_rounded,
    };
  }

  String _getFlashLabel(FlashMode mode) {
    return switch (mode) {
      FlashMode.off => 'Flash Off',
      FlashMode.auto => 'Auto Flash',
      FlashMode.always => 'Flash On',
      FlashMode.torch => 'Torch On',
    };
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(smartScanNotifierProvider);
    final notifier = ref.read(smartScanNotifierProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? AppColorScheme.backgroundDark : Colors.black;

    final session = ref.watch(scanSessionProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (!session.hasPages && !state.hasStagedPages) {
          Navigator.of(context).pop();
          return;
        }
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Exit Camera?'),
            content: const Text('Do you want to discard your captured document pages?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Discard'),
              ),
            ],
          ),
        );
        if (shouldPop == true && context.mounted) {
          ref.read(scanSessionProvider.notifier).clearSession(deleteFiles: true);
          notifier.clearStagedPages();
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: Column(
            children: [
              // ── Header Bar ─────────────────────────────────────────────
              _buildHeader(context, state, notifier),

              // ── Camera Viewport / Fallback Body ──────────────────────────
              Expanded(
                child: _buildCameraBody(context, state, notifier),
              ),

              // ── Bottom Control Bar ─────────────────────────────────────
              _buildFooterControls(context, state, notifier),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    SmartScanState state,
    SmartScanNotifier notifier,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 24),
            onPressed: () {
              if (state.hasStagedPages) {
                notifier.clearStagedPages();
              }
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutes.home);
              }
            },
          ),
          const Text(
            'Smart Scan',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  state.isAutoCaptureEnabled
                      ? Icons.auto_awesome_rounded
                      : Icons.touch_app_rounded,
                  color: state.isAutoCaptureEnabled
                      ? const Color(0xFF00E676)
                      : Colors.white70,
                  size: 22,
                ),
                tooltip: state.isAutoCaptureEnabled
                    ? 'Auto-Capture On'
                    : 'Auto-Capture Off',
                onPressed: () => notifier.toggleAutoCapture(),
              ),
              IconButton(
                icon: Icon(
                  _getFlashIcon(state.flashMode),
                  color: state.flashMode != FlashMode.off
                      ? AppColorScheme.primaryBlueStart
                      : Colors.white70,
                  size: 24,
                ),
                tooltip: _getFlashLabel(state.flashMode),
                onPressed: state.isCameraReady ? () => notifier.toggleFlashMode() : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCameraBody(
    BuildContext context,
    SmartScanState state,
    SmartScanNotifier notifier,
  ) {
    switch (state.status) {
      case SmartScanStatus.permissionRequesting:
      case SmartScanStatus.cameraInitializing:
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 36,
                height: 36,
                child: CustomCircularProgress(),
              ),
              SizedBox(height: 16),
              Text(
                'Initializing Camera...',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        );

      case SmartScanStatus.permissionDenied:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.camera_alt_outlined, color: Colors.amber, size: 64),
                const SizedBox(height: 16),
                const Text(
                  'Camera Permission Required',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'FluxConvert needs camera access to scan physical documents.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColorScheme.primaryBlueStart,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  icon: const Icon(Icons.security_rounded),
                  label: const Text('Grant Camera Permission'),
                  onPressed: () => notifier.initializeSession(),
                ),
              ],
            ),
          ),
        );

      case SmartScanStatus.permissionPermanentlyDenied:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline_rounded, color: Colors.orange, size: 64),
                const SizedBox(height: 16),
                const Text(
                  'Camera Access Permanently Denied',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please enable camera permissions in Android settings to use Smart Scan.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColorScheme.primaryBlueStart,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  icon: const Icon(Icons.settings_rounded),
                  label: const Text('Open App Settings'),
                  onPressed: () => notifier.openSettings(),
                ),
              ],
            ),
          ),
        );

      case SmartScanStatus.cameraError:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 64),
                const SizedBox(height: 16),
                const Text(
                  'Camera Unavailable',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  state.errorMessage ?? 'An error occurred while launching camera.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColorScheme.primaryBlueStart,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => notifier.initializeSession(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );

      case SmartScanStatus.cameraReady:
      case SmartScanStatus.capturing:
        final controller = notifier.cameraController;
        if (controller == null || !controller.value.isInitialized) {
          return const Center(child: CustomCircularProgress());
        }

        return Container(
          width: double.infinity,
          color: Colors.black,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CameraPreview(controller),
                  CustomPaint(
                    painter: DocumentOverlayPainter(
                      quadrilateral: state.detectedQuad,
                      isStable: state.isStableForAutoCapture,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

      case SmartScanStatus.initial:
      case SmartScanStatus.disposed:
        return const SizedBox.shrink();
    }
  }

  Widget _buildFooterControls(
    BuildContext context,
    SmartScanState state,
    SmartScanNotifier notifier,
  ) {
    final session = ref.watch(scanSessionProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      color: Colors.black,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Staged session page thumbnail -> opens Page Manager
          if (session.hasPages || state.hasStagedPages)
            GestureDetector(
              onTap: () {
                context.push(AppRoutes.smartScanManager);
              },
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.grey[850],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColorScheme.primaryBlueStart, width: 2),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.file(
                      File(session.hasPages
                          ? (session.activePage?.processedPath ?? session.pages.last.originalPath)
                          : state.stagedImagePaths.last),
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => const Icon(
                        Icons.description_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Positioned(
                    top: -6,
                    right: -6,
                    child: CircleAvatar(
                      radius: 10,
                      backgroundColor: AppColorScheme.primaryBlueStart,
                      child: Text(
                        '${session.hasPages ? session.pageCount : state.pageCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            const SizedBox(width: 48),

          // Main Shutter / Capture Button
          GestureDetector(
            onTap: state.isCameraReady && !state.isCapturing
                ? () async {
                    HapticFeedback.mediumImpact();
                    final quad = state.detectedQuad;
                    final path = await notifier.capturePage();
                    if (path != null && context.mounted) {
                      await ref
                          .read(scanSessionProvider.notifier)
                          .addPage(path, quad: quad);
                      if (context.mounted) {
                        AppPopups.showSnackBar(
                          context: context,
                          message: 'Page ${ref.read(scanSessionProvider).pageCount} captured!',
                        );
                      }
                    }
                  }
                : null,
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
              ),
              padding: const EdgeInsets.all(4),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: state.isCapturing
                      ? Colors.amber
                      : (state.isCameraReady ? Colors.white : Colors.white38),
                ),
                child: state.isCapturing
                    ? const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Colors.black,
                          ),
                        ),
                      )
                    : null,
              ),
            ),
          ),

          // Staged session page action button -> Go to Document Manager Review
          if (session.hasPages || state.hasStagedPages)
            IconButton(
              icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 28),
              tooltip: 'Review Pages',
              onPressed: () {
                context.push(AppRoutes.smartScanManager);
              },
            )
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }
}
