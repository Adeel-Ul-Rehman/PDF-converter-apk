import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import 'package:flux_convert/core/core.dart';
import 'package:flux_convert/features/converter/domain/entities/conversion_format.dart';
import 'package:flux_convert/features/converter/presentation/providers/converter_providers.dart';
import 'package:flux_convert/features/files/presentation/widgets/file_card.dart';
import 'package:flux_convert/features/files/presentation/widgets/file_grid.dart';
import 'package:flux_convert/features/storage/domain/usecases/scan_all_files_use_case.dart';
import 'package:flux_convert/features/storage/presentation/storage_manager.dart';

// IMPROVED: Enterprise Files & Document Browser Screen (Layer 6 Rewrite)
/// Discovers all device PDF, image, and document files in a background isolate,
/// rendering them in smooth 60fps List or Grid mode with lazy pagination (20/batch),
/// filter category chips, instant search, and sorting.
class FilesPage extends ConsumerStatefulWidget {
  const FilesPage({super.key});

  @override
  ConsumerState<FilesPage> createState() => _FilesPageState();
}

class _FilesPageState extends ConsumerState<FilesPage> {
  final ScanAllFilesUseCase _scanUseCase = ScanAllFilesUseCase();
  final ScrollController _scrollController = ScrollController();

  List<DiscoveredFile> _allDiscoveredFiles = [];
  List<DiscoveredFile> _filteredFiles = [];
  bool _isLoading = true;
  bool _isGridView = false;

  // Filters & Sorting
  FileTypeCategoryFilter _activeCategory = FileTypeCategoryFilter.all;
  FileSortOption _activeSortOption = FileSortOption.date;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Lazy Pagination (20 items per page)
  int _displayedCount = 20;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _runStorageScan();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (_displayedCount < _filteredFiles.length) {
        setState(() {
          _displayedCount = (_displayedCount + 20).clamp(0, _filteredFiles.length);
        });
      }
    }
  }

  Future<void> _runStorageScan() async {
    setState(() => _isLoading = true);

    try {
      final files = await _scanUseCase.executeScan(
        category: _activeCategory,
        sortOption: _activeSortOption,
      );

      if (!mounted) return;
      setState(() {
        _allDiscoveredFiles = files;
        _applyFiltersAndSearch();
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('FilesPage: Failed storage scan', e);
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFiltersAndSearch() {
    var result = List<DiscoveredFile>.from(_allDiscoveredFiles);

    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.trim().toLowerCase();
      result = result.where((f) => f.name.toLowerCase().contains(query)).toList();
    }

    _filteredFiles = result;
    _displayedCount = 20.clamp(0, _filteredFiles.length);
  }

  void _onFileTap(DiscoveredFile file) {
    if (file.extension == 'pdf') {
      context.push('${AppRoutes.pdfViewer}?path=${Uri.encodeComponent(file.path)}');
      return;
    }

    // Stage in Riverpod for converter
    final notifier = ref.read(converterNotifierProvider.notifier);
    notifier.setFile(
      file.path,
      file.name,
      file.sizeBytes,
      file.extension == 'png' || file.extension == 'jpg' || file.extension == 'jpeg'
          ? FileCategory.image
          : FileCategory.document,
      ConversionFormat.pdf,
    );

    ref.read(storageManagerProvider).openFile(file.path);
  }

  void _showSortDialog() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sort Files By',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.calendar_today_rounded),
              title: const Text('Date Modified (Newest first)'),
              trailing: _activeSortOption == FileSortOption.date
                  ? const Icon(Icons.check_rounded, color: Colors.blue)
                  : null,
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _activeSortOption = FileSortOption.date);
                _runStorageScan();
              },
            ),
            ListTile(
              leading: const Icon(Icons.sort_by_alpha_rounded),
              title: const Text('Name (A-Z)'),
              trailing: _activeSortOption == FileSortOption.name
                  ? const Icon(Icons.check_rounded, color: Colors.blue)
                  : null,
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _activeSortOption = FileSortOption.name);
                _runStorageScan();
              },
            ),
            ListTile(
              leading: const Icon(Icons.data_usage_rounded),
              title: const Text('Size (Largest first)'),
              trailing: _activeSortOption == FileSortOption.size
                  ? const Icon(Icons.check_rounded, color: Colors.blue)
                  : null,
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _activeSortOption = FileSortOption.size);
                _runStorageScan();
              },
            ),
            ListTile(
              leading: const Icon(Icons.category_rounded),
              title: const Text('File Type'),
              trailing: _activeSortOption == FileSortOption.type
                  ? const Icon(Icons.check_rounded, color: Colors.blue)
                  : null,
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _activeSortOption = FileSortOption.type);
                _runStorageScan();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColorScheme.backgroundDark : AppColorScheme.backgroundLight;
    final textPrimaryColor = isDark ? AppColorScheme.textPrimaryDark : AppColorScheme.textPrimaryLight;
    final displayedFiles = _filteredFiles.take(_displayedCount).toList();

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: textPrimaryColor),
        title: Text(
          'All Documents & Files',
          style: TextStyle(
            color: textPrimaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded, color: textPrimaryColor),
            onPressed: () => setState(() => _isGridView = !_isGridView),
            tooltip: _isGridView ? 'List View' : 'Grid View',
          ),
          IconButton(
            icon: Icon(Icons.sort_rounded, color: textPrimaryColor),
            onPressed: _showSortDialog,
            tooltip: 'Sort Options',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _runStorageScan,
        child: Column(
          children: [
            // Search Bar & Filter Chips Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search files...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                              _applyFiltersAndSearch();
                            });
                          },
                        )
                      : null,
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                    _applyFiltersAndSearch();
                  });
                },
              ),
            ),

            // Category Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: FileTypeCategoryFilter.values.map((cat) {
                  final isSelected = _activeCategory == cat;
                  final label = switch (cat) {
                    FileTypeCategoryFilter.all => 'All Files',
                    FileTypeCategoryFilter.pdf => 'PDF Documents',
                    FileTypeCategoryFilter.images => 'Images',
                    FileTypeCategoryFilter.documents => 'Docs & Spreadsheets',
                  };

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(label),
                      selected: isSelected,
                      selectedColor: AppColorScheme.primaryBlueStart,
                      onSelected: (_) {
                        setState(() => _activeCategory = cat);
                        _runStorageScan();
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 8),

            // File Content List / Grid
            Expanded(
              child: _isLoading
                  ? const Center(child: CustomCircularProgress())
                  : displayedFiles.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.folder_open_rounded, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              Text(
                                'No files found',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        )
                      : _isGridView
                          ? GridView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(16),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 1.25,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                              itemCount: displayedFiles.length,
                              itemBuilder: (context, index) {
                                final file = displayedFiles[index];
                                return FileGridCard(
                                  file: file,
                                  onTap: () => _onFileTap(file),
                                );
                              },
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              itemCount: displayedFiles.length,
                              itemBuilder: (context, index) {
                                final file = displayedFiles[index];
                                return FileCard(
                                  file: file,
                                  onTap: () => _onFileTap(file),
                                  onShare: () => Share.shareXFiles([XFile(file.path)]),
                                  onDelete: () async {
                                    final confirm = await AppPopups.showConfirmationDialog(
                                      context: context,
                                      title: 'Delete File',
                                      message: 'Are you sure you want to delete ${file.name}?',
                                      confirmLabel: 'Delete',
                                    );
                                    if (confirm == true) {
                                      try {
                                        File(file.path).deleteSync();
                                        _runStorageScan();
                                      } catch (_) {}
                                    }
                                  },
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
