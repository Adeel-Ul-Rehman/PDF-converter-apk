import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flux_convert/core/core.dart';
import 'package:flux_convert/features/converter/domain/entities/conversion_format.dart';
import 'package:flux_convert/features/converter/presentation/providers/converter_providers.dart';
import 'package:flux_convert/features/home/presentation/pages/convert_to_pdf_sheet.dart';

class ImageToPdfPreviewPage extends ConsumerStatefulWidget {
  const ImageToPdfPreviewPage({super.key});

  @override
  ConsumerState<ImageToPdfPreviewPage> createState() =>
      _ImageToPdfPreviewPageState();
}

class _ImageToPdfPreviewPageState extends ConsumerState<ImageToPdfPreviewPage> {
  bool _isSelectionMode = false;
  final Set<String> _selectedItemsForDelete = {};

  // Action: rename output PDF
  Future<void> _showRenameDialog() async {
    final state = ref.read(converterNotifierProvider);
    final currentName =
        state.selectedFileName?.replaceAll(RegExp(r'\.[^.]+$'), '') ??
        'pdf_compiled';
    final controller = TextEditingController(text: currentName);

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Output PDF'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter PDF filename',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColorScheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                final newName = controller.text.trim();
                final finalPdfName = newName.endsWith('.pdf')
                    ? newName
                    : '$newName.pdf';
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
              }
              Navigator.pop(context);
            },
            child: const Text(
              'Save',
              style: TextStyle(
                color: AppColorScheme.primaryBlueStart,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Action: Set PDF Password protection with professional UI
  Future<void> _showPasswordDialog() async {
    final state = ref.read(converterNotifierProvider);
    final controller = TextEditingController(text: state.pdfPassword ?? '');
    var obscureText = true;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 8,
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          title: Column(
            children: [
              // Lock icon with gradient background
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColorScheme.primaryBlueStart,
                      AppColorScheme.primaryBlueEnd,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppColorScheme.primaryBlueStart.withAlpha(50),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Set PDF Password',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Protect your PDF with a password. Leave empty to disable.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: controller,
                obscureText: obscureText,
                autofocus: true,
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'Enter a strong password',
                  prefixIcon: Icon(
                    Icons.key_rounded,
                    color: AppColorScheme.primaryBlueStart.withAlpha(120),
                    size: 22,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: Colors.grey.shade300,
                      width: 1.5,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: Colors.grey.shade300,
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: AppColorScheme.primaryBlueStart,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureText
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      color: Colors.grey.shade500,
                      size: 22,
                    ),
                    onPressed: () {
                      setDialogState(() {
                        obscureText = !obscureText;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: Colors.amber.shade700,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Password is required to open this PDF. Keep it safe!',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.amber.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey.shade700,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                minimumSize: const Size(80, 40),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColorScheme.primaryBlueStart,
                foregroundColor: Colors.white,
                elevation: 2,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                minimumSize: const Size(100, 44),
              ),
              onPressed: () {
                final password = controller.text.trim();
                ref
                    .read(converterNotifierProvider.notifier)
                    .setPdfPassword(password.isEmpty ? null : password);
                Navigator.pop(context);

                // Show appropriate snackbar message
                if (mounted) {
                  AppPopups.showSnackBar(
                    context: context,
                    message: password.isEmpty
                        ? '🔓 Password protection removed'
                        : '🔒 PDF password set successfully',
                  );
                }
              },
              child: const Text(
                'Save',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Action: Sort files programmatically
  void _sortFiles(String criterion, bool ascending) {
    final state = ref.read(converterNotifierProvider);
    final paths = List<String>.from(state.additionalSelectedFilePaths);
    final names = List<String>.from(state.additionalSelectedFileNames);

    if (paths.length <= 1) return;

    final pairs = List.generate(
      paths.length,
      (i) => MapEntry(paths[i], names[i]),
    );

    if (criterion == 'Name') {
      pairs.sort((a, b) {
        final nameA = a.value.toLowerCase();
        final nameB = b.value.toLowerCase();
        return ascending ? nameA.compareTo(nameB) : nameB.compareTo(nameA);
      });
    } else if (criterion == 'Date') {
      pairs.sort((a, b) {
        final fileA = File(a.key);
        final fileB = File(b.key);
        final dateA = fileA.existsSync()
            ? fileA.lastModifiedSync()
            : DateTime(1970);
        final dateB = fileB.existsSync()
            ? fileB.lastModifiedSync()
            : DateTime(1970);
        return ascending ? dateA.compareTo(dateB) : dateB.compareTo(dateA);
      });
    }

    final sortedPaths = pairs.map((p) => p.key).toList();
    final sortedNames = pairs.map((p) => p.value).toList();

    ref
        .read(converterNotifierProvider.notifier)
        .setFile(
          sortedPaths.first,
          state.selectedFileName ?? 'pdf_compiled.pdf',
          state.selectedFileSize ?? 0,
          state.selectedFileCategory ?? FileCategory.image,
          state.selectedInputFormat ?? ConversionFormat.png,
          additionalPaths: sortedPaths,
          additionalNames: sortedNames,
        );

    AppPopups.showSnackBar(
      context: context,
      message:
          'Sorted list by $criterion (${ascending ? "Ascending" : "Descending"}).',
    );
  }

  // Action: Delete selected items
  Future<void> _deleteSelectedItems() async {
    if (_selectedItemsForDelete.isEmpty) return;

    final confirm = await AppPopups.showConfirmationDialog(
      context: context,
      title: 'Delete Images',
      message:
          'Are you sure you want to delete the ${_selectedItemsForDelete.length} selected images?',
      confirmLabel: 'Delete',
    );

    if (confirm == true) {
      final state = ref.read(converterNotifierProvider);
      final paths = List<String>.from(state.additionalSelectedFilePaths);
      final names = List<String>.from(state.additionalSelectedFileNames);

      for (final deletePath in _selectedItemsForDelete) {
        final idx = paths.indexOf(deletePath);
        if (idx != -1) {
          paths.removeAt(idx);
          names.removeAt(idx);
        }
      }

      setState(() {
        _selectedItemsForDelete.clear();
        _isSelectionMode = false;
      });

      if (!mounted) return;
      if (paths.isEmpty) {
        ref.read(converterNotifierProvider.notifier).clearSelection();
        context.pop(); // Go back to selector
        return;
      }

      ref
          .read(converterNotifierProvider.notifier)
          .setFile(
            paths.first,
            state.selectedFileName ?? 'pdf_compiled.pdf',
            state.selectedFileSize ?? 0,
            state.selectedFileCategory ?? FileCategory.image,
            state.selectedInputFormat ?? ConversionFormat.png,
            additionalPaths: paths,
            additionalNames: names,
          );
    }
  }

  // Open 3-Dots Options Menu
  void _openOptionsMenu(BuildContext context) {
    final state = ref.read(converterNotifierProvider);
    final filename = state.selectedFileName ?? 'Image to PDF';

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Text(
                    filename,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Save to Gallery'),
                  onTap: () {
                    Navigator.pop(context);
                    // Save first page original file as demo save
                    if (state.selectedFilePath != null) {
                      _saveToGallery(state.selectedFilePath!);
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('Rename'),
                  onTap: () {
                    Navigator.pop(context);
                    _showRenameDialog();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.check_box_outlined),
                  title: const Text('Select'),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _isSelectionMode = true;
                      _selectedItemsForDelete.clear();
                    });
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.lock_outlined),
                  title: const Text('Set Password'),
                  onTap: () {
                    Navigator.pop(context);
                    _showPasswordDialog();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.swap_vert_rounded),
                  title: const Text('Manual Sorting'),
                  onTap: () {
                    Navigator.pop(context);
                    context.push(AppRoutes.imageSort);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.sort_rounded),
                  title: const Text('Sort By'),
                  onTap: () {
                    Navigator.pop(context);
                    _openSortByDialog();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Gallery Saver helper
  Future<void> _saveToGallery(String path) async {
    try {
      final file = File(path);
      final filename = path.split('/').last.split(r'\').last;
      final downloadDir = Directory('/storage/emulated/0/Download');

      if (downloadDir.existsSync()) {
        final targetFile = File('${downloadDir.path}/$filename');
        await file.copy(targetFile.path);
        if (!mounted) return;
        AppPopups.showSnackBar(
          context: context,
          message: 'Saved to Downloads: ${targetFile.path}',
        );
      } else {
        final appDir = await ref
            .read(fileStorageServiceProvider)
            .appDocumentsDir;
        final targetFile = File('${appDir.path}/$filename');
        await file.copy(targetFile.path);
        if (!mounted) return;
        AppPopups.showSnackBar(
          context: context,
          message: 'Saved to documents: ${targetFile.path}',
        );
      }
    } catch (e) {
      if (!mounted) return;
      AppPopups.showSnackBar(
        context: context,
        message: 'Failed to save: $e',
        isError: true,
      );
    }
  }

  // Sort By sub-menu dialog
  void _openSortByDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sort Images By'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Name (A to Z)'),
              onTap: () {
                Navigator.pop(context);
                _sortFiles('Name', true);
              },
            ),
            ListTile(
              title: const Text('Name (Z to A)'),
              onTap: () {
                Navigator.pop(context);
                _sortFiles('Name', false);
              },
            ),
            ListTile(
              title: const Text('Date (Oldest First)'),
              onTap: () {
                Navigator.pop(context);
                _sortFiles('Date', true);
              },
            ),
            ListTile(
              title: const Text('Date (Newest First)'),
              onTap: () {
                Navigator.pop(context);
                _sortFiles('Date', false);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(converterNotifierProvider);
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final filePaths = state.additionalSelectedFilePaths;
    final fileNames = state.additionalSelectedFileNames;

    final displayTitle = state.selectedFileName ?? 'Image to PDF';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_isSelectionMode) {
          setState(() {
            _isSelectionMode = false;
            _selectedItemsForDelete.clear();
          });
        } else {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(AppRoutes.home);
          }
        }
      },
      child: Scaffold(
        backgroundColor: isDarkMode
            ? theme.colorScheme.background
            : AppColorScheme.background,
        appBar: AppBar(
          backgroundColor: isDarkMode
              ? theme.colorScheme.surface
              : Colors.white,
          elevation: 0.5,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            color: isDarkMode ? Colors.white : AppColorScheme.textPrimary,
            onPressed: () {
              if (_isSelectionMode) {
                setState(() {
                  _isSelectionMode = false;
                  _selectedItemsForDelete.clear();
                });
              } else {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(AppRoutes.home);
                }
              }
            },
          ),
          title: Text(
            _isSelectionMode
                ? '${_selectedItemsForDelete.length} Selected'
                : displayTitle,
            style: AppTextStyles.title.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          actions: _isSelectionMode
              ? [
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: _deleteSelectedItems,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _isSelectionMode = false;
                        _selectedItemsForDelete.clear();
                      });
                    },
                  ),
                ]
              : [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: _showRenameDialog,
                  ),
                  IconButton(
                    icon: const Icon(Icons.swap_vert_rounded),
                    onPressed: () => context.push(AppRoutes.imageSort),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert_rounded),
                    onPressed: () => _openOptionsMenu(context),
                  ),
                  const SizedBox(width: 8),
                ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Preview Image Cards Grid
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: filePaths.length + (_isSelectionMode ? 0 : 1),
                  itemBuilder: (context, index) {
                    // Last Card is Add Image card
                    if (index == filePaths.length) {
                      return _buildAddImageCard(isDarkMode);
                    }

                    final path = filePaths[index];
                    final name = fileNames.length > index
                        ? fileNames[index]
                        : path.split('/').last.split(r'\').last;
                    final isItemChecked = _selectedItemsForDelete.contains(
                      path,
                    );

                    return _buildImageCard(
                      path,
                      name,
                      index,
                      isItemChecked,
                      isDarkMode,
                    );
                  },
                ),
              ),

              // Bottom bar converter
              _buildBottomActionBar(isDarkMode),
            ],
          ),
        ),
      ),
    );
  }

  // Image Card Widget
  Widget _buildImageCard(
    String path,
    String name,
    int index,
    bool isChecked,
    bool isDarkMode,
  ) {
    return InkWell(
      onTap: () {
        if (_isSelectionMode) {
          setState(() {
            if (isChecked) {
              _selectedItemsForDelete.remove(path);
            } else {
              _selectedItemsForDelete.add(path);
            }
          });
        } else {
          // Open editor for this specific image page
          context.push(AppRoutes.imageEditor);
        }
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(File(path), fit: BoxFit.cover),

            // Select checkbox overlay
            if (_isSelectionMode)
              Positioned(
                top: 8,
                left: 8,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    color: Colors.white70,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isChecked
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: isChecked
                        ? AppColorScheme.primaryBlueStart
                        : Colors.grey,
                  ),
                ),
              ),

            // Footer overlay showing file index and name
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.black.withAlpha(140),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white24,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Add more images card
  Widget _buildAddImageCard(bool isDarkMode) {
    return InkWell(
      onTap: () {
        context.push('${AppRoutes.imageSelection}?append=true');
      },
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.withAlpha(60), width: 1.5),
        ),
        color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, size: 36, color: Colors.grey),
            SizedBox(height: 8),
            Text(
              'Add Images',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Footer actionBar
  Widget _buildBottomActionBar(bool isDarkMode) {
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade900 : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Floating plus button
          IconButton(
            icon: const Icon(
              Icons.add_circle_outline_rounded,
              size: 30,
              color: AppColorScheme.primaryBlueStart,
            ),
            onPressed: () {
              context.push('${AppRoutes.imageSelection}?append=true');
            },
          ),
          const SizedBox(width: 8),

          // Large Convert to PDF button
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColorScheme.primaryBlueStart,
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: AppColorScheme.primaryBlueStart.withAlpha(80),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              onPressed: () {
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => const ConvertToPdfSheet(),
                );
              },
              child: const Text(
                'Convert to PDF',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
