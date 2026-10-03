import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:syncfusion_flutter_core/theme.dart';

import 'package:flux_convert/core/core.dart';
import 'package:flux_convert/features/converter/presentation/providers/converter_providers.dart';
import 'package:flux_convert/features/conversion/core/engine/conversion_storage_manager.dart';
import 'package:flux_convert/features/annotations/domain/annotation_models.dart';
import 'package:flux_convert/features/annotations/data/pdf_annotation_exporter.dart';

// FIXED: Clean Modern Text Editor Page matching exact user specifications
class TextEditorPage extends ConsumerStatefulWidget {
  const TextEditorPage({super.key});

  @override
  ConsumerState<TextEditorPage> createState() => _TextEditorPageState();
}

class _TextEditorPageState extends ConsumerState<TextEditorPage> {
  late PdfViewerController _pdfController;
  final GlobalKey<SfPdfViewerState> _pdfViewerKey =
      GlobalKey<SfPdfViewerState>();

  bool _isLoading = true;
  bool _isPdf = true;
  String? _filePath;
  int _currentPage = 1;
  int _totalPages = 0;

  // Viewport dimensions
  double _canvasWidth = 800.0;
  double _canvasHeight = 1100.0;

  // Text Elements list
  final List<TextAnnotationElement> _textElements = [];
  int? _selectedTextIndex;

  static const List<String> _fontFamilies = [
    'Roboto',
    'Arial',
    'Times New Roman',
    'Courier New',
    'Georgia',
    'Verdana',
    'Comic Sans MS',
    'Impact',
  ];

  static const List<Color> _presetColors = [
    Colors.black,
    Colors.white,
    Color(0xFFFF0000), // Red
    Color(0xFF00FF00), // Green
    Color(0xFF0044FF), // Blue
    Color(0xFFFF00CC), // Pink
    Color(0xFF00E5FF), // Cyan
    Color(0xFFFFD700), // Yellow
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

  // Opens text entry modal sheet to customize text & font
  void _openAddTextSheet({
    TextAnnotationElement? existingElement,
    int? editIndex,
  }) {
    final isEditing = existingElement != null;
    final textController = TextEditingController(
      text: existingElement?.text ?? '',
    );
    var selectedColor = existingElement?.color ?? Colors.black;
    var selectedFont = existingElement?.fontFamily ?? 'Roboto';
    final fontSize = existingElement?.fontSize ?? 24.0;
    var isBold = existingElement?.isBold ?? false;
    var isItalic = existingElement?.isItalic ?? false;
    var alignment = existingElement?.alignment ?? TextAlign.center;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final isDarkMode = Theme.of(context).brightness == Brightness.dark;

          return Container(
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1E1E2C) : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              top: 20,
              left: 20,
              right: 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEditing ? 'Edit Text' : 'Add Custom Text',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColorScheme.primaryBlueStart,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        onPressed: () {
                          final text = textController.text.trim();
                          if (text.isEmpty) {
                            Navigator.pop(ctx);
                            return;
                          }

                          if (isEditing && editIndex != null) {
                            setState(() {
                              _textElements[editIndex] = existingElement
                                  .copyWith(
                                    text: text,
                                    color: selectedColor,
                                    fontSize: fontSize,
                                    fontFamily: selectedFont,
                                    isBold: isBold,
                                    isItalic: isItalic,
                                    alignment: alignment,
                                  );
                            });
                          } else {
                            final newElement = TextAnnotationElement(
                              id: const Uuid().v4(),
                              text: text,
                              offset: Offset(
                                _canvasWidth / 2 - 80,
                                _canvasHeight / 3,
                              ),
                              color: selectedColor,
                              fontSize: fontSize,
                              fontFamily: selectedFont,
                              fontWeight: isBold
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontStyle: isItalic
                                  ? FontStyle.italic
                                  : FontStyle.normal,
                              isBold: isBold,
                              isItalic: isItalic,
                              alignment: alignment,
                              pageIndex: _currentPage,
                            );

                            setState(() {
                              _textElements.add(newElement);
                              _selectedTextIndex = _textElements.length - 1;
                            });
                          }

                          Navigator.pop(ctx);
                        },
                        child: const Text(
                          'OK',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  TextField(
                    controller: textController,
                    autofocus: true,
                    maxLines: 3,
                    minLines: 1,
                    style: TextStyle(
                      color: selectedColor,
                      fontSize: fontSize.clamp(14.0, 32.0),
                      fontFamily: selectedFont,
                      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                      fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter your text here...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Style Controls (Bold, Italic, Alignment)
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.format_bold_rounded,
                          color: isBold
                              ? AppColorScheme.primaryBlueStart
                              : Colors.grey,
                        ),
                        onPressed: () => setModalState(() => isBold = !isBold),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.format_italic_rounded,
                          color: isItalic
                              ? AppColorScheme.primaryBlueStart
                              : Colors.grey,
                        ),
                        onPressed: () =>
                            setModalState(() => isItalic = !isItalic),
                      ),
                      const VerticalDivider(width: 20),
                      IconButton(
                        icon: Icon(
                          Icons.format_align_left_rounded,
                          color: alignment == TextAlign.left
                              ? AppColorScheme.primaryBlueStart
                              : Colors.grey,
                        ),
                        onPressed: () =>
                            setModalState(() => alignment = TextAlign.left),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.format_align_center_rounded,
                          color: alignment == TextAlign.center
                              ? AppColorScheme.primaryBlueStart
                              : Colors.grey,
                        ),
                        onPressed: () =>
                            setModalState(() => alignment = TextAlign.center),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.format_align_right_rounded,
                          color: alignment == TextAlign.right
                              ? AppColorScheme.primaryBlueStart
                              : Colors.grey,
                        ),
                        onPressed: () =>
                            setModalState(() => alignment = TextAlign.right),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Font Family Selector
                  Row(
                    children: [
                      const Text(
                        'Font: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: selectedFont,
                          items: _fontFamilies.map((font) {
                            return DropdownMenuItem(
                              value: font,
                              child: Text(
                                font,
                                style: TextStyle(fontFamily: font),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() => selectedFont = val);
                            }
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Color Swatches
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _presetColors.length,
                      itemBuilder: (context, index) {
                        final c = _presetColors[index];
                        final isSelected = selectedColor == c;

                        return GestureDetector(
                          onTap: () => setModalState(() => selectedColor = c),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: c,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? AppColorScheme.primaryBlueStart
                                      : Colors.grey.shade400,
                                  width: isSelected ? 3.0 : 1.0,
                                ),
                              ),
                              child:
                                  isSelected &&
                                      c != Colors.black &&
                                      c != Colors.white
                                  ? const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 16,
                                    )
                                  : null,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _deleteTextElement(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      _textElements.removeAt(index);
      if (_selectedTextIndex == index) {
        _selectedTextIndex = null;
      }
    });
  }

  void _resetAllTexts() {
    if (_textElements.isEmpty) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _textElements.clear();
      _selectedTextIndex = null;
    });
  }

  Future<void> _saveAndApplyPdf() async {
    if (_filePath == null) return;
    setState(() => _isLoading = true);

    try {
      if (_isPdf) {
        final pages = <PageAnnotations>[];
        final maxPage = _totalPages > 0 ? _totalPages : 1;

        for (var i = 1; i <= maxPage; i++) {
          final textAnnots = _textElements
              .map(
                (e) => TextAnnotation(
                  id: e.id,
                  text: e.text,
                  offset: e.offset,
                  color: e.color,
                  fontSize: e.fontSize,
                  fontFamily: e.fontFamily,
                  fontWeight: e.isBold ? 'bold' : 'normal',
                  fontStyle: e.isItalic ? 'italic' : 'normal',
                  alignment: e.alignment,
                  rotation: e.rotation,
                  backgroundColor: e.backgroundColor,
                  isUnderline: e.isUnderline,
                  pageIndex: i,
                ),
              )
              .toList();

          pages.add(
            PageAnnotations(
              texts: textAnnots,
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
            .replaceAll('.pdf', '_text.pdf');

        final destPathResult =
            await ConversionStorageManager.getDestinationPath(
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
              message: '✅ Text saved to PDF successfully!',
            );
            context.push(AppRoutes.conversionSuccess);
          }
        }
      }
    } catch (e) {
      AppLogger.error('Failed saving text PDF', e);
      if (mounted) {
        AppPopups.showSnackBar(
          context: context,
          message: 'Error saving text: $e',
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
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
              size: 22,
            ),
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
              onPressed: _resetAllTexts,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
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
            // Whole PDF opens in continuous vertical scroll mode
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  _canvasWidth = constraints.maxWidth;
                  _canvasHeight = constraints.maxHeight;

                  return _isLoading
                      ? const Center(child: CustomCircularProgress())
                      : _isPdf
                          ? _buildPdfViewer(filePath)
                          : _buildImageViewer(filePath);
                },
              ),
            ),

            // FIXED: Bottom Action Bar matching user screenshot (Cross, + ADD button, Tick button)
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
          onTap: () => setState(() => _selectedTextIndex = null),
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
        for (var i = 0; i < _textElements.length; i++)
          _buildDraggableTextWidget(i, _textElements[i]),
      ],
    );
  }

  Widget _buildImageViewer(String filePath) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _selectedTextIndex = null),
      child: Stack(
        children: [
          Center(
            child: Image.file(
              File(filePath),
              fit: BoxFit.contain,
            ),
          ),
          for (var i = 0; i < _textElements.length; i++)
            _buildDraggableTextWidget(i, _textElements[i]),
        ],
      ),
    );
  }

  // FIXED: Picsart-style Draggable & Resizable Text Widget with selection toggle, Cross delete handle, and Arrow resize handle
  Widget _buildDraggableTextWidget(int index, TextAnnotationElement element) {
    final isSelected = _selectedTextIndex == index;

    return Positioned(
      left: element.offset.dx,
      top: element.offset.dy,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Draggable Container
          GestureDetector(
            onTap: () {
              setState(() => _selectedTextIndex = index);
            },
            onDoubleTap: () {
              _openAddTextSheet(existingElement: element, editIndex: index);
            },
            onPanUpdate: (details) {
              setState(() {
                _textElements[index] = element.copyWith(
                  offset: element.offset + details.delta,
                );
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withAlpha(220)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? AppColorScheme.primaryBlueStart
                      : Colors.transparent,
                  width: isSelected ? 2.0 : 0.0,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.black.withAlpha(30),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                element.text,
                textAlign: element.alignment,
                style: TextStyle(
                  color: element.color,
                  fontSize: element.fontSize,
                  fontFamily: element.fontFamily,
                  fontWeight: element.isBold
                      ? FontWeight.bold
                      : FontWeight.normal,
                  fontStyle: element.isItalic
                      ? FontStyle.italic
                      : FontStyle.normal,
                ),
              ),
            ),
          ),

          // Upper Left Corner (Cross icon to discard text - 44x44 touch hit target)
          if (isSelected)
            Positioned(
              top: -16,
              left: -16,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _deleteTextElement(index),
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

          // Lower Right Corner (Arrow handle to control text size - 44x44 touch hit target)
          if (isSelected)
            Positioned(
              bottom: -16,
              right: -16,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanUpdate: (details) {
                  final deltaScale = details.delta.dx + details.delta.dy;
                  final newSize = (element.fontSize + (deltaScale * 0.4)).clamp(
                    10.0,
                    120.0,
                  );
                  setState(() {
                    _textElements[index] = element.copyWith(fontSize: newSize);
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

  // FIXED: Bottom Action Toolbar matching exact screenshot (Cross, + ADD pill button, Tick apply button)
  Widget _buildBottomActionBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF232733),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left: Cross Cancel icon
            IconButton(
              icon: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 26,
              ),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(AppRoutes.home);
                }
              },
              tooltip: 'Cancel',
            ),

            // Center: + ADD pill button
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white38, width: 1.5),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              onPressed: _openAddTextSheet,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text(
                'ADD',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 1.0,
                ),
              ),
            ),

            // Right: Checkmark Tick icon (Saves text annotations & proceeds to success screen)
            IconButton(
              icon: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 26,
              ),
              onPressed: _saveAndApplyPdf,
              tooltip: 'Apply Text',
            ),
          ],
        ),
      ),
    );
  }
}
