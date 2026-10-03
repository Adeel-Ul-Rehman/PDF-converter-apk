import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

// IMPROVED: Filter parameters model supporting presets, custom sliders, and intensity
class FilterParams {
  const FilterParams({
    this.presetName = 'Original',
    this.intensity = 1.0,
    this.brightness = 0.0,   // -100 to +100
    this.contrast = 100.0,   // 0 to 200
    this.saturation = 100.0, // 0 to 200
    this.sharpness = 0.0,   // 0 to 100
    this.hue = 0.0,          // 0 to 360
    this.blur = 0.0,         // 0 to 100
  });

  final String presetName;
  final double intensity;  // 0.0 to 1.0
  final double brightness;
  final double contrast;
  final double saturation;
  final double sharpness;
  final double hue;
  final double blur;

  FilterParams copyWith({
    String? presetName,
    double? intensity,
    double? brightness,
    double? contrast,
    double? saturation,
    double? sharpness,
    double? hue,
    double? blur,
  }) =>
      FilterParams(
        presetName: presetName ?? this.presetName,
        intensity: intensity ?? this.intensity,
        brightness: brightness ?? this.brightness,
        contrast: contrast ?? this.contrast,
        saturation: saturation ?? this.saturation,
        sharpness: sharpness ?? this.sharpness,
        hue: hue ?? this.hue,
        blur: blur ?? this.blur,
      );

  static const List<String> presetNames = [
    'Original',
    'Vintage',
    'Noir',
    'Sepia',
    'Vivid',
    'Matte',
    'Cool',
    'Warm',
    'High Contrast',
    'Soft Glow',
    'Dramatic',
  ];
}

// IMPROVED: Domain Use Case for computing 5x5 ColorFilter matrices and baking isolate filters
class ApplyFilterUseCase {
  /// Generates a 5x5 ColorMatrix for 60fps real-time Flutter UI rendering
  ColorFilter buildColorFilter(FilterParams params) {
    final matrix = calculateColorMatrix(params);
    return ColorFilter.matrix(matrix);
  }

  /// Calculates 20-element ColorMatrix array for ColorFilter.matrix()
  List<double> calculateColorMatrix(FilterParams params) {
    // 1. Get base preset matrix
    var base = _getPresetMatrix(params.presetName);

    // Blend preset matrix with identity based on intensity (0.0 .. 1.0)
    if (params.intensity < 1.0) {
      base = _blendMatrices(_identityMatrix, base, params.intensity);
    }

    // 2. Compute custom adjustments (Brightness, Contrast, Saturation)
    final b = params.brightness; // -100 to 100
    final c = params.contrast / 100.0; // 0 to 2.0
    final s = params.saturation / 100.0; // 0 to 2.0

    // Multiply base matrix with brightness/contrast/saturation adjustments
    final invSat = 1.0 - s;
    final rLum = 0.2126 * invSat;
    final gLum = 0.7152 * invSat;
    final bLum = 0.0722 * invSat;

    final result = List<double>.from(base);

    // Apply scaling
    for (var i = 0; i < 15; i++) {
      if (i % 5 == 0) result[i] = (result[i] * c) + (rLum * c);
      if (i % 5 == 1) result[i] = (result[i] * c) + (gLum * c);
      if (i % 5 == 2) result[i] = (result[i] * c) + (bLum * c);
    }

    // Apply brightness offset
    result[4] += b;
    result[9] += b;
    result[14] += b;

    return result;
  }

  /// Offloads heavy pixel filter baking to a background isolate via compute()
  Future<String> bakeFilterInIsolate({
    required String sourcePath,
    required String outputPath,
    required FilterParams params,
  }) async {
    return compute(
      _bakeFilterIsolateEntryPoint,
      _BakeParams(sourcePath: sourcePath, outputPath: outputPath, params: params),
    );
  }

  static const List<double> _identityMatrix = [
    1, 0, 0, 0, 0,
    0, 1, 0, 0, 0,
    0, 0, 1, 0, 0,
    0, 0, 0, 1, 0,
  ];

  List<double> _getPresetMatrix(String preset) {
    return switch (preset) {
      'Vintage' => const [
          0.9, 0.5, 0.1, 0, 10,
          0.3, 0.8, 0.1, 0, 5,
          0.2, 0.3, 0.5, 0, 0,
          0, 0, 0, 1, 0,
        ],
      'Noir' => const [
          0.33, 0.33, 0.33, 0, -20,
          0.33, 0.33, 0.33, 0, -20,
          0.33, 0.33, 0.33, 0, -20,
          0, 0, 0, 1, 0,
        ],
      'Sepia' => const [
          0.393, 0.769, 0.189, 0, 0,
          0.349, 0.686, 0.168, 0, 0,
          0.272, 0.534, 0.131, 0, 0,
          0, 0, 0, 1, 0,
        ],
      'Vivid' => const [
          1.3, -0.1, -0.1, 0, 0,
          -0.1, 1.3, -0.1, 0, 0,
          -0.1, -0.1, 1.3, 0, 0,
          0, 0, 0, 1, 0,
        ],
      'Matte' => const [
          0.8, 0.1, 0.1, 0, 20,
          0.1, 0.8, 0.1, 0, 20,
          0.1, 0.1, 0.8, 0, 20,
          0, 0, 0, 1, 0,
        ],
      'Cool' => const [
          0.8, 0, 0, 0, 0,
          0, 0.9, 0, 0, 0,
          0, 0, 1.2, 0, 15,
          0, 0, 0, 1, 0,
        ],
      'Warm' => const [
          1.2, 0, 0, 0, 15,
          0, 1.0, 0, 0, 5,
          0, 0, 0.8, 0, 0,
          0, 0, 0, 1, 0,
        ],
      'High Contrast' => const [
          1.5, 0, 0, 0, -25,
          0, 1.5, 0, 0, -25,
          0, 0, 1.5, 0, -25,
          0, 0, 0, 1, 0,
        ],
      'Soft Glow' => const [
          1.1, 0.05, 0.05, 0, 10,
          0.05, 1.1, 0.05, 0, 10,
          0.05, 0.05, 1.1, 0, 10,
          0, 0, 0, 1, 0,
        ],
      'Dramatic' => const [
          1.4, -0.1, -0.1, 0, -10,
          -0.1, 1.4, -0.1, 0, -10,
          -0.1, -0.1, 1.4, 0, -10,
          0, 0, 0, 1, 0,
        ],
      _ => _identityMatrix,
    };
  }

  List<double> _blendMatrices(List<double> m1, List<double> m2, double t) {
    final result = List<double>.filled(20, 0.0);
    for (var i = 0; i < 20; i++) {
      result[i] = m1[i] + (m2[i] - m1[i]) * t;
    }
    return result;
  }
}

// ─── Isolate entry point ───────────────────────────────────────────────────

class _BakeParams {
  const _BakeParams({
    required this.sourcePath,
    required this.outputPath,
    required this.params,
  });

  final String sourcePath;
  final String outputPath;
  final FilterParams params;
}

String _bakeFilterIsolateEntryPoint(_BakeParams bakeParams) {
  final srcFile = File(bakeParams.sourcePath);
  if (!srcFile.existsSync()) return bakeParams.sourcePath;

  var decoded = img.decodeImage(srcFile.readAsBytesSync());
  if (decoded == null) return bakeParams.sourcePath;

  final p = bakeParams.params;

  // Apply contrast / brightness
  final cVal = (p.contrast / 100.0) * p.intensity;
  final bVal = ((p.brightness + 100.0) / 100.0) * p.intensity;
  decoded = img.adjustColor(decoded, contrast: cVal, brightness: bVal);

  // Apply preset specific color transforms
  switch (p.presetName) {
    case 'Noir' || 'Sepia':
      decoded = img.grayscale(decoded);
    case 'Vivid' || 'Dramatic':
      decoded = img.adjustColor(decoded, saturation: 1.5);
    case 'Cool':
      decoded = img.adjustColor(decoded, amount: 0.1);
    default:
      break;
  }

  final outFile = File(bakeParams.outputPath);
  outFile.writeAsBytesSync(img.encodeJpg(decoded, quality: 90));
  return bakeParams.outputPath;
}
