import 'package:flutter/material.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// AppColorScheme — Strict 2-3 Color Design System Palette
///
/// Ensures unified brand identity across Light & Dark modes:
/// 1. Brand Primary Accent: Royal Indigo Blue (0xFF1E88E5)
/// 2. Surfaces & Backgrounds: Clean Light Slate (0xFFF5F7FA) / Sleek Dark Greyish Slate (0xFF12151C)
/// 3. Typography Neutrals: Charcoal Dark (0xFF1A1D26) / Off-White (0xFFF0F2F5)
/// ─────────────────────────────────────────────────────────────────────────────
abstract final class AppColorScheme {
  // ── Brand Primary Accent (Color #1) ───────────────────────────────────────
  static const Color primaryBlueStart = Color(0xFF1E88E5);
  static const Color primaryBlueEnd = Color(0xFF1565C0);
  static const Color accent = Color(0xFF1E88E5);

  // ── Backward Compatible Mappings ──────────────────────────────────────────
  static const Color secondaryPurpleStart = Color(0xFF1E88E5);
  static const Color secondaryPurpleEnd = Color(0xFF1565C0);

  // ── Semantic Feedback ──────────────────────────────────────────────────────
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFED6C02);
  static const Color danger = Color(0xFFD32F2F);

  // ── Light Theme Palette ────────────────────────────────────────────────────
  static const Color backgroundLight = Color(0xFFF5F7FA);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE5E8EB);
  static const Color textPrimaryLight = Color(0xFF1A1D26);
  static const Color textSecondaryLight = Color(0xFF6C727F);

  // ── Dark Theme Palette (Sleek Greyish Dark Slate) ──────────────────────────
  static const Color backgroundDark = Color(0xFF12151C);
  static const Color surfaceDark = Color(0xFF1C202B);
  static const Color cardDark = Color(0xFF1C202B);
  static const Color borderDark = Color(0xFF2A2F3D);
  static const Color textPrimaryDark = Color(0xFFF0F2F5);
  static const Color textSecondaryDark = Color(0xFF949BAA);

  // ── Legacy Aliases ────────────────────────────────────────────────────────
  static const Color background = backgroundLight;
  static const Color surface = surfaceLight;
  static const Color card = cardLight;
  static const Color border = borderLight;
  static const Color textPrimary = textPrimaryLight;
  static const Color textSecondary = textSecondaryLight;
  static const Color disabled = Color(0xFFBDBDBD);

  static const Color primary = primaryBlueStart;
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color secondary = primaryBlueStart;
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color tertiary = primaryBlueStart;
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color error = danger;

  static const Color surfaceVariantLight = Color(0xFFF5F7FA);
  static const Color onSurfaceLight = textPrimaryLight;

  static const Color outline = borderLight;
  static const Color outlineVariant = borderLight;
  static const Color shadow = Color(0xFF000000);
  static const Color scrim = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  // ── Unified Gradients ─────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryBlueStart, primaryBlueEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [primaryBlueStart, primaryBlueEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF388E3C), success],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warningGradient = LinearGradient(
    colors: [Color(0xFFF57C00), warning],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient dangerGradient = LinearGradient(
    colors: [Color(0xFFE53935), danger],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
