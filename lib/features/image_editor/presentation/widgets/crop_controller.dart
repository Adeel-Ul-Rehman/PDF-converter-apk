import 'package:flutter/material.dart';

/// CropRectData — Fraction 0.0 .. 1.0 representation of the crop rectangle
class CropRectData {
  const CropRectData({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  final double left;   // Fraction 0.0 .. 1.0
  final double top;    // Fraction 0.0 .. 1.0
  final double width;  // Fraction 0.0 .. 1.0
  final double height; // Fraction 0.0 .. 1.0

  double get right => (left + width).clamp(0.0, 1.0);
  double get bottom => (top + height).clamp(0.0, 1.0);

  CropRectData copyWith({
    double? left,
    double? top,
    double? width,
    double? height,
  }) =>
      CropRectData(
        left: left ?? this.left,
        top: top ?? this.top,
        width: width ?? this.width,
        height: height ?? this.height,
      );

  static const full = CropRectData(left: 0.0, top: 0.0, width: 1.0, height: 1.0);
}

class CropController extends ChangeNotifier {
  CropController({CropRectData? initialCrop})
      : _current = initialCrop ?? CropRectData.full {
    _historyStack.add(_current);
  }

  CropRectData _current;
  CropRectData get current => _current;

  double? _aspectRatio;
  double? get aspectRatio => _aspectRatio;

  int _rotationTurns = 0;
  int get rotationTurns => _rotationTurns;

  bool _isFlippedHorizontally = false;
  bool get isFlippedHorizontally => _isFlippedHorizontally;

  bool _isFlippedVertically = false;
  bool get isFlippedVertically => _isFlippedVertically;

  final List<CropRectData> _historyStack = [];
  bool get canUndo => _historyStack.length > 1;

  void setAspectRatio(double? ratio, Size imageSize) {
    _aspectRatio = ratio;
    if (ratio != null && imageSize.width > 0 && imageSize.height > 0) {
      _applyAspectRatioConstraint(imageSize);
    }
    notifyListeners();
  }

  void rotate90Degrees() {
    _rotationTurns = (_rotationTurns + 1) % 4;
    notifyListeners();
  }

  void toggleFlipHorizontal() {
    _isFlippedHorizontally = !_isFlippedHorizontally;
    notifyListeners();
  }

  void toggleFlipVertical() {
    _isFlippedVertically = !_isFlippedVertically;
    notifyListeners();
  }

  /// Updates crop rectangle using exact boundary positions (left, top, right, bottom)
  /// with automatic swapping if handles cross over each other (e.g. dragging top below bottom).
  void updateCropEdges({
    required double left,
    required double top,
    required double right,
    required double bottom,
    Size? imageSize,
  }) {
    var minL = left.clamp(0.0, 1.0);
    var minT = top.clamp(0.0, 1.0);
    var maxR = right.clamp(0.0, 1.0);
    var maxB = bottom.clamp(0.0, 1.0);

    // Swap if crossed over (drag top past bottom or left past right)
    if (minL > maxR) {
      final temp = minL;
      minL = maxR;
      maxR = temp;
    }
    if (minT > maxB) {
      final temp = minT;
      minT = maxB;
      maxB = temp;
    }

    // Ensure minimum size (5% of image width/height)
    var w = maxR - minL;
    var h = maxB - minT;
    if (w < 0.05) w = 0.05;
    if (h < 0.05) h = 0.05;

    // Clamp right/bottom within bounds
    if (minL + w > 1.0) minL = 1.0 - w;
    if (minT + h > 1.0) minT = 1.0 - h;

    _current = CropRectData(
      left: minL,
      top: minT,
      width: w,
      height: h,
    );

    if (_aspectRatio != null && imageSize != null) {
      _applyAspectRatioConstraint(imageSize);
    }

    _pushHistory(_current);
    notifyListeners();
  }

  /// Legacy helper for fraction updating
  void updateCropFraction({
    required double left,
    required double top,
    required double width,
    required double height,
    Size? imageSize,
  }) {
    updateCropEdges(
      left: left,
      top: top,
      right: left + width,
      bottom: top + height,
      imageSize: imageSize,
    );
  }

  void reset() {
    _current = CropRectData.full;
    _aspectRatio = null;
    _rotationTurns = 0;
    _isFlippedHorizontally = false;
    _isFlippedVertically = false;
    _historyStack.clear();
    _historyStack.add(_current);
    notifyListeners();
  }

  void undo() {
    if (canUndo) {
      _historyStack.removeLast();
      _current = _historyStack.last;
      notifyListeners();
    }
  }

  void _pushHistory(CropRectData state) {
    if (_historyStack.isEmpty || _historyStack.last != state) {
      _historyStack.add(state);
      if (_historyStack.length > 30) {
        _historyStack.removeAt(0);
      }
    }
  }

  void _applyAspectRatioConstraint(Size imageSize) {
    if (_aspectRatio == null) return;

    final targetRatio = _aspectRatio!;

    var currentW = _current.width * imageSize.width;
    var currentH = _current.height * imageSize.height;

    currentH = currentW / targetRatio;
    if (currentH > imageSize.height * (1.0 - _current.top)) {
      currentH = imageSize.height * (1.0 - _current.top);
      currentW = currentH * targetRatio;
    }

    final newW = (currentW / imageSize.width).clamp(0.05, 1.0 - _current.left);
    final newH = (currentH / imageSize.height).clamp(0.05, 1.0 - _current.top);

    _current = _current.copyWith(width: newW, height: newH);
  }
}
