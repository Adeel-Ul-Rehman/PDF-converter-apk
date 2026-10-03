import 'package:flutter/material.dart';
import 'package:flux_convert/features/annotations/domain/annotation_models.dart';
import 'package:flux_convert/features/annotations/presentation/annotation_painter.dart';

// FIXED: Reusable signature/drawing pad with draw/scroll toggle support
/// A reusable, smooth signature/drawing pad with Draw/Scroll mode support.
class AnnotationPad extends StatefulWidget {
  const AnnotationPad({
    super.key,
    this.strokeColor = Colors.black,
    this.strokeWidth = 3.0,
    this.eraserMode = false,
    this.isDrawMode = true,
    this.onStarted,
    this.onChanged,
    this.onCommit,
    this.initialStrokes = const [],
    this.normalizeOutput = false,
    this.pageIndex = 0,
  });

  final Color strokeColor;
  final double strokeWidth;
  final bool eraserMode;
  final bool isDrawMode;
  final VoidCallback? onStarted;
  final ValueChanged<List<DoodleStroke>>? onChanged;
  final ValueChanged<List<DoodleStroke>>? onCommit;
  final List<DoodleStroke> initialStrokes;
  final bool normalizeOutput;
  final int pageIndex;

  @override
  State<AnnotationPad> createState() => _AnnotationPadState();
}

class _AnnotationPadState extends State<AnnotationPad> {
  final List<DoodleStroke> _strokes = [];
  final List<Offset> _currentPoints = [];
  bool _drawing = false;

  @override
  void initState() {
    super.initState();
    _strokes.addAll(widget.initialStrokes);
  }

  void _onPanStart(DragStartDetails d) {
    if (!widget.isDrawMode) return;
    _drawing = true;
    _currentPoints
      ..clear()
      ..add(d.localPosition);
    widget.onStarted?.call();
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (!_drawing || !widget.isDrawMode) return;
    _currentPoints.add(d.localPosition);
    setState(() {});
  }

  void _onPanEnd(DragEndDetails d) {
    if (!_drawing || !widget.isDrawMode) return;
    _drawing = false;

    if (_currentPoints.length > 1) {
      final stroke = DoodleStroke(
        points: List<Offset>.from(_currentPoints),
        color: widget.strokeColor,
        width: widget.strokeWidth,
        isEraser: widget.eraserMode,
        pageIndex: widget.pageIndex,
      );
      _strokes.add(stroke);
      widget.onCommit?.call(List.unmodifiable(_strokes));
      widget.onChanged?.call(List.unmodifiable(_strokes));
    }

    _currentPoints.clear();
  }

  List<DoodleStroke> normalizedStrokes() {
    if (_strokes.isEmpty) return const [];
    var minX = double.infinity;
    var minY = double.infinity;
    var maxX = double.negativeInfinity;
    var maxY = double.negativeInfinity;
    for (final s in _strokes) {
      for (final p in s.points) {
        minX = p.dx < minX ? p.dx : minX;
        minY = p.dy < minY ? p.dy : minY;
        maxX = p.dx > maxX ? p.dx : maxX;
        maxY = p.dy > maxY ? p.dy : maxY;
      }
    }
    final w = maxX - minX;
    final h = maxY - minY;
    if (w <= 0 || h <= 0) return _strokes;
    return _strokes
        .map(
          (s) => s.copyWith(
            points: s.points
                .map((p) => Offset((p.dx - minX) / w, (p.dy - minY) / h))
                .toList(),
          ),
        )
        .toList();
  }

  void clear() {
    setState(() {
      _strokes.clear();
      _currentPoints.clear();
    });
    widget.onChanged?.call(const []);
  }

  @override
  Widget build(BuildContext context) {
    final currentStroke = _drawing && _currentPoints.length > 1
        ? DoodleStroke(
            points: List<Offset>.from(_currentPoints),
            color: widget.strokeColor,
            width: widget.strokeWidth,
            isEraser: widget.eraserMode,
            pageIndex: widget.pageIndex,
          )
        : null;

    final allStrokes = currentStroke != null
        ? [..._strokes, currentStroke]
        : _strokes;

    return GestureDetector(
      behavior: widget.isDrawMode ? HitTestBehavior.opaque : HitTestBehavior.translucent,
      onPanStart: widget.isDrawMode ? _onPanStart : null,
      onPanUpdate: widget.isDrawMode ? _onPanUpdate : null,
      onPanEnd: widget.isDrawMode ? _onPanEnd : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CustomPaint(
          size: Size.infinite,
          painter: DoodleBoardPainter(
            strokes: allStrokes,
            pageIndex: widget.pageIndex,
          ),
        ),
      ),
    );
  }
}
