import 'package:flutter/material.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// AppDimensions — Reusable Spacing & Size Tokens
///
/// Centralizes all dimensions. Includes Spacing, Padding, and SizedBox helpers.
/// ─────────────────────────────────────────────────────────────────────────────
abstract final class AppDimensions {
  // ── Spacing Tokens ─────────────────────────────────────────────────────────
  static const double s2 = 2.0;
  static const double s4 = 4.0;
  static const double s6 = 6.0;
  static const double s8 = 8.0;
  static const double s10 = 10.0;
  static const double s12 = 12.0;
  static const double s16 = 16.0;
  static const double s20 = 20.0;
  static const double s24 = 24.0;
  static const double s28 = 28.0;
  static const double s32 = 32.0;
  static const double s40 = 40.0;
  static const double s48 = 48.0;
  static const double s56 = 56.0;
  static const double s64 = 64.0;
  static const double s80 = 80.0;

  // ── Backward Compatible Mappings for AppTheme and Extensions ───────────────
  static const double spaceXs = s4;
  static const double spaceSmall = s8;
  static const double spaceMedium = s16;
  static const double spaceLarge = s24;
  static const double spaceXl = s32;
  static const double spaceXxl = s48;
  static const double spaceXxxl = s64;
  static const double spaceXxs = s2;
  static const double radiusCircular = 100.0;

  // ── SizedBox Helpers ───────────────────────────────────────────────────────
  static const SizedBox h2 = SizedBox(height: s2);
  static const SizedBox h4 = SizedBox(height: s4);
  static const SizedBox h6 = SizedBox(height: s6);
  static const SizedBox h8 = SizedBox(height: s8);
  static const SizedBox h10 = SizedBox(height: s10);
  static const SizedBox h12 = SizedBox(height: s12);
  static const SizedBox h16 = SizedBox(height: s16);
  static const SizedBox h20 = SizedBox(height: s20);
  static const SizedBox h24 = SizedBox(height: s24);
  static const SizedBox h28 = SizedBox(height: s28);
  static const SizedBox h32 = SizedBox(height: s32);
  static const SizedBox h40 = SizedBox(height: s40);
  static const SizedBox h48 = SizedBox(height: s48);
  static const SizedBox h56 = SizedBox(height: s56);
  static const SizedBox h64 = SizedBox(height: s64);
  static const SizedBox h80 = SizedBox(height: s80);

  static const SizedBox w2 = SizedBox(width: s2);
  static const SizedBox w4 = SizedBox(width: s4);
  static const SizedBox w6 = SizedBox(width: s6);
  static const SizedBox w8 = SizedBox(width: s8);
  static const SizedBox w10 = SizedBox(width: s10);
  static const SizedBox w12 = SizedBox(width: s12);
  static const SizedBox w16 = SizedBox(width: s16);
  static const SizedBox w20 = SizedBox(width: s20);
  static const SizedBox w24 = SizedBox(width: s24);
  static const SizedBox w28 = SizedBox(width: s28);
  static const SizedBox w32 = SizedBox(width: s32);
  static const SizedBox w40 = SizedBox(width: s40);
  static const SizedBox w48 = SizedBox(width: s48);
  static const SizedBox w56 = SizedBox(width: s56);
  static const SizedBox w64 = SizedBox(width: s64);
  static const SizedBox w80 = SizedBox(width: s80);

  // ── Padding Helpers ────────────────────────────────────────────────────────
  static const EdgeInsets paddingAll4 = EdgeInsets.all(s4);
  static const EdgeInsets paddingAll8 = EdgeInsets.all(s8);
  static const EdgeInsets paddingAll12 = EdgeInsets.all(s12);
  static const EdgeInsets paddingAll16 = EdgeInsets.all(s16);
  static const EdgeInsets paddingAll24 = EdgeInsets.all(s24);

  static const EdgeInsets paddingHorizontal16 = EdgeInsets.symmetric(horizontal: s16);
  static const EdgeInsets paddingHorizontal24 = EdgeInsets.symmetric(horizontal: s24);
  
  static const EdgeInsets paddingVertical12 = EdgeInsets.symmetric(vertical: s12);
  static const EdgeInsets paddingVertical16 = EdgeInsets.symmetric(vertical: s16);

  static const EdgeInsets paddingScreenContent = EdgeInsets.symmetric(
    horizontal: s16,
    vertical: s20,
  );
}
