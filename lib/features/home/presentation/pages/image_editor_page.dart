import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import 'package:flux_convert/core/core.dart';
import 'package:flux_convert/features/converter/domain/entities/conversion_format.dart';
import 'package:flux_convert/features/converter/presentation/providers/converter_providers.dart';
import 'package:flux_convert/features/image_editor/presentation/pages/crop_page.dart';

class PageConfig {
  PageConfig({
    required this.originalPath,
    required this.currentPath,
    this.rotationTurns = 0,
    this.filterType = 'Original',
    this.contrast = 50.0,
    this.brightness = 50.0,
    this.details = 50.0,
    this.cropRect,
  });

  final String originalPath;
  String currentPath; 
  int rotationTurns;  // 0, 1, 2, 3
  String filterType;  // 'Original', 'Docx', 'Image', 'Super', 'Enhanced', 'Enhanced 2', 'B&W', 'Grey', 'invert'
  double contrast;    // 1 - 100, default 50
  double brightness;  // 1 - 100, default 50
  double details;     // 1 - 100, default 50
  CropRect? cropRect;

  PageConfig copyWith({
    String? originalPath,
    String? currentPath,
    int? rotationTurns,
    String? filterType,
    double? contrast,
    double? brightness,
    double? details,
    CropRect? cropRect,
    bool clearCrop = false,
  }) {
    return PageConfig(
      originalPath: originalPath ?? this.originalPath,
      currentPath: currentPath ?? this.currentPath,
      rotationTurns: rotationTurns ?? this.rotationTurns,
      filterType: filterType ?? this.filterType,
      contrast: contrast ?? this.contrast,
      brightness: brightness ?? this.brightness,
      details: details ?? this.details,
      cropRect: clearCrop ? null : (cropRect ?? this.cropRect),
    );
  }
}

class CropClipper extends CustomClipper<Rect> {
  CropClipper(this.rect);

  final CropRect rect;

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(
      rect.left * size.width,
      rect.top * size.height,
      rect.width * size.width,
      rect.height * size.height,
    );
  }

  @override
  bool shouldReclip(CropClipper oldClipper) => oldClipper.rect != rect;
}

/// Serializable input for the background image-processing isolate.
class PageProcessParams {
  const PageProcessParams({
    required this.sourcePath,
    required this.outputPath,
    this.cropRect,
    this.rotationTurns = 0,
    this.contrast = 50.0,
    this.brightness = 50.0,
    this.filterType = 'Original',
  });

  final String sourcePath;
  final String outputPath;
  final CropRect? cropRect;
  final int rotationTurns;
  final double contrast;
  final double brightness;
  final String filterType;
}

/// Runs full image processing (decode → crop → rotate → adjust → encode) on a
/// background isolate so the UI thread never freezes during PDF compilation.
String _processPageIsolate(PageProcessParams params) {
  final srcFile = File(params.sourcePath);
  if (!srcFile.existsSync()) {
    return params.sourcePath;
  }

  var decoded = img.decodeImage(srcFile.readAsBytesSync());
  if (decoded == null) {
    return params.sourcePath;
  }

  // Non-destructive aspect crop.
  final cropRect = params.cropRect;
  if (cropRect != null) {
    final startX = (cropRect.left * decoded.width).toInt().clamp(0, decoded.width - 1);
    final startY = (cropRect.top * decoded.height).toInt().clamp(0, decoded.height - 1);
    final cropW = (cropRect.width * decoded.width).toInt().clamp(10, decoded.width - startX);
    final cropH = (cropRect.height * decoded.height).toInt().clamp(10, decoded.height - startY);
    decoded = img.copyCrop(decoded, x: startX, y: startY, width: cropW, height: cropH);
  }

  // Rotations (quarter turns).
  if (params.rotationTurns != 0) {
    decoded = img.copyRotate(decoded, angle: params.rotationTurns * 90);
  }

  // Contrast/brightness adjustments.
  final cVal = params.contrast / 50.0;
  final bVal = params.brightness / 50.0;
  decoded = img.adjustColor(decoded, contrast: cVal, brightness: bVal);

  // Filters.
  switch (params.filterType) {
    case 'Grey' || 'B&W' || 'Docs':
      decoded = img.grayscale(decoded);
      if (params.filterType == 'B&W') {
        decoded = img.adjustColor(decoded, contrast: 1.6);
      } else if (params.filterType == 'Docs') {
        decoded = img.adjustColor(decoded, contrast: 2.0, brightness: 1.1);
      }
    case 'invert':
      decoded = img.invert(decoded);
    case 'Enhanced':
      decoded = img.adjustColor(decoded, contrast: 1.2, saturation: 1.2);
    case 'Enhanced 2':
      decoded = img.adjustColor(decoded, contrast: 1.4, saturation: 1.1);
    case 'Super':
      decoded = img.adjustColor(decoded, contrast: 1.1, brightness: 1.2);
    case 'Image':
      decoded = img.adjustColor(decoded, brightness: 1.05);
    default:
      break;
  }

  final tempFile = File(params.outputPath);
  tempFile.writeAsBytesSync(img.encodeJpg(decoded, quality: 85));
  return params.outputPath;
}

class ImageEditorPage extends ConsumerStatefulWidget {
  const ImageEditorPage({super.key});

  @override
  ConsumerState<ImageEditorPage> createState() => _ImageEditorPageState();
}

class _ImageEditorPageState extends ConsumerState<ImageEditorPage> {
  bool _isInitialized = false;
  bool _isProcessing = false;
  List<PageConfig> _pages = [];
  int _currentIndex = 0;
  String _pdfName = '';

  // Filters list mapping
  final List<String> _filters = [
    'Original',
    'Docs', // mapped to Docx
    'Image',
    'Super',
    'Enhanced',
    'Enhanced 2',
    'B&W',
    'Grey',
    'invert',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _initializeEditorState();
    }
  }

  void _initializeEditorState() {
    final state = ref.read(converterNotifierProvider);
    final filePaths = state.additionalSelectedFilePaths;
    
    if (filePaths.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.pop();
      });
      return;
    }

    final pdfBaseName = state.selectedFileName?.replaceAll(RegExp(r'\.[^.]+$'), '') ?? 'pdf_compiled';
    
    setState(() {
      _pages = filePaths.map((path) => PageConfig(
        originalPath: path,
        currentPath: path,
      )).toList();
      _pdfName = '${pdfBaseName}_converted';
      _isInitialized = true;
    });
  }

  ColorFilter _getCombinedFilter(double contrast, double brightness, String filterType) {
    final c = contrast / 50.0;
    final b = (brightness - 50.0) * 2.5; 

    List<double> matrix;
    switch (filterType) {
      case 'Grey':
        matrix = [
          0.2126 * c, 0.7152 * c, 0.0722 * c, 0, b,
          0.2126 * c, 0.7152 * c, 0.0722 * c, 0, b,
          0.2126 * c, 0.7152 * c, 0.0722 * c, 0, b,
          0, 0, 0, 1, 0,
        ];
      case 'B&W':
        final bwContrast = c * 1.8;
        matrix = [
          0.2126 * bwContrast, 0.7152 * bwContrast, 0.0722 * bwContrast, 0, b - 80,
          0.2126 * bwContrast, 0.7152 * bwContrast, 0.0722 * bwContrast, 0, b - 80,
          0.2126 * bwContrast, 0.7152 * bwContrast, 0.0722 * bwContrast, 0, b - 80,
          0, 0, 0, 1, 0,
        ];
      case 'Docs': // Mapped from Docx
        final docContrast = c * 2.2;
        matrix = [
          0.2126 * docContrast, 0.7152 * docContrast, 0.0722 * docContrast, 0, b - 40,
          0.2126 * docContrast, 0.7152 * docContrast, 0.0722 * docContrast, 0, b - 40,
          0.2126 * docContrast, 0.7152 * docContrast, 0.0722 * docContrast, 0, b - 40,
          0, 0, 0, 1, 0,
        ];
      case 'Enhanced':
        matrix = [
          1.2 * c, 0, 0, 0, b + 10,
          0, 1.2 * c, 0, 0, b + 10,
          0, 0, 1.2 * c, 0, b + 10,
          0, 0, 0, 1, 0,
        ];
      case 'Enhanced 2':
        matrix = [
          1.4 * c, 0, 0, 0, b - 10,
          0, 1.4 * c, 0, 0, b - 10,
          0, 0, 1.4 * c, 0, b - 10,
          0, 0, 0, 1, 0,
        ];
      case 'Super':
        matrix = [
          1.1 * c, 0, 0, 0, b + 30,
          0, 1.1 * c, 0, 0, b + 30,
          0, 0, 1.1 * c, 0, b + 30,
          0, 0, 0, 1, 0,
        ];
      case 'Image':
        matrix = [
          1.0 * c, 0, 0, 0, b + 15,
          0, 1.0 * c, 0, 0, b + 15,
          0, 0, 1.0 * c, 0, b + 15,
          0, 0, 0, 1, 0,
        ];
      case 'invert':
        matrix = [
          -1.0 * c, 0, 0, 0, 255.0 + b,
          0, -1.0 * c, 0, 0, 255.0 + b,
          0, 0, -1.0 * c, 0, 255.0 + b,
          0, 0, 0, 1, 0,
        ];
      case 'Original':
      default:
        matrix = [
          c, 0, 0, 0, b,
          0, c, 0, 0, b,
          0, 0, c, 0, b,
          0, 0, 0, 1, 0,
        ];
    }
    return ColorFilter.matrix(matrix);
  }

  // Rotate counter-clockwise
  void _rotateLeft() {
    setState(() {
      final config = _pages[_currentIndex];
      _pages[_currentIndex] = config.copyWith(
        rotationTurns: (config.rotationTurns - 1) % 4,
      );
    });
  }

  // Rotate clockwise
  void _rotateRight() {
    setState(() {
      final config = _pages[_currentIndex];
      _pages[_currentIndex] = config.copyWith(
        rotationTurns: (config.rotationTurns + 1) % 4,
      );
    });
  }

  // Rename output dialog
  Future<void> _showRenameDialog() async {
    final controller = TextEditingController(text: _pdfName);
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
            child: const Text('Cancel', style: TextStyle(color: AppColorScheme.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  _pdfName = controller.text.trim();
                });
              }
              Navigator.pop(context);
            },
            child: const Text('Save', style: TextStyle(color: AppColorScheme.primaryBlueStart, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // Delete current page configuration
  Future<void> _deleteCurrentPage() async {
    if (_pages.length <= 1) {
      final confirm = await AppPopups.showConfirmationDialog(
        context: context,
        title: 'Delete Last Image',
        message: 'Deleting this image will cancel the conversion. Proceed?',
        confirmLabel: 'Yes',
        cancelLabel: 'No',
      );
      if (confirm == true) {
        if (mounted) {
          context.pop(); // Returns to ImageSelectionPage
        }
      }
      return;
    }

    final confirm = await AppPopups.showConfirmationDialog(
      context: context,
      title: 'Delete Page',
      message: 'Are you sure you want to delete this page?',
      confirmLabel: 'Delete',
    );

    if (confirm == true) {
      setState(() {
        _pages.removeAt(_currentIndex);
        if (_currentIndex >= _pages.length) {
          _currentIndex = _pages.length - 1;
        }
      });
    }
  }

  // Visual Interactive Crop modal
  Future<void> _openCropModal() async {
    final config = _pages[_currentIndex];
    final file = File(config.originalPath);
    if (!file.existsSync()) return;

    final result = await showDialog<CropRect>(
      context: context,
      barrierDismissible: false,
      builder: (context) => CropEditorDialog(
        imageFile: file,
        initialCropRect: config.cropRect,
      ),
    );

    if (result != null) {
      setState(() {
        if (result.left == 0.0 && result.top == 0.0 && result.width == 1.0 && result.height == 1.0) {
          _pages[_currentIndex] = config.copyWith(clearCrop: true);
        } else {
          _pages[_currentIndex] = config.copyWith(
            cropRect: result,
          );
        }
      });
    }
  }

  // Adjustments Panel Sheet
  void _openAdjustPanel() {
    final config = _pages[_currentIndex];
    var localContrast = config.contrast;
    var localBrightness = config.brightness;
    var localDetails = config.details;

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Manual Adjustments',
                    style: AppTextStyles.title.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  
                  // Contrast Slider
                  Text('Contrast (${localContrast.toInt()})', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Slider(
                    value: localContrast,
                    min: 1.0,
                    max: 100.0,
                    activeColor: AppColorScheme.primaryBlueStart,
                    onChanged: (val) {
                      setModalState(() => localContrast = val);
                      setState(() {
                        _pages[_currentIndex] = _pages[_currentIndex].copyWith(contrast: val);
                      });
                    },
                  ),

                  // Brightness Slider
                  Text('Brightness (${localBrightness.toInt()})', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Slider(
                    value: localBrightness,
                    min: 1.0,
                    max: 100.0,
                    activeColor: AppColorScheme.primaryBlueStart,
                    onChanged: (val) {
                      setModalState(() => localBrightness = val);
                      setState(() {
                        _pages[_currentIndex] = _pages[_currentIndex].copyWith(brightness: val);
                      });
                    },
                  ),

                  // Details/Sharpness Slider
                  Text('Details / Sharpness (${localDetails.toInt()})', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Slider(
                    value: localDetails,
                    min: 1.0,
                    max: 100.0,
                    activeColor: AppColorScheme.primaryBlueStart,
                    onChanged: (val) {
                      setModalState(() => localDetails = val);
                      setState(() {
                        _pages[_currentIndex] = _pages[_currentIndex].copyWith(details: val);
                      });
                    },
                  ),

                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade100,
                      foregroundColor: AppColorScheme.primaryBlueStart,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      setState(() {
                        for (var i = 0; i < _pages.length; i++) {
                          _pages[i] = _pages[i].copyWith(
                            contrast: localContrast,
                            brightness: localBrightness,
                            details: localDetails,
                          );
                        }
                      });
                      Navigator.pop(context);
                      AppPopups.showSnackBar(
                        context: context,
                        message: 'Adjustments applied to all pages.',
                      );
                    },
                    child: const Text('Apply to All Pages', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Compile filters offline in a separate isolate or async loop on tap of DONE
  Future<void> _processAndCompile() async {
    setState(() => _isProcessing = true);

    try {
      final tempDir = await getTemporaryDirectory();
      final processedPaths = <String>[];
      final processedNames = <String>[];

      for (var i = 0; i < _pages.length; i++) {
        final page = _pages[i];
        final srcFile = File(page.originalPath);

        if (!srcFile.existsSync()) {
          processedPaths.add(page.originalPath);
          processedNames.add(page.originalPath.split('/').last.split(r'\').last);
          continue;
        }

        // If page has no edits (original state), bypass processing to make it instant!
        final isUnmodified = page.cropRect == null &&
            page.rotationTurns == 0 &&
            page.contrast == 50.0 &&
            page.brightness == 50.0 &&
            page.filterType == 'Original';

        if (isUnmodified) {
          processedPaths.add(page.originalPath);
          processedNames.add(page.originalPath.split('/').last.split(r'\').last);
          continue;
        }

        // Process only modified pages in a background isolate
        final outputPath =
            '${tempDir.path}/processed_${i}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final resultPath = await compute(
          _processPageIsolate,
          PageProcessParams(
            sourcePath: page.originalPath,
            outputPath: outputPath,
            cropRect: page.cropRect,
            rotationTurns: page.rotationTurns,
            contrast: page.contrast,
            brightness: page.brightness,
            filterType: page.filterType,
          ),
        );

        processedPaths.add(resultPath);
        processedNames.add(resultPath.split('/').last.split(r'\').last);
      }

      // Sync data to Riverpod ConverterNotifier provider state
      final firstPath = processedPaths.first;
      final firstFile = File(firstPath);
      final firstSize = firstFile.existsSync() ? firstFile.lengthSync() : 1024 * 100;
      final finalPdfName = _pdfName.endsWith('.pdf') ? _pdfName : '$_pdfName.pdf';

      final notifier = ref.read(converterNotifierProvider.notifier);
      notifier.setFile(
        firstPath,
        finalPdfName,
        firstSize,
        FileCategory.image,
        ConversionFormat.png,
        additionalPaths: processedPaths,
        additionalNames: processedNames,
      );

      notifier.selectOutputFormat(ConversionFormat.pdf);

      if (mounted) {
        setState(() => _isProcessing = false);
        context.push(AppRoutes.imagePreview);
      }
    } catch (e) {
      AppLogger.error('Failed processing filtered images', e);
      if (mounted) {
        setState(() => _isProcessing = false);
        AppPopups.showSnackBar(
          context: context,
          message: 'An error occurred during filters compilation.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(child: CustomCircularProgress()),
      );
    }

    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final config = _pages[_currentIndex];
    
    // Calculate size of page preview
    final totalPages = _pages.length;

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
      child: Stack(
        children: [
          Scaffold(
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
            title: InkWell(
              onTap: _showRenameDialog,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        _pdfName,
                        style: AppTextStyles.title.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.edit_outlined, size: 16, color: theme.colorScheme.primary),
                  ],
                ),
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.crop_rotate_rounded, size: 22),
                tooltip: 'Crop Page',
                color: isDarkMode ? Colors.white : AppColorScheme.textPrimary,
                onPressed: _openCropModal,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 22),
                tooltip: 'Delete Page',
                color: Colors.red,
                onPressed: _deleteCurrentPage,
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                // Display Canvas area
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: isDarkMode ? Colors.grey.shade900 : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(isDarkMode ? 30 : 10),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              clipBehavior: Clip.antiAlias,
                              alignment: Alignment.center,
                              child: ClipRect(
                                child: RotatedBox(
                                  quarterTurns: config.rotationTurns,
                                  child: CropClipperWidget(
                                    cropRect: config.cropRect,
                                    child: ColorFiltered(
                                      colorFilter: _getCombinedFilter(
                                        config.contrast,
                                        config.brightness,
                                        config.filterType,
                                      ),
                                      child: Image.file(
                                        File(config.currentPath),
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Page number indicator block
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.keyboard_arrow_left_rounded, size: 30),
                                onPressed: _currentIndex > 0
                                    ? () => setState(() => _currentIndex--)
                                    : null,
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${_currentIndex + 1} / $totalPages',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.keyboard_arrow_right_rounded, size: 30),
                                onPressed: _currentIndex < totalPages - 1
                                    ? () => setState(() => _currentIndex++)
                                    : null,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Filters Slider Selector Row
                _buildFiltersBar(isDarkMode, config.currentPath, config),

                // Bottom editing footer controls
                _buildFooterControls(isDarkMode),
              ],
            ),
          ),
        ),

        // Processing Overlay loading state
        if (_isProcessing)
          const ColoredBox(
            color: Colors.black54,
            child: Center(
              child: Card(
                elevation: 8,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomCircularProgress(),
                      SizedBox(height: 16),
                      Text(
                        'Processing filters...',
                        style: TextStyle(fontWeight: FontWeight.bold),
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

  // Horizontal filters bar displaying thumbnail filters preview
  Widget _buildFiltersBar(bool isDarkMode, String currentPath, PageConfig config) {
    return Container(
      height: 96,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade900 : Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.withAlpha(25)),
          bottom: BorderSide(color: Colors.grey.withAlpha(25)),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = config.filterType == filter;

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () {
                setState(() {
                  _pages[_currentIndex] = config.copyWith(filterType: filter);
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? AppColorScheme.primaryBlueStart : Colors.transparent,
                    width: 2.0,
                  ),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: ColorFiltered(
                          colorFilter: _getCombinedFilter(50.0, 50.0, filter),
                          child: Image.file(
                            File(currentPath),
                            fit: BoxFit.cover,
                            width: 60,
                            height: 48,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      filter,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? AppColorScheme.primaryBlueStart : AppColorScheme.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Footer options
  Widget _buildFooterControls(bool isDarkMode) {
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: isDarkMode ? Colors.grey.shade900 : Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Rotate Left
          _buildTextFooterButton(
            icon: Icons.rotate_left_rounded,
            label: 'Left',
            onTap: _rotateLeft,
            isDarkMode: isDarkMode,
          ),

          // Rotate Right
          _buildTextFooterButton(
            icon: Icons.rotate_right_rounded,
            label: 'Right',
            onTap: _rotateRight,
            isDarkMode: isDarkMode,
          ),

          // Adjust Sliders trigger
          _buildTextFooterButton(
            icon: Icons.tune_rounded,
            label: 'Adjust',
            onTap: _openAdjustPanel,
            isDarkMode: isDarkMode,
          ),

          // Done Button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColorScheme.primaryBlueStart,
              foregroundColor: Colors.white,
              elevation: 4,
              shadowColor: AppColorScheme.primaryBlueStart.withAlpha(80),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            onPressed: _processAndCompile,
            child: const Text(
              'DONE',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextFooterButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDarkMode,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isDarkMode ? Colors.white70 : AppColorScheme.textPrimary,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isDarkMode ? Colors.white60 : AppColorScheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CropClipperWidget extends StatelessWidget {
  const CropClipperWidget({
    required this.cropRect,
    required this.child,
    super.key,
  });

  final CropRect? cropRect;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (cropRect == null) return child;
    return ClipRect(
      clipper: CropClipper(cropRect!),
      child: child,
    );
  }
}
