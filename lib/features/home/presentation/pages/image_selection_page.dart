import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:image_picker/image_picker.dart';

import 'package:flux_convert/core/core.dart';
import 'package:flux_convert/features/converter/domain/entities/conversion_format.dart';
import 'package:flux_convert/features/converter/presentation/providers/converter_providers.dart';

class ImageSelectionPage extends ConsumerStatefulWidget {
  const ImageSelectionPage({this.append = false, super.key});

  final bool append;

  @override
  ConsumerState<ImageSelectionPage> createState() => _ImageSelectionPageState();
}

class _ImageSelectionPageState extends ConsumerState<ImageSelectionPage> {
  bool _hasPermission = false;
  bool _isLoading = true;
  List<AssetPathEntity> _albums = [];
  AssetPathEntity? _selectedAlbum;
  List<AssetEntity> _assets = [];
  final List<AssetEntity> _selectedAssets = [];
  final Map<String, String> _pathCache = {};
  
  // Track camera captured images
  final List<File> _cameraCapturedFiles = [];

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _requestPermission();
  }

  Future<void> _requestPermission() async {
    setState(() => _isLoading = true);
    // Request permission from the device
    final ps = await PhotoManager.requestPermissionExtend();
    if (ps.isAuth) {
      setState(() => _hasPermission = true);
      await _loadAlbums();
    } else {
      setState(() {
        _hasPermission = false;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAlbums() async {
    try {
      final albums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        filterOption: FilterOptionGroup(
          imageOption: const FilterOption(
            needTitle: true,
            sizeConstraint: SizeConstraint(ignoreSize: true),
          ),
          orders: [
            const OrderOption(),
          ],
        ),
      );

      if (albums.isEmpty) {
        setState(() {
          _albums = [];
          _assets = [];
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _albums = albums;
        _selectedAlbum = albums.first;
      });

      await _loadAssetsForAlbum(albums.first);
    } catch (e) {
      AppLogger.error('Failed to load photo albums', e);
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAssetsForAlbum(AssetPathEntity album) async {
    setState(() => _isLoading = true);
    try {
      final assetCount = await album.assetCountAsync;
      final assets = await album.getAssetListRange(
        start: 0,
        end: assetCount > 2000 ? 2000 : assetCount, // Load a maximum of 2000 images for visual fluidity
      );

      setState(() {
        _assets = assets;
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('Failed to load assets for album ${album.name}', e);
      setState(() => _isLoading = false);
    }
  }

  // Launch camera capture
  Future<void> _captureFromCamera() async {
    try {
      final image = await _picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        final file = File(image.path);
        setState(() {
          _cameraCapturedFiles.add(file);
        });
      }
    } catch (e) {
      AppLogger.error('Failed to capture image from camera', e);
      if (mounted) {
        AppPopups.showSnackBar(
          context: context,
          message: 'Failed to access camera.',
        );
      }
    }
  }

  // Preloads path and returns cache
  Future<String?> _resolveAssetPath(AssetEntity asset) async {
    if (_pathCache.containsKey(asset.id)) {
      return _pathCache[asset.id];
    }
    final file = await asset.file;
    if (file != null) {
      _pathCache[asset.id] = file.path;
      return file.path;
    }
    return null;
  }

  void _toggleAssetSelection(AssetEntity asset) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_selectedAssets.contains(asset)) {
        _selectedAssets.remove(asset);
      } else {
        _selectedAssets.add(asset);
        // Start preloading path in background
        unawaited(_resolveAssetPath(asset));
      }
    });
  }

  void _removeSelectedAsset(AssetEntity asset) {
    setState(() {
      _selectedAssets.remove(asset);
    });
  }

  void _removeCapturedFile(File file) {
    setState(() {
      _cameraCapturedFiles.remove(file);
    });
  }

  int _getSelectionIndex(AssetEntity asset) {
    return _selectedAssets.indexOf(asset) + 1;
  }

  Future<void> _handleImport() async {
    final totalSelected = _selectedAssets.length + _cameraCapturedFiles.length;
    if (totalSelected == 0) {
      AppPopups.showSnackBar(
        context: context,
        message: 'Please select at least one image to import.',
      );
      return;
    }

    final allPaths = <String>[];
    final allNames = <String>[];

    // 1. Resolve camera captured images
    for (final file in _cameraCapturedFiles) {
      allPaths.add(file.path);
      allNames.add(file.path.split('/').last.split(r'\').last);
    }

    // 2. Resolve gallery images in parallel
    final resolveResults = await Future.wait(
      _selectedAssets.map((asset) async {
        final path = await _resolveAssetPath(asset);
        if (path != null) {
          final name = asset.title ?? path.split('/').last.split(r'\').last;
          return MapEntry<String, String>(path, name);
        }
        return null;
      }),
    );

    for (final result in resolveResults) {
      if (result != null) {
        allPaths.add(result.key);
        allNames.add(result.value);
      }
    }

    if (allPaths.isEmpty) {
      setState(() => _isLoading = false);
      if (mounted) {
        AppPopups.showSnackBar(
          context: context,
          message: 'Failed to read selected image files.',
        );
      }
      return;
    }

    final notifier = ref.read(converterNotifierProvider.notifier);
    final state = ref.read(converterNotifierProvider);

    final List<String> finalPaths;
    final List<String> finalNames;

    if (widget.append && state.additionalSelectedFilePaths.isNotEmpty) {
      finalPaths = List<String>.from(state.additionalSelectedFilePaths)..addAll(allPaths);
      finalNames = List<String>.from(state.additionalSelectedFileNames)..addAll(allNames);
    } else {
      finalPaths = allPaths;
      finalNames = allNames;
    }

    final firstPath = finalPaths.first;
    final firstFile = File(firstPath);
    final firstSize = firstFile.existsSync() ? firstFile.lengthSync() : 1024 * 100;
    final firstName = finalNames.first;

    notifier.setFile(
      firstPath,
      widget.append ? (state.selectedFileName ?? firstName) : firstName,
      widget.append ? (state.selectedFileSize ?? firstSize) : firstSize,
      FileCategory.image,
      ConversionFormat.png, // Default source format
      additionalPaths: finalPaths,
      additionalNames: finalNames,
    );

    // Default target format is PDF for Image to PDF
    notifier.selectOutputFormat(ConversionFormat.pdf);

    if (mounted) {
      setState(() => _isLoading = false);
      if (widget.append) {
        context.pop();
      } else {
        context.push(AppRoutes.imageEditor);
      }
    }
  }

  void _showAlbumSelectionSheet(BuildContext context, bool isDarkMode) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  'Select Folder',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: _albums.length,
                  itemBuilder: (context, index) {
                    final album = _albums[index];
                    final isSelected = album == _selectedAlbum;

                    return FutureBuilder<int>(
                      future: album.assetCountAsync,
                      builder: (context, snapshot) {
                        final count = snapshot.data ?? 0;
                        return ListTile(
                          leading: const Icon(Icons.folder_outlined, color: Colors.blueGrey),
                          title: Text(
                            album.name.isEmpty ? 'All Images' : album.name,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? AppColorScheme.primaryBlueStart : null,
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey.withAlpha(30),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$count',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ),
                          selected: isSelected,
                          onTap: () {
                            Navigator.pop(context);
                            setState(() {
                              _selectedAlbum = album;
                            });
                            _loadAssetsForAlbum(album);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    if (!_hasPermission && !_isLoading) {
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
          appBar: AppBar(
            title: const Text('Image Selection'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(AppRoutes.home);
                }
              },
            ),
          ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.s24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.photo_library_outlined,
                  size: 64,
                  color: AppColorScheme.primaryBlueStart,
                ),
                AppDimensions.h16,
                Text(
                  'Gallery Access Required',
                  style: AppTextStyles.titleMedium,
                ),
                AppDimensions.h8,
                Text(
                  'Please grant photo storage access permission to select images for conversion.',
                  style: AppTextStyles.body,
                  textAlign: TextAlign.center,
                ),
                AppDimensions.h24,
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColorScheme.primaryBlueStart,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _requestPermission,
                  child: const Text('Grant Access'),
                ),
                const TextButton(
                  onPressed: PhotoManager.openSetting,
                  child: Text('Open Settings'),
                ),
              ],
            ),
          ),
        ),
      ),);
    }

    final totalSelectedCount = _selectedAssets.length + _cameraCapturedFiles.length;

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
          title: InkWell(
            onTap: () => _showAlbumSelectionSheet(context, isDarkMode),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    _selectedAlbum != null
                        ? (_selectedAlbum!.name.isEmpty ? 'All Images' : _selectedAlbum!.name)
                        : 'Image Selection',
                    style: AppTextStyles.title.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.arrow_drop_down_rounded, size: 24, color: AppColorScheme.primaryBlueStart),
              ],
            ),
          ),
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
        actions: [
          // Select All / Deselect All Action
          IconButton(
            icon: const Icon(Icons.select_all_rounded, size: 24),
            tooltip: 'Select All',
            color: isDarkMode ? Colors.white : AppColorScheme.textPrimary,
            onPressed: () {
              if (_assets.isNotEmpty) {
                setState(() {
                  if (_selectedAssets.length == _assets.length) {
                    _selectedAssets.clear();
                  } else {
                    _selectedAssets.clear();
                    _selectedAssets.addAll(_assets);
                  }
                });
              }
            },
          ),
          AppDimensions.w8,
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Gallery Grid
            Expanded(
              child: _isLoading
                  ? const Center(child: CustomCircularProgress())
                  : _assets.isEmpty && _cameraCapturedFiles.isEmpty
                      ? Center(
                          child: Text(
                            'No images found on your device.',
                            style: AppTextStyles.body,
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(8),
                          physics: const BouncingScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          // First cell is camera, so add 1
                          itemCount: _assets.length + 1,
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return _buildCameraGridItem(isDarkMode);
                            }

                            final asset = _assets[index - 1];
                            final isSelected = _selectedAssets.contains(asset);
                            final selectionNumber = _getSelectionIndex(asset);

                            return _buildGalleryGridItem(asset, isSelected, selectionNumber, isDarkMode);
                          },
                        ),
            ),

            // Horizontal selected items carousel overlay (above bottom bar)
            if (totalSelectedCount > 0) _buildSelectedCarousel(isDarkMode),

            // Bottom Album & Action Control Bar
            _buildBottomActionBar(isDarkMode),
          ],
        ),
      ),
    ),
  );
}

  // Camera Grid Item (Item 0)
  Widget _buildCameraGridItem(bool isDarkMode) {
    return InkWell(
      onTap: _captureFromCamera,
      borderRadius: BorderRadius.circular(12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey.shade900 : Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDarkMode ? Colors.grey.shade800 : Colors.blue.shade100,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt_outlined,
              size: 32,
              color: isDarkMode ? Colors.blue.shade400 : AppColorScheme.primaryBlueStart,
            ),
            const SizedBox(height: 8),
            Text(
              'Camera',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.blue.shade400 : AppColorScheme.primaryBlueStart,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // FIXED: Gallery Item Widget with tap selection, checkmark overlay, and order badge
  Widget _buildGalleryGridItem(AssetEntity asset, bool isSelected, int selectionNumber, bool isDarkMode) {
    return FutureBuilder<Uint8List?>(
      future: asset.thumbnailDataWithSize(const ThumbnailSize(200, 200)),
      builder: (context, snapshot) {
        final data = snapshot.data;
        if (snapshot.connectionState == ConnectionState.done && data != null) {
          return InkWell(
            onTap: () => _toggleAssetSelection(asset),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColorScheme.primaryBlueStart : Colors.transparent,
                  width: 3,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(
                      data,
                      fit: BoxFit.cover,
                    ),
                    if (isSelected) ...[
                      // Dark overlay for selection contrast
                      Container(color: Colors.black38),
                      // Checkmark badge top right
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            color: AppColorScheme.primaryBlueStart,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                      // Selection order number badge top left
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$selectionNumber',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }

        // Placeholder loading indicator
        return DecoratedBox(
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      },
    );
  }

  // Selected Assets Horizontal Preview
  Widget _buildSelectedCarousel(bool isDarkMode) {
    return Container(
      height: 90,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade900 : Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.withAlpha(25)),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _cameraCapturedFiles.length + _selectedAssets.length,
        itemBuilder: (context, index) {
          // Camera captured items first
          if (index < _cameraCapturedFiles.length) {
            final file = _cameraCapturedFiles[index];
            return _buildSelectedFileThumbnail(file);
          }

          final assetIndex = index - _cameraCapturedFiles.length;
          final asset = _selectedAssets[assetIndex];
          return _buildSelectedAssetThumbnail(asset);
        },
      ),
    );
  }

  // Horizontal Carousel Thumbnail for Camera File
  Widget _buildSelectedFileThumbnail(File file) {
    return Padding(
      key: ValueKey(file.path),
      padding: const EdgeInsets.only(right: 12),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColorScheme.primaryBlueStart, width: 1.5),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.file(
                file,
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Delete badge
          Positioned(
            top: -6,
            right: -6,
            child: GestureDetector(
              onTap: () => _removeCapturedFile(file),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade800.withAlpha(220),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Horizontal Carousel Thumbnail for Gallery Asset
  Widget _buildSelectedAssetThumbnail(AssetEntity asset) {
    return Padding(
      key: ValueKey(asset.id),
      padding: const EdgeInsets.only(right: 12),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          FutureBuilder<Uint8List?>(
            future: asset.thumbnailDataWithSize(const ThumbnailSize(100, 100)),
            builder: (context, snapshot) {
              final data = snapshot.data;
              if (snapshot.connectionState == ConnectionState.done && data != null) {
                return Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColorScheme.primaryBlueStart, width: 1.5),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.memory(
                      data,
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              }
              return Container(
                width: 70,
                height: 70,
                color: Colors.grey.shade200,
              );
            },
          ),
          // Delete badge
          Positioned(
            top: -6,
            right: -6,
            child: GestureDetector(
              onTap: () => _removeSelectedAsset(asset),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade800.withAlpha(220),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // FIXED: Bottom Action Bar displaying "NEXT (count)"
  Widget _buildBottomActionBar(bool isDarkMode) {
    final totalSelected = _selectedAssets.length + _cameraCapturedFiles.length;

    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColorScheme.primaryBlueStart,
            foregroundColor: Colors.white,
            elevation: 4,
            shadowColor: AppColorScheme.primaryBlueStart.withAlpha(80),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          onPressed: totalSelected > 0 ? _handleImport : null,
          child: Text(
            totalSelected > 0 ? 'NEXT ($totalSelected)' : 'SELECT IMAGES',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
