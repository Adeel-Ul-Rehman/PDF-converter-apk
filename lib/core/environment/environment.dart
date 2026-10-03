/// ─────────────────────────────────────────────────────────────────────────────
/// Environment — Build Environment Configuration
///
/// Defines which runtime environment the app is operating in.
/// Enables environment-specific behaviour (logging, API endpoints, etc.)
/// without compile-time conditional blocks scattered across the codebase.
///
/// Usage:
/// ```dart
/// if (Environment.current == Environment.production) { ... }
/// ```
/// ─────────────────────────────────────────────────────────────────────────────
library;

// ignore_for_file: do_not_use_environment
import 'package:flutter/foundation.dart';

/// Represents the runtime environment of the application.
enum Environment {
  /// Local development environment — verbose logging, debug tools active.
  development,

  /// Staging / QA environment — production-like, with extra diagnostics.
  staging,

  /// Production environment — logs suppressed, optimised behaviour.
  production;

  /// Returns the active [Environment] derived from [kDebugMode] / [kReleaseMode].
  ///
  /// Override this by passing `--dart-define=ENVIRONMENT=staging` at build time.
  static Environment get current {
    const envName = String.fromEnvironment('ENVIRONMENT');
    return switch (envName) {
      'staging' => Environment.staging,
      'production' => Environment.production,
      _ => kReleaseMode ? Environment.production : Environment.development,
    };
  }

  /// Returns `true` when running in [Environment.development].
  bool get isDevelopment => this == Environment.development;

  /// Returns `true` when running in [Environment.staging].
  bool get isStaging => this == Environment.staging;

  /// Returns `true` when running in [Environment.production].
  bool get isProduction => this == Environment.production;

  /// Returns `true` when logging should be active (dev + staging).
  bool get isLoggingEnabled => !isProduction;
}
