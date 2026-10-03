import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flux_convert/bootstrap/bootstrap.dart';
import 'package:flux_convert/core/error/error_handler.dart';
import 'package:flux_convert/core/routing/app_router.dart';
import 'package:flux_convert/core/services/error_log_service.dart';
import 'package:flux_convert/core/services/storage_service.dart';
import 'package:flux_convert/core/theme/app_theme.dart';
import 'package:flux_convert/features/settings/presentation/providers/settings_providers.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Application Entrypoint
///
/// Bootstraps the app inside a zoned guard to catch uncaught async errors.
/// Integrates with ErrorLogService for production-grade error logging.
/// ─────────────────────────────────────────────────────────────────────────────
void main() {
  FlutterError.onError = AppErrorHandler.onFlutterError;
  PlatformDispatcher.instance.onError = AppErrorHandler.onPlatformError;

  runZonedGuarded(() => unawaited(_bootstrap()), AppErrorHandler.onZoneError);
}

Future<void> _bootstrap() async {
  final prefs = await AppBootstrap.init();
  await ErrorLogService.instance.init(prefs);

  // FIXED: Configure Flutter ImageCache limits to eliminate Memory Pressure Warnings
  PaintingBinding.instance.imageCache.maximumSizeBytes = 40 * 1024 * 1024; // 40MB max
  PaintingBinding.instance.imageCache.maximumSize = 80; // max 80 cached images
  WidgetsBinding.instance.addObserver(_AppMemoryObserver());

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const FluxConvertApp(),
    ),
  );
}

// FIXED: Handles device low-memory events by flushing image caches immediately
class _AppMemoryObserver extends WidgetsBindingObserver {
  @override
  void didHaveMemoryPressure() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  }
}

/// Root widget of the application.
class FluxConvertApp extends ConsumerWidget {
  const FluxConvertApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(
      settingsNotifierProvider.select((settings) => settings.themeMode),
    );

    return MaterialApp.router(
      title: 'FluxConvert',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _resolveThemeMode(themeMode),
      routerConfig: AppRouter.config,
    );
  }

  ThemeMode _resolveThemeMode(String mode) {
    switch (mode) {
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      case 'light':
      default:
        return ThemeMode.light;
    }
  }
}
