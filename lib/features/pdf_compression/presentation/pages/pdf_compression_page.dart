import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import 'package:flux_convert/core/core.dart';
import 'package:flux_convert/features/pdf_compression/domain/entities/pdf_compression_config.dart';
import 'package:flux_convert/features/pdf_compression/presentation/providers/pdf_compression_notifier.dart';

/// Production PDF Compressor Page for FluxConvert.
class PdfCompressionPage extends ConsumerWidget {
  const PdfCompressionPage({super.key});

  Future<void> _pickPdfFile(BuildContext context, WidgetRef ref) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        await ref.read(pdfCompressionProvider.notifier).selectFile(path);
      }
    } catch (e) {
      if (context.mounted) {
        AppPopups.showSnackBar(
          context: context,
          message: 'Failed to select PDF file: $e',
          isError: true,
        );
      }
    }
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes >= 1024 * 1024) {
      final mb = bytes / (1024 * 1024);
      return '${mb.toStringAsFixed(1)} MB';
    }
    final kb = bytes / 1024;
    return '${kb.toStringAsFixed(0)} KB';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pdfCompressionProvider);
    final notifier = ref.read(pdfCompressionProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: !state.isCompressing,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (state.isCompressing) {
          AppPopups.showSnackBar(
            context: context,
            message: 'PDF compression is in progress. Please wait for completion.',
            isError: true,
          );
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? AppColorScheme.backgroundDark : AppColorScheme.backgroundLight,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: state.isCompressing ? null : () => context.pop(),
          ),
          title: const Text(
            'Compress PDF',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          actions: [
            if (state.hasFile && !state.isCompressing)
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () => notifier.clearSelection(),
                tooltip: 'Select Another PDF',
              ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── 1. File Selection / Metadata Header ────────────────────
                if (!state.hasFile)
                  _buildEmptySelectionCard(context, ref, isDark)
                else
                  _buildPdfInfoCard(context, state, notifier, isDark),

                const SizedBox(height: 20),

                // ── 2. Error Message Display ───────────────────────────────
                if (state.errorMessage != null) ...[
                  _buildErrorMessageCard(context, state.errorMessage!, isDark),
                  const SizedBox(height: 20),
                ],

                // ── 3. Active Compression View ──────────────────────────────
                if (state.isCompressing) ...[
                  _buildProgressCard(context, state, isDark),
                ] else if (state.isCompleted && state.result != null) ...[
                  _buildResultCard(context, state.result!, notifier, isDark),
                ] else if (state.hasFile) ...[
                  // ── 4. Compression Mode Selector Cards ───────────────────
                  const Text(
                    'Select Compression Level',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ...PdfCompressionLevel.values.map(
                    (lvl) => _buildLevelCard(context, lvl, state, notifier, isDark),
                  ),
                  const SizedBox(height: 24),

                  // ── 5. Compress Action CTA ─────────────────────────────────
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColorScheme.primaryBlueStart,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 2,
                    ),
                    icon: const Icon(Icons.compress_rounded),
                    label: Text(
                      'Compress PDF (${state.level.displayName})',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      notifier.compressPdf();
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptySelectionCard(BuildContext context, WidgetRef ref, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColorScheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColorScheme.primaryBlueStart.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.picture_as_pdf_rounded,
              color: AppColorScheme.primaryBlueStart,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Select a PDF Document',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose a PDF file from your device storage to optimize stream size and embedded media.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColorScheme.primaryBlueStart,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.folder_open_rounded),
            label: const Text('Browse Files', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () => _pickPdfFile(context, ref),
          ),
        ],
      ),
    );
  }

  Widget _buildPdfInfoCard(
    BuildContext context,
    PdfCompressionState state,
    PdfCompressionNotifier notifier,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColorScheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColorScheme.primaryBlueStart.withAlpha(60), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColorScheme.primaryBlueStart.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.picture_as_pdf_rounded,
              color: AppColorScheme.primaryBlueStart,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.fileName ?? 'document.pdf',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      _formatBytes(state.originalSizeBytes),
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black87,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (state.pageCount > 0) ...[
                      const Text(' • ', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColorScheme.primaryBlueStart.withAlpha(20),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${state.pageCount} Pages',
                          style: const TextStyle(
                            color: AppColorScheme.primaryBlueStart,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelCard(
    BuildContext context,
    PdfCompressionLevel level,
    PdfCompressionState state,
    PdfCompressionNotifier notifier,
    bool isDark,
  ) {
    final isSelected = state.level == level;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          notifier.setCompressionLevel(level);
        },
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColorScheme.primaryBlueStart.withAlpha(isDark ? 30 : 15)
                : (isDark ? AppColorScheme.cardDark : Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? AppColorScheme.primaryBlueStart
                  : (isDark ? Colors.white12 : Colors.black12),
              width: isSelected ? 2.0 : 1.0,
            ),
          ),
          child: Row(
            children: [
              // Radio Circle
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? AppColorScheme.primaryBlueStart : Colors.grey,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Center(
                        child: Container(
                          width: 11,
                          height: 11,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColorScheme.primaryBlueStart,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 14),

              // Title & Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          level.displayName,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            color: isSelected
                                ? AppColorScheme.primaryBlueStart
                                : (isDark ? Colors.white : Colors.black87),
                          ),
                        ),
                        if (level == PdfCompressionLevel.medium) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColorScheme.primaryBlueStart.withAlpha(30),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Recommended',
                              style: TextStyle(
                                color: AppColorScheme.primaryBlueStart,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      level.subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressCard(BuildContext context, PdfCompressionState state, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColorScheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColorScheme.primaryBlueStart.withAlpha(60)),
      ),
      child: Column(
        children: [
          const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3.5,
              color: AppColorScheme.primaryBlueStart,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            state.statusMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: state.progress,
              backgroundColor: isDark ? Colors.white12 : Colors.grey[200],
              color: AppColorScheme.primaryBlueStart,
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(
    BuildContext context,
    PdfCompressionResult result,
    PdfCompressionNotifier notifier,
    bool isDark,
  ) {
    final origText = _formatBytes(result.originalSizeBytes);
    final compText = _formatBytes(result.compressedSizeBytes);
    final savedText = _formatBytes(result.savedBytes);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColorScheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.greenAccent.withAlpha(80), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Compression Completed!',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Size Stats Row
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.black26 : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text('Original Size', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(
                          origText,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.lineThrough,
                            color: Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                    const Icon(Icons.arrow_forward_rounded, color: AppColorScheme.primaryBlueStart),
                    Column(
                      children: [
                        const Text('Compressed', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(
                          compText,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (result.isOriginalRetained)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.withAlpha(80)),
                    ),
                    child: const Text(
                      'This PDF was already highly optimized. The original file has been preserved as the best result.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withAlpha(25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Saved $savedText (${result.percentageSaved.toStringAsFixed(1)}% smaller)',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Action CTAs
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColorScheme.primaryBlueStart,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.visibility_rounded),
            label: const Text('Open PDF Document', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () {
              context.push(AppRoutes.pdfViewer, extra: result.destinationPath);
            },
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColorScheme.primaryBlueStart,
              side: const BorderSide(color: AppColorScheme.primaryBlueStart),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.share_rounded),
            label: const Text('Share PDF', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () {
              Share.shareXFiles([XFile(result.destinationPath)]);
            },
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => notifier.clearSelection(),
            child: const Text('Compress Another PDF'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessageCard(BuildContext context, String message, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.redAccent.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withAlpha(80)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.redAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
