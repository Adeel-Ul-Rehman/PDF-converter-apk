import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:syncfusion_flutter_core/theme.dart';

import 'package:flux_convert/core/core.dart';
import 'package:flux_convert/features/converter/presentation/providers/converter_providers.dart';
import 'package:flux_convert/features/conversion/core/engine/conversion_storage_manager.dart';
import 'package:flux_convert/features/annotations/domain/annotation_models.dart';
import 'package:flux_convert/features/annotations/data/pdf_annotation_exporter.dart';

// FIXED: Clean Modern Signature Editor Page matching exact 2 user screenshots
class SignatureEditorPage extends ConsumerStatefulWidget {
  const SignatureEditorPage({super.key});

  @override
  ConsumerState<SignatureEditorPage> createState() => _SignatureEditorPageState();
}

class _SignatureEditorPageState extends ConsumerState<SignatureEditorPage> {
  late PdfViewerController _pdfController;
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey<SfPdfViewerState>();

  bool _isLoading = true;
  bool _isPdf = true;
  String? _filePath;
  int _currentPage = 1;
  int _totalPages = 0;

  // Viewport dimensions
  double _canvasWidth = 800.0;
  double _canvasHeight = 1100.0;

  // Placed Signatures on active document
  final List<SignatureElement> _signatures = [];
  int? _selectedSignatureIndex;

  // Saved Signature Library
  final List<SavedSignature> _signatureLibrary = [];

  @override
  void initState() {
    super.initState();
    _pdfController = PdfViewerController();
    _initializeEditor();
    _loadSavedSignatures();
  }

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

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

  Future<void> _loadSavedSignatures() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('saved_signatures_v2');
      if (jsonString != null && jsonString.isNotEmpty) {
        final list = jsonDecode(jsonString) as List<dynamic>;
        final loaded = <SavedSignature>[];
        for (final item in list) {
          final map = item as Map<String, dynamic>;
          final strokesList = (map['strokes'] as List<dynamic>?)?.map((s) {
            final strokeMap = s as Map<String, dynamic>;
            final pts = (strokeMap['points'] as List<dynamic>).map((p) {
              final pMap = p as Map<String, dynamic>;
              return Offset((pMap['x'] as num).toDouble(), (pMap['y'] as num).toDouble());
            }).toList();
            return DoodleStroke(
              points: pts,
              color: Color(strokeMap['color'] as int),
              width: (strokeMap['width'] as num).toDouble(),
            );
          }).toList() ?? [];

          if (strokesList.isNotEmpty) {
            loaded.add(SavedSignature(
              id: map['id'] as String,
              name: map['name'] as String,
              strokes: strokesList,
            ));
          }
        }
        setState(() {
          _signatureLibrary.clear();
          _signatureLibrary.addAll(loaded);
        });
      }
    } catch (_) {}
  }

  Future<void> _persistSavedSignatures() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _signatureLibrary.map((sig) {
        return {
          'id': sig.id,
          'name': sig.name,
          'strokes': sig.strokes.map((st) {
            return {
              'color': st.color.toARGB32(),
              'width': st.width,
              'points': st.points.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
            };
          }).toList(),
        };
      }).toList();
      await prefs.setString('saved_signatures_v2', jsonEncode(list));
    } catch (_) {}
  }

  // Opens Screen 2: Smooth Full-Screen Signature Scratchpad Canvas
  void _openSignatureScratchpadScreen() {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (ctx) => _SignatureScratchpadScreen(
          onSignatureCreated: (strokes, color) {
            if (strokes.isEmpty) return;

            final newSig = SignatureElement(
              id: const Uuid().v4(),
              strokes: strokes,
              color: color,
              offset: Offset(
                _canvasWidth / 2 - 75,
                _canvasHeight / 3,
              ),
              scale: 1.0,
              rotation: 0.0,
              pageIndex: _currentPage,
            );

            final savedSig = SavedSignature(
              id: const Uuid().v4(),
              name: 'Signature ${_signatureLibrary.length + 1}',
              strokes: strokes,
            );

            setState(() {
              _signatures.add(newSig);
              _selectedSignatureIndex = _signatures.length - 1;
              _signatureLibrary.add(savedSig);
            });

            _persistSavedSignatures();
          },
        ),
      ),
    );
  }

  void _placeLibrarySignature(SavedSignature sig) {
    HapticFeedback.lightImpact();
    final newSig = SignatureElement(
      id: const Uuid().v4(),
      strokes: sig.strokes,
      color: Colors.black,
      offset: Offset(
        _canvasWidth / 2 - 75,
        _canvasHeight / 3,
      ),
      scale: 1.0,
      rotation: 0.0,
      pageIndex: _currentPage,
    );

    setState(() {
      _signatures.add(newSig);
      _selectedSignatureIndex = _signatures.length - 1;
    });
  }

  void _deleteSignatureElement(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      _signatures.removeAt(index);
      if (_selectedSignatureIndex == index) {
        _selectedSignatureIndex = null;
      }
    });
  }

  void _removeLibrarySignature(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      _signatureLibrary.removeAt(index);
    });
    _persistSavedSignatures();
  }

  Future<void> _saveAndApplyPdf() async {
    if (_filePath == null) return;
    setState(() => _isLoading = true);

    try {
      if (_isPdf) {
        final pages = <PageAnnotations>[];
        final maxPage = _totalPages > 0 ? _totalPages : 1;

        for (var i = 1; i <= maxPage; i++) {
          final pageSigs = _signatures
              .where((s) => s.pageIndex == i)
              .map(
                (s) => SignatureAnnotation(
                  id: s.id,
                  strokes: s.strokes,
                  offset: s.offset,
                  scale: s.scale,
                  rotation: s.rotation,
                  color: s.color,
                  isTyped: s.isTyped,
                  text: s.text,
                  fontFamily: s.fontFamily,
                  fontSize: s.fontSize,
                  pageIndex: i,
                ),
              )
              .toList();

          pages.add(
            PageAnnotations(
              signatures: pageSigs,
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
            .replaceAll('.pdf', '_signed.pdf');

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
              message: '✅ Signature saved to PDF successfully!',
            );
            context.push(AppRoutes.conversionSuccess);
          }
        }
      }
    } catch (e) {
      AppLogger.error('Failed saving signature PDF', e);
      if (mounted) {
        AppPopups.showSnackBar(
          context: context,
          message: 'Error saving signature: $e',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
          title: const Text(
            'Add signature',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          actions: [
            // Top Right Blue Tick Button matching Screenshot 2
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColorScheme.primaryBlueStart,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(44, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                onPressed: _saveAndApplyPdf,
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  _canvasWidth = constraints.maxWidth;
                  _canvasHeight = constraints.maxHeight;                  return _isLoading
                      ? const Center(child: CustomCircularProgress())
                      : _isPdf
                          ? _buildPdfViewer(filePath)
                          : _buildImageViewer(filePath);
                },
              ),
            ),

            _buildBottomActionBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildPdfViewer(String filePath) {
    return Stack(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _selectedSignatureIndex = null),
          child: SfPdfViewerTheme(
            data: const SfPdfViewerThemeData(
              backgroundColor: Color(0xFF14171F),
            ),
            child: SfPdfViewer.file(
              File(filePath),
              key: _pdfViewerKey,
              controller: _pdfController,
              onPageChanged: (details) {
                setState(() => _currentPage = details.newPageNumber);
              },
              onDocumentLoaded: (details) {
                setState(() => _totalPages = details.document.pages.count);
              },
            ),
          ),
        ),
        if (_totalPages > 0)
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(150),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '$_currentPage/$_totalPages',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        for (var i = 0; i < _signatures.length; i++)
          _buildPlacedSignatureWidget(i, _signatures[i]),
      ],
    );
  }

  Widget _buildImageViewer(String filePath) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _selectedSignatureIndex = null),
      child: Stack(
        children: [
          Center(
            child: Image.file(
              File(filePath),
              fit: BoxFit.contain,
            ),
          ),
          for (var i = 0; i < _signatures.length; i++)
            _buildPlacedSignatureWidget(i, _signatures[i]),
        ],
      ),
    );
  }

  Widget _buildPlacedSignatureWidget(int index, SignatureElement element) {
    final isSelected = _selectedSignatureIndex == index;

    return Positioned(
      left: element.offset.dx,
      top: element.offset.dy,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Draggable Signature Box Container
          GestureDetector(
            onTap: () {
              setState(() => _selectedSignatureIndex = index);
            },
            onPanUpdate: (details) {
              setState(() {
                _signatures[index] = element.copyWith(
                  offset: element.offset + details.delta,
                );
              });
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withAlpha(40) : Colors.transparent,
                border: isSelected
                    ? Border.all(color: AppColorScheme.primaryBlueStart, width: 2.0)
                    : Border.all(color: Colors.transparent),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SizedBox(
                width: 140 * element.scale,
                height: 75 * element.scale,
                child: CustomPaint(
                  painter: SignaturePreviewPainter(
                    strokes: element.strokes,
                    color: element.color,
                  ),
                  size: Size.infinite,
                ),
              ),
            ),
          ),

          // Upper Left Corner (Cross icon to discard signature - 44x44 touch hit target)
          if (isSelected)
            Positioned(
              top: -16,
              left: -16,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _deleteSignatureElement(index),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Lower Right Corner (Arrow handle to resize signature - 44x44 touch hit target)
          if (isSelected)
            Positioned(
              bottom: -16,
              right: -16,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanUpdate: (details) {
                  final deltaScale = (details.delta.dx + details.delta.dy) * 0.01;
                  final newScale = (element.scale + deltaScale).clamp(0.4, 4.0);
                  setState(() {
                    _signatures[index] = element.copyWith(scale: newScale);
                  });
                },
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: const BoxDecoration(
                        color: AppColorScheme.primaryBlueStart,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.open_in_full_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // FIXED: Bottom Action Bar matching Screenshot 2 exactly
  Widget _buildBottomActionBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF232733),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 80,
          child: Row(
            children: [
              // + Add signature Button (Left side matching Screenshot 2)
              GestureDetector(
                onTap: _openSignatureScratchpadScreen,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: const BoxDecoration(
                        color: AppColorScheme.primaryBlueStart,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Add signature',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),
              const VerticalDivider(color: Colors.white24, width: 1),
              const SizedBox(width: 16),

              // Saved Signatures horizontal scroll list matching Screenshot 2
              Expanded(
                child: _signatureLibrary.isEmpty
                    ? const Center(
                        child: Text(
                          'No saved signatures.\nTap + to create one!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                      )
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _signatureLibrary.length,
                        itemBuilder: (context, index) {
                          final sig = _signatureLibrary[index];

                          return GestureDetector(
                            onTap: () => _placeLibrarySignature(sig),
                            child: Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    width: 75,
                                    height: 60,
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.white24),
                                    ),
                                    child: CustomPaint(
                                      painter: SignaturePreviewPainter(
                                        strokes: sig.strokes,
                                        color: Colors.black,
                                      ),
                                      size: Size.infinite,
                                    ),
                                  ),

                                  // Delete badge on thumbnail top right
                                  Positioned(
                                    top: -6,
                                    right: -6,
                                    child: GestureDetector(
                                      onTap: () => _removeLibrarySignature(index),
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF666666),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close_rounded,
                                          color: Colors.white,
                                          size: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN 2: Smooth Full-Screen Signature Scratchpad Canvas Screen (Screenshot 1)
// ─────────────────────────────────────────────────────────────────────────────
class _SignatureScratchpadScreen extends StatefulWidget {
  const _SignatureScratchpadScreen({
    required this.onSignatureCreated,
  });

  final void Function(List<DoodleStroke> strokes, Color color) onSignatureCreated;

  @override
  State<_SignatureScratchpadScreen> createState() => _SignatureScratchpadScreenState();
}

class _SignatureScratchpadScreenState extends State<_SignatureScratchpadScreen> {
  Color _selectedColor = Colors.black;
  double _strokeWidth = 16.0;

  final List<DoodleStroke> _strokes = [];
  final List<DoodleStroke> _redoStack = [];
  final List<Offset> _currentPoints = [];
  bool _isDrawing = false;

  static const List<Color> _swatchColors = [
    Colors.black,
    Color(0xFF424242), // Dark Grey
    Color(0xFF808080), // Grey
    Color(0xFFE0E0E0), // Light Grey
    Color(0xFFFF0000), // Red
    Color(0xFF00FF00), // Green
    Color(0xFF0044FF), // Blue
    Color(0xFFFF00CC), // Magenta
  ];

  void _onPanStart(DragStartDetails details) {
    HapticFeedback.selectionClick();
    setState(() {
      _isDrawing = true;
      _currentPoints.clear();
      _currentPoints.add(details.localPosition);
      _redoStack.clear();
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDrawing) return;
    setState(() {
      _currentPoints.add(details.localPosition);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (!_isDrawing) return;
    setState(() {
      _isDrawing = false;

      if (_currentPoints.length > 1) {
        final stroke = DoodleStroke(
          points: List<Offset>.from(_currentPoints),
          color: _selectedColor,
          width: _strokeWidth,
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

  void _reset() {
    if (_strokes.isEmpty && _currentPoints.isEmpty) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _strokes.clear();
      _redoStack.clear();
      _currentPoints.clear();
    });
  }

  List<DoodleStroke> get _allStrokesWithCurrent {
    final list = List<DoodleStroke>.from(_strokes);
    if (_isDrawing && _currentPoints.length > 1) {
      list.add(
        DoodleStroke(
          points: List<Offset>.from(_currentPoints),
          color: _selectedColor,
          width: _strokeWidth,
        ),
      );
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final hasContent = _strokes.isNotEmpty || _currentPoints.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFF14171F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF14171F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Add signature',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          // Top Right Reset Pill Button matching Screenshot 1
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: TextButton(
                onPressed: _reset,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(25),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'Reset',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // White Signature Scratchpad Canvas with Watermark matching Screenshot 1
          Expanded(
            child: ColoredBox(
              color: Colors.white,
              child: Stack(
                children: [
                  // Watermark Text ("Sign here / Add a signature to your document.")
                  if (!hasContent)
                    const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Sign here',
                            style: TextStyle(
                              color: Color(0xFFC0C4D0),
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Add a signature to your document.',
                            style: TextStyle(
                              color: Color(0xFFD0D4E0),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Ultra-smooth 60fps gesture drawing surface
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanStart: _onPanStart,
                    onPanUpdate: _onPanUpdate,
                    onPanEnd: _onPanEnd,
                    child: CustomPaint(
                      painter: SignaturePreviewPainter(
                        strokes: _allStrokesWithCurrent,
                        color: _selectedColor,
                      ),
                      size: Size.infinite,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Controls Sheet matching Screenshot 1
          _buildBottomControlsSheet(),
        ],
      ),
    );
  }

  Widget _buildBottomControlsSheet() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF232733),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Row 1: Size Slider (1 - 100)
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

            // Row 2: Color Swatches matching Screenshot 1
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

            // Row 3: Actions Bar (Cross cancel, Undo, Redo, Checkmark Apply)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Cross Icon (Cancel & exit back to Screen 1)
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 26),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Cancel',
                ),

                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.undo_rounded,
                        color: _strokes.isNotEmpty ? Colors.white : Colors.white38,
                        size: 24,
                      ),
                      onPressed: _strokes.isNotEmpty ? _undo : null,
                      tooltip: 'Undo',
                    ),
                    const SizedBox(width: 16),
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

                // Checkmark Tick Icon (Confirms signature & returns to Screen 1)
                IconButton(
                  icon: const Icon(Icons.check_rounded, color: Colors.white, size: 26),
                  onPressed: () {
                    final allStrokes = List<DoodleStroke>.from(_strokes);
                    if (_currentPoints.length > 1) {
                      allStrokes.add(
                        DoodleStroke(
                          points: List<Offset>.from(_currentPoints),
                          color: _selectedColor,
                          width: _strokeWidth,
                        ),
                      );
                    }
                    if (allStrokes.isNotEmpty) {
                      widget.onSignatureCreated(allStrokes, _selectedColor);
                    }
                    Navigator.pop(context);
                  },
                  tooltip: 'Use Signature',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// FIXED: CustomPainter helper for rendering normalized vector signature strokes centered inside container box
class SignaturePreviewPainter extends CustomPainter {
  SignaturePreviewPainter({required this.strokes, required this.color});

  final List<DoodleStroke> strokes;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (strokes.isEmpty) return;

    // Compute bounding box of original signature strokes
    var minX = double.infinity;
    var minY = double.infinity;
    var maxX = -double.infinity;
    var maxY = -double.infinity;

    for (final stroke in strokes) {
      for (final p in stroke.points) {
        if (p.dx < minX) minX = p.dx;
        if (p.dy < minY) minY = p.dy;
        if (p.dx > maxX) maxX = p.dx;
        if (p.dy > maxY) maxY = p.dy;
      }
    }

    if (minX == double.infinity || maxX == -double.infinity) return;

    final origWidth = (maxX - minX).clamp(1.0, 10000.0);
    final origHeight = (maxY - minY).clamp(1.0, 10000.0);

    const padding = 6.0;
    final availWidth = (size.width - (padding * 2)).clamp(10.0, 10000.0);
    final availHeight = (size.height - (padding * 2)).clamp(10.0, 10000.0);

    final scaleX = availWidth / origWidth;
    final scaleY = availHeight / origHeight;
    final scale = scaleX < scaleY ? scaleX : scaleY;

    final offsetX = padding + (availWidth - (origWidth * scale)) / 2;
    final offsetY = padding + (availHeight - (origHeight * scale)) / 2;

    for (final stroke in strokes) {
      if (stroke.points.isEmpty) continue;

      final paint = Paint()
        ..color = stroke.color != Colors.transparent ? stroke.color : color
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = (stroke.width * scale * 0.35).clamp(2.0, 6.0)
        ..style = PaintingStyle.stroke;

      if (stroke.points.length == 1) {
        final p = stroke.points.first;
        final normX = offsetX + (p.dx - minX) * scale;
        final normY = offsetY + (p.dy - minY) * scale;
        canvas.drawCircle(Offset(normX, normY), 3.0, paint);
        continue;
      }

      final path = Path();
      final p0 = stroke.points.first;
      final normX0 = offsetX + (p0.dx - minX) * scale;
      final normY0 = offsetY + (p0.dy - minY) * scale;

      path.moveTo(normX0, normY0);

      for (var i = 0; i < stroke.points.length - 1; i++) {
        final p2 = stroke.points[i + 1];
        final normX2 = offsetX + (p2.dx - minX) * scale;
        final normY2 = offsetY + (p2.dy - minY) * scale;

        if (i < stroke.points.length - 2) {
          final p3 = stroke.points[i + 2];
          final normX3 = offsetX + (p3.dx - minX) * scale;
          final normY3 = offsetY + (p3.dy - minY) * scale;
          final mid = Offset((normX2 + normX3) / 2, (normY2 + normY3) / 2);
          path.quadraticBezierTo(normX2, normY2, mid.dx, mid.dy);
        } else {
          path.lineTo(normX2, normY2);
        }
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(SignaturePreviewPainter oldDelegate) =>
      oldDelegate.strokes != strokes || oldDelegate.color != color;
}
