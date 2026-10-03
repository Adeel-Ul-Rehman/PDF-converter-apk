import 'package:flutter/material.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// AppShadows — Centralized Design System Elevation Shadows
/// ─────────────────────────────────────────────────────────────────────────────
abstract final class AppShadows {
  /// Light/Subtle elevation preset (resting card)
  static final List<BoxShadow> light = [
    BoxShadow(
      color: const Color(0xFF000000).withAlpha(10),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  /// Medium elevation preset (active card / header)
  static final List<BoxShadow> medium = [
    BoxShadow(
      color: const Color(0xFF000000).withAlpha(15),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  /// Heavy elevation preset (dropdown overlay / dialog)
  static final List<BoxShadow> heavy = [
    BoxShadow(
      color: const Color(0xFF000000).withAlpha(20),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  /// Floating/Bouncy preset (FAB, bottom navigations)
  static final List<BoxShadow> floating = [
    BoxShadow(
      color: const Color(0xFF000000).withAlpha(15),
      blurRadius: 32,
      offset: const Offset(0, 12),
      spreadRadius: -4,
    ),
  ];
}
