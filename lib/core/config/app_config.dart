import 'package:flutter/foundation.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// AppConfig — Application-wide Configuration Constants
///
/// Centralises all environment-specific values in one place.
/// No hardcoded strings should exist outside of constants files.
/// ─────────────────────────────────────────────────────────────────────────────
abstract final class AppConfig {
  // ── App Identity ────────────────────────────────────────────────────────────
  static const String appName = 'FluxConvert';
  static const String appPackageName = 'com.fluxconvert.app';
  static const String appVersion = '1.0.0';
  static const int appBuildNumber = 1;

  // ── Build Environment ───────────────────────────────────────────────────────
  static const bool isDebug = kDebugMode;
  static const bool isRelease = kReleaseMode;
  static const bool isProfile = kProfileMode;

  // ── Storage Keys ────────────────────────────────────────────────────────────
  static const String prefsKeyThemeMode = 'pref_theme_mode';
  static const String prefsKeyOnboardingDone = 'pref_onboarding_done';
  static const String prefsKeyConversionHistoryPath = 'pref_history_path';

  // ── File Limits ─────────────────────────────────────────────────────────────
  /// Maximum allowed input file size in bytes (default: 500 MB).
  static const int maxFileSizeBytes = 500 * 1024 * 1024;

  /// Maximum number of concurrent conversion jobs.
  static const int maxConcurrentJobs = 2;

  // ── Timeouts ─────────────────────────────────────────────────────────────────
  /// Default conversion operation timeout.
  static const Duration conversionTimeout = Duration(minutes: 10);

  // ── Networking (reserved for future Hybrid mode) ────────────────────────────
  // static const String apiBaseUrl = 'https://api.fluxconvert.com';
}
