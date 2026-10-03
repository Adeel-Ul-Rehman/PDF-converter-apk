import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flux_convert/core/core.dart';
import 'package:flux_convert/features/smart_scan/data/scan_enhancement_service.dart';
import 'package:flux_convert/features/smart_scan/domain/entities/scan_session.dart';
import 'package:flux_convert/features/smart_scan/domain/entities/scanned_page.dart';
import 'package:flux_convert/features/smart_scan/presentation/controllers/scan_session_notifier.dart';

/// SmartScanPageManagerPage — Multi-page document management, reordering, page preview,
/// enhancement color modes, brightness/contrast adjustments, page retake, and PDF handoff.
class SmartScanPageManagerPage extends ConsumerStatefulWidget {
  const SmartScanPageManagerPage({super.key});

  @override
  ConsumerState<SmartScanPageManagerPage> createState() =>
      _SmartScanPageManagerPageState();
}

class _SmartScanPageManagerPageState
    extends ConsumerState<SmartScanPageManagerPage> {
  final ScanEnhancementService _enhancementService = const ScanEnhancementService();

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(scanSessionProvider);
    final notifier = ref.read(scanSessionProvider.notifier);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (!session.hasPages) {
          Navigator.of(context).pop();
          return;
        }
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Discard Scan Session?'),
            content: const Text('All scanned document pages in this session will be cleared.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Keep Session'),
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
          notifier.clearSession(deleteFiles: true);
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              // ── Header Bar ─────────────────────────────────────────────
              _buildHeader(context, session, notifier),

              // ── Main Body (Large Preview / Empty State) ─────────────────
              Expanded(
                child: session.hasPages
                    ? _buildMainPreviewArea(context, session, notifier)
                    : _buildEmptyState(context),
              ),

              // ── Selected Page Tool Action Bar & Enhancements ─────────────
              if (session.hasPages) ...[
                _buildEnhancementModeSelector(context, session, notifier),
                _buildPageToolsBar(context, session, notifier),
              ],

              // ── Reorderable Thumbnail Strip ─────────────────────────────
              if (session.hasPages)
                _buildThumbnailStrip(context, session, notifier),

              // ── Bottom Action Footer Bar ─────────────────────────────────
              _buildFooterBar(context, session, notifier),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ScanSession session,
    ScanSessionNotifier notifier,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 24),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutes.smartScan);
              }
            },
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Document Review',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (session.hasPages)
                Text(
                  'Page ${session.activePageIndex + 1} of ${session.pageCount}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          if (session.hasPages)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 24),
              tooltip: 'Clear session',
              onPressed: () {
                _showClearConfirmationDialog(context, notifier);
              },
            )
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildMainPreviewArea(
    BuildContext context,
    ScanSession session,
    ScanSessionNotifier notifier,
  ) {
    final page = session.activePage;
    if (page == null) return const SizedBox.shrink();

    final imageFile = File(page.processedPath.isNotEmpty && File(page.processedPath).existsSync()
        ? page.processedPath
        : page.originalPath);

    final filter = _enhancementService.buildColorFilter(
      page.enhancementMode,
      brightness: page.brightness,
      contrast: page.contrast,
    );

    final angleRad = (page.rotation * math.pi) / 180.0;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 60fps Instant Preview with Filter & Transform Rotation
          Transform.rotate(
            angle: angleRad,
            child: ColorFiltered(
              colorFilter: filter,
              child: Image.file(
                imageFile,
                fit: BoxFit.contain,
                key: ValueKey('${page.id}_${page.processedPath}_${page.rotation}'),
                errorBuilder: (ctx, err, stack) => const Center(
                  child: Icon(Icons.broken_image_rounded, color: Colors.white38, size: 48),
                ),
              ),
            ),
          ),

          // Processing Badge Overlay
          if (page.processingStatus == PageProcessingStatus.processing)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColorScheme.primaryBlueStart, width: 1.5),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColorScheme.primaryBlueStart,
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Baking Image...',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

          // Crop Adjustment Overlay Button
          Positioned(
            top: 12,
            right: 12,
            child: Material(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(30),
              child: InkWell(
                borderRadius: BorderRadius.circular(30),
                onTap: () {
                  context.push('${AppRoutes.smartScanCrop}?path=${Uri.encodeComponent(page.originalPath)}');
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.crop_rounded, color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Crop Quadrilateral',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.document_scanner_outlined,
                color: Colors.white70,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Pages in Scan Session',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Capture physical document pages using Smart Scan to begin review.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColorScheme.primaryBlueStart,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.camera_alt_rounded),
              label: const Text('Scan Document'),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(AppRoutes.smartScan);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancementModeSelector(
    BuildContext context,
    ScanSession session,
    ScanSessionNotifier notifier,
  ) {
    final activePage = session.activePage;
    if (activePage == null) return const SizedBox.shrink();

    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: ScanEnhancementMode.values.length,
        itemBuilder: (ctx, index) {
          final mode = ScanEnhancementMode.values[index];
          final isSelected = activePage.enhancementMode == mode;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(mode.displayName),
              selected: isSelected,
              selectedColor: AppColorScheme.primaryBlueStart,
              backgroundColor: Colors.grey[850],
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              onSelected: (selected) {
                if (selected) {
                  HapticFeedback.selectionClick();
                  notifier.updateEnhancement(session.activePageIndex, mode);
                }
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildPageToolsBar(
    BuildContext context,
    ScanSession session,
    ScanSessionNotifier notifier,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildToolButton(
            icon: Icons.tune_rounded,
            label: 'Adjust',
            onTap: () => _showAdjustmentBottomSheet(context, session, notifier),
          ),
          _buildToolButton(
            icon: Icons.rotate_right_rounded,
            label: 'Rotate',
            onTap: () {
              HapticFeedback.lightImpact();
              notifier.rotatePageAt(session.activePageIndex);
            },
          ),
          _buildToolButton(
            icon: Icons.cameraswitch_rounded,
            label: 'Retake',
            onTap: () => _retakePage(context, session, notifier),
          ),
          _buildToolButton(
            icon: Icons.delete_outline_rounded,
            label: 'Delete',
            color: Colors.redAccent,
            onTap: () {
              HapticFeedback.mediumImpact();
              notifier.removePageAt(session.activePageIndex);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.white70,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnailStrip(
    BuildContext context,
    ScanSession session,
    ScanSessionNotifier notifier,
  ) {
    return Container(
      height: 95,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ReorderableListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: session.pages.length,
        onReorder: (oldIdx, newIdx) {
          HapticFeedback.mediumImpact();
          notifier.reorderPages(oldIdx, newIdx);
        },
        itemBuilder: (ctx, index) {
          final page = session.pages[index];
          final isSelected = index == session.activePageIndex;

          final thumbFile = File(page.processedPath.isNotEmpty && File(page.processedPath).existsSync()
              ? page.processedPath
              : page.originalPath);

          return Container(
            key: ValueKey(page.id),
            margin: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                notifier.selectPage(index);
              },
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 55,
                    height: 75,
                    decoration: BoxDecoration(
                      color: Colors.grey[850],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? AppColorScheme.primaryBlueStart
                            : Colors.white24,
                        width: isSelected ? 2.5 : 1,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Transform.rotate(
                      angle: (page.rotation * math.pi) / 180.0,
                      child: Image.file(
                        thumbFile,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => const Icon(
                          Icons.description_rounded,
                          color: Colors.white38,
                          size: 20,
                        ),
                      ),
                    ),
                  ),

                  // Page Index Badge
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFooterBar(
    BuildContext context,
    ScanSession session,
    ScanSessionNotifier notifier,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.black,
      child: Row(
        children: [
          // Add Page Button
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white38),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.add_a_photo_rounded, size: 20),
              label: const Text('Add Page', style: TextStyle(fontWeight: FontWeight.w600)),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(AppRoutes.smartScan);
                }
              },
            ),
          ),
          const SizedBox(width: 12),

          // Create PDF Button
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColorScheme.primaryBlueStart,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.picture_as_pdf_rounded, size: 20),
              label: Text(
                session.hasPages ? 'Create PDF (${session.pageCount})' : 'Create PDF',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: session.hasPages
                  ? () {
                      HapticFeedback.mediumImpact();
                      context.push(AppRoutes.smartScanReview);
                    }
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  void _showAdjustmentBottomSheet(
    BuildContext context,
    ScanSession session,
    ScanSessionNotifier notifier,
  ) {
    final page = session.activePage;
    if (page == null) return;

    var tempBrightness = page.brightness;
    var tempContrast = page.contrast;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColorScheme.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Image Adjustments',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setSheetState(() {
                              tempBrightness = 0.0;
                              tempContrast = 100.0;
                            });
                          },
                          child: const Text(
                            'Reset',
                            style: TextStyle(color: AppColorScheme.primaryBlueStart),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Brightness Slider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Brightness', style: TextStyle(color: Colors.white70)),
                        Text('${tempBrightness.toInt()}', style: const TextStyle(color: Colors.white)),
                      ],
                    ),
                    Slider(
                      value: tempBrightness,
                      min: -100.0,
                      max: 100.0,
                      activeColor: AppColorScheme.primaryBlueStart,
                      onChanged: (val) {
                        setSheetState(() {
                          tempBrightness = val;
                        });
                      },
                    ),

                    const SizedBox(height: 12),

                    // Contrast Slider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Contrast', style: TextStyle(color: Colors.white70)),
                        Text('${tempContrast.toInt()}%', style: const TextStyle(color: Colors.white)),
                      ],
                    ),
                    Slider(
                      value: tempContrast,
                      min: 0.0,
                      max: 200.0,
                      activeColor: AppColorScheme.primaryBlueStart,
                      onChanged: (val) {
                        setSheetState(() {
                          tempContrast = val;
                        });
                      },
                    ),

                    const SizedBox(height: 20),

                    // Apply Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColorScheme.primaryBlueStart,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          notifier.updateAdjustments(
                            session.activePageIndex,
                            brightness: tempBrightness,
                            contrast: tempContrast,
                          );
                          Navigator.of(ctx).pop();
                        },
                        child: const Text('Apply Adjustments', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _retakePage(
    BuildContext context,
    ScanSession session,
    ScanSessionNotifier notifier,
  ) {
    if (!session.hasPages) return;
    // Return to Smart Scan camera to replace selected page
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.smartScan);
    }
  }

  void _showClearConfirmationDialog(
    BuildContext context,
    ScanSessionNotifier notifier,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColorScheme.cardDark,
        title: const Text('Clear Scan Session?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'All staged document pages and edits will be permanently deleted.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.of(ctx).pop();
              notifier.clearSession();
            },
            child: const Text('Clear All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
