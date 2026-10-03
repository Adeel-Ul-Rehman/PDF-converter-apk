import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

import 'package:flux_convert/core/core.dart';
import 'package:flux_convert/features/converter/domain/entities/conversion_format.dart';
import 'package:flux_convert/features/converter/presentation/providers/converter_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flux_convert/features/storage/presentation/providers/storage_providers.dart';
import 'package:flux_convert/features/storage/data/repositories/storage_repository_impl.dart';

// FIXED: Screen 4 — Conversion Success Page matching exact UI layout from user screenshot 2
class ConversionSuccessPage extends ConsumerStatefulWidget {
  const ConversionSuccessPage({super.key});

  @override
  ConsumerState<ConversionSuccessPage> createState() => _ConversionSuccessPageState();
}

class _ConversionSuccessPageState extends ConsumerState<ConversionSuccessPage> {
  String _currentCompletedPath = '';
  bool _isPathInitialized = false;
  bool _showFeedbackCard = true;
  double _swipeDelta = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      HapticFeedback.heavyImpact();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isPathInitialized) {
      final state = ref.read(converterNotifierProvider);
      _currentCompletedPath = state.completedDestinationPath ?? '';
      _isPathInitialized = true;
    }
  }

  Future<void> _changeSaveLocation() async {
    try {
      final selectedDirectory = await FilePicker.platform.getDirectoryPath();
      if (selectedDirectory != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('custom_save_location', selectedDirectory);

        ref.read(directoryManagerProvider).clearCache();

        final repo = ref.read(storageRepositoryProvider);
        if (repo is StorageRepositoryImpl) {
          repo.clearCache();
        }

        await ref.read(storageNotifierProvider.notifier).initialise();

        final currentFile = File(_currentCompletedPath);
        if (currentFile.existsSync()) {
          final fileName = _currentCompletedPath.split('/').last.split(r'\').last;
          final newFilePath = '$selectedDirectory/$fileName';
          await currentFile.copy(newFilePath);
          await currentFile.delete();

          setState(() {
            _currentCompletedPath = newFilePath;
          });
          ref.read(converterNotifierProvider.notifier).setCompletedDestinationPath(newFilePath);
        }

        if (mounted) {
          AppPopups.showSnackBar(
            context: context,
            message: 'Save location updated! File moved to new folder.',
          );
        }
      }
    } catch (e) {
      AppLogger.error('Failed to change save location', e);
      if (mounted) {
        AppPopups.showSnackBar(
          context: context,
          message: 'Failed to update save location.',
          isError: true,
        );
      }
    }
  }

  Future<void> _shareFile(String path) async {
    try {
      final file = File(path);
      if (file.existsSync()) {
        await Share.shareXFiles([XFile(path)], text: 'Check out my converted PDF file!');
      } else {
        if (!mounted) return;
        AppPopups.showSnackBar(
          context: context,
          message: 'Output file could not be found.',
          isError: true,
        );
      }
    } catch (e) {
      if (!mounted) return;
      AppPopups.showSnackBar(
        context: context,
        message: 'Share error: $e',
        isError: true,
      );
    }
  }

  Future<void> _openFile(String path) async {
    try {
      final file = File(path);
      if (file.existsSync()) {
        if (path.toLowerCase().endsWith('.pdf')) {
          if (mounted) {
            context.push('${AppRoutes.pdfViewer}?path=${Uri.encodeComponent(path)}');
          }
        } else {
          await OpenFilex.open(path);
        }
      } else {
        if (!mounted) return;
        AppPopups.showSnackBar(
          context: context,
          message: 'Output file could not be found.',
          isError: true,
        );
      }
    } catch (e) {
      if (!mounted) return;
      AppPopups.showSnackBar(
        context: context,
        message: 'Failed to open file: $e',
        isError: true,
      );
    }
  }

  void _copyLocationToClipboard(String path) {
    final parentDir = File(path).parent.path;
    Clipboard.setData(ClipboardData(text: parentDir));
    AppPopups.showSnackBar(
      context: context,
      message: 'Save location path copied to clipboard!',
    );
  }

  Future<void> _showRenameCompletedDialog(String currentPath) async {
    final state = ref.read(converterNotifierProvider);
    final file = File(currentPath);
    if (!file.existsSync()) return;

    final currentFilename = file.path.split('/').last.split(r'\').last;
    final cleanName = currentFilename.replaceAll(RegExp(r'\.[^.]+$'), '');
    final controller = TextEditingController(text: cleanName);

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Saved PDF'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter new filename',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColorScheme.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                final newName = controller.text.trim();
                final finalPdfName = newName.endsWith('.pdf') ? newName : '$newName.pdf';
                final parentDir = file.parent.path;
                final newPath = '$parentDir/$finalPdfName';

                try {
                  await file.rename(newPath);
                  
                  if (!mounted) return;
                  
                  final notifier = ref.read(converterNotifierProvider.notifier);
                  notifier.setFile(
                    state.selectedFilePath!,
                    finalPdfName,
                    state.selectedFileSize ?? 0,
                    state.selectedFileCategory ?? FileCategory.image,
                    state.selectedInputFormat ?? ConversionFormat.png,
                    additionalPaths: state.additionalSelectedFilePaths,
                    additionalNames: state.additionalSelectedFileNames,
                  );
                  notifier.setCompletedDestinationPath(newPath);
                  setState(() {
                    _currentCompletedPath = newPath;
                  });

                  if (!context.mounted) return;
                  AppPopups.showSnackBar(
                    context: context,
                    message: 'File renamed successfully!',
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  AppPopups.showSnackBar(
                    context: context,
                    message: 'Rename failed: $e',
                    isError: true,
                  );
                }
              }
              if (!context.mounted) return;
              Navigator.pop(context);
            },
            child: const Text('Save', style: TextStyle(color: AppColorScheme.primaryBlueStart, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _stageAndNavigate(String routePath) {
    final state = ref.read(converterNotifierProvider);
    final path = _currentCompletedPath.isNotEmpty ? _currentCompletedPath : state.completedDestinationPath;
    if (path == null || path.isEmpty) return;

    final file = File(path);
    final size = file.existsSync() ? file.lengthSync() : 1024;
    final name = file.path.split('/').last.split(r'\').last;

    final notifier = ref.read(converterNotifierProvider.notifier);
    notifier.setFile(
      file.path,
      name,
      size,
      FileCategory.document,
      ConversionFormat.pdf,
    );

    context.push(routePath);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(converterNotifierProvider);
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final filename = _currentCompletedPath.split('/').last.split(r'\').last;
    final pagesCount = state.additionalSelectedFilePaths.length;
    final firstImagePath = state.additionalSelectedFilePaths.isNotEmpty 
        ? state.additionalSelectedFilePaths.first 
        : null;

    final displayPath = _currentCompletedPath.isNotEmpty
        ? Directory(_currentCompletedPath).parent.path
        : '/Internal Storage/Documents/Image to PDF Converter';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        ref.read(converterNotifierProvider.notifier).clearSelection();
        context.go('/');
      },
      child: Scaffold(
        backgroundColor: isDarkMode ? theme.colorScheme.background : AppColorScheme.background,
        body: GestureDetector(
          onVerticalDragUpdate: (details) {
            if (details.delta.dy > 0) {
              _swipeDelta += details.delta.dy;
            }
          },
          onVerticalDragEnd: (details) {
            if (_swipeDelta > 80) {
              HapticFeedback.mediumImpact();
              ref.read(converterNotifierProvider.notifier).clearSelection();
              context.go('/');
            }
            _swipeDelta = 0.0;
          },
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // FIXED: Top Success Notification Card matching screenshot 2
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey.shade900 : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(15),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: AppColorScheme.primaryBlueStart,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Converted to PDF successfully!',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Thumbnail Card with Page Count Badge
                  Center(
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(20),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (firstImagePath != null && File(firstImagePath).existsSync())
                            Image.file(
                              File(firstImagePath),
                              fit: BoxFit.cover,
                            )
                          else
                            ColoredBox(
                              color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
                              child: const Icon(Icons.picture_as_pdf, size: 50, color: AppColorScheme.primaryBlueStart),
                            ),
                          
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$pagesCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Filename with Pencil Edit button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          filename,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.grey),
                        onPressed: () => _showRenameCompletedDialog(_currentCompletedPath),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Location Link Line matching screenshot 2
                  Center(
                    child: GestureDetector(
                      onTap: _changeSaveLocation,
                      onLongPress: () => _copyLocationToClipboard(_currentCompletedPath),
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkMode ? Colors.white70 : AppColorScheme.textSecondary,
                          ),
                          children: [
                            const TextSpan(text: 'Location: '),
                            TextSpan(
                              text: displayPath,
                              style: const TextStyle(
                                color: AppColorScheme.primaryBlueStart,
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // SHARE primary solid button matching screenshot 2
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColorScheme.primaryBlueStart,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 2,
                    ),
                    onPressed: () => _shareFile(_currentCompletedPath),
                    child: const Text(
                      'SHARE',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // OPEN primary outline button matching screenshot 2
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColorScheme.primaryBlueStart, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: () => _openFile(_currentCompletedPath),
                    child: const Text(
                      'OPEN',
                      style: TextStyle(
                        color: AppColorScheme.primaryBlueStart,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // More Features section divider matching screenshot 2
                  const Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'More Features',
                          style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 6 Quick Feature Grid Icons matching screenshot 2
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 20,
                    children: [
                      _buildCircularFeature(
                        icon: Icons.open_in_new_rounded,
                        label: 'Open With',
                        onTap: () {
                          if (_currentCompletedPath.isNotEmpty) {
                            OpenFilex.open(_currentCompletedPath);
                          }
                        },
                      ),
                      _buildCircularFeature(
                        icon: Icons.folder_outlined,
                        label: 'Save Location',
                        onTap: _changeSaveLocation,
                      ),
                      _buildCircularFeature(
                        icon: Icons.chat_bubble_outline_rounded,
                        label: 'WhatsApp',
                        onTap: () => _shareFile(_currentCompletedPath),
                      ),
                      _buildCircularFeature(
                        icon: Icons.brush_outlined,
                        label: 'Doodle',
                        onTap: () => _stageAndNavigate(AppRoutes.doodle),
                      ),
                      _buildCircularFeature(
                        icon: Icons.text_fields_rounded,
                        label: 'Add Text',
                        onTap: () => _stageAndNavigate(AppRoutes.textEditor),
                      ),
                      _buildCircularFeature(
                        icon: Icons.gesture_rounded,
                        label: 'Signature',
                        onTap: () => _stageAndNavigate(AppRoutes.signatureEditor),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // FIXED: Bottom Feedback Card matching screenshot 2
                  if (_showFeedbackCard)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey.shade900 : Colors.blue.shade50.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.blue.shade100.withOpacity(0.5)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const SizedBox(width: 24),
                              const Text(
                                'Is PDF Converter easy to use?',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                                onPressed: () {
                                  setState(() => _showFeedbackCard = false);
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
                                    foregroundColor: Colors.black87,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                  ),
                                  onPressed: () {
                                    setState(() => _showFeedbackCard = false);
                                    AppPopups.showSnackBar(
                                      context: context,
                                      message: 'Thanks for your feedback!',
                                    );
                                  },
                                  icon: const Text('😒', style: TextStyle(fontSize: 16)),
                                  label: const Text(
                                    'Not really',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
                                    foregroundColor: Colors.black87,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                  ),
                                  onPressed: () {
                                    setState(() => _showFeedbackCard = false);
                                    AppPopups.showSnackBar(
                                      context: context,
                                      message: 'Thank you for your rating!',
                                    );
                                  },
                                  icon: const Text('😃', style: TextStyle(fontSize: 16)),
                                  label: const Text(
                                    'Good',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCircularFeature({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey.shade900 : AppColorScheme.primaryBlueStart.withAlpha(16),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: AppColorScheme.primaryBlueStart,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
