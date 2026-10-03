import 'package:flutter/material.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// ColorExtensions — Styling helper utilities on Color instances
/// ─────────────────────────────────────────────────────────────────────────────
extension ColorExtensions on Color {
  /// Darkens a color by a specific fraction (0.0 to 1.0).
  Color darken([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1, 'Amount must be between 0.0 and 1.0');
    final f = 1.0 - amount;
    return Color.fromARGB(
      (a * 255.0).round().clamp(0, 255),
      ((r * 255.0).round().clamp(0, 255) * f).round(),
      ((g * 255.0).round().clamp(0, 255) * f).round(),
      ((b * 255.0).round().clamp(0, 255) * f).round(),
    );
  }

  /// Lightens a color by a specific fraction (0.0 to 1.0).
  Color lighten([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1, 'Amount must be between 0.0 and 1.0');
    final ri = (r * 255.0).round().clamp(0, 255);
    final gi = (g * 255.0).round().clamp(0, 255);
    final bi = (b * 255.0).round().clamp(0, 255);
    return Color.fromARGB(
      (a * 255.0).round().clamp(0, 255),
      ri + ((255 - ri) * amount).round(),
      gi + ((255 - gi) * amount).round(),
      bi + ((255 - bi) * amount).round(),
    );
  }

  /// Returns true if the color is light (relative luminance > 0.5).
  bool get isLight => ThemeData.estimateBrightnessForColor(this) == Brightness.light;

  /// Returns true if the color is dark (relative luminance <= 0.5).
  bool get isDark => !isLight;
}
