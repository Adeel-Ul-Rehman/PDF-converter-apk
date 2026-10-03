import 'package:flutter/material.dart';
import 'package:flux_convert/core/theme/app_colors.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// AppTextStyles — Centralised Typography Scale
///
/// Uses the system font stack (Roboto on Android) for 100% offline-first
/// operation. No network requests, no download errors, zero latency.
/// ─────────────────────────────────────────────────────────────────────────────
abstract final class AppTextStyles {
  // ── Display ─────────────────────────────────────────────────────────────────
  static TextStyle get displayLarge => const TextStyle(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.25,
        height: 1.12,
      );

  static TextStyle get displayMedium => const TextStyle(
        fontSize: 45,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.16,
      );

  // ── Headline ────────────────────────────────────────────────────────────────
  static TextStyle get headline => const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        height: 1.29,
      );

  // ── Title & Subtitle ────────────────────────────────────────────────────────
  static TextStyle get title => const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        height: 1.4,
      );

  static TextStyle get subtitle => const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
        height: 1.45,
      );

  // ── Body ────────────────────────────────────────────────────────────────────
  static TextStyle get body => const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        height: 1.5,
      );

  // ── Caption ─────────────────────────────────────────────────────────────────
  static TextStyle get caption => const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        height: 1.33,
      );

  // ── Button ──────────────────────────────────────────────────────────────────
  static TextStyle get button => const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        height: 1.43,
      );

  // ── Label ───────────────────────────────────────────────────────────────────
  static TextStyle get label => const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        height: 1.33,
      );

  // ── Error ───────────────────────────────────────────────────────────────────
  static TextStyle get error => const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        height: 1.33,
        color: AppColorScheme.danger,
      );

  // ── Hint ────────────────────────────────────────────────────────────────────
  static TextStyle get hint => const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        height: 1.43,
      );

  // ── Backward Compatible Mappings for Theme/Widgets ──────────────────────────
  static TextStyle get titleLarge => title;
  static TextStyle get titleMedium => subtitle;
  static TextStyle get titleSmall => subtitle.copyWith(fontSize: 14);
  static TextStyle get bodyLarge => body.copyWith(fontSize: 16);
  static TextStyle get bodyMedium => body;
  static TextStyle get bodySmall => caption;
  static TextStyle get labelLarge => button;
  static TextStyle get labelMedium => label;
  static TextStyle get labelSmall => label.copyWith(fontSize: 11);

  /// Mono-spaced style for file paths, byte sizes, etc.
  /// Uses system monospace font — available offline on all devices.
  static TextStyle get mono => const TextStyle(
        fontFamily: 'monospace',
        fontSize: 13,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.5,
      );

  /// Builds the Material 3 TextTheme from the styles above.
  static TextTheme get textTheme => TextTheme(
        displayLarge: displayLarge,
        displayMedium: displayMedium,
        headlineMedium: headline,
        titleLarge: titleLarge,
        titleMedium: titleMedium,
        titleSmall: titleSmall,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        bodySmall: bodySmall,
        labelLarge: labelLarge,
        labelMedium: labelMedium,
        labelSmall: labelSmall,
      );
}
