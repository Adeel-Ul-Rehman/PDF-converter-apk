import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import 'package:flux_convert/core/logging/logger_service.dart';
import 'package:flux_convert/core/routing/app_routes.dart';
import 'package:flux_convert/core/utils/file_type_detector.dart';
import 'package:flux_convert/features/converter/domain/entities/conversion_format.dart';
import 'package:flux_convert/features/converter/presentation/providers/converter_providers.dart';
import 'package:flux_convert/features/smart_scan/data/scan_enhancement_service.dart';
import 'package:flux_convert/features/smart_scan/domain/entities/document_quadrilateral.dart';
import 'package:flux_convert/features/smart_scan/domain/entities/scan_session.dart';
import 'package:flux_convert/features/smart_scan/domain/entities/scanned_page.dart';
import 'package:flux_convert/features/storage/data/services/directory_manager.dart';

/// Provider for [ScanSessionNotifier].
final scanSessionProvider =
    StateNotifierProvider.autoDispose<ScanSessionNotifier, ScanSession>(
  (ref) => ScanSessionNotifier(
    enhancementService: const ScanEnhancementService(),
    directoryManager: DirectoryManager(),
    ref: ref,
  ),
);

/// Riverpod state controller driving multi-page scan session management,
/// editing, page reordering, retaking, and background enhancement baking.
class ScanSessionNotifier extends StateNotifier<ScanSession> {
  ScanSessionNotifier({
    required ScanEnhancementService enhancementService,
    required DirectoryManager directoryManager,
    required Ref ref,
  })  : _enhancementService = enhancementService,
        _directoryManager = directoryManager,
        _ref = ref,
        super(ScanSession(sessionId: const Uuid().v4()));

  final ScanEnhancementService _enhancementService;
  final DirectoryManager _directoryManager;
  final Ref _ref;

  /// Adds a newly captured camera photo to the multi-page session.
  Future<String?> addPage(
    String originalPath, {
    DocumentQuadrilateral? quad,
  }) async {
    final config = await _directoryManager.ensureAll();
    final scansDir = Directory(config.scansTempPath);
    if (!scansDir.existsSync()) {
      scansDir.createSync(recursive: true);
    }

    final pageId = const Uuid().v4();
    final timeStamp = DateTime.now().millisecondsSinceEpoch;
    final processedPath = '${config.scansTempPath}/proc_${pageId}_$timeStamp.jpg';

    final page = ScannedPage(
      id: pageId,
      originalPath: originalPath,
      processedPath: processedPath,
      creationOrder: state.pageCount + 1,
      quadrilateral: quad,
      processingStatus: PageProcessingStatus.processing,
    );

    final updatedPages = List<ScannedPage>.from(state.pages)..add(page);
    final newActiveIndex = updatedPages.length - 1;

    state = state.copyWith(
      pages: updatedPages,
      activePageIndex: newActiveIndex,
      isProcessing: true,
    );

    AppLogger.info('ScanSessionNotifier: Added page ${page.id} to session');

    // Trigger background isolate enhancement processing
    await _processPageAtIndex(newActiveIndex);
    return processedPath;
  }

  /// Removes a page at [index] and safely deletes its temporary files.
  void removePageAt(int index) {
    if (index < 0 || index >= state.pages.length) return;

    final targetPage = state.pages[index];

    // Delete temp files safely
    _deleteFile(targetPage.processedPath);
    if (targetPage.originalPath != targetPage.processedPath) {
      _deleteFile(targetPage.originalPath);
    }

    final updatedPages = List<ScannedPage>.from(state.pages)..removeAt(index);
    final newActiveIndex = updatedPages.isEmpty
        ? 0
        : (index >= updatedPages.length ? updatedPages.length - 1 : index);

    state = state.copyWith(
      pages: updatedPages,
      activePageIndex: newActiveIndex,
    );

    AppLogger.info('ScanSessionNotifier: Removed page at index $index');
  }

  /// Reorders pages from [oldIndex] to [newIndex].
  void reorderPages(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= state.pages.length) return;
    var targetNewIndex = newIndex;
    if (oldIndex < targetNewIndex) {
      targetNewIndex -= 1;
    }

    final updatedPages = List<ScannedPage>.from(state.pages);
    final movedPage = updatedPages.removeAt(oldIndex);
    updatedPages.insert(targetNewIndex, movedPage);

    // Keep active page selection aligned
    int newActiveIndex = state.activePageIndex;
    if (state.activePageIndex == oldIndex) {
      newActiveIndex = targetNewIndex;
    } else if (oldIndex < state.activePageIndex && targetNewIndex >= state.activePageIndex) {
      newActiveIndex -= 1;
    } else if (oldIndex > state.activePageIndex && targetNewIndex <= state.activePageIndex) {
      newActiveIndex += 1;
    }

    state = state.copyWith(
      pages: updatedPages,
      activePageIndex: newActiveIndex,
    );

    AppLogger.info('ScanSessionNotifier: Reordered page from $oldIndex to $targetNewIndex');
  }

  /// Rotates page at [index] 90 degrees clockwise.
  Future<void> rotatePageAt(int index) async {
    if (index < 0 || index >= state.pages.length) return;

    final page = state.pages[index];
    final nextRotation = (page.rotation + 90) % 360;

    final updatedPage = page.copyWith(
      rotation: nextRotation,
      processingStatus: PageProcessingStatus.processing,
    );

    _updatePageInState(index, updatedPage);
    await _processPageAtIndex(index);
  }

  /// Updates enhancement color mode for page at [index].
  Future<void> updateEnhancement(int index, ScanEnhancementMode mode) async {
    if (index < 0 || index >= state.pages.length) return;

    final page = state.pages[index];
    if (page.enhancementMode == mode) return;

    final updatedPage = page.copyWith(
      enhancementMode: mode,
      processingStatus: PageProcessingStatus.processing,
    );

    _updatePageInState(index, updatedPage);
    await _processPageAtIndex(index);
  }

  /// Updates brightness and contrast adjustments for page at [index].
  Future<void> updateAdjustments(
    int index, {
    double? brightness,
    double? contrast,
  }) async {
    if (index < 0 || index >= state.pages.length) return;

    final page = state.pages[index];
    final updatedPage = page.copyWith(
      brightness: brightness ?? page.brightness,
      contrast: contrast ?? page.contrast,
      processingStatus: PageProcessingStatus.processing,
    );

    _updatePageInState(index, updatedPage);
    await _processPageAtIndex(index);
  }

  /// Retakes/replaces the image for page at [index] while preserving its position.
  Future<void> retakePageAt(
    int index,
    String newOriginalPath, {
    DocumentQuadrilateral? quad,
  }) async {
    if (index < 0 || index >= state.pages.length) return;

    final oldPage = state.pages[index];
    _deleteFile(oldPage.processedPath);
    if (oldPage.originalPath != oldPage.processedPath) {
      _deleteFile(oldPage.originalPath);
    }

    final updatedPage = oldPage.copyWith(
      originalPath: newOriginalPath,
      quadrilateral: quad,
      clearQuadrilateral: quad == null,
      processingStatus: PageProcessingStatus.processing,
    );

    _updatePageInState(index, updatedPage);
    await _processPageAtIndex(index);
  }

  /// Selects page at [index] for large preview display.
  void selectPage(int index) {
    if (index < 0 || index >= state.pages.length) return;
    state = state.copyWith(activePageIndex: index);
  }

  /// Clears all pages in session and deletes associated temporary scan files.
  void clearSession({bool deleteFiles = true}) {
    if (deleteFiles) {
      for (final page in state.pages) {
        _deleteFile(page.processedPath);
        if (page.originalPath != page.processedPath) {
          _deleteFile(page.originalPath);
        }
      }
    }

    state = ScanSession(sessionId: const Uuid().v4());
    AppLogger.info('ScanSessionNotifier: Session cleared');
  }

  /// Runs background isolate image processing for page at [index].
  Future<void> _processPageAtIndex(int index) async {
    if (index < 0 || index >= state.pages.length) return;

    final page = state.pages[index];

    try {
      final params = ScanEnhancementParams(
        sourcePath: page.originalPath,
        outputPath: page.processedPath,
        quadrilateral: page.quadrilateral,
        rotation: page.rotation,
        enhancementMode: page.enhancementMode,
        brightness: page.brightness,
        contrast: page.contrast,
      );

      final bakedPath = await _enhancementService.processImageInIsolate(params);

      if (mounted) {
        final completedPage = page.copyWith(
          processedPath: bakedPath,
          processingStatus: PageProcessingStatus.completed,
        );
        _updatePageInState(index, completedPage);
      }
    } catch (e, stack) {
      AppLogger.error('ScanSessionNotifier: Failed to process page at index $index', e, stack);
      if (mounted) {
        final failedPage = page.copyWith(
          processingStatus: PageProcessingStatus.failed,
        );
        _updatePageInState(index, failedPage);
      }
    } finally {
      if (mounted) {
        final anyProcessing = state.pages.any((p) => p.processingStatus == PageProcessingStatus.processing);
        state = state.copyWith(isProcessing: anyProcessing);
      }
    }
  }

  void _updatePageInState(int index, ScannedPage updatedPage) {
    if (index < 0 || index >= state.pages.length) return;
    final updatedList = List<ScannedPage>.from(state.pages);
    updatedList[index] = updatedPage;
    state = state.copyWith(pages: updatedList);
  }

  void _deleteFile(String path) {
    try {
      final file = File(path);
      if (file.existsSync()) {
        file.deleteSync();
      }
    } catch (e) {
      AppLogger.warning('ScanSessionNotifier: Failed to delete temp file at $path', e);
    }
  }

  /// Compiles final ordered scan session pages and opens FluxConvert's PDF creation flow.
  Future<void> compileAndConvertToPdf(BuildContext context) async {
    if (state.pages.isEmpty) return;

    // Ensure all background processing completes
    final pendingIndices = <int>[];
    for (var i = 0; i < state.pages.length; i++) {
      if (state.pages[i].processingStatus == PageProcessingStatus.processing) {
        pendingIndices.add(i);
      }
    }
    if (pendingIndices.isNotEmpty) {
      await Future.wait(pendingIndices.map((idx) => _processPageAtIndex(idx)));
    }

    final finalPaths = state.pages.map((p) => p.processedPath).toList();
    if (finalPaths.isEmpty) return;

    final firstPath = finalPaths.first;
    final firstFile = File(firstPath);
    final fileSize = firstFile.existsSync() ? firstFile.lengthSync() : 0;

    final converterNotifier = _ref.read(converterNotifierProvider.notifier);
    converterNotifier.setFile(
      firstPath,
      'scanned_document.pdf',
      fileSize,
      FileCategory.image,
      ConversionFormat.jpg,
      additionalPaths: finalPaths.sublist(1),
      additionalNames: List.generate(
        finalPaths.length - 1,
        (i) => 'page_${i + 2}.jpg',
      ),
    );

    AppLogger.info('ScanSessionNotifier: Handed off ${finalPaths.length} pages to PDF converter');

    if (context.mounted) {
      context.push(AppRoutes.imagePreview);
    }
  }
}
