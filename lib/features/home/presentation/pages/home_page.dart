import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import 'package:flux_convert/core/core.dart';
import 'package:flux_convert/features/converter/presentation/providers/converter_providers.dart';
import 'package:flux_convert/features/history/domain/entities/conversion_history.dart';
import 'package:flux_convert/features/history/presentation/providers/history_providers.dart';
import 'package:flux_convert/features/storage/presentation/storage_manager.dart';

// FIXED: Clean Modern Home Page matching exact user screenshot
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(richHistoryNotifierProvider.notifier).loadAllHistory();
      ref.read(richHistoryNotifierProvider.notifier).refreshStats();
      ref.read(storageManagerProvider).runTempCleanup();
    });
  }

  Future<void> _showExitConfirmationDialog(BuildContext context) async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Exit App?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to close the app?',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColorScheme.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Exit'),
          ),
        ],
      ),
    );

    if (shouldExit == true) {
      SystemNavigator.pop();
    }
  }

  void _showComingSoonSnackBar(String featureName) {
    AppPopups.showSnackBar(
      context: context,
      message: '$featureName is coming soon in a future update!',
    );
  }

  Future<void> _handleQuickAction(String actionLabel) async {
    final notifier = ref.read(converterNotifierProvider.notifier);
    HapticFeedback.lightImpact();

    switch (actionLabel) {
      case 'Image to PDF':
        context.push(AppRoutes.imageSelection);

      case 'Smart Scan':
        context.push(AppRoutes.smartScan);

      case 'Import PDF':
        await notifier.selectFile(allowedExtensions: ['pdf']);
        final state = ref.read(converterNotifierProvider);
        if (state.selectedFilePath != null && mounted) {
          context.push(
            '${AppRoutes.pdfViewer}?path=${Uri.encodeComponent(state.selectedFilePath!)}',
          );
        }

      case 'Compress':
        context.push(AppRoutes.compressPdf);

      case 'More':
        context.push(AppRoutes.allTools);

      default:
        _showComingSoonSnackBar(actionLabel);
    }
  }

  @override
  Widget build(BuildContext context) {
    final historyState = ref.watch(richHistoryNotifierProvider);
    final allFiles = historyState.historyList;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? AppColorScheme.backgroundDark : AppColorScheme.backgroundLight;
    final cardBgColor = isDark ? AppColorScheme.cardDark : AppColorScheme.cardLight;
    final textPrimaryColor = isDark ? AppColorScheme.textPrimaryDark : AppColorScheme.textPrimaryLight;
    final textSecondaryColor = isDark ? AppColorScheme.textSecondaryDark : AppColorScheme.textSecondaryLight;
    final gridCircleBgColor = isDark ? const Color(0xFF1E2638) : const Color(0xFFE3F2FD);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _showExitConfirmationDialog(context);
      },
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: bgColor,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Text(
            'Home',
            style: TextStyle(
              color: textPrimaryColor,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.search_rounded, color: textPrimaryColor, size: 24),
              onPressed: () => context.push(AppRoutes.history),
              tooltip: 'Search files',
            ),
            IconButton(
              icon: Icon(Icons.settings_outlined, color: textPrimaryColor, size: 24),
              onPressed: () => context.push(AppRoutes.settings),
              tooltip: 'Settings',
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            await ref.read(richHistoryNotifierProvider.notifier).loadAllHistory();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // FIXED: Quick Actions Grid matching Screenshot (2 rows of 4 circular tiles)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      // Row 1
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildGridItem(
                            label: 'Image to PDF',
                            iconWidget: const Icon(Icons.picture_as_pdf_rounded, color: AppColorScheme.primaryBlueStart, size: 24),
                            circleBgColor: gridCircleBgColor,
                            onTap: () => _handleQuickAction('Image to PDF'),
                          ),
                          _buildGridItem(
                            label: 'Smart Scan',
                            iconWidget: const Icon(Icons.document_scanner_rounded, color: AppColorScheme.primaryBlueStart, size: 24),
                            circleBgColor: gridCircleBgColor,
                            onTap: () => _handleQuickAction('Smart Scan'),
                          ),
                          _buildGridItem(
                            label: 'Import PDF',
                            iconWidget: const Icon(Icons.folder_rounded, color: AppColorScheme.primaryBlueStart, size: 24),
                            circleBgColor: gridCircleBgColor,
                            onTap: () => _handleQuickAction('Import PDF'),
                          ),
                          _buildGridItem(
                            label: 'Compress',
                            iconWidget: const Icon(Icons.compress_rounded, color: AppColorScheme.primaryBlueStart, size: 24),
                            circleBgColor: gridCircleBgColor,
                            onTap: () => _handleQuickAction('Compress'),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Row 2
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildGridItem(
                            label: 'PDF to JPG',
                            iconWidget: const Icon(Icons.image_outlined, color: AppColorScheme.primaryBlueStart, size: 24),
                            circleBgColor: gridCircleBgColor,
                            onTap: () => _handleQuickAction('PDF to JPG'),
                          ),
                          _buildGridItem(
                            label: 'Merge PDF',
                            iconWidget: const Icon(Icons.merge_type_rounded, color: AppColorScheme.primaryBlueStart, size: 24),
                            circleBgColor: gridCircleBgColor,
                            onTap: () => _handleQuickAction('Merge PDF'),
                          ),
                          _buildGridItem(
                            label: 'Docx to PDF',
                            iconWidget: const Icon(Icons.description_rounded, color: AppColorScheme.primaryBlueStart, size: 24),
                            circleBgColor: gridCircleBgColor,
                            onTap: () => _handleQuickAction('Docx to PDF'),
                          ),
                          _buildGridItem(
                            label: 'More',
                            iconWidget: const Icon(Icons.grid_view_rounded, color: AppColorScheme.primaryBlueStart, size: 24),
                            circleBgColor: gridCircleBgColor,
                            onTap: () => _handleQuickAction('More'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // FIXED: Container Card for Recent Files matching user screenshot
                Container(
                  decoration: BoxDecoration(
                    color: cardBgColor,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(isDark ? 30 : 10),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Header Row (All files count + select/sort icons)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                'All',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimaryColor,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '(${allFiles.length})',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: textSecondaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.fact_check_outlined, color: textPrimaryColor, size: 22),
                                onPressed: () => context.push(AppRoutes.history),
                              ),
                              IconButton(
                                icon: Icon(Icons.filter_list_rounded, color: textPrimaryColor, size: 22),
                                onPressed: () => context.push(AppRoutes.history),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      if (allFiles.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Column(
                            children: [
                              Icon(Icons.folder_open_rounded, size: 56, color: Colors.grey),
                              SizedBox(height: 12),
                              Text(
                                'No converted files yet.',
                                style: TextStyle(color: Colors.grey, fontSize: 14),
                              ),
                            ],
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: allFiles.length,
                          separatorBuilder: (ctx, i) => const Divider(height: 16, color: Color(0xFFF0F0F0)),
                          itemBuilder: (context, index) {
                            final fileRecord = allFiles[index];
                            final fileExists = File(fileRecord.destinationFilePath).existsSync();

                            return InkWell(
                              onTap: () {
                                if (fileExists && fileRecord.destinationFormat.toLowerCase() == 'pdf') {
                                  context.push(
                                    '${AppRoutes.pdfViewer}?path=${Uri.encodeComponent(fileRecord.destinationFilePath)}',
                                  );
                                } else if (fileExists) {
                                  ref.read(storageManagerProvider).openFile(fileRecord.destinationFilePath);
                                }
                              },
                              child: Row(
                                children: [
                                  // File Thumbnail Preview with PDF badge
                                  Container(
                                    width: 56,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF0F2F5),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        const Icon(
                                          Icons.insert_drive_file_rounded,
                                          color: Colors.redAccent,
                                          size: 32,
                                        ),
                                        Positioned(
                                          top: 4,
                                          right: 4,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade700,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              fileRecord.destinationFormat.toUpperCase(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 8,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(width: 12),

                                  // File Metadata
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          fileRecord.destinationFileName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: textPrimaryColor,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: isDark ? const Color(0xFF2E3445) : Colors.grey.shade300,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                '1',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: textPrimaryColor,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              DateFormatter.formatShortDate(fileRecord.completedDate),
                                              style: TextStyle(fontSize: 12, color: textSecondaryColor),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '${(fileRecord.convertedFileSize / 1024).round()} kB',
                                              style: TextStyle(fontSize: 12, color: textSecondaryColor),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Actions: Share & 3 Dots Menu
                                  IconButton(
                                    icon: const Icon(Icons.share_outlined, color: Colors.grey, size: 20),
                                    onPressed: () {
                                      if (fileExists) {
                                        Share.shareXFiles([XFile(fileRecord.destinationFilePath)]);
                                      }
                                    },
                                  ),

                                  IconButton(
                                    icon: const Icon(Icons.more_vert_rounded, color: Colors.grey, size: 20),
                                    onPressed: () => _showFileOptionsBottomSheet(context, fileRecord),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGridItem({
    required String label,
    required Widget iconWidget,
    required Color circleBgColor,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 72,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: circleBgColor,
                shape: BoxShape.circle,
              ),
              child: Center(child: iconWidget),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFileOptionsBottomSheet(BuildContext context, ConversionHistory fileRecord) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.open_in_new_rounded),
            title: const Text('Open File'),
            onTap: () {
              Navigator.pop(ctx);
              context.push(
                '${AppRoutes.pdfViewer}?path=${Uri.encodeComponent(fileRecord.destinationFilePath)}',
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.share_outlined),
            title: const Text('Share File'),
            onTap: () {
              Navigator.pop(ctx);
              Share.shareXFiles([XFile(fileRecord.destinationFilePath)]);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline_rounded, color: AppColorScheme.danger),
            title: const Text('Delete File', style: TextStyle(color: AppColorScheme.danger)),
            onTap: () async {
              Navigator.pop(ctx);
              final confirm = await AppPopups.showConfirmationDialog(
                context: context,
                title: 'Delete File',
                message: 'Are you sure you want to delete "${fileRecord.destinationFileName}"?',
                confirmLabel: 'Delete',
              );
              if (confirm == true) {
                ref.read(richHistoryNotifierProvider.notifier).deleteItem(fileRecord.id);
              }
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
