import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flux_convert/core/error/error_handler.dart';
import 'package:flux_convert/core/logging/logger_service.dart';
import 'package:flux_convert/features/conversion/core/adapters/placeholders.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// AppBootstrap — Application Warm-up & Setup Handler
///
/// Prepares asynchronous plugins, registers handlers, and returns initial
/// values like [SharedPreferences] to configure Riverpod's ProviderScope.
/// ─────────────────────────────────────────────────────────────────────────────
abstract final class AppBootstrap {
  /// Core warm-up routine. Runs before runApp() is called.
  static Future<SharedPreferences> init() async {
    // 1. Ensure bindings are setup
    WidgetsFlutterBinding.ensureInitialized();

    // 2. Global framework exception routing
    FlutterError.onError = AppErrorHandler.onFlutterError;
    PlatformDispatcher.instance.onError = AppErrorHandler.onPlatformError;

    // 3. Logger initialization
    AppLogger.init();
    AppLogger.info('AppBootstrap: Initializing core components...');

    // 4. Registry placeholder registrations
    Placeholders.registerAll();

    // 5. SharedPreferences initialization
    final prefs = await SharedPreferences.getInstance();

    AppLogger.info('AppBootstrap: Warm-up finished successfully.');
    return prefs;
  }
}
