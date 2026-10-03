import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:flux_convert/core/core.dart';
import 'package:flux_convert/features/converter/presentation/providers/converter_providers.dart';
import 'package:flux_convert/features/conversion/core/engine/conversion_storage_manager.dart';
import 'package:flux_convert/features/annotations/domain/annotation_models.dart';
import 'package:flux_convert/features/annotations/data/pdf_annotation_exporter.dart';
import 'package:flux_convert/features/annotations/presentation/annotation_painter.dart';

// FIXED: Clean Modern Multi-Page PDF Doodle Editor
class DoodlePage extends ConsumerStatefulWidget {
  const DoodlePage({super.key});

  @override
  ConsumerState<DoodlePage> createState() => _DoodlePageState();
}

class _DoodlePageState extends ConsumerState<DoodlePage> {
  final GlobalKey _repaintBoundaryKey = GlobalKey();
  late PdfViewerController _pdfController;
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey<SfPdfViewerState>();

  bool _isLoading = true;
  bool _isPdf = true;
  String? _filePath;
  int _currentPage = 1;
  int _totalPages = 0;

  // FIXED: Draw vs Pan/Scroll mode toggle button state
  bool _isPanScrollMode = false; // When true: brush stops writing, user can scroll & zoom

  // Drawing Configurations
  Color _selectedColor = Colors.black;
  double _strokeWidth = 16.0; // Range 1 - 100

  // Canvas Dimensions
  double _canvasWidth = 800.0;
  double _canvasHeight = 1100.0;

  // Stroke lists & Undo/Redo stacks
  final List<DoodleStroke> _strokes = [];
  final List<DoodleStroke> _redoStack = [];
  final List<Offset> _currentPoints = [];
  bool _isDrawing = false;

  // Preset Colors Swatches matching user screenshot
  static const List<Color> _swatchColors = [
    Colors.black,
    Colors.white,
    Color(0xFF808080), // Grey
    Color(0xFFFF0000), // Bright Red
    Color(0xFF00FF00), // Bright Green
    Color(0xFF0044FF), // Primary Blue
    Color(0xFFFF00CC), // Magenta / Pink
    Color(0xFF00E5FF), // Cyan
    Color(0xFFFFD700), // Gold / Yellow
    Color(0xFFFF9100), // Orange
    Color(0xFF9C27B0), // Purple
  ];

  @override
  void initState() {
    super.initState();
    _pdfController = PdfViewerController();
    _initializeEditor();
  }

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

  // Detect format: PDF inputs open as multi-page PDF document; Image inputs open in image editor mode
  Future<void> _initializeEditor() async {
    final state = ref.read(converterNotifierProvider);
    final filePath = state.selectedFilePath;

    if (filePath == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isPdf = false;
        });
      }
      return;
    }

    final isPdf = filePath.toLowerCase().endsWith('.pdf');

    if (mounted) {
      setState(() {
        _filePath = filePath;
        _isPdf = isPdf;
        _isLoading = false;
      });
    }
  }

  // Gesture drawing handlers
  void _onPanStart(DragStartDetails details) {
    if (_isPanScrollMode) return;
    HapticFeedback.selectionClick();

    setState(() {
      _isDrawing = true;
      _currentPoints.clear();
      _currentPoints.add(details.localPosition);
      _redoStack.clear();
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDrawing || _isPanScrollMode) return;
    setState(() {
      _currentPoints.add(details.localPosition);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (!_isDrawing || _isPanScrollMode) return;

    setState(() {
      _isDrawing = false;

      if (_currentPoints.length > 1) {
        final stroke = DoodleStroke(
          points: List<Offset>.from(_currentPoints),
          color: _selectedColor,
          width: _strokeWidth,
          pageIndex: _currentPage,
        );

        _strokes.add(stroke);
        _redoStack.clear();
      }

      _currentPoints.clear();
    });
  }

  void _undo() {
    if (_strokes.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() {
      final removed = _strokes.removeLast();
      _redoStack.add(removed);
    });
  }

  void _redo() {
    if (_redoStack.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() {
      final added = _redoStack.removeLast();
      _strokes.add(added);
    });
  }

  void _resetAllStrokes() {
    if (_strokes.isEmpty) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _redoStack.addAll(_strokes.reversed);
      _strokes.clear();
    });
  }

  Future<void> _saveAndApplyDoodle() async {
    if (_filePath == null) return;
    setState(() => _isLoading = true);

    try {
      if (_isPdf) {
        final pages = <PageAnnotations>[];
        final maxPage = _totalPages > 0 ? _totalPages : 1;

        for (var i = 1; i <= maxPage; i++) {
          pages.add(
            PageAnnotations(
              doodles: _strokes,
              width: _canvasWidth,
              height: _canvasHeight,
              pageIndex: i,
            ),
          );
        }

        final exporter = PdfAnnotationExporter();
        final bytes = await exporter.exportAnnotations(
          sourcePath: _filePath!,
          pages: pages,
        );

        final fileName = _filePath!
            .split('/')
            .last
            .split(r'\')
            .last
            .replaceAll('.pdf', '_doodled.pdf');

        final destPathResult = await ConversionStorageManager.getDestinationPath(
          fileName.replaceAll('.pdf', ''),
          'pdf',
        );

        if (destPathResult.isSuccess) {
          final destFile = File(destPathResult.value);
          await destFile.writeAsBytes(bytes);

          final notifier = ref.read(converterNotifierProvider.notifier);
          notifier.setCompletedDestinationPath(destFile.path);

          if (mounted) {
            AppPopups.showSnackBar(
              context: context,
              message: '✅ Doodle saved to PDF successfully!',
            );
            context.push(AppRoutes.conversionSuccess);
          }
        }
      } else {
        // Image doodle export
        final boundary = _repaintBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
        if (boundary != null) {
          final image = await boundary.toImage(pixelRatio: 2.0);
          final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
          if (byteData != null) {
            final bytes = byteData.buffer.asUint8List();
            final destPathResult = await ConversionStorageManager.getDestinationPath(
              'doodle_saved',
              'png',
            );

            if (destPathResult.isSuccess) {
              final destFile = File(destPathResult.value);
              await destFile.writeAsBytes(bytes);

              final notifier = ref.read(converterNotifierProvider.notifier);
              notifier.setCompletedDestinationPath(destFile.path);

              if (mounted) {
                AppPopups.showSnackBar(
                  context: context,
                  message: '✅ Doodle saved successfully!',
                );
                context.push(AppRoutes.conversionSuccess);
              }
            }
          }
        }
      }
    } catch (e) {
      AppLogger.error('Failed saving doodle', e);
      if (mounted) {
        AppPopups.showSnackBar(
          context: context,
          message: 'Error saving doodle: $e',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<DoodleStroke> get _allStrokesWithCurrent {
    final list = List<DoodleStroke>.from(_strokes);
    if (_isDrawing && _currentPoints.length > 1) {
      list.add(
        DoodleStroke(
          points: List<Offset>.from(_currentPoints),
          color: _selectedColor,
          width: _strokeWidth,
          pageIndex: _currentPage,
        ),
      );
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final filePath = _filePath;

    if (filePath == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('No document selected.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(AppRoutes.home);
                  }
                },
                child: const Text('Back'),
              ),
            ],
          ),
        ),
      );
    }

    final filename = filePath.split('/').last.split(r'\').last;

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
        backgroundColor: const Color(0xFF14171F),
        appBar: AppBar(
          backgroundColor: const Color(0xFF14171F),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutes.home);
              }
            },
          ),
          title: Text(
            filename,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            TextButton(
              onPressed: _resetAllStrokes,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(20),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'Reset',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  _canvasWidth = constraints.maxWidth;
                  _canvasHeight = constraints.maxHeight;

                  return _isLoading
                      ? const Center(child: CustomCircularProgress())
                      : _isPdf
                          ? _buildPdfViewer()
                          : _buildImageViewer(filePath);
                },
              ),
            ),

            // FIXED: Bottom Toolbar matching screenshot 100%
            _buildBottomToolbar(),
          ],
        ),
      ),
    );
  }

  // Vertical scrollable PDF viewer
  Widget _buildPdfViewer() {
    return Stack(
      children: [
        SfPdfViewerTheme(
          data: const SfPdfViewerThemeData(
            backgroundColor: Color(0xFF14171F),
          ),
          child: SfPdfViewer.file(
            File(_filePath!),
            key: _pdfViewerKey,
            controller: _pdfController,
            scrollDirection: PdfScrollDirection.vertical,
            onPageChanged: (details) {
              setState(() => _currentPage = details.newPageNumber);
            },
            onDocumentLoaded: (details) {
              setState(() => _totalPages = details.document.pages.count);
            },
          ),
        ),

        // FIXED: Gesture Drawing Overlay with pan/scroll hit testing mode
        Positioned.fill(
          child: GestureDetector(
            behavior: _isPanScrollMode ? HitTestBehavior.translucent : HitTestBehavior.opaque,
            onPanStart: _isPanScrollMode ? null : _onPanStart,
            onPanUpdate: _isPanScrollMode ? null : _onPanUpdate,
            onPanEnd: _isPanScrollMode ? null : _onPanEnd,
            child: CustomPaint(
              painter: DoodleBoardPainter(
                strokes: _allStrokesWithCurrent,
                pageIndex: _currentPage,
              ),
              size: Size.infinite,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageViewer(String filePath) {
    return Center(
      child: InteractiveViewer(
        minScale: 0.5,
        maxScale: 4.0,
        panEnabled: _isPanScrollMode,
        scaleEnabled: _isPanScrollMode,
        child: RepaintBoundary(
          key: _repaintBoundaryKey,
          child: Stack(
            children: [
              Image.file(File(filePath), fit: BoxFit.contain),
              Positioned.fill(
                child: GestureDetector(
                  behavior: _isPanScrollMode ? HitTestBehavior.translucent : HitTestBehavior.opaque,
                  onPanStart: _isPanScrollMode ? null : _onPanStart,
                  onPanUpdate: _isPanScrollMode ? null : _onPanUpdate,
                  onPanEnd: _isPanScrollMode ? null : _onPanEnd,
                  child: CustomPaint(
                    painter: DoodleBoardPainter(
                      strokes: _allStrokesWithCurrent,
                    ),
                    size: Size.infinite,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // FIXED: Bottom Toolbar matching user screenshot exactly
  Widget _buildBottomToolbar() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF232733),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: Stroke Size Slider (1 - 100)
          Row(
            children: [
              const Text(
                'Size',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                  ),
                  child: Slider(
                    value: _strokeWidth,
                    min: 1.0,
                    max: 100.0,
                    activeColor: Colors.white,
                    inactiveColor: Colors.white24,
                    onChanged: (val) {
                      setState(() {
                        _strokeWidth = val;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 32,
                child: Text(
                  '${_strokeWidth.round()}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Row 2: Color Swatches matching screenshot
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _swatchColors.length,
              itemBuilder: (context, index) {
                final color = _swatchColors[index];
                final isSelected = _selectedColor == color;

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedColor = color;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.yellow : (color == Colors.white ? Colors.grey : Colors.transparent),
                          width: isSelected ? 3.0 : 1.0,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Colors.yellow.withAlpha(100),
                                  blurRadius: 6,
                                ),
                              ]
                            : null,
                      ),
                      child: isSelected && color != Colors.black && color != Colors.white
                          ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                          : null,
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Row 3: Action Buttons (Cross, Undo, Pan/Scroll Toggle, Redo, Checkmark Tick)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Cross icon (Cancel)
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 26),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(AppRoutes.home);
                  }
                },
                tooltip: 'Cancel',
              ),

              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Undo Button
                  IconButton(
                    icon: Icon(
                      Icons.undo_rounded,
                      color: _strokes.isNotEmpty ? Colors.white : Colors.white38,
                      size: 24,
                    ),
                    onPressed: _strokes.isNotEmpty ? _undo : null,
                    tooltip: 'Undo',
                  ),

                  const SizedBox(width: 12),

                  // FIXED: Pan / Scroll Toggle Button (Toggles between Draw mode and Scroll/Zoom mode)
                  InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _isPanScrollMode = !_isPanScrollMode;
                      });
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: _isPanScrollMode ? AppColorScheme.primaryBlueStart : Colors.white12,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _isPanScrollMode ? Colors.white : Colors.white24,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isPanScrollMode ? Icons.pan_tool_rounded : Icons.gesture_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _isPanScrollMode ? 'Scroll ON' : 'Draw ON',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Redo Button
                  IconButton(
                    icon: Icon(
                      Icons.redo_rounded,
                      color: _redoStack.isNotEmpty ? Colors.white : Colors.white38,
                      size: 24,
                    ),
                    onPressed: _redoStack.isNotEmpty ? _redo : null,
                    tooltip: 'Redo',
                  ),
                ],
              ),

              // Checkmark Tick icon (Confirm & Save)
              IconButton(
                icon: const Icon(Icons.check_rounded, color: Colors.white, size: 26),
                onPressed: _saveAndApplyDoodle,
                tooltip: 'Apply Doodle',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
