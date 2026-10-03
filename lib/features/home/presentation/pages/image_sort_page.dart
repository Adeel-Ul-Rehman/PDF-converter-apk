import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flux_convert/core/core.dart';
import 'package:flux_convert/features/converter/domain/entities/conversion_format.dart';
import 'package:flux_convert/features/converter/presentation/providers/converter_providers.dart';

class ImageSortPage extends ConsumerStatefulWidget {
  const ImageSortPage({super.key});

  @override
  ConsumerState<ImageSortPage> createState() => _ImageSortPageState();
}

class _ImageSortPageState extends ConsumerState<ImageSortPage> {
  // Update state with newly sorted list
  void _updateSortedList(List<String> newPaths, List<String> newNames) {
    final state = ref.read(converterNotifierProvider);
    ref.read(converterNotifierProvider.notifier).setFile(
      newPaths.first,
      state.selectedFileName ?? 'pdf_compiled.pdf',
      state.selectedFileSize ?? 0,
      state.selectedFileCategory ?? FileCategory.image,
      state.selectedInputFormat ?? ConversionFormat.png,
      additionalPaths: newPaths,
      additionalNames: newNames,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(converterNotifierProvider);
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final filePaths = List<String>.from(state.additionalSelectedFilePaths);
    final fileNames = List<String>.from(state.additionalSelectedFileNames);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(AppRoutes.home);
        }
      },
      child: Scaffold(
        backgroundColor: isDarkMode ? theme.colorScheme.background : AppColorScheme.background,
        appBar: AppBar(
          backgroundColor: isDarkMode ? theme.colorScheme.surface : Colors.white,
          elevation: 0.5,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            color: isDarkMode ? Colors.white : AppColorScheme.textPrimary,
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutes.home);
              }
            },
          ),
        title: const Text(
          'Drag to sort manually',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: SafeArea(
        child: filePaths.isEmpty
            ? const Center(child: Text('No images to sort.'))
            : ReorderableListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: filePaths.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    var destinationIndex = newIndex;
                    if (oldIndex < destinationIndex) {
                      destinationIndex -= 1;
                    }
                    final draggedPath = filePaths.removeAt(oldIndex);
                    final draggedName = fileNames.removeAt(oldIndex);

                    filePaths.insert(destinationIndex, draggedPath);
                    fileNames.insert(destinationIndex, draggedName);

                    _updateSortedList(filePaths, fileNames);
                  });
                },
                itemBuilder: (context, index) {
                  final path = filePaths[index];
                  final name = fileNames.length > index
                      ? fileNames[index]
                      : path.split('/').last.split(r'\').last;

                  return Card(
                    key: ValueKey(path),
                    elevation: 1.5,
                    margin: const EdgeInsets.only(bottom: 12),
                    color: isDarkMode ? Colors.grey.shade900 : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: Colors.grey.withOpacity(isDarkMode ? 0.1 : 0.2),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColorScheme.primaryBlueStart.withAlpha(220),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 50,
                              height: 50,
                              child: Image.file(
                                File(path),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDarkMode ? Colors.white : AppColorScheme.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(
                            Icons.drag_handle_rounded,
                            color: Colors.grey,
                            size: 22,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    ),);
  }
}
